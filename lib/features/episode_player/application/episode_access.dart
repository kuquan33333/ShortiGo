import '../../../domain/entities/episode.dart';
import '../../../domain/entities/user.dart';

enum EpisodeAccessState {
  open,
  vipRequired,
  bonusRequired,
  sourceLocked,
  sourceUnavailable,
}

EpisodeAccessState accessFor(
  Episode episode,
  AppUser? user, {
  bool? effectiveVip,
}) {
  if (episode.sourceLocked) {
    return EpisodeAccessState.sourceLocked;
  }
  if (!episode.sourceAvailable) {
    return EpisodeAccessState.sourceUnavailable;
  }
  if (episode.isVipLocked && !(effectiveVip ?? user?.isVip ?? false)) {
    return EpisodeAccessState.vipRequired;
  }
  if (episode.canUnlockWithBonus &&
      !(user?.unlockedEpisodeIds.contains(episode.id) ?? false)) {
    return EpisodeAccessState.bonusRequired;
  }
  return EpisodeAccessState.open;
}
