import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shortigo/data/remote/content_api_client.dart';
import 'package:shortigo/data/remote/content_api_mapper.dart';
import 'package:shortigo/data/remote/content_api_models.dart';
import 'package:shortigo/data/remote/remote_series_repository.dart';

Map<String, dynamic> _book(String id) => {
      'bookId': id,
      'bookName': 'Series $id',
      'cover': 'https://example.com/$id.jpg',
      'chapterCount': 12,
      'playable': true,
    };

http.Response _ok(Object data) => http.Response(
      jsonEncode({'success': true, 'data': data}),
      200,
      headers: {'content-type': 'application/json'},
    );

void main() {
  test('byId resolves through the independent detail endpoint', () async {
    final requestedPaths = <String>[];
    final client = ContentApiClient(
      defaultBaseUrl: 'https://example.com',
      httpClient: MockClient((request) async {
        requestedPaths.add(request.url.path);
        expect(request.url.path, '/api/book/search-only');
        return _ok(_book('search-only'));
      }),
    );
    final repository = RemoteSeriesRepository(client);

    final series = await repository.byId('search-only');

    expect(series.id, 'search-only');
    expect(requestedPaths, ['/api/book/search-only']);
    expect((await repository.byId('search-only')).title, 'Series search-only');
    expect(requestedPaths, ['/api/book/search-only']);
  });

  test('a remembered search result resolves without another home request',
      () async {
    var requests = 0;
    final client = ContentApiClient(
      defaultBaseUrl: 'https://example.com',
      httpClient: MockClient((_) async {
        requests += 1;
        return _ok(_book('remembered'));
      }),
    );
    final repository = RemoteSeriesRepository(client);
    final series = await repository.byId('remembered');
    repository.remember(series);

    expect((await repository.byId('remembered')).id, 'remembered');
    expect(requests, 1);
  });

  test('search result resolves after repository restart through detail API',
      () async {
    final detail = _book('search-restart');
    final client = ContentApiClient(
      defaultBaseUrl: 'https://example.com',
      httpClient: MockClient((request) async {
        if (request.url.path == '/api/search/query/1') {
          return _ok({
            'list': [detail]
          });
        }
        expect(request.url.path, '/api/book/search-restart');
        return _ok(detail);
      }),
    );
    final firstRepository = RemoteSeriesRepository(client);
    final searchData = await client.search('query');
    final result =
        searchData.map((item) => ContentApiMapper.series(item)).single;
    firstRepository.remember(result);

    final restartedRepository = RemoteSeriesRepository(client);
    final resolved = await restartedRepository.byId(result.id);

    expect(resolved.id, 'search-restart');
    expect(resolved.title, 'Series search-restart');
  });

  test('old servers fall back to home after a detail 404', () async {
    final paths = <String>[];
    final client = ContentApiClient(
      defaultBaseUrl: 'https://example.com',
      httpClient: MockClient((request) async {
        paths.add(request.url.path);
        if (request.url.path == '/api/book/home-only') {
          return http.Response(
            jsonEncode({'success': false, 'error': 'not-found'}),
            404,
          );
        }
        return _ok({'hero': _book('home-only')});
      }),
    );
    final repository = RemoteSeriesRepository(client);

    final series = await repository.byId('home-only');

    expect(series.id, 'home-only');
    expect(paths, ['/api/book/home-only', '/api/home']);
  });

  test('unknown detail and home item returns not-found', () async {
    final client = ContentApiClient(
      defaultBaseUrl: 'https://example.com',
      httpClient: MockClient((request) async {
        if (request.url.path == '/api/book/missing') {
          return http.Response(
            jsonEncode({'success': false, 'error': 'not-found'}),
            404,
          );
        }
        return _ok({'sections': []});
      }),
    );
    final repository = RemoteSeriesRepository(client);

    await expectLater(
      repository.byId('missing'),
      throwsA(
        isA<ContentApiException>().having(
          (error) => error.code,
          'code',
          'not-found',
        ),
      ),
    );
  });
}
