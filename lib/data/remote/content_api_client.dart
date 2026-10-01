import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../local/shortigo_database.dart';
import 'content_api_models.dart';

const contentApiBaseUrlKey = 'contentApiBaseUrl';

class ContentApiClient {
  ContentApiClient({
    ShortigoDatabase? database,
    http.Client? httpClient,
    String defaultBaseUrl = '',
    this.timeout = const Duration(seconds: 12),
  })  : _database = database,
        _httpClient = httpClient ?? http.Client(),
        _defaultBaseUrl = normalizeBaseUrl(defaultBaseUrl);

  final ShortigoDatabase? _database;
  final http.Client _httpClient;
  final String? _defaultBaseUrl;
  final Duration timeout;

  String? _baseUrlOverride;

  String? get defaultBaseUrl => _defaultBaseUrl;

  Future<String?> get configuredBaseUrl async {
    if (_baseUrlOverride != null) return _baseUrlOverride;
    final stored = await _database?.readSetting(contentApiBaseUrlKey);
    return normalizeBaseUrl(stored ?? '') ?? _defaultBaseUrl;
  }

  Future<void> saveBaseUrl(String rawUrl) async {
    final normalized = normalizeBaseUrl(rawUrl);
    if (normalized == null) {
      throw const ContentApiException(
        code: 'invalid-url',
      );
    }
    _baseUrlOverride = normalized;
    await _database?.writeSetting(contentApiBaseUrlKey, normalized);
  }

  Future<void> clearSavedBaseUrl() async {
    _baseUrlOverride = null;
    await _database?.writeSetting(contentApiBaseUrlKey, _defaultBaseUrl ?? '');
  }

  void invalidate() {
    // The override is the active, already-normalized configuration. Clearing
    // it here would immediately revert a newly saved URL when no database is
    // available (and would make invalidation itself change app settings).
  }

  Future<ContentApiSourceStatus> checkConnection({String? baseUrl}) async {
    final normalized = normalizeBaseUrl(baseUrl ?? await configuredBaseUrl);
    if (normalized == null) {
      throw const ContentApiException(
        code: 'invalid-url',
      );
    }
    final data = await _getData('/api/source-status', baseUrl: normalized);
    final status = ContentApiSourceStatus.fromJson(data);
    if (!status.isCompatible) {
      throw const ContentApiException(code: 'api-incompatible');
    }
    return status;
  }

  Future<ContentApiSourceStatus> getSourceStatus() => checkConnection();

  Future<Map<String, dynamic>> getData(String path) => _getData(path);

  Future<ContentApiHomePayload> getHome() async {
    return ContentApiHomePayload.fromJson(await _getData('/api/home'));
  }

  Future<ContentApiCollectionPage> getCollection({
    required String slug,
    int page = 1,
    int pageSize = 30,
    String sort = 'hot',
    String? cursor,
  }) async {
    final query = <String, String>{
      'pageSize': '$pageSize',
      'sort': sort,
      if (cursor != null && cursor.isNotEmpty) 'cursor': cursor,
    };
    final path = Uri(
      path: '/api/collection/${Uri.encodeComponent(slug)}/$page',
      queryParameters: query,
    ).toString();
    return ContentApiCollectionPage.fromJson(await _getData(path));
  }

  Future<List<Map<String, dynamic>>> search(String keyword) async {
    final data = await _getData(
      '/api/search/${Uri.encodeComponent(keyword)}/1',
    );
    return _listFrom(data, 'list');
  }

  Future<ContentApiSearchPage> searchPage(
    String keyword, {
    int page = 1,
    int pageSize = 30,
  }) async {
    final path = Uri(
      path: '/api/search/${Uri.encodeComponent(keyword)}/$page',
      queryParameters: {'pageSize': '$pageSize'},
    ).toString();
    return ContentApiSearchPage.fromJson(await _getData(path));
  }

  Future<Map<String, dynamic>> getBook(String bookId) {
    return _getData('/api/book/${Uri.encodeComponent(bookId)}');
  }

  Future<Map<String, dynamic>> getChapters(String bookId) {
    return _getData('/api/chapters/${Uri.encodeComponent(bookId)}');
  }

  Future<ContentApiPlayback> getWatch(
    String bookId,
    int chapterIndex,
  ) async {
    final data = await _getData(
      '/api/watch/${Uri.encodeComponent(bookId)}/$chapterIndex',
    );
    return ContentApiPlayback.fromJson(data);
  }

  Future<List<String>> suggest(String keyword) async {
    final data = await _getData(
      '/api/suggest/${Uri.encodeComponent(keyword)}',
    );
    final raw = data['suggestList'] ?? data['list'] ?? const <dynamic>[];
    if (raw is! List) return const [];
    return raw
        .map((item) {
          if (item is Map) {
            return (item['bookName'] ?? item['title'] ?? item['keyword'] ?? '')
                .toString();
          }
          return item.toString();
        })
        .where((item) => item.isNotEmpty)
        .toList(growable: false);
  }

  Future<Map<String, dynamic>> _getData(
    String path, {
    String? baseUrl,
  }) async {
    final root = normalizeBaseUrl(baseUrl ?? await configuredBaseUrl);
    if (root == null) {
      throw const ContentApiException(
        code: 'not-configured',
      );
    }

    final uri = Uri.tryParse('$root/${path.replaceFirst(RegExp(r'^/+'), '')}');
    if (uri == null || (uri.scheme != 'http' && uri.scheme != 'https')) {
      throw const ContentApiException(
        code: 'invalid-url',
      );
    }

    http.Response response;
    try {
      response = await _httpClient.get(uri).timeout(timeout);
    } on TimeoutException catch (error) {
      throw ContentApiException(
        code: 'timeout',
        cause: error,
      );
    } on Object catch (error) {
      throw ContentApiException(
        code: 'network',
        cause: error,
      );
    }

    Map<String, dynamic> body;
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) {
        throw const FormatException('object expected');
      }
      body = Map<String, dynamic>.from(decoded);
    } on Object catch (error) {
      throw ContentApiException(
        code: 'malformed-json',
        statusCode: response.statusCode,
        cause: error,
      );
    }

    if (response.statusCode == 403 && path.contains('/watch/')) {
      throw ContentApiSourceLockedException(statusCode: response.statusCode);
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ContentApiException(
        code: 'http-${response.statusCode}',
        statusCode: response.statusCode,
      );
    }

    if (body['success'] != true) {
      throw ContentApiException(
        code: 'api-error',
        message: body['message']?.toString(),
        statusCode: response.statusCode,
      );
    }
    final data = body['data'];
    if (data is! Map) {
      throw const ContentApiException(
        code: 'invalid-schema',
      );
    }
    return Map<String, dynamic>.from(data);
  }

  List<Map<String, dynamic>> _listFrom(
    Map<String, dynamic> data,
    String key,
  ) {
    final raw = data[key];
    if (raw is! List) return const [];
    return raw
        .whereType<Map<String, dynamic>>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList(growable: false);
  }
}

String? normalizeBaseUrl(String? raw) {
  final value = raw?.trim() ?? '';
  if (value.isEmpty) return null;
  final uri = Uri.tryParse(value);
  if (uri == null || uri.host.isEmpty) return null;
  if (uri.scheme != 'http' && uri.scheme != 'https') return null;
  if (uri.userInfo.isNotEmpty ||
      uri.query.isNotEmpty ||
      uri.fragment.isNotEmpty) {
    return null;
  }
  final normalizedPath = uri.path.replaceFirst(RegExp(r'/+$'), '');
  return uri
      .replace(path: normalizedPath)
      .toString()
      .replaceFirst(RegExp(r'/+$'), '');
}
