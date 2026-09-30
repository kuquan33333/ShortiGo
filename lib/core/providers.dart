import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../bootstrap/firebase_bootstrap.dart';
import 'env/env.dart';
import '../data/ads/admob_ad_gateway.dart';
import '../data/firestore/transaction_repository.dart';
import '../data/firestore/user_repository.dart';
import '../data/iap/revenuecat_iap_gateway.dart';
import '../data/social/firestore_social_actions_gateway.dart';
import '../data/rewards/firestore_reward_gateway.dart';
import '../data/local/shortigo_database.dart';
import '../data/local/guest_favorites_repository.dart';
import '../data/remote/content_api_client.dart';
import '../data/remote/remote_episode_repository.dart';
import '../data/remote/remote_series_repository.dart';
import '../data/remote/remote_video_source.dart';
import '../data/rewards/reward_api_gateway.dart';
import '../domain/entities/user.dart';
import '../domain/interfaces/ad_gateway.dart';
import '../domain/interfaces/episode_repository.dart';
import '../domain/interfaces/iap_gateway.dart';
import '../domain/interfaces/reward_gateway.dart';
import '../domain/interfaces/series_repository.dart';
import '../domain/interfaces/social_actions_gateway.dart';
import '../domain/interfaces/transaction_repository.dart';
import '../domain/interfaces/user_repository.dart';
import '../domain/interfaces/video_source.dart';

// === Foundational providers (always available) ===

final firebaseAvailableProvider =
    Provider<bool>((_) => FirebaseBootstrap.isAvailable);

final firestoreProvider = Provider<FirebaseFirestore>((_) {
  if (!FirebaseBootstrap.isAvailable) {
    throw StateError('Dịch vụ tài khoản hiện chưa được cấu hình.');
  }
  return FirebaseFirestore.instance;
});

final firebaseAuthProvider = Provider<fb.FirebaseAuth>((_) {
  if (!FirebaseBootstrap.isAvailable) {
    throw StateError('Dịch vụ tài khoản hiện chưa được cấu hình.');
  }
  return fb.FirebaseAuth.instance;
});

final currentAuthUserProvider = StreamProvider<fb.User?>((ref) {
  if (!ref.watch(firebaseAvailableProvider)) return Stream.value(null);
  return ref.watch(firebaseAuthProvider).authStateChanges();
});

final currentAppUserDocProvider = StreamProvider<AppUser?>((ref) {
  final auth = ref.watch(currentAuthUserProvider).value;
  if (auth == null) {
    return Stream.value(null);
  }
  return ref.watch(userRepositoryProvider).watch(auth.uid);
});

final shortigoDatabaseProvider = Provider<ShortigoDatabase>((_) {
  return ShortigoDatabase();
});

final guestFavoritesRepositoryProvider =
    Provider<GuestFavoritesRepository>((ref) {
  return GuestFavoritesRepository(ref.watch(shortigoDatabaseProvider));
});

final guestFavoriteSavedProvider =
    FutureProvider.family<bool, String>((ref, id) {
  return ref.watch(guestFavoritesRepositoryProvider).contains(id);
});

final contentApiClientProvider = Provider<ContentApiClient>((ref) {
  return ContentApiClient(
    database: ref.watch(shortigoDatabaseProvider),
    defaultBaseUrl: env.contentApiBaseUrl,
  );
});

final seriesRepositoryProvider = Provider<SeriesRepository>((ref) {
  return RemoteSeriesRepository(ref.watch(contentApiClientProvider));
});

final episodeRepositoryProvider = Provider<EpisodeRepository>((ref) {
  return RemoteEpisodeRepository(ref.watch(contentApiClientProvider));
});

final transactionRepositoryProvider = Provider<TransactionRepository>((ref) {
  return FirestoreTransactionRepository(ref.watch(firestoreProvider));
});

final userRepositoryProvider = Provider<UserRepository>((ref) {
  return FirestoreUserRepository(ref.watch(firestoreProvider));
});

final socialActionsGatewayProvider = Provider<SocialActionsGateway>((ref) {
  return FirestoreSocialActionsGateway(
    db: ref.watch(firestoreProvider),
    userId: ref.watch(firebaseAuthProvider).currentUser?.uid,
  );
});

final videoSourceProvider = Provider<VideoSource>((ref) {
  return RemoteVideoSource(ref.watch(contentApiClientProvider));
});

final adGatewayProvider = Provider<AdGateway>((_) {
  return AdmobAdGateway();
});

final adStatusProvider = StreamProvider<AdStatus>((ref) {
  return ref.watch(adGatewayProvider).status;
});

final rewardGatewayProvider = Provider<RewardGateway>((ref) {
  if (env.rewardApiBaseUrl.isEmpty) {
    return FirestoreRewardGateway(
      db: ref.watch(firestoreProvider),
      userId: ref.watch(firebaseAuthProvider).currentUser?.uid,
    );
  }
  return RewardApiGateway(
    auth: ref.watch(firebaseAuthProvider),
    baseUrl: env.rewardApiBaseUrl,
  );
});

final iapGatewayProvider = Provider<IapGateway>((_) {
  return RevenueCatIapGateway();
});

// === Future providers (added in their respective milestones) ===
// M6: adminConfigGatewayProvider
