import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/perf/trace.dart';
import '../../../core/providers.dart';
import '../../../data/remote/remote_series_repository.dart';
import '../../../domain/entities/category.dart';
import '../../../domain/entities/series.dart';
import 'discover_state.dart';

class _DiscoverFeedCache {
  _DiscoverFeedCache({
    required Iterable<Series> items,
    this.page = 1,
    this.hasMore = false,
    this.nextCursor,
  }) : items = List<Series>.from(items);

  final List<Series> items;
  int page;
  bool hasMore;
  String? nextCursor;
  bool isLoadingMore = false;
  Object? loadMoreError;

  void append(RemoteSeriesPage pageData) {
    final seen = items.map((item) => item.id).toSet();
    for (final item in pageData.items) {
      if (seen.add(item.id)) items.add(item);
    }
    page = pageData.page;
    hasMore = pageData.hasMore;
    nextCursor = pageData.nextCursor;
    loadMoreError = null;
  }
}

class DiscoverNotifier extends AsyncNotifier<DiscoverState> {
  final _tabFeeds = <DiscoverHomeTab, _DiscoverFeedCache>{};
  final _categoryFeeds = <Category, _DiscoverFeedCache>{};
  final _inflight = <String, Future<List<Series>>>{};
  int? _sourceRevision;

  @override
  Future<DiscoverState> build() async {
    final sourceRevision = ref.watch(contentApiRevisionProvider);
    if (_sourceRevision != sourceRevision) {
      _sourceRevision = sourceRevision;
      _tabFeeds.clear();
      _categoryFeeds.clear();
      _inflight.clear();
    }
    return withTrace('discover_load', () async {
      final repo = ref.read(seriesRepositoryProvider);
      if (repo is RemoteSeriesRepository) {
        final home = await repo.homeCatalog();
        var hot = <Series>[
          ...home.heroes,
          ...home.sections.expand((section) => section.series),
        ];
        try {
          hot = await _loadTab(DiscoverHomeTab.hot);
        } catch (_) {
          // /home remains a valid first paint when the collection is degraded.
          _tabFeeds[DiscoverHomeTab.hot] = _DiscoverFeedCache(items: hot);
        }
        final result = DiscoverState(
          currentCategory: Category.hot,
          selectedTab: DiscoverHomeTab.hot,
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
          page: _tabFeeds[DiscoverHomeTab.hot]?.page ?? 1,
          hasMore: _tabFeeds[DiscoverHomeTab.hot]?.hasMore ?? false,
          nextCursor: _tabFeeds[DiscoverHomeTab.hot]?.nextCursor,
        );
        unawaited(_loadTab(DiscoverHomeTab.newReleases));
        unawaited(_loadTab(DiscoverHomeTab.ranking));
        return result;
      }
      final series = await repo.byCategory(Category.forYou);
      _tabFeeds[DiscoverHomeTab.hot] = _DiscoverFeedCache(items: series);
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
      const category = Category.recommended;
      final cached = _categoryFeeds[category];
      state = AsyncData(
        _tabState(
          previous,
          tab: tab,
          category: category,
          series: cached?.items ?? const [],
          feed: cached,
        ),
      );
      if (cached != null) return;

      try {
        final series = await _loadCategory(category);
        final current = state.valueOrNull;
        if (current?.selectedTab != tab ||
            current?.currentCategory != category) {
          return;
        }
        state = AsyncData(
          _tabState(
            current ?? previous,
            tab: tab,
            category: category,
            series: series,
            feed: _categoryFeeds[category],
          ),
        );
      } catch (error, stackTrace) {
        final current = state.valueOrNull;
        if (current?.selectedTab == tab &&
            current?.currentCategory == category) {
          state = AsyncError<DiscoverState>(error, stackTrace).copyWithPrevious(
            state,
          );
        }
      }
      return;
    }
    final cached = _tabFeeds[tab];
    state = AsyncData(
      _tabState(
        previous,
        tab: tab,
        category: _categoryForTab(tab),
        series: cached?.items ?? previous?.series ?? const [],
        feed: cached,
      ),
    );
    if (cached != null) return;

    try {
      final series = await _loadTab(tab);
      if (state.valueOrNull?.selectedTab != tab) return;
      state = AsyncData(
        _tabState(
          state.valueOrNull ?? previous,
          tab: tab,
          category: _categoryForTab(tab),
          series: series,
          feed: _tabFeeds[tab],
        ),
      );
    } catch (error, stackTrace) {
      if (state.valueOrNull?.selectedTab == tab) {
        state = AsyncError<DiscoverState>(error, stackTrace).copyWithPrevious(
          state,
        );
      }
    }
  }

  Future<void> selectCategory(Category category) async {
    final previous = state.valueOrNull;
    final cached = _categoryFeeds[category];
    state = AsyncData(
      _tabState(
        previous,
        tab: DiscoverHomeTab.categories,
        category: category,
        series: cached?.items ?? const [],
        feed: cached,
      ),
    );
    if (cached != null) return;
    try {
      final series = await _loadCategory(category);
      final current = state.valueOrNull;
      if (current?.selectedTab != DiscoverHomeTab.categories ||
          current?.currentCategory != category) {
        return;
      }
      state = AsyncData(
        _tabState(
          current ?? previous,
          tab: DiscoverHomeTab.categories,
          category: category,
          series: series,
          feed: _categoryFeeds[category],
        ),
      );
    } catch (error, stackTrace) {
      final current = state.valueOrNull;
      if (current?.selectedTab == DiscoverHomeTab.categories &&
          current?.currentCategory == category) {
        state = AsyncError<DiscoverState>(error, stackTrace).copyWithPrevious(
          state,
        );
      }
    }
  }

  /// Loads the next server cursor without replacing the existing grid.
  Future<void> loadMore() async {
    final current = state.valueOrNull;
    if (current == null || current.selectedTab == DiscoverHomeTab.ranking) {
      return;
    }
    final isCategory = current.selectedTab == DiscoverHomeTab.categories;
    final feed = isCategory
        ? _categoryFeeds[current.currentCategory]
        : _tabFeeds[current.selectedTab];
    if (feed == null || !feed.hasMore || feed.isLoadingMore) return;
    final repo = ref.read(seriesRepositoryProvider);
    if (repo is! RemoteSeriesRepository) return;

    feed.isLoadingMore = true;
    feed.loadMoreError = null;
    state = AsyncData(_stateWithFeed(current, feed));
    try {
      final page = await repo.collectionPage(
        slug: isCategory
            ? _slugForCategory(current.currentCategory)
            : _slugForTab(current.selectedTab),
        page: feed.page + 1,
        cursor: feed.nextCursor,
        sort: isCategory
            ? _sortForCategory(current.currentCategory)
            : _sortForTab(current.selectedTab),
        pageSize: 30,
      );
      feed.append(page);
    } catch (error) {
      feed.loadMoreError = error;
    } finally {
      feed.isLoadingMore = false;
      final latest = state.valueOrNull;
      if (latest != null &&
          latest.selectedTab == current.selectedTab &&
          (!isCategory || latest.currentCategory == current.currentCategory)) {
        state = AsyncData(_stateWithFeed(latest, feed));
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
      if (repo is RemoteSeriesRepository) {
        if (tab == DiscoverHomeTab.ranking) {
          final series = await repo.ranked(limit: 60);
          _tabFeeds[tab] = _DiscoverFeedCache(items: series);
          return series;
        }
        final page = await repo.collectionPage(
          slug: _slugForTab(tab),
          sort: _sortForTab(tab),
          pageSize: 30,
        );
        final feed = _DiscoverFeedCache(
          items: page.items,
          page: page.page,
          hasMore: page.hasMore,
          nextCursor: page.nextCursor,
        );
        _tabFeeds[tab] = feed;
        return List<Series>.unmodifiable(feed.items);
      }
      final series = await repo.byCategory(
        _categoryForTab(tab),
        limit: 60,
      );
      _tabFeeds[tab] = _DiscoverFeedCache(items: series);
      return series;
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
    final future = () async {
      final repo = ref.read(seriesRepositoryProvider);
      if (repo is RemoteSeriesRepository) {
        final page = await repo.collectionPage(
          slug: _slugForCategory(category),
          sort: _sortForCategory(category),
          pageSize: 30,
        );
        final feed = _DiscoverFeedCache(
          items: page.items,
          page: page.page,
          hasMore: page.hasMore,
          nextCursor: page.nextCursor,
        );
        _categoryFeeds[category] = feed;
        return List<Series>.unmodifiable(feed.items);
      }
      final series = await repo.byCategory(category);
      _categoryFeeds[category] = _DiscoverFeedCache(items: series);
      return series;
    }();
    _inflight[key] = future;
    future.then<void>(
      (_) => _inflight.remove(key),
      onError: (Object _, StackTrace __) => _inflight.remove(key),
    );
    return future;
  }

  String _slugForTab(DiscoverHomeTab tab) => switch (tab) {
        DiscoverHomeTab.hot => 'trending',
        DiscoverHomeTab.newReleases => 'new',
        DiscoverHomeTab.ranking => 'rank',
        DiscoverHomeTab.categories => 'recommended',
      };

  String _sortForTab(DiscoverHomeTab tab) =>
      tab == DiscoverHomeTab.newReleases ? 'new' : 'hot';

  String _slugForCategory(Category category) => switch (category) {
        Category.hot => 'trending',
        Category.newReleases => 'new',
        Category.forYou => 'recommended',
        _ => category.id,
      };

  String _sortForCategory(Category category) =>
      category == Category.newReleases ? 'new' : 'hot';

  DiscoverState _stateWithFeed(
    DiscoverState current,
    _DiscoverFeedCache feed,
  ) {
    return current.copyWith(
      series: List<Series>.unmodifiable(feed.items),
      page: feed.page,
      hasMore: feed.hasMore,
      nextCursor: feed.nextCursor,
      clearNextCursor: feed.nextCursor == null,
      isLoadingMore: feed.isLoadingMore,
      loadMoreError: feed.loadMoreError,
      clearLoadMoreError: feed.loadMoreError == null,
    );
  }

  DiscoverState _tabState(
    DiscoverState? previous, {
    required DiscoverHomeTab tab,
    required Category category,
    required List<Series> series,
    _DiscoverFeedCache? feed,
  }) {
    final state = DiscoverState(
      currentCategory: category,
      selectedTab: tab,
      series: series,
      sections: previous?.sections ?? const [],
      hero: previous?.hero,
    );
    return feed == null ? state : _stateWithFeed(state, feed);
  }
}

final discoverNotifierProvider =
    AsyncNotifierProvider<DiscoverNotifier, DiscoverState>(
  DiscoverNotifier.new,
);
