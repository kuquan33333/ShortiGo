import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/interfaces/social_actions_gateway.dart';

class FirestoreSocialActionsGateway implements SocialActionsGateway {
  FirestoreSocialActionsGateway({
    required FirebaseFirestore db,
    required String? userId,
  })  : _db = db,
        _userId = userId;

  final FirebaseFirestore _db;
  final String? _userId;

  @override
  Future<void> setEpisodeLiked({
    required String episodeId,
    required bool liked,
  }) {
    final userId = _requireUserId();
    final userRef = _db.collection('users').doc(userId);
    final episodeRef = _db.collection('episodes').doc(episodeId);
    return _updateUserPreference(
      userRef: userRef,
      field: 'likedEpisodeIds',
      value: episodeId,
      enabled: liked,
    ).then((changed) async {
      if (changed) {
        await _updateLegacyCounter(
          ref: episodeRef,
          field: 'likeCount',
          delta: liked ? 1 : -1,
        );
      }
    });
  }

  @override
  Future<void> setSeriesSaved({
    required String seriesId,
    required bool saved,
  }) {
    final userId = _requireUserId();
    final userRef = _db.collection('users').doc(userId);
    final seriesRef = _db.collection('series').doc(seriesId);

    return _updateUserPreference(
      userRef: userRef,
      field: 'favoriteSeriesIds',
      value: seriesId,
      enabled: saved,
    ).then((changed) async {
      if (changed) {
        await _updateLegacyCounter(
          ref: seriesRef,
          field: 'saveCount',
          delta: saved ? 1 : -1,
        );
      }
    });
  }

  @override
  Future<void> recordEpisodeShare({required String episodeId}) {
    final episodeRef = _db.collection('episodes').doc(episodeId);
    return _db.runTransaction((transaction) async {
      final episode = await transaction.get(episodeRef);
      if (episode.exists) {
        transaction.update(episodeRef, {
          'shareCount': _nextCount(episode.data()?['shareCount'], 1),
        });
      }
    });
  }

  @override
  Future<void> setSeriesFollowed({
    required String seriesId,
    required bool followed,
  }) {
    final userId = _requireUserId();
    final userRef = _db.collection('users').doc(userId);
    final seriesRef = _db.collection('series').doc(seriesId);

    return _updateUserPreference(
      userRef: userRef,
      field: 'followedSeriesIds',
      value: seriesId,
      enabled: followed,
    ).then((changed) async {
      if (changed) {
        await _updateLegacyCounter(
          ref: seriesRef,
          field: 'followerCount',
          delta: followed ? 1 : -1,
        );
      }
    });
  }

  Future<bool> _updateUserPreference({
    required DocumentReference<Map<String, dynamic>> userRef,
    required String field,
    required String value,
    required bool enabled,
  }) async {
    return _db.runTransaction((transaction) async {
      final snapshot = await transaction.get(userRef);
      final values = (snapshot.data()?[field] as List<Object?>?) ?? const [];
      final present = values.contains(value);
      if (present == enabled) return false;
      transaction.update(userRef, {
        field: enabled
            ? FieldValue.arrayUnion([value])
            : FieldValue.arrayRemove([value]),
      });
      return true;
    });
  }

  Future<void> _updateLegacyCounter({
    required DocumentReference<Map<String, dynamic>> ref,
    required String field,
    required int delta,
  }) async {
    try {
      final snapshot = await ref.get();
      if (!snapshot.exists) return;
      await ref.update({
        field: _nextCount(snapshot.data()?[field], delta),
      });
    } on Object {
      // Content API catalog items do not have to exist in Firestore. The
      // account preference above is authoritative; legacy counters are best
      // effort only.
    }
  }

  String _requireUserId() {
    final userId = _userId;
    if (userId == null) {
      throw StateError('Sign in required');
    }
    return userId;
  }
}

int _nextCount(Object? current, int delta) {
  final count = current is int ? current : 0;
  final next = count + delta;
  return next < 0 ? 0 : next;
}
