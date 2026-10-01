import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shortigo/data/social/firestore_social_actions_gateway.dart';

void main() {
  group('FirestoreSocialActionsGateway', () {
    test('liking and unliking an episode updates user state and public count',
        () async {
      final db = FakeFirebaseFirestore();
      await _seedUser(db);
      await db.collection('episodes').doc('e1').set({
        'seriesId': 's1',
        'order': 1,
        'videoUrl': 'https://example.com/v.mp4',
        'thumbnailUrl': 'https://example.com/t.jpg',
        'durationSec': 60,
        'likeCount': 0,
      });
      final gateway = FirestoreSocialActionsGateway(db: db, userId: 'u1');

      await gateway.setEpisodeLiked(episodeId: 'e1', liked: true);
      await gateway.setEpisodeLiked(episodeId: 'e1', liked: true);

      var user = await db.collection('users').doc('u1').get();
      var episode = await db.collection('episodes').doc('e1').get();
      expect(user.data()!['likedEpisodeIds'], ['e1']);
      expect(episode.data()!['likeCount'], 1);

      await gateway.setEpisodeLiked(episodeId: 'e1', liked: false);

      user = await db.collection('users').doc('u1').get();
      episode = await db.collection('episodes').doc('e1').get();
      expect(user.data()!['likedEpisodeIds'], isEmpty);
      expect(episode.data()!['likeCount'], 0);
    });

    test('saving and unsaving a series updates favorite state and save count',
        () async {
      final db = FakeFirebaseFirestore();
      await _seedUser(db);
      await db.collection('series').doc('s1').set({
        'title': 'Drama',
        'coverUrl': 'https://example.com/c.jpg',
        'category': 'hot',
        'createdAt': Timestamp.fromDate(DateTime.utc(2026, 6, 10)),
        'saveCount': 0,
      });
      final gateway = FirestoreSocialActionsGateway(db: db, userId: 'u1');

      await gateway.setSeriesSaved(seriesId: 's1', saved: true);
      await gateway.setSeriesSaved(seriesId: 's1', saved: true);

      var user = await db.collection('users').doc('u1').get();
      var series = await db.collection('series').doc('s1').get();
      expect(user.data()!['favoriteSeriesIds'], ['s1']);
      expect(series.data()!['saveCount'], 1);

      await gateway.setSeriesSaved(seriesId: 's1', saved: false);

      user = await db.collection('users').doc('u1').get();
      series = await db.collection('series').doc('s1').get();
      expect(user.data()!['favoriteSeriesIds'], isEmpty);
      expect(series.data()!['saveCount'], 0);
    });

    test('sharing an episode increments share count once per tap', () async {
      final db = FakeFirebaseFirestore();
      await _seedUser(db);
      await db.collection('episodes').doc('e1').set({
        'seriesId': 's1',
        'order': 1,
        'videoUrl': 'https://example.com/v.mp4',
        'thumbnailUrl': 'https://example.com/t.jpg',
        'durationSec': 60,
        'shareCount': 0,
      });
      final gateway = FirestoreSocialActionsGateway(db: db, userId: 'u1');

      await gateway.recordEpisodeShare(episodeId: 'e1');
      await gateway.recordEpisodeShare(episodeId: 'e1');

      final episode = await db.collection('episodes').doc('e1').get();
      expect(episode.data()!['shareCount'], 2);
    });

    test('user preferences do not require a Firestore catalog document',
        () async {
      final db = FakeFirebaseFirestore();
      await _seedUser(db);
      final gateway = FirestoreSocialActionsGateway(db: db, userId: 'u1');

      await gateway.setSeriesSaved(seriesId: 'remote-series', saved: true);
      await gateway.setEpisodeLiked(episodeId: 'remote-episode', liked: true);

      final user = await db.collection('users').doc('u1').get();
      expect(user.data()!['favoriteSeriesIds'], ['remote-series']);
      expect(user.data()!['likedEpisodeIds'], ['remote-episode']);
    });

    test('following and unfollowing a series updates user state and count',
        () async {
      final db = FakeFirebaseFirestore();
      await _seedUser(db);
      await db.collection('series').doc('s1').set({
        'title': 'Drama',
        'coverUrl': 'https://example.com/c.jpg',
        'category': 'hot',
        'createdAt': Timestamp.fromDate(DateTime.utc(2026, 6, 10)),
        'followerCount': 0,
      });
      final gateway = FirestoreSocialActionsGateway(db: db, userId: 'u1');

      await gateway.setSeriesFollowed(seriesId: 's1', followed: true);
      await gateway.setSeriesFollowed(seriesId: 's1', followed: true);

      var user = await db.collection('users').doc('u1').get();
      var series = await db.collection('series').doc('s1').get();
      expect(user.data()!['followedSeriesIds'], ['s1']);
      expect(series.data()!['followerCount'], 1);

      await gateway.setSeriesFollowed(seriesId: 's1', followed: false);

      user = await db.collection('users').doc('u1').get();
      series = await db.collection('series').doc('s1').get();
      expect(user.data()!['followedSeriesIds'], isEmpty);
      expect(series.data()!['followerCount'], 0);
    });
  });
}

Future<void> _seedUser(FakeFirebaseFirestore db) {
  return db.collection('users').doc('u1').set({
    'email': 'u@example.com',
    'createdAt': Timestamp.fromDate(DateTime.utc(2026, 6, 10)),
    'favoriteSeriesIds': <String>[],
    'likedEpisodeIds': <String>[],
    'followedSeriesIds': <String>[],
  });
}
