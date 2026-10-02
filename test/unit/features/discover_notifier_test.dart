import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shortigo/core/providers.dart';
import 'package:shortigo/data/remote/remote_series_repository.dart';
import 'package:shortigo/domain/entities/category.dart';
import 'package:shortigo/domain/entities/series.dart';
import 'package:shortigo/domain/interfaces/series_repository.dart';
import 'package:shortigo/features/discover/application/discover_notifier.dart';
import 'package:shortigo/features/discover/application/discover_state.dart';

class _MockSeriesRepository extends Mock implements SeriesRepository {}

class _MockRemoteSeriesRepository extends Mock
    implements RemoteSeriesRepository {}

void main() {
  late _MockSeriesRepository repo;
  late ProviderContainer container;

  setUp(() {
    repo = _MockSeriesRepository();
    container = ProviderContainer(
      overrides: [
        seriesRepositoryProvider.overrideWithValue(repo),
      ],
    );
    addTearDown(container.dispose);
  });

  test('build() returns For You series from repo', () async {
    final series = Series(
      id: 's1',
      title: 'X',
      coverUrl: 'u',
      category: Category.forYou,
      createdAt: DateTime.utc(2026),
    );
    when(() => repo.byCategory(Category.forYou)).thenAnswer(
      (_) async => [series],
    );

    final state = await container.read(discoverNotifierProvider.future);

    expect(state.currentCategory, Category.forYou);
    expect(state.series, [series]);
  });

  test('selectCategory loads new series', () async {
    when(() => repo.byCategory(Category.forYou)).thenAnswer((_) async => []);
    when(() => repo.byCategory(Category.hot)).thenAnswer(
      (_) async => [
        Series(
          id: 's2',
          title: 'Hot',
          coverUrl: 'u',
          category: Category.hot,
          createdAt: DateTime.utc(2026),
        ),
      ],
    );

    await container.read(discoverNotifierProvider.future);
    await container
        .read(discoverNotifierProvider.notifier)
        .selectCategory(Category.hot);
    final state = container.read(discoverNotifierProvider).requireValue;

    expect(state.currentCategory, Category.hot);
    expect(state.series.first.id, 's2');
  });

  test('cached tabs do not fetch again when switching back', () async {
    final hot = Series(
      id: 'hot',
      title: 'Hot',
      coverUrl: 'u',
      category: Category.hot,
      createdAt: DateTime.utc(2026),
    );
    final newer = Series(
      id: 'new',
      title: 'New',
      coverUrl: 'u',
      category: Category.newReleases,
      createdAt: DateTime.utc(2026),
    );
    when(() => repo.byCategory(Category.forYou)).thenAnswer((_) async => []);
    when(() => repo.byCategory(Category.hot, limit: 60)).thenAnswer(
      (_) async => [hot],
    );
    when(() => repo.byCategory(Category.newReleases, limit: 60)).thenAnswer(
      (_) async => [newer],
    );

    await container.read(discoverNotifierProvider.future);
    final notifier = container.read(discoverNotifierProvider.notifier);
    await notifier.selectTab(DiscoverHomeTab.newReleases);
    await notifier.selectTab(DiscoverHomeTab.hot);
    await notifier.selectTab(DiscoverHomeTab.newReleases);

    verify(() => repo.byCategory(Category.newReleases, limit: 60)).called(1);
    expect(
      container.read(discoverNotifierProvider).requireValue.series.first.id,
      'new',
    );
  });

  test('opening categories loads recommended instead of reusing hot', () async {
    final remote = _MockRemoteSeriesRepository();
    final hot = _series('hot', 'Hot', Category.hot);
    final recommended =
        _series('recommended', 'Recommended', Category.recommended);

    when(() => remote.homeCatalog()).thenAnswer(
      (_) async => RemoteHomeCatalog(heroes: [hot]),
    );
    when(() => remote.ranked(limit: 60)).thenAnswer((_) async => const []);
    when(
      () => remote.collectionPage(
        slug: any(named: 'slug'),
        page: any(named: 'page'),
        cursor: any(named: 'cursor'),
        sort: any(named: 'sort'),
        pageSize: any(named: 'pageSize'),
      ),
    ).thenAnswer((invocation) async {
      final slug = invocation.namedArguments[#slug] as String;
      if (slug == 'trending') {
        return RemoteSeriesPage(
          title: 'Hot',
          page: 1,
          items: [hot],
          hasMore: false,
        );
      }
      if (slug == 'recommended') {
        return RemoteSeriesPage(
          title: 'Recommended',
          page: 1,
          items: [recommended],
          hasMore: true,
          nextCursor: 'recommended-cursor',
        );
      }
      return const RemoteSeriesPage(
        title: 'Other',
        page: 1,
        items: [],
        hasMore: false,
      );
    });

    final remoteContainer = ProviderContainer(
      overrides: [seriesRepositoryProvider.overrideWithValue(remote)],
    );
    addTearDown(remoteContainer.dispose);

    await remoteContainer.read(discoverNotifierProvider.future);
    final notifier = remoteContainer.read(discoverNotifierProvider.notifier);
    await notifier.selectTab(DiscoverHomeTab.categories);

    final state = remoteContainer.read(discoverNotifierProvider).requireValue;
    expect(state.currentCategory, Category.recommended);
    expect(state.series.map((item) => item.id), ['recommended']);
    expect(state.hasMore, isTrue);
    expect(state.nextCursor, 'recommended-cursor');
    verify(
      () => remote.collectionPage(
        slug: 'recommended',
        page: 1,
        cursor: null,
        sort: 'hot',
        pageSize: 30,
      ),
    ).called(1);
  });

  test('recommended category pagination is restored after switching tabs',
      () async {
    final remote = _MockRemoteSeriesRepository();
    final hot = _series('hot', 'Hot', Category.hot);
    final recommendedA =
        _series('recommended-a', 'Recommended A', Category.recommended);
    final recommendedB =
        _series('recommended-b', 'Recommended B', Category.recommended);

    when(() => remote.homeCatalog()).thenAnswer(
      (_) async => RemoteHomeCatalog(heroes: [hot]),
    );
    when(() => remote.ranked(limit: 60)).thenAnswer((_) async => const []);
    when(
      () => remote.collectionPage(
        slug: any(named: 'slug'),
        page: any(named: 'page'),
        cursor: any(named: 'cursor'),
        sort: any(named: 'sort'),
        pageSize: any(named: 'pageSize'),
      ),
    ).thenAnswer((invocation) async {
      final slug = invocation.namedArguments[#slug] as String;
      final cursor = invocation.namedArguments[#cursor] as String?;
      if (slug == 'trending') {
        return RemoteSeriesPage(
          title: 'Hot',
          page: 1,
          items: [hot],
          hasMore: false,
        );
      }
      if (slug == 'recommended' && cursor == null) {
        return RemoteSeriesPage(
          title: 'Recommended',
          page: 1,
          items: [recommendedA],
          hasMore: true,
          nextCursor: 'recommended-cursor',
        );
      }
      if (slug == 'recommended') {
        return RemoteSeriesPage(
          title: 'Recommended',
          page: 2,
          items: [recommendedB],
          hasMore: false,
        );
      }
      return const RemoteSeriesPage(
        title: 'Other',
        page: 1,
        items: [],
        hasMore: false,
      );
    });

    final remoteContainer = ProviderContainer(
      overrides: [seriesRepositoryProvider.overrideWithValue(remote)],
    );
    addTearDown(remoteContainer.dispose);

    await remoteContainer.read(discoverNotifierProvider.future);
    final notifier = remoteContainer.read(discoverNotifierProvider.notifier);
    await notifier.selectTab(DiscoverHomeTab.categories);
    await notifier.loadMore();
    await notifier.selectTab(DiscoverHomeTab.hot);
    await notifier.selectTab(DiscoverHomeTab.categories);

    final state = remoteContainer.read(discoverNotifierProvider).requireValue;
    expect(state.currentCategory, Category.recommended);
    expect(state.series.map((item) => item.id), [
      'recommended-a',
      'recommended-b',
    ]);
    expect(state.page, 2);
    expect(state.hasMore, isFalse);
    verify(
      () => remote.collectionPage(
        slug: 'recommended',
        page: 1,
        cursor: null,
        sort: 'hot',
        pageSize: 30,
      ),
    ).called(1);
    verify(
      () => remote.collectionPage(
        slug: 'recommended',
        page: 2,
        cursor: 'recommended-cursor',
        sort: 'hot',
        pageSize: 30,
      ),
    ).called(1);
  });

  test('remote feeds append cursor pages for hot, new, and categories',
      () async {
    final remote = _MockRemoteSeriesRepository();
    final hotA = _series('hot-a', 'Hot A', Category.hot);
    final hotB = _series('hot-b', 'Hot B', Category.hot);
    final hotC = _series('hot-c', 'Hot C', Category.hot);
    final newA = _series('new-a', 'New A', Category.newReleases);
    final newB = _series('new-b', 'New B', Category.newReleases);
    final romanceA = _series('romance-a', 'Romance A', Category.romance);
    final romanceB = _series('romance-b', 'Romance B', Category.romance);

    when(() => remote.homeCatalog()).thenAnswer(
      (_) async => const RemoteHomeCatalog(),
    );
    when(() => remote.ranked(limit: 60)).thenAnswer((_) async => const []);
    when(
      () => remote.collectionPage(
        slug: any(named: 'slug'),
        page: any(named: 'page'),
        cursor: any(named: 'cursor'),
        sort: any(named: 'sort'),
        pageSize: any(named: 'pageSize'),
      ),
    ).thenAnswer((invocation) async {
      final slug = invocation.namedArguments[#slug] as String;
      final cursor = invocation.namedArguments[#cursor] as String?;
      if (slug == 'trending') {
        return RemoteSeriesPage(
          title: 'Hot',
          page: cursor == null ? 1 : 2,
          items: cursor == null ? [hotA, hotB] : [hotB, hotC],
          hasMore: cursor == null,
          nextCursor: cursor == null ? 'hot-cursor' : null,
        );
      }
      if (slug == 'new') {
        return RemoteSeriesPage(
          title: 'New',
          page: cursor == null ? 1 : 2,
          items: cursor == null ? [newA] : [newB],
          hasMore: cursor == null,
          nextCursor: cursor == null ? 'new-cursor' : null,
        );
      }
      return RemoteSeriesPage(
        title: 'Romance',
        page: cursor == null ? 1 : 2,
        items: cursor == null ? [romanceA] : [romanceA, romanceB],
        hasMore: cursor == null,
        nextCursor: cursor == null ? 'romance-cursor' : null,
      );
    });

    final remoteContainer = ProviderContainer(
      overrides: [
        seriesRepositoryProvider.overrideWithValue(remote),
      ],
    );
    addTearDown(remoteContainer.dispose);

    final initial = await remoteContainer.read(discoverNotifierProvider.future);
    expect(initial.series.map((item) => item.id), ['hot-a', 'hot-b']);
    expect(initial.hasMore, isTrue);
    expect(initial.nextCursor, 'hot-cursor');

    final notifier = remoteContainer.read(discoverNotifierProvider.notifier);
    await notifier.loadMore();
    var state = remoteContainer.read(discoverNotifierProvider).requireValue;
    expect(state.series.map((item) => item.id), ['hot-a', 'hot-b', 'hot-c']);
    verify(
      () => remote.collectionPage(
        slug: 'trending',
        page: 2,
        cursor: 'hot-cursor',
        sort: 'hot',
        pageSize: 30,
      ),
    ).called(1);

    await notifier.selectTab(DiscoverHomeTab.newReleases);
    await notifier.loadMore();
    state = remoteContainer.read(discoverNotifierProvider).requireValue;
    expect(state.series.map((item) => item.id), ['new-a', 'new-b']);

    await notifier.selectCategory(Category.romance);
    await notifier.loadMore();
    state = remoteContainer.read(discoverNotifierProvider).requireValue;
    expect(state.series.map((item) => item.id), ['romance-a', 'romance-b']);
  });
}

Series _series(String id, String title, Category category) => Series(
      id: id,
      title: title,
      coverUrl: 'u',
      category: category,
      createdAt: DateTime.utc(2026),
    );
