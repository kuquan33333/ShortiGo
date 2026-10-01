import 'package:flutter_test/flutter_test.dart';
import 'package:shortigo/domain/entities/episode.dart';
import 'package:shortigo/domain/entities/user.dart';
import 'package:shortigo/features/episode_player/application/episode_access.dart';

void main() {
  final user = AppUser(
    id: 'user-1',
    email: 'viewer@example.com',
    bonus: 80,
    createdAt: DateTime.utc(2026, 6, 4),
  );

  test('VIP lock remains exclusive', () {
    expect(
      accessFor(_episode(isVipLocked: true, bonusUnlockCost: 60), user),
      EpisodeAccessState.vipRequired,
    );
    expect(
      accessFor(
        _episode(isVipLocked: true, bonusUnlockCost: 60),
        user,
        effectiveVip: true,
      ),
      EpisodeAccessState.open,
    );
  });

  test('bonus episode requires unlock until permanently unlocked', () {
    final episode = _episode(bonusUnlockCost: 60);
    expect(accessFor(episode, user), EpisodeAccessState.bonusRequired);
    expect(
      accessFor(episode, user.copyWith(unlockedEpisodeIds: [episode.id])),
      EpisodeAccessState.open,
    );
  });

  test(
    'provider locked and unavailable episodes never become ShortiGo VIP',
    () {
      expect(
        accessFor(_episode(sourceLocked: true), user),
        EpisodeAccessState.sourceLocked,
      );
      expect(
        accessFor(_episode(sourceAvailable: false), user),
        EpisodeAccessState.sourceUnavailable,
      );
      expect(
        accessFor(
          _episode(sourceLocked: true, isVipLocked: true),
          user,
          effectiveVip: true,
        ),
        EpisodeAccessState.sourceLocked,
      );
    },
  );
}

Episode _episode({
  bool isVipLocked = false,
  int? bonusUnlockCost,
  bool sourceAvailable = true,
  bool sourceLocked = false,
}) {
  return Episode(
    id: 'episode-1',
    seriesId: 'series-1',
    order: 1,
    videoUrl: 'https://example.com/video.mp4',
    thumbnailUrl: 'https://example.com/thumb.jpg',
    durationSec: 60,
    isVipLocked: isVipLocked,
    bonusUnlockCost: bonusUnlockCost,
    sourceAvailable: sourceAvailable,
    sourceLocked: sourceLocked,
  );
}
