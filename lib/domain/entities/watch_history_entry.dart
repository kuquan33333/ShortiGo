import 'package:flutter/foundation.dart';

import 'series.dart';

@immutable
class WatchHistoryEntry {
  const WatchHistoryEntry({
    required this.seriesId,
    required this.series,
    required this.episodeId,
    required this.episodeOrder,
    required this.chapterIndex,
    required this.positionMs,
    required this.durationMs,
    required this.watchedAt,
  });

  final String seriesId;
  final Series series;
  final String episodeId;
  final int episodeOrder;
  final int chapterIndex;
  final int positionMs;
  final int durationMs;
  final DateTime watchedAt;

  Map<String, dynamic> toJson() => {
        'seriesId': seriesId,
        'series': series.toJson(),
        'episodeId': episodeId,
        'episodeOrder': episodeOrder,
        'chapterIndex': chapterIndex,
        'positionMs': positionMs,
        'durationMs': durationMs,
        'watchedAt': watchedAt.toUtc().toIso8601String(),
      };

  factory WatchHistoryEntry.fromJson(Map<String, dynamic> json) {
    return WatchHistoryEntry(
      seriesId: json['seriesId']?.toString() ?? '',
      series: Series.fromJson(
        Map<String, dynamic>.from(json['series'] as Map),
      ),
      episodeId: json['episodeId']?.toString() ?? '',
      episodeOrder: _int(json['episodeOrder']),
      chapterIndex: _int(json['chapterIndex']),
      positionMs: _int(json['positionMs']),
      durationMs: _int(json['durationMs']),
      watchedAt: DateTime.tryParse(json['watchedAt']?.toString() ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
    );
  }
}

int _int(Object? value) {
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}
