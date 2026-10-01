import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart';
import 'package:http/testing.dart';
import 'package:shortigo/core/providers.dart';
import 'package:shortigo/data/remote/content_api_client.dart';
import 'package:shortigo/features/settings/presentation/settings_page.dart';
import 'package:shortigo/l10n/app_localizations.dart';

Widget _app(ContentApiClient client) {
  return ProviderScope(
    overrides: [contentApiClientProvider.overrideWithValue(client)],
    child: const MaterialApp(
      locale: Locale('vi', 'VN'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: SettingsPage(),
    ),
  );
}

Response _statusResponse() => Response(
      jsonEncode({
        'success': true,
        'data': {
          'apiVersion': 2,
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
            {'id': 'reelshort', 'name': 'ReelShort', 'ok': true},
          ],
        },
      }),
      200,
    );

void main() {
  testWidgets('save verifies source status before persisting a valid URL',
      (tester) async {
    final requests = <String>[];
    final client = ContentApiClient(
      defaultBaseUrl: 'https://old.example.com',
      httpClient: MockClient((request) async {
        requests.add(request.url.toString());
        return _statusResponse();
      }),
    );
    await tester.pumpWidget(_app(client));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'https://new.example.com/');
    await tester.tap(find.text('Lưu'));
    await tester.pumpAndSettle();

    expect(requests, ['https://new.example.com/api/source-status']);
    expect(await client.configuredBaseUrl, 'https://new.example.com');
    expect(find.text('Hoạt động'), findsWidgets);
  });

  testWidgets('save keeps the previous URL when source status fails',
      (tester) async {
    final client = ContentApiClient(
      defaultBaseUrl: 'https://old.example.com',
      httpClient: MockClient((_) async => Response('not-json', 200)),
    );
    await tester.pumpWidget(_app(client));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'https://dead.example.com');
    await tester.tap(find.text('Lưu'));
    await tester.pumpAndSettle();

    expect(await client.configuredBaseUrl, 'https://old.example.com');
    expect(find.text('Máy chủ trả về dữ liệu không hợp lệ.'), findsOneWidget);
  });
}
