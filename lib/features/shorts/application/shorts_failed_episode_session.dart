/// Tracks media failures for one Shorts page session.
///
/// A failed episode stays blocked when the user navigates back to it. Only an
/// explicit retry clears the flag; a new page/session gets a new instance.
class ShortsFailedEpisodeSession {
  final Set<String> _failedEpisodeIds = <String>{};

  bool contains(String episodeId) => _failedEpisodeIds.contains(episodeId);

  void markFailed(String episodeId) => _failedEpisodeIds.add(episodeId);

  void clearForRetry(String episodeId) => _failedEpisodeIds.remove(episodeId);
}
