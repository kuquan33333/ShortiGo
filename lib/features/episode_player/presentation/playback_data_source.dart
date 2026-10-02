import 'dart:async';
import 'dart:math' as math;

import 'package:better_player_plus/better_player_plus.dart';
import 'package:flutter/foundation.dart';

import '../../../data/remote/content_api_models.dart';
import '../../../domain/entities/episode.dart';
import '../../../domain/entities/playable_media.dart';

enum PlaybackMediaKind { hls, mp4, unknown }

class PlaybackCandidateSequence {
  PlaybackCandidateSequence(PlayableMedia media)
      : _media = media,
        _attempt = 1;

  PlayableMedia _media;
  int _index = 0;
  bool _resolveRetryUsed = false;
  int _attempt;

  PlaybackCandidate get currentCandidate => _media.typedCandidates[_index];
  String get currentUrl => currentCandidate.url;
  String? get provider => currentCandidate.provider ?? _media.provider;
  Map<String, String> get headers => currentCandidate.headers;
  int get currentIndex => _index;
  int get candidateCount => _media.typedCandidates.length;
  int get currentAttempt => _attempt;
  bool get hasNext => _index + 1 < candidateCount;
  bool get canRetryCurrent => _attempt < 2;
  bool get canResolveAgain => !_resolveRetryUsed;

  bool retryCurrent() {
    if (!canRetryCurrent) return false;
    _attempt++;
    return true;
  }

  bool moveNext() {
    if (!hasNext) return false;
    _index++;
    _attempt = 1;
    return true;
  }

  void replaceAfterResolve(PlayableMedia media) {
    _media = media;
    _index = 0;
    _attempt = 1;
    _resolveRetryUsed = true;
  }
}

/// Keeps the native player surface ahead of media resolution/setup.
Future<void> mountPlayerBeforeSetup({
  required bool playerMounted,
  required Future<void> Function() mountPlayer,
  required Future<void> Function() frameReady,
  required Future<PlayableMedia> Function() resolveMedia,
  required Future<void> Function(PlayableMedia media) setupMedia,
}) async {
  if (!playerMounted) await mountPlayer();
  await frameReady();
  final media = await resolveMedia();
  await setupMedia(media);
}

/// Pauses an existing native source without touching a controller that has
/// not received its first data source yet.
Future<void> pauseIfInitialized({
  required bool initialized,
  required Future<void> Function() pause,
}) async {
  if (!initialized) return;
  await pause();
}

typedef PlaybackCandidateSetup = Future<void> Function(
  PlaybackCandidate candidate,
);
typedef PlaybackCandidateRefresh = Future<PlayableMedia> Function();

class PlaybackWatchdog {
  PlaybackWatchdog({
    required this.timeout,
    required this.onTimeout,
  });

  final Duration timeout;
  final VoidCallback onTimeout;
  Timer? _timer;

  void start() {
    _timer?.cancel();
    _timer = Timer(timeout, onTimeout);
  }

  void cancel() {
    _timer?.cancel();
    _timer = null;
  }
}

/// Returns whether a watchdog callback still belongs to the active candidate
/// attempt. Readiness is scoped to the attempt rather than the episode so a
/// previously initialized candidate cannot suppress a later retry watchdog.
bool isPlaybackWatchdogCurrent({
  required int episodeGeneration,
  required int attemptGeneration,
  required int activeEpisodeGeneration,
  required int activeAttemptGeneration,
  required bool candidateReady,
}) {
  return episodeGeneration == activeEpisodeGeneration &&
      attemptGeneration == activeAttemptGeneration &&
      !candidateReady;
}

/// Continues recovery after the currently mounted candidate has failed.
///
/// The refreshed media is always attempted at index zero before advancing to
/// another refreshed candidate. This is shared by the main player, Shorts,
/// and the legacy episode player so their retry semantics cannot diverge.
Future<void> recoverPlaybackCandidates({
  required PlaybackCandidateSequence sequence,
  required PlaybackCandidateSetup setup,
  required PlaybackCandidateRefresh refresh,
  Object? currentError,
  StackTrace? currentStack,
}) async {
  Object? lastError = currentError;
  StackTrace? lastStack = currentStack;

  if (currentError != null && _isNonRetryablePlaybackError(currentError)) {
    if (currentStack != null) {
      Error.throwWithStackTrace(currentError, currentStack);
    }
    throw currentError;
  }

  while (true) {
    if (sequence.retryCurrent()) {
      try {
        await setup(sequence.currentCandidate);
        return;
      } on Object catch (error, stackTrace) {
        if (_isNonRetryablePlaybackError(error)) {
          Error.throwWithStackTrace(error, stackTrace);
        }
        lastError = error;
        lastStack = stackTrace;
      }
    }

    if (sequence.moveNext()) {
      try {
        await setup(sequence.currentCandidate);
        return;
      } on Object catch (error, stackTrace) {
        if (_isNonRetryablePlaybackError(error)) {
          Error.throwWithStackTrace(error, stackTrace);
        }
        lastError = error;
        lastStack = stackTrace;
        continue;
      }
    }

    if (!sequence.canResolveAgain) {
      if (lastError != null && lastStack != null) {
        Error.throwWithStackTrace(lastError, lastStack);
      }
      throw StateError('playback-candidates-exhausted');
    }

    final refreshed = await refresh();
    sequence.replaceAfterResolve(refreshed);
    try {
      await setup(sequence.currentCandidate);
      return;
    } on Object catch (error, stackTrace) {
      if (_isNonRetryablePlaybackError(error)) {
        Error.throwWithStackTrace(error, stackTrace);
      }
      lastError = error;
      lastStack = stackTrace;
    }
  }
}

bool _isNonRetryablePlaybackError(Object error) {
  if (error is ContentApiSourceLockedException) return true;
  if (error is! ContentApiException) return false;
  return error.code == 'source-locked' ||
      error.code == 'source-unavailable' ||
      error.statusCode == 403;
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

bool shouldUsePlaybackCache(
  PlaybackCandidate candidate, {
  TargetPlatform? platform,
}) {
  final resolvedPlatform = platform ?? defaultTargetPlatform;
  if (resolvedPlatform == TargetPlatform.iOS ||
      resolvedPlatform == TargetPlatform.macOS) {
    return false;
  }

  final kind = playbackMediaKind(candidate.url);
  if (kind == PlaybackMediaKind.hls) return false;
  if (candidate.provider?.toLowerCase() == 'netshort') return false;

  // BetterPlayer's iOS CachingPlayerItem cannot infer a media type from an
  // opaque URL. Keep opaque MP4 URLs out of the cache path on other platforms
  // too; direct .mp4 URLs remain cacheable on Android.
  final path = Uri.tryParse(candidate.url)?.path ?? '';
  if (kind == PlaybackMediaKind.mp4 && !path.toLowerCase().endsWith('.mp4')) {
    return false;
  }
  return kind == PlaybackMediaKind.mp4;
}

/// Builds the one network source configuration used by every player surface.
BetterPlayerDataSource buildNetworkVideoDataSource(
  PlaybackCandidate candidate, {
  TargetPlatform? platform,
}) {
  final kind = playbackMediaKind(candidate.url);
  return BetterPlayerDataSource.network(
    candidate.url,
    headers: candidate.headers.isEmpty ? null : candidate.headers,
    videoFormat: switch (kind) {
      PlaybackMediaKind.hls => BetterPlayerVideoFormat.hls,
      PlaybackMediaKind.mp4 => BetterPlayerVideoFormat.other,
      PlaybackMediaKind.unknown => null,
    },
    cacheConfiguration: BetterPlayerCacheConfiguration(
      useCache: shouldUsePlaybackCache(candidate, platform: platform),
    ),
  );
}

String playbackHost(String url) => Uri.tryParse(url)?.host ?? 'unknown';

String sanitizePlaybackError(Object error) {
  final raw = error.toString();
  return raw
      .replaceAll(
          RegExp(r'([?&](?:auth_key|token|signature|sig)=)[^&\s]+',
              caseSensitive: false),
          r'\1<redacted>')
      .replaceAll(RegExp(r'https?://[^\s)]+'), '<url-redacted>');
}
