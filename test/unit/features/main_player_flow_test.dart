import 'package:better_player_plus/better_player_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shortigo/domain/entities/episode.dart';
import 'package:shortigo/domain/entities/playable_media.dart';
import 'package:shortigo/features/episode_player/presentation/main_player_page.dart';
import 'package:shortigo/features/episode_player/presentation/playback_data_source.dart';

void main() {
  final episodes = List.generate(
    10,
    (index) => Episode(
      id: 'ep${index + 1}',
      seriesId: 's1',
      order: index + 1,
      videoUrl: 'https://example.com/ep${index + 1}.mp4',
      thumbnailUrl: '',
      durationSec: 60,
      sourceAvailable: index != 0,
    ),
  );

  test('no deep link starts at the first playable episode', () {
    expect(resolveInitialEpisodeIndex(episodes, null), 1);
  });

  test('main player mounts before resolving and setting up media', () async {
    final events = <String>[];

    await mountPlayerBeforeSetup(
      playerMounted: false,
      mountPlayer: () async => events.add('mount'),
      frameReady: () async => events.add('frame'),
      resolveMedia: () async {
        events.add('resolve');
        return const PlayableMedia(
          primaryUrl: 'https://cdn.example.test/video.m3u8',
          candidateUrls: ['https://cdn.example.test/video.m3u8'],
        );
      },
      setupMedia: (_) async => events.add('setup'),
    );

    expect(events, ['mount', 'frame', 'resolve', 'setup']);
  });

  test('initial candidate skips pause until the controller is initialized',
      () async {
    final events = <String>[];
    var initialized = false;

    await pauseIfInitialized(
      initialized: initialized,
      pause: () async => events.add('pause'),
    );
    events.add('setup');
    initialized = true;
    events.add('play');

    expect(events, ['setup', 'play']);
  });

  test('switching candidates pauses the initialized source before setup',
      () async {
    final events = <String>[];

    await pauseIfInitialized(
      initialized: true,
      pause: () async => events.add('pause'),
    );
    events.add('setup');
    events.add('play');

    expect(events, ['pause', 'setup', 'play']);
  });

  test('candidate retry keeps setup order after the initial candidate fails',
      () async {
    final events = <String>[];
    var initialized = false;

    Future<void> setupCandidate(String candidate) async {
      await pauseIfInitialized(
        initialized: initialized,
        pause: () async => events.add('pause $candidate'),
      );
      events.add('setup $candidate');
      initialized = true;
      if (candidate == 'A') throw StateError('candidate-failed');
      events.add('play $candidate');
    }

    try {
      await setupCandidate('A');
    } on StateError {
      await setupCandidate('B');
    }

    expect(events, ['setup A', 'pause B', 'setup B', 'play B']);
  });

  test('deep link resolves requested episode before playback', () {
    expect(resolveInitialEpisodeIndex(episodes, 'ep7'), 6);
  });

  test('adjacent preload only keeps previous and next episode', () {
    expect(adjacentEpisodeIndices(6, episodes.length), [5, 7]);
    expect(adjacentEpisodeIndices(0, episodes.length), [1]);
  });

  test('auto-next stops at the last episode instead of looping', () {
    expect(nextEpisodeIndex(2, episodes.length), 3);
    expect(nextEpisodeIndex(9, episodes.length), -1);
  });

  test('seek position is clamped to the real duration', () {
    expect(clampSeekPosition(-10, 100), 0);
    expect(clampSeekPosition(50, 100), 50);
    expect(clampSeekPosition(120, 100), 100);
    expect(clampSeekPosition(50, 0), 0);
    expect(clampSeekPosition(60000 * .5, 60000), 30000);
  });

  test('playback uses explicit source chapter index when provided', () {
    final episode = episodes[7].copyWith(sourceChapterIndex: 19);
    expect(canonicalChapterIndex(episode), 19);
  });

  test('playback falls back to zero-based episode order', () {
    final episode = episodes[0].copyWith(order: 1, sourceChapterIndex: null);
    expect(canonicalChapterIndex(episode), 0);
  });

  test('HLS source bypasses BetterPlayer cache proxy', () {
    final source = buildNetworkVideoDataSource(
      const PlaybackCandidate(
        url: 'https://cdn.example.test/video/master.m3u8?token=redacted',
      ),
    );
    expect(source.videoFormat, BetterPlayerVideoFormat.hls);
    expect(source.cacheConfiguration?.useCache, isFalse);
  });

  test('opaque NetShort URL with media query is treated as MP4', () {
    final source = buildNetworkVideoDataSource(
      const PlaybackCandidate(
        url: 'https://cdn.example.test/opaque?mime_type=video_mp4',
        provider: 'netshort',
      ),
    );
    expect(source.videoFormat, BetterPlayerVideoFormat.other);
    expect(source.cacheConfiguration?.useCache, isFalse);
  });

  test('remote playback bypasses cache on iOS for every media kind', () {
    expect(
      shouldUsePlaybackCache(
        const PlaybackCandidate(url: 'https://cdn.example.test/video.mp4'),
        platform: TargetPlatform.iOS,
      ),
      isFalse,
    );
    expect(
      shouldUsePlaybackCache(
        const PlaybackCandidate(url: 'https://cdn.example.test/video.m3u8'),
        platform: TargetPlatform.iOS,
      ),
      isFalse,
    );
    expect(
      shouldUsePlaybackCache(
        const PlaybackCandidate(
          url: 'https://cdn.example.test/opaque?mime_type=video_mp4',
          provider: 'netshort',
        ),
        platform: TargetPlatform.iOS,
      ),
      isFalse,
    );
  });

  test('Android only caches direct MP4 sources', () {
    expect(
      shouldUsePlaybackCache(
        const PlaybackCandidate(url: 'https://cdn.example.test/video.mp4'),
        platform: TargetPlatform.android,
      ),
      isTrue,
    );
    expect(
      shouldUsePlaybackCache(
        const PlaybackCandidate(
          url: 'https://cdn.example.test/opaque?mime_type=video_mp4',
        ),
        platform: TargetPlatform.android,
      ),
      isFalse,
    );
  });

  test('playback watchdog fires only when no ready event arrives', () async {
    var timedOut = false;
    final watchdog = PlaybackWatchdog(
      timeout: const Duration(milliseconds: 1),
      onTimeout: () => timedOut = true,
    )..start();

    await Future<void>.delayed(const Duration(milliseconds: 5));

    expect(timedOut, isTrue);
    watchdog.cancel();
  });

  test('playback watchdog can be cancelled by an initialized event', () async {
    var timedOut = false;
    final watchdog = PlaybackWatchdog(
      timeout: const Duration(milliseconds: 5),
      onTimeout: () => timedOut = true,
    )..start();
    watchdog.cancel();

    await Future<void>.delayed(const Duration(milliseconds: 10));

    expect(timedOut, isFalse);
  });
}
