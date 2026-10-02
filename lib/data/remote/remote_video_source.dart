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
    final candidates = <PlaybackCandidate>[];
    final defaultQuality = playback.qualities
        .where((quality) => quality.isDefault)
        .map((quality) => (quality.videoPath, quality.quality))
        .firstOrNull;
    _addCandidate(candidates, defaultQuality?.$1,
        quality: defaultQuality?.$2, provider: playback.provider);
    _addCandidate(candidates, playback.videoUrl, provider: playback.provider);
    for (final quality in playback.qualities) {
      _addCandidate(candidates, quality.videoPath,
          quality: quality.quality, provider: playback.provider);
    }
    if (candidates.isEmpty) {
      throw const ContentApiException(code: 'invalid-schema');
    }
    return PlayableMedia(
      primaryUrl: candidates.first.url,
      candidateUrls:
          candidates.map((candidate) => candidate.url).toList(growable: false),
      provider: playback.provider,
      candidates: List.unmodifiable(candidates),
    );
  }

  void _addCandidate(
    List<PlaybackCandidate> candidates,
    String? value, {
    required String? provider,
    int? quality,
  }) {
    final url = value?.trim() ?? '';
    final uri = Uri.tryParse(url);
    if (uri == null || (uri.scheme != 'http' && uri.scheme != 'https')) {
      return;
    }
    if (candidates.any((candidate) => candidate.url == url)) return;
    candidates.add(PlaybackCandidate(
      url: url,
      provider: provider,
      quality: quality,
      mediaKind: _mediaKind(url),
    ));
  }

  String _mediaKind(String url) {
    final uri = Uri.tryParse(url);
    final path = uri?.path.toLowerCase() ?? url.toLowerCase();
    if (path.endsWith('.m3u8')) return 'hls';
    if (path.endsWith('.mp4')) return 'mp4';
    final mimeType = uri?.queryParameters['mime_type']?.toLowerCase();
    if (mimeType == 'video_mp4' || mimeType == 'video/mp4') return 'mp4';
    if (mimeType == 'application_mpegurl' ||
        mimeType == 'application/vnd.apple.mpegurl') {
      return 'hls';
    }
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
