import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../../../data/remote/content_api_models.dart';
import '../../../data/local/local_library_repository.dart';
import '../../../domain/entities/series.dart';
import '../../../domain/entities/watch_history_entry.dart';
import '../../../domain/interfaces/series_repository.dart';

class MyListState {
  const MyListState({
    this.series = const [],
    this.history = const [],
    this.requiresSignIn = false,
  });

  final List<Series> series;
  final List<WatchHistoryEntry> history;
  final bool requiresSignIn;
}

class MyListNotifier extends AsyncNotifier<MyListState> {
  @override
  Future<MyListState> build() async {
    final user = await ref.watch(currentAppUserDocProvider.future);
    final library = ref.read(localLibraryRepositoryProvider);
    final scope = LocalLibraryRepository.scopeFor(user?.id);
    final localSaved = await library.listSaved(scope);
    var history = await library.listHistory(scope);
    if (user == null) {
      final guestSeries =
          await ref.read(guestFavoritesRepositoryProvider).list();
      final byId = <String, Series>{
        for (final series in [...localSaved, ...guestSeries]) series.id: series,
      };
      return MyListState(
        series: byId.values.toList(growable: false),
        history: history,
      );
    }

    final favoriteSeriesIds = user.favoriteSeriesIds;
    final repo = ref.read(seriesRepositoryProvider);
    final localById = <String, Series>{
      for (final item in localSaved) item.id: item,
    };
    final series = <Series>[];
    final missing = <String>[];
    for (final id in favoriteSeriesIds) {
      final cached = localById[id];
      if (cached != null) {
        series.add(cached);
      } else {
        missing.add(id);
      }
    }

    for (var offset = 0; offset < missing.length; offset += 4) {
      final batch = missing.skip(offset).take(4);
      final resolved = await Future.wait(batch.map((id) async {
        try {
          return await repo.byId(id);
        } on ContentApiException catch (error) {
          if (error.code == 'not-found' || error.statusCode == 404) return null;
          return null;
        } on Object {
          return null;
        }
      }));
      for (final saved in resolved.whereType<Series>()) {
        if (!saved.isPublished) continue;
        series.add(saved);
        await library.saveSeries(scope, saved);
      }
    }

    try {
      final cloudHistory =
          await ref.read(userRepositoryProvider).readWatchHistory(user.id);
      final merged = <String, WatchHistoryEntry>{
        for (final item in history) item.seriesId: item,
      };
      for (final cloud in cloudHistory) {
        final local = merged[cloud.seriesId];
        if (local == null || cloud.watchedAt.isAfter(local.watchedAt)) {
          final resolvedSeries = await _resolveHistorySeries(repo, cloud);
          final resolved = _copyWithSeries(cloud, resolvedSeries);
          merged[cloud.seriesId] = resolved;
          await library.upsertHistory(scope, resolved);
        } else if (local.watchedAt.isAfter(cloud.watchedAt)) {
          await ref
              .read(userRepositoryProvider)
              .saveWatchHistory(user.id, local);
        }
      }
      history = merged.values.toList()
        ..sort((a, b) => b.watchedAt.compareTo(a.watchedAt));
    } on Object {
      // A stale local history is still useful when Firestore is unavailable.
    }

    return MyListState(series: series, history: history);
  }

  Future<Series> _resolveHistorySeries(
    SeriesRepository repo,
    WatchHistoryEntry entry,
  ) async {
    try {
      final resolved = await repo.byId(entry.seriesId);
      return resolved;
    } on Object {
      return entry.series;
    }
  }

  WatchHistoryEntry _copyWithSeries(
    WatchHistoryEntry entry,
    Series series,
  ) {
    return WatchHistoryEntry(
      seriesId: entry.seriesId,
      series: series,
      episodeId: entry.episodeId,
      episodeOrder: entry.episodeOrder,
      chapterIndex: entry.chapterIndex,
      positionMs: entry.positionMs,
      durationMs: entry.durationMs,
      watchedAt: entry.watchedAt,
    );
  }
}

final myListNotifierProvider =
    AsyncNotifierProvider<MyListNotifier, MyListState>(
  MyListNotifier.new,
);
