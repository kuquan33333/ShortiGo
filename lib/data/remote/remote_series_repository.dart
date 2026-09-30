import '../../domain/entities/category.dart';
import '../../domain/entities/series.dart';
import '../../domain/interfaces/series_repository.dart';
import 'content_api_client.dart';
import 'content_api_mapper.dart';
import 'content_api_models.dart';

class RemoteSeriesRepository implements SeriesRepository {
  RemoteSeriesRepository(this._client);

  final ContentApiClient _client;
  final Map<String, Series> _byId = {};

  @override
  Future<List<Series>> forYou({int limit = 20}) async {
    try {
      final data = await _client.getData('/api/home');
      final raw = <Map<String, dynamic>>[];
      final hero = data['hero'];
      if (hero is Map<String, dynamic>)
        raw.add(Map<String, dynamic>.from(hero));
      final heroes = data['heroes'];
      if (heroes is List) {
        raw.addAll(
          heroes
              .whereType<Map<String, dynamic>>()
              .map(Map<String, dynamic>.from),
        );
      }
      final sections = data['sections'];
      if (sections is List) {
        for (final section in sections.whereType<Map<String, dynamic>>()) {
          final list = section['list'];
          if (list is List) {
            raw.addAll(
              list
                  .whereType<Map<String, dynamic>>()
                  .map(Map<String, dynamic>.from),
            );
          }
        }
      }
      final mapped = _mapUnique(raw);
      if (mapped.isNotEmpty) return mapped.take(limit).toList();
    } on ContentApiException catch (error) {
      // Keep the original API error; the fallback is useful only when /home
      // is not available on an older compatible server.
      if (error.statusCode != 404) rethrow;
    }

    final items = _fromList(
      await _client.getData('/api/foryou/1'),
      category: Category.forYou,
    );
    return items.take(limit).toList();
  }

  @override
  Future<List<Series>> byCategory(Category category, {int limit = 20}) async {
    final path = switch (category) {
      Category.forYou => '/api/home',
      Category.newReleases => '/api/new/1',
      Category.hot => '/api/rank/1',
      Category.adventure => '/api/collection/action/1',
      Category.scary => '/api/collection/fantasy/1',
      Category.anime => '/api/collection/recommended/1',
      // Provider locks must never be interpreted as ShortiGo VIP content.
      Category.vip => '/api/collection/recommended/1',
    };

    if (category == Category.forYou) return forYou(limit: limit);
    final data = await _client.getData(path);
    final list = _listFromPayload(data);
    final mapped = _mapUnique(list, category: category);
    return mapped.take(limit).toList();
  }

  @override
  Future<Series> byId(String id) async {
    final cached = _byId[id];
    if (cached != null) return cached;

    final candidates = await forYou(limit: 100);
    final found = candidates.where((item) => item.id == id).firstOrNull;
    if (found != null) return found;

    throw const ContentApiException(
      code: 'not-found',
      message: 'Không tìm thấy phim trên máy chủ.',
      statusCode: 404,
    );
  }

  List<Series> _fromList(
    Map<String, dynamic> data, {
    required Category category,
  }) {
    return _mapUnique(_listFromPayload(data), category: category);
  }

  List<Series> _mapUnique(
    Iterable<Map<String, dynamic>> raw, {
    Category category = Category.forYou,
  }) {
    final result = <Series>[];
    final seen = <String>{};
    for (final item in raw) {
      try {
        final mapped = ContentApiMapper.series(item, category: category);
        if (seen.add(mapped.id)) {
          _byId[mapped.id] = mapped;
          result.add(mapped);
        }
      } on FormatException {
        // One malformed catalog item must not break the whole grid.
      }
    }
    return result;
  }

  List<Map<String, dynamic>> _listFromPayload(Map<String, dynamic> data) {
    final list = data['list'];
    if (list is List) {
      return list
          .whereType<Map<String, dynamic>>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList();
    }
    final sections = data['sections'];
    if (sections is List) {
      return sections
          .whereType<Map<String, dynamic>>()
          .expand((section) => section['list'] is List
              ? (section['list'] as List).whereType<Map<String, dynamic>>()
              : const <Map<String, dynamic>>[])
          .map((item) => Map<String, dynamic>.from(item))
          .toList();
    }
    return const [];
  }
}

extension<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
