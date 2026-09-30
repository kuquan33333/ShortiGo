import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shortigo/data/remote/content_api_client.dart';
import 'package:shortigo/data/remote/content_api_models.dart';

void main() {
  test('normalizes and validates API base URLs', () {
    expect(normalizeBaseUrl(' https://example.vercel.app/// '),
        'https://example.vercel.app');
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
              'apiVersion': 1,
              'language': 'vi',
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
    expect(status.apiVersion, 1);
    expect(status.language, 'vi');
    expect(status.providers.single.name, 'ReelShort VI');
    expect(status.providers.single.available, isTrue);
  });

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
      httpClient: MockClient((_) async => http.Response(
            jsonEncode(
                {'success': false, 'reason': 'locked-no-public-alternative'}),
            403,
          )),
    );
    await expectLater(
      locked.getData('/api/watch/book/0'),
      throwsA(isA<ContentApiSourceLockedException>()),
    );
  });
}
