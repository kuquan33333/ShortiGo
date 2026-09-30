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

    return _db.runTransaction((transaction) async {
      final user = await transaction.get(userRef);
      final episode = await transaction.get(episodeRef);
      final likedIds = _stringList(user.data()?['likedEpisodeIds']);
      final alreadyLiked = likedIds.contains(episodeId);

      if (liked == alreadyLiked) {
        return;
      }

      transaction.update(userRef, {
        'likedEpisodeIds': liked
            ? FieldValue.arrayUnion([episodeId])
            : FieldValue.arrayRemove([episodeId]),
      });
      if (episode.exists) {
        transaction.update(episodeRef, {
          'likeCount': _nextCount(episode.data()?['likeCount'], liked ? 1 : -1),
        });
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

    return _db.runTransaction((transaction) async {
      final user = await transaction.get(userRef);
      final series = await transaction.get(seriesRef);
      final savedIds = _stringList(user.data()?['favoriteSeriesIds']);
      final alreadySaved = savedIds.contains(seriesId);

      if (saved == alreadySaved) {
        return;
      }

      transaction.update(userRef, {
        'favoriteSeriesIds': saved
            ? FieldValue.arrayUnion([seriesId])
            : FieldValue.arrayRemove([seriesId]),
      });
      // Catalog metadata now comes from the Content API. The account
      // preference remains in Firestore, while the old catalog counter is
      // updated only when a legacy Firestore series document still exists.
      if (series.exists) {
        transaction.update(seriesRef, {
          'saveCount': _nextCount(series.data()?['saveCount'], saved ? 1 : -1),
        });
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

    return _db.runTransaction((transaction) async {
      final user = await transaction.get(userRef);
      final series = await transaction.get(seriesRef);
      final followedIds = _stringList(user.data()?['followedSeriesIds']);
      final alreadyFollowed = followedIds.contains(seriesId);

      if (followed == alreadyFollowed) {
        return;
      }

      transaction.update(userRef, {
        'followedSeriesIds': followed
            ? FieldValue.arrayUnion([seriesId])
            : FieldValue.arrayRemove([seriesId]),
      });
      if (series.exists) {
        transaction.update(seriesRef, {
          'followerCount':
              _nextCount(series.data()?['followerCount'], followed ? 1 : -1),
        });
      }
    });
  }

  String _requireUserId() {
    final userId = _userId;
    if (userId == null) {
      throw StateError('Sign in required');
    }
    return userId;
  }
}

List<String> _stringList(Object? value) {
  if (value is Iterable) {
    return value.whereType<String>().toList();
  }
  return const [];
}

int _nextCount(Object? current, int delta) {
  final count = current is int ? current : 0;
  final next = count + delta;
  return next < 0 ? 0 : next;
}
