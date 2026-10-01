import 'dart:math' as math;

import 'package:better_player_plus/better_player_plus.dart';

import '../../../domain/entities/episode.dart';

enum PlaybackMediaKind { hls, mp4, unknown }

PlaybackMediaKind playbackMediaKind(String url) {
  final parsed = Uri.tryParse(url);
  final path = parsed?.path.toLowerCase() ?? url.toLowerCase();
  if (path.endsWith('.m3u8')) return PlaybackMediaKind.hls;
  if (path.endsWith('.mp4')) return PlaybackMediaKind.mp4;
  final mimeType = parsed?.queryParameters['mime_type']?.toLowerCase();
  if (mimeType == 'video_mp4' || mimeType == 'video/mp4') {
    return PlaybackMediaKind.mp4;
  }
  if (mimeType == 'application_mpegurl' ||
      mimeType == 'application/vnd.apple.mpegurl') {
    return PlaybackMediaKind.hls;
  }
  return PlaybackMediaKind.unknown;
}

int canonicalChapterIndex(Episode episode) {
  return episode.sourceChapterIndex ?? math.max(0, episode.order - 1);
}

/// Builds the one network source configuration used by every player surface.
///
/// BetterPlayer Plus uses an iOS reverse-proxy cache for HLS. Signed playlist
/// URLs from the public resolver are short-lived, so bypass that cache path
/// for HLS while retaining the existing cache behavior for direct MP4 files.
BetterPlayerDataSource buildNetworkVideoDataSource(String url) {
  final kind = playbackMediaKind(url);
  return BetterPlayerDataSource.network(
    url,
    videoFormat: switch (kind) {
      PlaybackMediaKind.hls => BetterPlayerVideoFormat.hls,
      PlaybackMediaKind.mp4 => BetterPlayerVideoFormat.other,
      PlaybackMediaKind.unknown => null,
    },
    cacheConfiguration: kind == PlaybackMediaKind.hls
        ? const BetterPlayerCacheConfiguration(useCache: false)
        : const BetterPlayerCacheConfiguration(useCache: true),
  );
}
