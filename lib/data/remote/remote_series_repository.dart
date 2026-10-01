import '../../domain/entities/category.dart';
import '../../domain/entities/series.dart';
import '../../domain/interfaces/series_repository.dart';
import 'content_api_client.dart';
import 'content_api_mapper.dart';
import 'content_api_models.dart';

abstract class PagedSeriesRepository {
  Future<RemoteSeriesPage> collectionPage({
    required String slug,
    int page = 1,
    String? cursor,
    String sort = 'hot',
    int pageSize = 30,
  });
}

class RemoteSeriesRepository
    implements SeriesRepository, PagedSeriesRepository {
  RemoteSeriesRepository(this._client);

  final ContentApiClient _client;
  final Map<String, Series> _byId = {};

  void remember(Series series) => _byId[series.id] = series;

  void rememberAll(Iterable<Series> series) {
    for (final item in series) {
      remember(item);
    }
  }

  Future<RemoteHomeCatalog> homeCatalog() async {
    final data = await _client.getHome();
    final hero = _mapOne(data.hero);
    final heroes =
        data.heroes.map((item) => _mapOne(item)).whereType<Series>().toList();
    final sections = data.sections
        .map((section) {
          final items = section.items
              .map((item) => _mapOne(item))
              .whereType<Series>()
              .toList();
          return RemoteHomeSection(
            slug: section.slug,
            title: section.title,
            series: items,
          );
        })
        .where((section) => section.series.isNotEmpty)
        .toList();
    return RemoteHomeCatalog(
      hero: hero,
      heroes: heroes,
      sections: sections,
    );
  }

  @override
  Future<RemoteSeriesPage> collectionPage({
    required String slug,
    int page = 1,
    String? cursor,
    String sort = 'hot',
    int pageSize = 30,
  }) async {
    final response = await _client.getCollection(
      slug: slug,
      page: page,
      pageSize: pageSize,
      sort: sort,
      cursor: cursor,
    );
    final items = _mapUnique(
      response.items,
      category: _categoryForSlug(slug),
    );
    return RemoteSeriesPage(
      title: response.title.isEmpty ? slug : response.title,
      page: response.page,
      items: items,
      hasMore: response.hasMore,
      nextCursor: response.nextCursor,
    );
  }

  @override
  Future<List<Series>> forYou({int limit = 20}) async {
    try {
      final data = await _client.getData('/api/home');
      final raw = <Map<String, dynamic>>[];
      final hero = data['hero'];
      if (hero is Map<String, dynamic>) {
        raw.add(Map<String, dynamic>.from(hero));
      }
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
    if (category == Category.vip) {
      // Provider paywalls are source metadata, not a ShortiGo catalog tier.
      return const [];
    }
    final path = switch (category) {
      Category.forYou => '/api/home',
      Category.newReleases => '/api/new/1',
      Category.hot => '/api/rank/1',
      Category.romance => '/api/collection/romance/1',
      Category.ceo => '/api/collection/ceo/1',
      Category.revenge => '/api/collection/revenge/1',
      Category.family => '/api/collection/family/1',
      Category.action => '/api/collection/action/1',
      Category.fantasy => '/api/collection/fantasy/1',
      Category.recommended => '/api/collection/recommended/1',
      Category.adventure => '/api/collection/action/1',
      Category.scary => '/api/collection/fantasy/1',
      Category.anime => '/api/collection/recommended/1',
      // Provider locks must never be interpreted as ShortiGo VIP content.
      Category.vip => '',
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

    try {
      final detail = await _client.getBook(id);
      final resolved = ContentApiMapper.series(detail);
      remember(resolved);
      return resolved;
    } on ContentApiException catch (error) {
      // Older API deployments may not expose /api/book yet. Only a missing
      // detail is eligible for the catalog fallback; network/server errors
      // must remain visible to the caller.
      if (error.statusCode != 404 && error.code != 'not-found') rethrow;
    }

    final candidates = await forYou(limit: 100);
    final found = candidates.where((item) => item.id == id).firstOrNull;
    if (found != null) {
      remember(found);
      return found;
    }

    throw const ContentApiException(
      code: 'not-found',
      statusCode: 404,
    );
  }

  Series? _mapOne(Object? value) {
    if (value is! Map) return null;
    try {
      final result = ContentApiMapper.series(Map<String, dynamic>.from(value));
      remember(result);
      return result;
    } on FormatException {
      return null;
    }
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

  Category _categoryForSlug(String slug) {
    return switch (slug.trim().toLowerCase()) {
      'new' => Category.newReleases,
      'trending' || 'hot' => Category.hot,
      'romance' => Category.romance,
      'ceo' => Category.ceo,
      'revenge' => Category.revenge,
      'family' => Category.family,
      'action' => Category.action,
      'fantasy' => Category.fantasy,
      'recommended' || 'for-you' || 'foryou' => Category.recommended,
      _ => Category.forYou,
    };
  }
}

class RemoteSeriesPage {
  const RemoteSeriesPage({
    required this.title,
    required this.page,
    required this.items,
    required this.hasMore,
    this.nextCursor,
  });

  final String title;
  final int page;
  final List<Series> items;
  final bool hasMore;
  final String? nextCursor;
}

class RemoteHomeCatalog {
  const RemoteHomeCatalog({
    this.hero,
    this.heroes = const [],
    this.sections = const [],
  });

  final Series? hero;
  final List<Series> heroes;
  final List<RemoteHomeSection> sections;
}

class RemoteHomeSection {
  const RemoteHomeSection({
    required this.slug,
    required this.title,
    required this.series,
  });

  final String slug;
  final String title;
  final List<Series> series;
}

extension<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
