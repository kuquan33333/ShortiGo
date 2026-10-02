import 'package:flutter_test/flutter_test.dart';
import 'package:shortigo/data/remote/content_api_models.dart';
import 'package:shortigo/domain/entities/playable_media.dart';
import 'package:shortigo/features/episode_player/presentation/playback_data_source.dart';

void main() {
  test('refresh tries the refreshed primary after a single initial candidate',
      () async {
    final attempts = <String>[];
    var refreshCount = 0;

    await _runRecovery(
      initial: _media(['A']),
      refreshed: _media(['B']),
      attempts: attempts,
      refreshCount: () => refreshCount++,
      failures: {'A'},
    );

    expect(attempts, ['A', 'A', 'B']);
    expect(refreshCount, 1);
  });

  test('refresh keeps all refreshed candidates in order', () async {
    final attempts = <String>[];
    var refreshCount = 0;

    await _runRecovery(
      initial: _media(['A', 'B']),
      refreshed: _media(['C', 'D']),
      attempts: attempts,
      refreshCount: () => refreshCount++,
      failures: {'A', 'B', 'C'},
    );

    expect(attempts, ['A', 'A', 'B', 'B', 'C', 'C', 'D']);
    expect(refreshCount, 1);
  });

  test('refresh is bounded to one resolve when refreshed media also fails',
      () async {
    final attempts = <String>[];
    var refreshCount = 0;

    await expectLater(
      _runRecovery(
        initial: _media(['A']),
        refreshed: _media(['A2']),
        attempts: attempts,
        refreshCount: () => refreshCount++,
        failures: {'A', 'A2'},
      ),
      throwsA(isA<StateError>()),
    );

    expect(attempts, ['A', 'A', 'A2', 'A2']);
    expect(refreshCount, 1);
  });

  test('same candidate succeeds on its bounded second attempt', () async {
    final attempts = <String>[];
    final sequence = PlaybackCandidateSequence(_media(['A']));
    var refreshCount = 0;

    Future<void> setup(String url) async {
      attempts.add(url);
      if (attempts.length == 1) throw StateError('transient');
    }

    try {
      await setup(sequence.currentUrl);
    } on Object catch (error, stackTrace) {
      await recoverPlaybackCandidates(
        sequence: sequence,
        setup: (candidate) => setup(candidate.url),
        refresh: () async {
          refreshCount++;
          return _media(['B']);
        },
        currentError: error,
        currentStack: stackTrace,
      );
    }

    expect(attempts, ['A', 'A']);
    expect(refreshCount, 0);
    expect(sequence.currentAttempt, 2);
  });

  test('source locked does not resolve another candidate to bypass the lock',
      () async {
    final attempts = <String>[];
    var refreshCount = 0;
    final sequence = PlaybackCandidateSequence(_media(['A', 'B']));

    await expectLater(
      recoverPlaybackCandidates(
        sequence: sequence,
        currentError: const ContentApiSourceLockedException(),
        setup: (candidate) async => attempts.add(candidate.url),
        refresh: () async {
          refreshCount++;
          return _media(['C']);
        },
      ),
      throwsA(isA<ContentApiSourceLockedException>()),
    );

    expect(attempts, isEmpty);
    expect(refreshCount, 0);
  });
}

Future<void> _runRecovery({
  required PlayableMedia initial,
  required PlayableMedia refreshed,
  required List<String> attempts,
  required void Function() refreshCount,
  required Set<String> failures,
}) async {
  final sequence = PlaybackCandidateSequence(initial);

  Future<void> setup(String url) async {
    attempts.add(url);
    if (failures.contains(url)) throw StateError('failed:$url');
  }

  try {
    await setup(sequence.currentUrl);
  } on Object catch (error, stackTrace) {
    await recoverPlaybackCandidates(
      sequence: sequence,
      currentError: error,
      currentStack: stackTrace,
      setup: (candidate) => setup(candidate.url),
      refresh: () async {
        refreshCount();
        return refreshed;
      },
    );
  }
}

PlayableMedia _media(List<String> urls) {
  return PlayableMedia(
    primaryUrl: urls.first,
    candidateUrls: urls,
  );
}
