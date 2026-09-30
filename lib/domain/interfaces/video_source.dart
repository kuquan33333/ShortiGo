/// Abstract source of playable episode URLs.
abstract class VideoSource {
  /// Returns a playable URL without downloading the video into the app.
  Future<String> playableUrl({
    required String seriesId,
    required String episodeId,
    required String storagePath,
    int? chapterIndex,
  });
}
