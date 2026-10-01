import '../../domain/interfaces/video_source.dart';
import 'content_api_client.dart';
import 'content_api_models.dart';

class RemoteVideoSource implements VideoSource {
  RemoteVideoSource(this._client);

  final ContentApiClient _client;

  @override
  Future<String> playableUrl({
    required String seriesId,
    required String episodeId,
    required String storagePath,
    int? chapterIndex,
  }) async {
    final index =
        chapterIndex ?? int.tryParse(storagePath.replaceFirst('remote://', ''));
    if (index == null) {
      throw const ContentApiException(
        code: 'episode-index',
      );
    }

    try {
      return (await _client.getWatch(seriesId, index)).videoUrl;
    } on ContentApiException {
      rethrow;
    }
  }
}
