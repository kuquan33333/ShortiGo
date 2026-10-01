import 'dart:convert';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shortigo/data/local/guest_favorites_repository.dart';
import 'package:shortigo/data/local/shortigo_database.dart';
import 'package:shortigo/domain/entities/category.dart';
import 'package:shortigo/domain/entities/series.dart';

void main() {
  late ShortigoDatabase database;

  setUp(() {
    database = ShortigoDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() async => database.close());

  test(
    'persists content API settings using the existing Drift cache',
    () async {
      await database.writeSetting('contentApiBaseUrl', 'https://api.example');
      expect(
        await database.readSetting('contentApiBaseUrl'),
        'https://api.example',
      );

      await database.deleteSetting('contentApiBaseUrl');
      expect(await database.readSetting('contentApiBaseUrl'), isNull);
    },
  );

  test('persists guest favorites locally without Firebase', () async {
    final favorites = GuestFavoritesRepository(database);
    final series = Series(
      id: 'book-1',
      title: 'Guest favorite',
      coverUrl: 'https://img.example/cover.jpg',
      category: Category.forYou,
      createdAt: DateTime.utc(2026),
    );

    await favorites.save(series);
    expect(await favorites.contains(series.id), isTrue);
    expect((await favorites.list()).single.title, series.title);
    expect(
      jsonDecode(
        utf8.decode((await database.readGuestFavorites()).single.payload),
      ),
      isA<Map<String, dynamic>>(),
    );

    await favorites.remove(series.id);
    expect(await favorites.list(), isEmpty);
  });
}
