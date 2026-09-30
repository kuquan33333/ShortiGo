import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/perf/trace.dart';
import '../../../core/providers.dart';
import '../../../data/remote/remote_series_repository.dart';
import '../../../domain/entities/category.dart';
import 'discover_state.dart';

class DiscoverNotifier extends AsyncNotifier<DiscoverState> {
  @override
  Future<DiscoverState> build() async {
    return withTrace('discover_load', () async {
      final repo = ref.read(seriesRepositoryProvider);
      if (repo is RemoteSeriesRepository) {
        final home = await repo.homeCatalog();
        return DiscoverState(
          currentCategory: Category.forYou,
          hero: home.hero,
          series: [
            ...home.heroes,
            ...home.sections.expand((section) => section.series),
          ],
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
      return DiscoverState(currentCategory: Category.forYou, series: series);
    });
  }

  Future<void> selectCategory(Category c) async {
    state = const AsyncLoading<DiscoverState>().copyWithPrevious(state);
    try {
      final repo = ref.read(seriesRepositoryProvider);
      final series = await repo.byCategory(c);
      state = AsyncData(
        DiscoverState(currentCategory: c, series: series),
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
