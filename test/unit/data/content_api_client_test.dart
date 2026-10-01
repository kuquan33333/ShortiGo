import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shortigo/data/remote/content_api_client.dart';
import 'package:shortigo/data/remote/content_api_models.dart';

void main() {
  test('an empty default leaves the Content API unconfigured', () async {
    final client = ContentApiClient(defaultBaseUrl: '');

    expect(await client.configuredBaseUrl, isNull);
    await expectLater(
      client.getData('/api/home'),
      throwsA(
        isA<ContentApiException>().having(
          (error) => error.code,
          'code',
          'not-configured',
        ),
      ),
    );
  });

  test('normalizes and validates API base URLs', () {
    expect(
      normalizeBaseUrl(' https://example.vercel.app/// '),
      'https://example.vercel.app',
    );
    expect(normalizeBaseUrl('http://localhost:3000/'), 'http://localhost:3000');
    expect(normalizeBaseUrl('ftp://example.com'), isNull);
    expect(normalizeBaseUrl('example.com'), isNull);
    expect(normalizeBaseUrl('https://example.com?token=secret'), isNull);
  });

  test('parses source status and validates providers', () async {
    final client = ContentApiClient(
      defaultBaseUrl: 'https://example.vercel.app',
      httpClient: MockClient((request) async {
        expect(request.url.path, '/api/source-status');
        return http.Response(
          jsonEncode({
            'success': true,
            'data': {
              'apiVersion': 2,
              'language': 'vi',
              'capabilities': {
                'home': true,
                'collections': true,
                'cursorPagination': true,
                'sorting': true,
                'search': true,
                'searchPagination': true,
                'suggest': true,
                'book': true,
                'chapters': true,
                'watch': true,
              },
              'providers': [
                {'id': 'reelshort', 'name': 'ReelShort VI'},
              ],
            },
          }),
          200,
        );
      }),
    );

    final status = await client.checkConnection();
    expect(status.apiVersion, 2);
    expect(status.language, 'vi');
    expect(status.providers.single.name, 'ReelShort VI');
    expect(status.providers.single.available, isTrue);
  });

  test('rejects an API without v2 capabilities', () async {
    final client = ContentApiClient(
      defaultBaseUrl: 'https://example.vercel.app',
      httpClient: MockClient(
        (_) async => http.Response(
          jsonEncode({
            'success': true,
            'data': {
              'apiVersion': 1,
              'providers': const <Map<String, dynamic>>[],
            },
          }),
          200,
        ),
      ),
    );
    await expectLater(
      client.checkConnection(),
      throwsA(
        isA<ContentApiException>().having(
          (error) => error.code,
          'code',
          'api-incompatible',
        ),
      ),
    );
  });

  test('parses collection and search pages without decoding cursor', () async {
    final client = ContentApiClient(
      defaultBaseUrl: 'https://example.vercel.app',
      httpClient: MockClient((request) async {
        if (request.url.path.startsWith('/api/collection/')) {
          expect(request.url.queryParameters['cursor'], 'opaque-v3');
          expect(request.url.queryParameters['sort'], 'new');
          return http.Response(
            jsonEncode({
              'success': true,
              'data': {
                'slug': 'romance',
                'title': 'Romance',
                'page': 2,
                'pageSize': 30,
                'list': const <dynamic>[],
                'hasMore': false,
                'nextCursor': null,
              },
            }),
            200,
          );
        }
        return http.Response(
          jsonEncode({
            'success': true,
            'data': {
              'page': 2,
              'pageSize': 30,
              'list': const <dynamic>[],
              'hasMore': true,
              'nextCursor': 'search-cursor',
            },
          }),
          200,
        );
      }),
    );

    final collection = await client.getCollection(
      slug: 'romance',
      page: 2,
      sort: 'new',
      cursor: 'opaque-v3',
    );
    final search = await client.searchPage('query', page: 2);
    expect(collection.page, 2);
    expect(collection.nextCursor, isNull);
    expect(search.page, 2);
    expect(search.nextCursor, 'search-cursor');
  });

  test(
    'runtime source override switches requests and restores the default',
    () async {
      final requestedRoots = <String>[];
      final client = ContentApiClient(
        defaultBaseUrl: 'https://server-a.example.com',
        httpClient: MockClient((request) async {
          requestedRoots.add(request.url.origin);
          return _sourceStatusResponse();
        }),
      );

      await client.checkConnection(baseUrl: 'https://server-a.example.com');
      await client.saveBaseUrl('https://server-b.example.com/');
      await client.getData('/api/home');
      await client.clearSavedBaseUrl();
      await client.getData('/api/home');

      expect(requestedRoots, [
        'https://server-a.example.com',
        'https://server-b.example.com',
        'https://server-a.example.com',
      ]);
    },
  );

  test('rejects malformed JSON and locked watch responses', () async {
    final malformed = ContentApiClient(
      defaultBaseUrl: 'https://example.vercel.app',
      httpClient: MockClient((_) async => http.Response('not-json', 200)),
    );
    await expectLater(
      malformed.getData('/api/home'),
      throwsA(isA<ContentApiException>()),
    );

    final locked = ContentApiClient(
      defaultBaseUrl: 'https://example.vercel.app',
      httpClient: MockClient(
        (_) async => http.Response(
          jsonEncode({
            'success': false,
            'reason': 'locked-no-public-alternative',
          }),
          403,
        ),
      ),
    );
    await expectLater(
      locked.getData('/api/watch/book/0'),
      throwsA(isA<ContentApiSourceLockedException>()),
    );
  });

  test('a blank default supports none to source and back to none', () async {
    final client = ContentApiClient(
      defaultBaseUrl: '',
      httpClient: MockClient((request) async {
        expect(request.url.origin, 'https://server-b.example.com');
        return _sourceStatusResponse();
      }),
    );

    expect(await client.configuredBaseUrl, isNull);
    await client.checkConnection(baseUrl: 'https://server-b.example.com');
    await client.saveBaseUrl('https://server-b.example.com');
    expect(await client.configuredBaseUrl, 'https://server-b.example.com');
    await client.clearSavedBaseUrl();
    expect(await client.configuredBaseUrl, isNull);
  });
}

http.Response _sourceStatusResponse() => http.Response(
      jsonEncode({
        'success': true,
        'data': {
          'apiVersion': 2,
          'providers': const <Map<String, dynamic>>[],
          'capabilities': {
            'home': true,
            'collections': true,
            'cursorPagination': true,
            'sorting': true,
            'search': true,
            'searchPagination': true,
            'suggest': true,
            'book': true,
            'chapters': true,
            'watch': true,
          },
        },
      }),
      200,
    );
