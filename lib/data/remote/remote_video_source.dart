import 'package:flutter/foundation.dart';

import '../../core/env/env.dart';
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

    _playbackLog(
      'seriesId=$seriesId episodeId=$episodeId '
      'chapterIndex=$index watchResolve=START',
    );
    try {
      final playback = await _client.getWatch(seriesId, index);
      final uri = Uri.tryParse(playback.videoUrl);
      final path = uri?.path.toLowerCase() ?? '';
      final mediaKind = path.endsWith('.m3u8')
          ? 'hls'
          : path.endsWith('.mp4')
              ? 'mp4'
              : 'unknown';
      _playbackLog(
        'provider=${playback.provider ?? 'unknown'} '
        'urlScheme=${uri?.scheme ?? 'unknown'} mediaKind=$mediaKind '
        'watchResolve=OK',
      );
      return playback.videoUrl;
    } on ContentApiException catch (error) {
      _playbackLog(
        'stage=watch-resolve code=${error.code} '
        'status=${error.statusCode ?? 'unknown'}',
      );
      rethrow;
    } on Object catch (error) {
      _playbackLog('stage=watch-resolve code=${error.runtimeType}');
      rethrow;
    }
  }

  void _playbackLog(String message) {
    if (kDebugMode || activeEnv.vipTestMode) {
      debugPrint('[playback] $message');
    }
  }
}
