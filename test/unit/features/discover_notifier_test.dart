import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shortigo/core/providers.dart';
import 'package:shortigo/domain/entities/category.dart';
import 'package:shortigo/domain/entities/series.dart';
import 'package:shortigo/domain/interfaces/series_repository.dart';
import 'package:shortigo/features/discover/application/discover_notifier.dart';
import 'package:shortigo/features/discover/application/discover_state.dart';

class _MockSeriesRepository extends Mock implements SeriesRepository {}

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
}
