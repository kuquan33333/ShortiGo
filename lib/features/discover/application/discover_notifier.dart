import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/perf/trace.dart';
import '../../../core/providers.dart';
import '../../../data/remote/remote_series_repository.dart';
import '../../../domain/entities/category.dart';
import '../../../domain/entities/series.dart';
import 'discover_state.dart';

class DiscoverNotifier extends AsyncNotifier<DiscoverState> {
  final _tabCache = <DiscoverHomeTab, List<Series>>{};
  final _categoryCache = <Category, List<Series>>{};
  final _inflight = <String, Future<List<Series>>>{};
  int? _sourceRevision;

  @override
  Future<DiscoverState> build() async {
    final sourceRevision = ref.watch(contentApiRevisionProvider);
    if (_sourceRevision != sourceRevision) {
      _sourceRevision = sourceRevision;
      _tabCache.clear();
      _categoryCache.clear();
      _inflight.clear();
    }
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
        _tabCache[DiscoverHomeTab.hot] = List.unmodifiable(hot);
        final result = DiscoverState(
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
        unawaited(_loadTab(DiscoverHomeTab.newReleases));
        unawaited(_loadTab(DiscoverHomeTab.ranking));
        return result;
      }
      final series = await repo.byCategory(Category.forYou);
      _tabCache[DiscoverHomeTab.hot] = List.unmodifiable(series);
      final result = DiscoverState(
        currentCategory: Category.forYou,
        selectedTab: DiscoverHomeTab.hot,
        series: series,
      );
      return result;
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
    final category = _categoryForTab(tab);
    final cached = _tabCache[tab];
    state = AsyncData(_tabState(
      previous,
      tab: tab,
      category: category,
      series: cached ?? previous?.series ?? const [],
    ));
    if (cached != null) return;

    try {
      final series = await _loadTab(tab);
      if (state.valueOrNull?.selectedTab != tab) return;
      state = AsyncData(_tabState(
        state.valueOrNull ?? previous,
        tab: tab,
        category: category,
        series: series,
      ));
    } catch (error, stackTrace) {
      if (state.valueOrNull?.selectedTab == tab) {
        state = AsyncError<DiscoverState>(error, stackTrace)
            .copyWithPrevious(state);
      }
    }
  }

  Future<void> selectCategory(Category c) async {
    final previous = state.valueOrNull;
    final cached = _categoryCache[c];
    state = AsyncData(_tabState(
      previous,
      tab: DiscoverHomeTab.categories,
      category: c,
      series: cached ?? previous?.series ?? const [],
    ));
    if (cached != null) return;
    try {
      final series = await _loadCategory(c);
      if (state.valueOrNull?.selectedTab != DiscoverHomeTab.categories ||
          state.valueOrNull?.currentCategory != c) {
        return;
      }
      state = AsyncData(_tabState(
        state.valueOrNull ?? previous,
        tab: DiscoverHomeTab.categories,
        category: c,
        series: series,
      ));
    } catch (e, st) {
      if (state.valueOrNull?.selectedTab == DiscoverHomeTab.categories &&
          state.valueOrNull?.currentCategory == c) {
        state = AsyncError<DiscoverState>(e, st).copyWithPrevious(state);
      }
    }
  }

  Category _categoryForTab(DiscoverHomeTab tab) => switch (tab) {
        DiscoverHomeTab.hot => Category.hot,
        DiscoverHomeTab.newReleases => Category.newReleases,
        DiscoverHomeTab.ranking => Category.hot,
        DiscoverHomeTab.categories => Category.forYou,
      };

  Future<List<Series>> _loadTab(DiscoverHomeTab tab) {
    final key = 'tab:${tab.name}';
    final existing = _inflight[key];
    if (existing != null) return existing;
    final future = () async {
      final repo = ref.read(seriesRepositoryProvider);
      final category = _categoryForTab(tab);
      final series =
          tab == DiscoverHomeTab.ranking && repo is RemoteSeriesRepository
              ? await repo.ranked(limit: 60)
              : await repo.byCategory(category, limit: 60);
      final result = List<Series>.unmodifiable(series);
      _tabCache[tab] = result;
      return result;
    }();
    _inflight[key] = future;
    future.then<void>(
      (_) => _inflight.remove(key),
      onError: (Object _, StackTrace __) => _inflight.remove(key),
    );
    return future;
  }

  Future<List<Series>> _loadCategory(Category category) {
    final key = 'category:${category.name}';
    final existing = _inflight[key];
    if (existing != null) return existing;
    final future = ref.read(seriesRepositoryProvider).byCategory(category).then(
      (series) {
        final result = List<Series>.unmodifiable(series);
        _categoryCache[category] = result;
        return result;
      },
    );
    _inflight[key] = future;
    future.then<void>(
      (_) => _inflight.remove(key),
      onError: (Object _, StackTrace __) => _inflight.remove(key),
    );
    return future;
  }

  DiscoverState _tabState(
    DiscoverState? previous, {
    required DiscoverHomeTab tab,
    required Category category,
    required List<Series> series,
  }) {
    return DiscoverState(
      currentCategory: category,
      selectedTab: tab,
      series: series,
      sections: previous?.sections ?? const [],
      hero: previous?.hero,
    );
  }
}

final discoverNotifierProvider =
    AsyncNotifierProvider<DiscoverNotifier, DiscoverState>(
  DiscoverNotifier.new,
);
