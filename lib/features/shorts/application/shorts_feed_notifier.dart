import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/perf/trace.dart';
import '../../../core/providers.dart';
import '../../../domain/entities/category.dart';
import '../../../domain/entities/episode.dart';
import '../../../domain/entities/series.dart';
import '../../episode_player/presentation/playback_data_source.dart';

const shortsFeedEpisodeLimit = 50;
const shortsCandidateLimit = 30;
const shortsUsableSeriesTarget = 20;
const shortsChapterConcurrency = 5;

List<Series> interleaveSeriesGroups(
  List<List<Series>> groups, {
  int limit = shortsCandidateLimit,
}) {
  final candidates = <Series>[];
  final seenIds = <String>{};
  final maxGroupLength = groups.fold<int>(
    0,
    (max, group) => group.length > max ? group.length : max,
  );
  for (var index = 0;
      index < maxGroupLength && candidates.length < limit;
      index++) {
    for (final group in groups) {
      if (index >= group.length) continue;
      final series = group[index];
      if (seenIds.add(series.id)) candidates.add(series);
      if (candidates.length >= limit) break;
    }
  }
  return candidates;
}

class ShortsFeedState {
  const ShortsFeedState({
    this.episodes = const [],
    this.seriesById = const {},
    this.isLoading = false,
    this.error,
  });

  final List<Episode> episodes;
  final Map<String, Series> seriesById;
  final bool isLoading;
  final Object? error;
}

/// Builds a diversified session: one first playable episode per series.
/// Chapter requests are intentionally bounded so Shorts does not stampede the
/// Content API when a new session starts.
class ShortsFeedNotifier extends AsyncNotifier<ShortsFeedState> {
  @override
  Future<ShortsFeedState> build() async {
    return withTrace('shorts_load', () async {
      final seriesRepo = ref.read(seriesRepositoryProvider);
      final episodeRepo = ref.read(episodeRepositoryProvider);
      final videoSource = ref.read(videoSourceProvider);
      final groups = await Future.wait([
        seriesRepo.byCategory(Category.forYou, limit: shortsCandidateLimit),
        seriesRepo.byCategory(Category.hot, limit: shortsCandidateLimit),
        seriesRepo.byCategory(Category.recommended,
            limit: shortsCandidateLimit),
      ]);
      final candidates = interleaveSeriesGroups(groups);
      if (candidates.isEmpty) return const ShortsFeedState();

      final usableEpisodes = <Episode>[];
      final usableSeries = <String, Series>{};
      for (var start = 0;
          start < candidates.length;
          start += shortsChapterConcurrency) {
        final batch =
            candidates.skip(start).take(shortsChapterConcurrency).toList();
        final results = await Future.wait(
          batch.map((series) async {
            try {
              final episodes = await episodeRepo.bySeriesId(series.id);
              final playable = episodes
                  .where((episode) =>
                      episode.sourceAvailable &&
                      !episode.sourceLocked &&
                      !episode.isVipLocked)
                  .toList()
                ..sort((a, b) => a.order.compareTo(b.order));
              if (playable.isEmpty) return null;
              final episode = playable.first;
              // Catalog metadata only says that the episode is public. Resolve
              // /watch once, with the same bounded chapter concurrency as the
              // episode requests, so known-dead media never enters Shorts.
              final media = await videoSource.playableMedia(
                seriesId: series.id,
                episodeId: episode.id,
                storagePath: episode.videoUrl,
                chapterIndex: canonicalChapterIndex(episode),
              );
              return media.candidateUrls.isEmpty ? null : (series, episode);
            } catch (_) {
              return null;
            }
          }),
        );
        for (final result in results) {
          if (result == null) continue;
          usableSeries[result.$1.id] = result.$1;
          usableEpisodes.add(result.$2);
        }
        if (usableEpisodes.length >= shortsUsableSeriesTarget) break;
      }

      final random = Random(DateTime.now().microsecondsSinceEpoch);
      usableEpisodes.shuffle(random);
      return ShortsFeedState(
        episodes:
            usableEpisodes.take(shortsFeedEpisodeLimit).toList(growable: false),
        seriesById: usableSeries,
      );
    });
  }
}

final shortsFeedNotifierProvider =
    AsyncNotifierProvider<ShortsFeedNotifier, ShortsFeedState>(
  ShortsFeedNotifier.new,
);
