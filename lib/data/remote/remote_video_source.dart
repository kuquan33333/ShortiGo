import 'package:flutter/foundation.dart';

import '../../core/env/env.dart';
import '../../domain/entities/playable_media.dart';
import '../../domain/interfaces/video_source.dart';
import 'content_api_client.dart';
import 'content_api_models.dart';

class RemoteVideoSource implements VideoSource {
  RemoteVideoSource(this._client);

  final ContentApiClient _client;

  @override
  Future<PlayableMedia> playableMedia({
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
      final media = _toPlayableMedia(playback);
      final uri = Uri.tryParse(media.primaryUrl);
      _playbackLog(
        'provider=${playback.provider ?? 'unknown'} '
        'candidateCount=${media.candidateUrls.length} '
        'urlHost=${uri?.host ?? 'unknown'} '
        'mediaKind=${_mediaKind(media.primaryUrl)} '
        'candidateIndex=0 setup=START watchResolve=OK',
      );
      return media;
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

  PlayableMedia _toPlayableMedia(ContentApiPlayback playback) {
    final urls = <String>[];
    final defaultQuality = playback.qualities
        .where((quality) => quality.isDefault)
        .map((quality) => quality.videoPath)
        .firstOrNull;
    _addUrl(urls, defaultQuality);
    _addUrl(urls, playback.videoUrl);
    for (final quality in playback.qualities) {
      _addUrl(urls, quality.videoPath);
    }
    if (urls.isEmpty) {
      throw const ContentApiException(code: 'invalid-schema');
    }
    return PlayableMedia(
      primaryUrl: urls.first,
      candidateUrls: List.unmodifiable(urls),
      provider: playback.provider,
    );
  }

  void _addUrl(List<String> urls, String? value) {
    final url = value?.trim() ?? '';
    final uri = Uri.tryParse(url);
    if (uri == null || (uri.scheme != 'http' && uri.scheme != 'https')) {
      return;
    }
    if (!urls.contains(url)) urls.add(url);
  }

  String _mediaKind(String url) {
    final uri = Uri.tryParse(url);
    final path = uri?.path.toLowerCase() ?? url.toLowerCase();
    if (path.endsWith('.m3u8')) return 'hls';
    if (path.endsWith('.mp4')) return 'mp4';
    return 'unknown';
  }

  void _playbackLog(String message) {
    if (kDebugMode || activeEnv.vipTestMode) {
      debugPrint('[playback] $message');
    }
  }
}

extension<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
