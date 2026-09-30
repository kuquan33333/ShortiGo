import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/perf/trace.dart';
import '../../../core/providers.dart';
import '../../../domain/entities/category.dart';
import '../../../domain/entities/episode.dart';
import '../../../domain/entities/series.dart';

const shortsFeedEpisodeLimit = 50;

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

class ShortsFeedNotifier extends AsyncNotifier<ShortsFeedState> {
  @override
  Future<ShortsFeedState> build() async {
    return withTrace('shorts_load', () async {
      final seriesRepo = ref.read(seriesRepositoryProvider);
      final episodeRepo = ref.read(episodeRepositoryProvider);
      final user = ref.read(currentAppUserDocProvider).value;

      final List<Series> loadedSeries = await seriesRepo.byCategory(
        Category.forYou,
        limit: 10,
      );
      final followedIds = user?.followedSeriesIds ?? const <String>[];
      final series = [...loadedSeries]..sort((a, b) {
          final aFollowed = followedIds.contains(a.id);
          final bFollowed = followedIds.contains(b.id);
          if (aFollowed == bFollowed) return 0;
          return aFollowed ? -1 : 1;
        });
      if (series.isEmpty) {
        return const ShortsFeedState();
      }

      final seriesById = {for (final item in series) item.id: item};

      final lists = await Future.wait(
        series.map((item) => episodeRepo.bySeriesId(item.id)),
      );
      final episodes = <Episode>[];
      for (var seriesIndex = 0; seriesIndex < lists.length; seriesIndex++) {
        episodes.addAll(
          lists[seriesIndex].where(
            (episode) => episode.sourceAvailable && !episode.sourceLocked,
          ),
        );
      }
      final seriesRankById = {
        for (var index = 0; index < series.length; index++)
          series[index].id: index,
      };
      episodes.sort((a, b) {
        final orderComparison = b.order.compareTo(a.order);
        if (orderComparison != 0) return orderComparison;
        return (seriesRankById[b.seriesId] ?? 0)
            .compareTo(seriesRankById[a.seriesId] ?? 0);
      });

      return ShortsFeedState(
        episodes: episodes.take(shortsFeedEpisodeLimit).toList(),
        seriesById: seriesById,
      );
    });
  }
}

final shortsFeedNotifierProvider =
    AsyncNotifierProvider<ShortsFeedNotifier, ShortsFeedState>(
  ShortsFeedNotifier.new,
);
