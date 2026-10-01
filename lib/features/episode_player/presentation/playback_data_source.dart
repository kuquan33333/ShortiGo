import 'dart:math' as math;

import 'package:better_player_plus/better_player_plus.dart';

import '../../../domain/entities/episode.dart';
import '../../../domain/entities/playable_media.dart';

enum PlaybackMediaKind { hls, mp4, unknown }

class PlaybackCandidateSequence {
  PlaybackCandidateSequence(PlayableMedia media) : _media = media;

  PlayableMedia _media;
  int _index = 0;
  bool _resolveRetryUsed = false;

  String get currentUrl => _media.candidateUrls[_index];
  int get currentIndex => _index;
  int get candidateCount => _media.candidateUrls.length;
  bool get hasNext => _index + 1 < _media.candidateUrls.length;
  bool get canResolveAgain => !_resolveRetryUsed;

  bool moveNext() {
    if (!hasNext) return false;
    _index++;
    return true;
  }

  void replaceAfterResolve(PlayableMedia media) {
    _media = media;
    _index = 0;
    _resolveRetryUsed = true;
  }
}

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
