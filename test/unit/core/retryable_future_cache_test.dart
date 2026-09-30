import 'package:flutter_test/flutter_test.dart';
import 'package:shortigo/core/async/retryable_future_cache.dart';

void main() {
  test('removes failed futures so the next request retries', () async {
    final cache = RetryableFutureCache<String, String>();
    var attempts = 0;

    await expectLater(
      cache.getOrCreate('episode', () async {
        attempts += 1;
        throw StateError('temporary');
      }),
      throwsStateError,
    );

    expect(
      await cache.getOrCreate('episode', () async {
        attempts += 1;
        return 'https://video.example/episode.mp4';
      }),
      'https://video.example/episode.mp4',
    );
    expect(attempts, 2);
  });
}
