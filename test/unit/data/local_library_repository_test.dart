import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shortigo/data/local/local_library_repository.dart';
import 'package:shortigo/data/local/shortigo_database.dart';
import 'package:shortigo/domain/entities/category.dart';
import 'package:shortigo/domain/entities/series.dart';
import 'package:shortigo/domain/entities/watch_history_entry.dart';

void main() {
  test('saved and history records are account-scoped and update in place',
      () async {
    final database = ShortigoDatabase.forTesting(NativeDatabase.memory());
    addTearDown(database.close);
    final library = LocalLibraryRepository(database);
    final series = Series(
      id: 's1',
      title: 'Drama',
      coverUrl: 'https://example.com/poster.jpg',
      category: Category.forYou,
      createdAt: DateTime.utc(2026),
    );
    final entry = WatchHistoryEntry(
      seriesId: series.id,
      series: series,
      episodeId: 'e3',
      episodeOrder: 3,
      chapterIndex: 2,
      positionMs: 100,
      durationMs: 1000,
      watchedAt: DateTime.utc(2026, 1, 1),
    );

    await library.saveSeries('guest', series);
    await library.saveSeries('user-a', series);
    await library.upsertHistory('guest', entry);
    await library.upsertHistory(
      'guest',
      WatchHistoryEntry(
        seriesId: series.id,
        series: series,
        episodeId: 'e3',
        episodeOrder: 3,
        chapterIndex: 2,
        positionMs: 700,
        durationMs: 1000,
        watchedAt: DateTime.utc(2026, 1, 2),
      ),
    );

    expect((await library.listSaved('guest')).map((item) => item.id), ['s1']);
    expect((await library.listSaved('user-b')), isEmpty);
    final history = await library.listHistory('guest');
    expect(history, hasLength(1));
    expect(history.single.positionMs, 700);
    expect((await library.listHistory('user-a')), isEmpty);
  });
}
