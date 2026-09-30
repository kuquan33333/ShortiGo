import '../../domain/entities/episode.dart';
import '../../domain/interfaces/episode_repository.dart';
import 'content_api_client.dart';
import 'content_api_mapper.dart';
import 'content_api_models.dart';

class RemoteEpisodeRepository implements EpisodeRepository {
  RemoteEpisodeRepository(this._client);

  final ContentApiClient _client;
  final Map<String, Episode> _byId = {};

  @override
  Future<List<Episode>> bySeriesId(String seriesId) async {
    final data = await _client.getData(
      '/api/chapters/${Uri.encodeComponent(seriesId)}',
    );
    final raw = data['chapterList'] ?? data['chapters'] ?? const <dynamic>[];
    if (raw is! List) return const [];
    final episodes = <Episode>[];
    for (final item in raw.whereType<Map<String, dynamic>>()) {
      try {
        final episode = ContentApiMapper.episode(
          Map<String, dynamic>.from(item),
          seriesId: seriesId,
        );
        _byId[episode.id] = episode;
        episodes.add(episode);
      } on FormatException {
        // Ignore malformed individual chapters and keep the list usable.
      }
    }
    episodes.sort((a, b) => a.order.compareTo(b.order));
    return episodes;
  }

  @override
  Future<Episode> byId(String id) async {
    final episode = _byId[id];
    if (episode != null) return episode;
    throw const ContentApiException(
      code: 'episode-not-loaded',
      message: 'Danh sách tập chưa được tải. Vui lòng mở lại trang phim.',
      statusCode: 404,
    );
  }
}
