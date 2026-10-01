import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shortigo/core/providers.dart';
import 'package:shortigo/domain/entities/category.dart';
import 'package:shortigo/domain/entities/episode.dart';
import 'package:shortigo/domain/entities/series.dart';
import 'package:shortigo/domain/interfaces/episode_repository.dart';
import 'package:shortigo/domain/interfaces/series_repository.dart';
import 'package:shortigo/features/shorts/application/shorts_feed_notifier.dart';

void main() {
  test('shorts feed selects one first playable episode per series', () async {
    final container = ProviderContainer(
      overrides: [
        currentAppUserDocProvider.overrideWith((_) => Stream.value(null)),
        seriesRepositoryProvider.overrideWithValue(
          _FakeSeriesRepository([
            _series('s1'),
            _series('s2'),
          ]),
        ),
        episodeRepositoryProvider.overrideWithValue(
          _FakeEpisodeRepository({
            's1': [
              _episode('s1_e1', 's1', 1),
              _episode('s1_e2', 's1', 2),
              _episode('s1_e3', 's1', 3),
              _episode('s1_e4', 's1', 4),
              _episode('s1_e5', 's1', 5),
              _episode('s1_locked', 's1', 6, sourceLocked: true),
              _episode('s1_unavailable', 's1', 7, sourceAvailable: false),
            ],
            's2': [
              _episode('s2_e1', 's2', 1),
              _episode('s2_e2', 's2', 2),
              _episode('s2_e3', 's2', 3, bonusUnlockCost: 60),
            ],
          }),
        ),
      ],
    );
    addTearDown(container.dispose);

    final state = await container.read(shortsFeedNotifierProvider.future);

    expect(state.episodes, hasLength(2));
    expect(
      state.episodes.map((episode) => episode.order),
      containsAll(<int>[1, 1]),
    );
    expect(state.episodes.map((episode) => episode.seriesId).toSet(),
        {'s1', 's2'});
    expect(state.episodes.map((episode) => episode.id),
        isNot(contains('s1_locked')));
    expect(state.episodes.map((episode) => episode.id),
        isNot(contains('s1_unavailable')));
  });
}

class _FakeSeriesRepository implements SeriesRepository {
  const _FakeSeriesRepository(this.series);

  final List<Series> series;

  @override
  Future<List<Series>> forYou({int limit = 20}) async {
    return series.take(limit).toList();
  }

  @override
  Future<List<Series>> byCategory(Category category, {int limit = 20}) async {
    if (category == Category.forYou) {
      return forYou(limit: limit);
    }
    return const [];
  }

  @override
  Future<Series> byId(String id) async {
    return series.singleWhere((item) => item.id == id);
  }
}

class _FakeEpisodeRepository implements EpisodeRepository {
  const _FakeEpisodeRepository(this.episodesBySeriesId);

  final Map<String, List<Episode>> episodesBySeriesId;

  @override
  Future<Episode> byId(String id) async {
    return episodesBySeriesId.values
        .expand((episodes) => episodes)
        .singleWhere((episode) => episode.id == id);
  }

  @override
  Future<List<Episode>> bySeriesId(String seriesId) async {
    return episodesBySeriesId[seriesId] ?? const [];
  }
}

Series _series(String id) {
  return Series(
    id: id,
    title: 'Series $id',
    coverUrl: 'https://example.com/$id.jpg',
    category: Category.forYou,
    createdAt: DateTime.utc(2026, 6, 10),
    isPublished: true,
  );
}

Episode _episode(
  String id,
  String seriesId,
  int order, {
  int? bonusUnlockCost,
  bool sourceAvailable = true,
  bool sourceLocked = false,
}) {
  return Episode(
    id: id,
    seriesId: seriesId,
    order: order,
    videoUrl: 'https://example.com/$id.mp4',
    thumbnailUrl: 'https://example.com/$id.jpg',
    durationSec: 60,
    bonusUnlockCost: bonusUnlockCost,
    sourceAvailable: sourceAvailable,
    sourceLocked: sourceLocked,
  );
}
