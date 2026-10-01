import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/transaction.dart' as domain;
import '../../domain/entities/user.dart';
import '../../domain/entities/category.dart';
import '../../domain/entities/series.dart';
import '../../domain/entities/watch_history_entry.dart';
import '../../domain/interfaces/user_repository.dart';
import 'firestore_json.dart';

class FirestoreUserRepository implements UserRepository {
  FirestoreUserRepository(this._db);

  final FirebaseFirestore _db;

  @override
  Future<AppUser> byId(String id) async {
    final doc = await _db.collection('users').doc(id).get();
    if (!doc.exists) {
      throw StateError('User $id not found');
    }

    return AppUser.fromJson(firestoreJson(doc.data()!, id: doc.id));
  }

  @override
  Stream<AppUser> watch(String id) {
    return _db.collection('users').doc(id).snapshots().map((doc) {
      if (!doc.exists) {
        throw StateError('User $id not found');
      }

      return AppUser.fromJson(firestoreJson(doc.data()!, id: doc.id));
    });
  }

  @override
  Future<void> createIfMissing(AppUser user) async {
    final ref = _db.collection('users').doc(user.id);
    await _db.runTransaction((transaction) async {
      final snapshot = await transaction.get(ref);
      if (!snapshot.exists) {
        transaction.set(ref, user.toJson());
      }
    });
  }

  @override
  Future<void> setDailyCheckIn(String userId, DateTime at) async {
    await _db.collection('users').doc(userId).update({
      'lastDailyCheckIn': Timestamp.fromDate(at),
    });
  }

  @override
  Future<void> saveSeries({
    required String userId,
    required String seriesId,
  }) async {
    await _db.collection('users').doc(userId).update({
      'favoriteSeriesIds': FieldValue.arrayUnion([seriesId]),
    });
  }

  @override
  Future<void> unsaveSeries({
    required String userId,
    required String seriesId,
  }) async {
    await _db.collection('users').doc(userId).update({
      'favoriteSeriesIds': FieldValue.arrayRemove([seriesId]),
    });
  }

  @override
  Future<void> deletePersonalData(String userId) async {
    final user = _db.collection('users').doc(userId);
    await _deleteCollection(user.collection('favorites'));
    await _deleteCollection(user.collection('events'));
    await _deleteCollection(user.collection('watchHistory'));
    await user.delete();
  }

  @override
  Future<List<WatchHistoryEntry>> readWatchHistory(String userId) async {
    final snapshot = await _db
        .collection('users')
        .doc(userId)
        .collection('watchHistory')
        .orderBy('watchedAt', descending: true)
        .get();
    return snapshot.docs.map((doc) {
      final data = doc.data();
      final watchedAt = data['watchedAt'];
      final cover = data['coverUrl']?.toString() ?? '';
      final title = data['title']?.toString() ?? doc.id;
      final seriesId = data['seriesId']?.toString() ?? doc.id;
      return WatchHistoryEntry(
        seriesId: seriesId,
        series: Series(
          id: seriesId,
          title: title,
          coverUrl: cover,
          category: Category.forYou,
          createdAt: DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
        ),
        episodeId: data['episodeId']?.toString() ?? '',
        episodeOrder: _int(data['episodeOrder']),
        chapterIndex: _int(data['chapterIndex']),
        positionMs: _int(data['positionMs']),
        durationMs: _int(data['durationMs']),
        watchedAt: _timestamp(watchedAt),
      );
    }).toList(growable: false);
  }

  @override
  Future<void> saveWatchHistory(
    String userId,
    WatchHistoryEntry entry,
  ) {
    return _db
        .collection('users')
        .doc(userId)
        .collection('watchHistory')
        .doc(entry.seriesId)
        .set({
      'seriesId': entry.seriesId,
      'episodeId': entry.episodeId,
      'episodeOrder': entry.episodeOrder,
      'chapterIndex': entry.chapterIndex,
      'positionMs': entry.positionMs,
      'durationMs': entry.durationMs,
      'watchedAt': Timestamp.fromDate(entry.watchedAt.toUtc()),
      'title': entry.series.title,
      'coverUrl': entry.series.coverUrl,
    }, SetOptions(merge: true));
  }

  Future<void> _deleteCollection(
    CollectionReference<Map<String, dynamic>> collection,
  ) async {
    while (true) {
      final snapshot = await collection.limit(400).get();
      if (snapshot.docs.isEmpty) {
        return;
      }
      final batch = _db.batch();
      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    }
  }

  @override
  Future<void> grantDemoBonus({
    required String userId,
    required domain.TxType type,
    required int amount,
    required String reference,
    DateTime? dailyCheckInAt,
  }) async {
    final now = DateTime.now().toUtc();
    final userRef = _db.collection('users').doc(userId);
    final txRef = type == domain.TxType.dailyCheckIn
        ? userRef.collection('transactions').doc(_transactionDocId(reference))
        : userRef.collection('transactions').doc();

    await _db.runTransaction((transaction) async {
      if (type == domain.TxType.dailyCheckIn) {
        final existingTx = await transaction.get(txRef);
        if (existingTx.exists) {
          return;
        }
      }

      transaction.update(userRef, {
        'bonus': FieldValue.increment(amount),
        if (dailyCheckInAt != null)
          'lastDailyCheckIn': dailyCheckInAt.toUtc().toIso8601String(),
      });
      transaction.set(txRef, {
        'id': txRef.id,
        'userId': userId,
        'type': type.name,
        'coinsDelta': 0,
        'bonusDelta': amount,
        'reference': reference,
        'at': now.toIso8601String(),
      });
    });
  }

  String _transactionDocId(String reference) {
    return reference.replaceAll('/', '_');
  }
}

int _int(Object? value) {
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

DateTime _timestamp(Object? value) {
  if (value is Timestamp) return value.toDate().toUtc();
  return DateTime.tryParse(value?.toString() ?? '')?.toUtc() ??
      DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);
}
