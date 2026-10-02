import 'package:flutter_test/flutter_test.dart';
import 'package:shortigo/features/shorts/application/shorts_failed_episode_session.dart';

void main() {
  test('failed episode remains blocked until explicit retry', () {
    final session = ShortsFailedEpisodeSession();

    session.markFailed('ep1');
    expect(session.contains('ep1'), isTrue);

    // Revisiting the page does not clear the failure. Only the Retry action
    // is allowed to clear it.
    expect(session.contains('ep1'), isTrue);
    session.clearForRetry('ep1');
    expect(session.contains('ep1'), isFalse);
  });

  test('failed episode state is isolated to the current Shorts session', () {
    final firstSession = ShortsFailedEpisodeSession()..markFailed('ep1');
    final newSession = ShortsFailedEpisodeSession();

    expect(firstSession.contains('ep1'), isTrue);
    expect(newSession.contains('ep1'), isFalse);
  });
}
