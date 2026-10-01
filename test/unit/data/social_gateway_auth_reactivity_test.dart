import 'dart:async';

import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shortigo/core/providers.dart';

class _MockFirebaseUser extends Mock implements fb.User {}

void main() {
  test('social gateway follows login, logout, and account switch UID',
      () async {
    final authChanges = StreamController<fb.User?>.broadcast();
    final firestore = FakeFirebaseFirestore();
    addTearDown(authChanges.close);

    await firestore.collection('users').doc('A').set({
      'favoriteSeriesIds': <String>[],
      'likedEpisodeIds': <String>[],
      'followedSeriesIds': <String>[],
    });
    await firestore.collection('users').doc('B').set({
      'favoriteSeriesIds': <String>[],
      'likedEpisodeIds': <String>[],
      'followedSeriesIds': <String>[],
    });

    final userA = _MockFirebaseUser();
    final userB = _MockFirebaseUser();
    when(() => userA.uid).thenReturn('A');
    when(() => userB.uid).thenReturn('B');

    final container = ProviderContainer(
      overrides: [
        currentAuthUserProvider.overrideWith((_) => authChanges.stream),
        firestoreProvider.overrideWithValue(firestore),
      ],
    );
    addTearDown(container.dispose);

    authChanges.add(null);
    await _flushAuthEvent();
    final guestGateway = container.read(socialActionsGatewayProvider);
    expect(
      () => guestGateway.setSeriesSaved(
        seriesId: 'guest-attempt',
        saved: true,
      ),
      throwsStateError,
    );

    authChanges.add(userA);
    await _flushAuthEvent();
    await container
        .read(socialActionsGatewayProvider)
        .setSeriesSaved(seriesId: 'saved-by-a', saved: true);

    authChanges.add(null);
    await _flushAuthEvent();
    authChanges.add(userB);
    await _flushAuthEvent();
    await container
        .read(socialActionsGatewayProvider)
        .setSeriesSaved(seriesId: 'saved-by-b', saved: true);

    final a = await firestore.collection('users').doc('A').get();
    final b = await firestore.collection('users').doc('B').get();
    expect(a.data()!['favoriteSeriesIds'], ['saved-by-a']);
    expect(b.data()!['favoriteSeriesIds'], ['saved-by-b']);
  });
}

Future<void> _flushAuthEvent() async {
  await Future<void>.delayed(Duration.zero);
  await Future<void>.delayed(Duration.zero);
}
