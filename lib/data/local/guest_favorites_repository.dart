import 'dart:convert';
import 'dart:typed_data';

import '../../domain/entities/series.dart';
import 'shortigo_database.dart';

class GuestFavoritesRepository {
  GuestFavoritesRepository(this._database);

  final ShortigoDatabase _database;

  Future<List<Series>> list() async {
    final rows = await _database.readGuestFavorites();
    final result = <Series>[];
    for (final row in rows) {
      try {
        final decoded = jsonDecode(utf8.decode(row.payload));
        if (decoded is Map) {
          result.add(Series.fromJson(Map<String, dynamic>.from(decoded)));
        }
      } on Object {
        // A corrupt local favorite should not prevent the rest from loading.
      }
    }
    return result;
  }

  Future<void> save(Series series) {
    return _database.writeGuestFavorite(
      seriesId: series.id,
      payload: Uint8List.fromList(utf8.encode(jsonEncode(series.toJson()))),
    );
  }

  Future<void> remove(String seriesId) =>
      _database.deleteGuestFavorite(seriesId);

  Future<bool> contains(String seriesId) =>
      _database.hasGuestFavorite(seriesId);
}
