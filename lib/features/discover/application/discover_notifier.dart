import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/perf/trace.dart';
import '../../../core/providers.dart';
import '../../../data/remote/remote_series_repository.dart';
import '../../../domain/entities/category.dart';
import '../../../domain/entities/series.dart';
import 'discover_state.dart';

class DiscoverNotifier extends AsyncNotifier<DiscoverState> {
  @override
  Future<DiscoverState> build() async {
    return withTrace('discover_load', () async {
      final repo = ref.read(seriesRepositoryProvider);
      if (repo is RemoteSeriesRepository) {
        final home = await repo.homeCatalog();
        List<Series> hot = [
          ...home.heroes,
          ...home.sections.expand((section) => section.series),
        ];
        try {
          hot = await repo.byCategory(Category.hot, limit: 60);
        } catch (_) {
          // /home remains a valid first paint if an older server has not
          // exposed the trending collection yet.
        }
        return DiscoverState(
          currentCategory: Category.hot,
          selectedTab: DiscoverHomeTab.hot,
          hero: home.hero,
          series: hot,
          sections: home.sections
              .map(
                (section) => DiscoverSection(
                  slug: section.slug,
                  title: section.title,
                  series: section.series,
                ),
              )
              .toList(),
        );
      }
      final series = await repo.byCategory(Category.forYou);
      return DiscoverState(
        currentCategory: Category.forYou,
        selectedTab: DiscoverHomeTab.hot,
        series: series,
      );
    });
  }

  Future<void> selectTab(DiscoverHomeTab tab) async {
    final previous = state.valueOrNull;
    if (tab == DiscoverHomeTab.categories) {
      state = AsyncData(
        DiscoverState(
          currentCategory: previous?.currentCategory ?? Category.forYou,
          selectedTab: tab,
          series: previous?.series ?? const [],
          sections: previous?.sections ?? const [],
          hero: previous?.hero,
        ),
      );
      return;
    }
    state = const AsyncLoading<DiscoverState>().copyWithPrevious(state);
    try {
      final repo = ref.read(seriesRepositoryProvider);
      final category = switch (tab) {
        DiscoverHomeTab.hot => Category.hot,
        DiscoverHomeTab.newReleases => Category.newReleases,
        DiscoverHomeTab.ranking => Category.hot,
        DiscoverHomeTab.categories => Category.forYou,
      };
      final series =
          tab == DiscoverHomeTab.ranking && repo is RemoteSeriesRepository
              ? await repo.ranked(limit: 60)
              : await repo.byCategory(category, limit: 60);
      final current = state.valueOrNull ?? previous;
      state = AsyncData(
        DiscoverState(
          currentCategory: category,
          selectedTab: tab,
          series: series,
          sections: current?.sections ?? const [],
          hero: current?.hero,
        ),
      );
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
    }
  }

  Future<void> selectCategory(Category c) async {
    state = const AsyncLoading<DiscoverState>().copyWithPrevious(state);
    try {
      final repo = ref.read(seriesRepositoryProvider);
      final series = await repo.byCategory(c);
      state = AsyncData(
        DiscoverState(
          currentCategory: c,
          selectedTab: DiscoverHomeTab.categories,
          series: series,
        ),
      );
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }
}

final discoverNotifierProvider =
    AsyncNotifierProvider<DiscoverNotifier, DiscoverState>(
  DiscoverNotifier.new,
);
