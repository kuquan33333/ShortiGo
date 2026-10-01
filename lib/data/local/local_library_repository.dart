import 'dart:convert';
import 'dart:typed_data';

import '../../domain/entities/series.dart';
import '../../domain/entities/watch_history_entry.dart';
import 'shortigo_database.dart';

class LocalLibraryRepository {
  LocalLibraryRepository(this._database);

  final ShortigoDatabase _database;

  static String scopeFor(String? userId) => userId == null ? 'guest' : userId;

  Future<List<Series>> listSaved(String scope) async {
    final rows = await _database.readCachedCategory(_savedCategory(scope));
    return rows.map(_seriesFromRow).whereType<Series>().toList(growable: false);
  }

  Future<void> saveSeries(String scope, Series series) {
    return _database.writeCachedRecord(
      id: _savedId(scope, series.id),
      payload: _encode(series.toJson()),
      category: _savedCategory(scope),
    );
  }

  Future<void> removeSeries(String scope, String seriesId) {
    return _database.deleteCachedRecord(_savedId(scope, seriesId));
  }

  Future<List<WatchHistoryEntry>> listHistory(String scope) async {
    final rows = await _database.readCachedCategory(_historyCategory(scope));
    return rows
        .map(_historyFromRow)
        .whereType<WatchHistoryEntry>()
        .toList(growable: false);
  }

  Future<void> upsertHistory(String scope, WatchHistoryEntry entry) {
    return _database.writeCachedRecord(
      id: _historyId(scope, entry.seriesId),
      payload: _encode(entry.toJson()),
      category: _historyCategory(scope),
    );
  }

  Series? _seriesFromRow(CachedSeriesRow row) {
    try {
      final json = jsonDecode(utf8.decode(row.payload));
      return json is Map
          ? Series.fromJson(Map<String, dynamic>.from(json))
          : null;
    } on Object {
      return null;
    }
  }

  WatchHistoryEntry? _historyFromRow(CachedSeriesRow row) {
    try {
      final json = jsonDecode(utf8.decode(row.payload));
      return json is Map
          ? WatchHistoryEntry.fromJson(Map<String, dynamic>.from(json))
          : null;
    } on Object {
      return null;
    }
  }

  Uint8List _encode(Map<String, dynamic> json) =>
      Uint8List.fromList(utf8.encode(jsonEncode(json)));

  String _savedCategory(String scope) => 'library:saved:$scope';
  String _historyCategory(String scope) => 'library:history:$scope';
  String _savedId(String scope, String seriesId) =>
      '__library__:saved:$scope:$seriesId';
  String _historyId(String scope, String seriesId) =>
      '__library__:history:$scope:$seriesId';
}
