import '../entities/playable_media.dart';

/// Abstract source of playable episode URLs.
abstract class VideoSource {
  /// Resolves public playback candidates without downloading video data.
  Future<PlayableMedia> playableMedia({
    required String seriesId,
    required String episodeId,
    required String storagePath,
    int? chapterIndex,
  });
}
