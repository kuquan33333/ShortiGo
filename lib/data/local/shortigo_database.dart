import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

part 'shortigo_database.g.dart';

@DataClassName('CachedSeriesRow')
class CachedSeries extends Table {
  TextColumn get id => text()();
  BlobColumn get payload => blob()();
  DateTimeColumn get cachedAt => dateTime()();
  TextColumn get category => text()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('CachedEpisodeRow')
class CachedEpisodes extends Table {
  TextColumn get seriesId => text()();
  IntColumn get orderIdx => integer()();
  BlobColumn get payload => blob()();
  DateTimeColumn get cachedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {seriesId, orderIdx};
}

@DriftDatabase(tables: [CachedSeries, CachedEpisodes])
class ShortigoDatabase extends _$ShortigoDatabase {
  ShortigoDatabase() : super(_openConnection());
  ShortigoDatabase.forTesting(super.e);

  @override
  int get schemaVersion => 1;

  Future<String?> readSetting(String key) async {
    final row = await (select(
      cachedSeries,
    )..where((table) => table.id.equals(_settingId(key))))
        .getSingleOrNull();
    return row == null ? null : String.fromCharCodes(row.payload);
  }

  Future<void> writeSetting(String key, String value) {
    return into(cachedSeries).insertOnConflictUpdate(
      CachedSeriesCompanion.insert(
        id: _settingId(key),
        payload: Uint8List.fromList(value.codeUnits),
        cachedAt: DateTime.now().toUtc(),
        category: 'settings',
      ),
    );
  }

  Future<void> deleteSetting(String key) {
    return (delete(
      cachedSeries,
    )..where((row) => row.id.equals(_settingId(key))))
        .go();
  }

  Future<List<CachedSeriesRow>> readGuestFavorites() {
    return (select(cachedSeries)
          ..where((table) => table.category.equals('guest-favorite'))
          ..orderBy([(row) => OrderingTerm.desc(row.cachedAt)]))
        .get();
  }

  Future<List<CachedSeriesRow>> readCachedCategory(String category) {
    return (select(cachedSeries)
          ..where((table) => table.category.equals(category))
          ..orderBy([(row) => OrderingTerm.desc(row.cachedAt)]))
        .get();
  }

  Future<void> writeCachedRecord({
    required String id,
    required Uint8List payload,
    required String category,
  }) {
    return into(cachedSeries).insertOnConflictUpdate(
      CachedSeriesCompanion.insert(
        id: id,
        payload: payload,
        cachedAt: DateTime.now().toUtc(),
        category: category,
      ),
    );
  }

  Future<void> deleteCachedRecord(String id) {
    return (delete(cachedSeries)..where((row) => row.id.equals(id))).go();
  }

  Future<void> writeGuestFavorite({
    required String seriesId,
    required Uint8List payload,
  }) {
    return into(cachedSeries).insertOnConflictUpdate(
      CachedSeriesCompanion.insert(
        id: _guestFavoriteId(seriesId),
        payload: payload,
        cachedAt: DateTime.now().toUtc(),
        category: 'guest-favorite',
      ),
    );
  }

  Future<void> deleteGuestFavorite(String seriesId) {
    return (delete(
      cachedSeries,
    )..where((row) => row.id.equals(_guestFavoriteId(seriesId))))
        .go();
  }

  Future<bool> hasGuestFavorite(String seriesId) async {
    final row = await (select(cachedSeries)
          ..where((table) => table.id.equals(_guestFavoriteId(seriesId))))
        .getSingleOrNull();
    return row != null;
  }

  static String _settingId(String key) => '__setting__:$key';
  static String _guestFavoriteId(String seriesId) => '__guest__:$seriesId';

  static LazyDatabase _openConnection() {
    return LazyDatabase(() async {
      final dir = await getApplicationDocumentsDirectory();
      final file = File(p.join(dir.path, 'shortigo_cache.sqlite'));
      return NativeDatabase.createInBackground(file);
    });
  }
}
