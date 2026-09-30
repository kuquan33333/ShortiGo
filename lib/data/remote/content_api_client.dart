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
        message: 'URL máy chủ phải bắt đầu bằng http:// hoặc https://.',
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
    _baseUrlOverride = null;
  }

  Future<ContentApiSourceStatus> checkConnection({String? baseUrl}) async {
    final normalized = normalizeBaseUrl(baseUrl ?? await configuredBaseUrl);
    if (normalized == null) {
      throw const ContentApiException(
        code: 'invalid-url',
        message: 'URL máy chủ không hợp lệ.',
      );
    }
    final data = await _getData('/api/source-status', baseUrl: normalized);
    return ContentApiSourceStatus.fromJson(data);
  }

  Future<Map<String, dynamic>> getData(String path) => _getData(path);

  Future<List<Map<String, dynamic>>> search(String keyword) async {
    final data = await _getData(
      '/api/search/${Uri.encodeComponent(keyword)}/1',
    );
    return _listFrom(data, 'list');
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
        message: 'Chưa cấu hình máy chủ API phim.',
      );
    }

    final uri = Uri.tryParse('$root/${path.replaceFirst(RegExp(r'^/+'), '')}');
    if (uri == null || (uri.scheme != 'http' && uri.scheme != 'https')) {
      throw const ContentApiException(
        code: 'invalid-url',
        message: 'URL máy chủ API không hợp lệ.',
      );
    }

    http.Response response;
    try {
      response = await _httpClient.get(uri).timeout(timeout);
    } on TimeoutException catch (error) {
      throw ContentApiException(
        code: 'timeout',
        message: 'Máy chủ phản hồi quá lâu. Vui lòng thử lại.',
        cause: error,
      );
    } on Object catch (error) {
      throw ContentApiException(
        code: 'network',
        message: 'Không thể kết nối tới máy chủ phim.',
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
        message: 'Máy chủ trả về dữ liệu không hợp lệ.',
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
        message: switch (response.statusCode) {
          403 => 'Máy chủ từ chối yêu cầu này.',
          404 => 'Không tìm thấy nội dung trên máy chủ.',
          >= 500 => 'Máy chủ phim đang gặp sự cố. Vui lòng thử lại sau.',
          _ => 'Máy chủ phim không thể xử lý yêu cầu.',
        },
        statusCode: response.statusCode,
      );
    }

    if (body['success'] != true) {
      throw ContentApiException(
        code: 'api-error',
        message: body['message']?.toString() ?? 'Máy chủ phim báo lỗi.',
        statusCode: response.statusCode,
      );
    }
    final data = body['data'];
    if (data is! Map) {
      throw const ContentApiException(
        code: 'invalid-schema',
        message: 'Máy chủ không trả về đúng cấu trúc dữ liệu.',
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
