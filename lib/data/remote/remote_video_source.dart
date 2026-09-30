import '../../domain/interfaces/video_source.dart';
import 'content_api_client.dart';
import 'content_api_mapper.dart';
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
        message: 'Không xác định được số tập để phát.',
      );
    }

    final data = await _client.getData(
      '/api/watch/${Uri.encodeComponent(seriesId)}/$index',
    );
    try {
      return ContentApiMapper.watchUrl(data);
    } on FormatException catch (error) {
      throw ContentApiException(
        code: 'invalid-watch-response',
        message: 'Máy chủ không trả về đường dẫn phát hợp lệ.',
        cause: error,
      );
    }
  }
}
