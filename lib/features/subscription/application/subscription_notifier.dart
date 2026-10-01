import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../../../domain/interfaces/iap_gateway.dart';
import '../../profile/application/profile_notifier.dart';

class SubscriptionState {
  const SubscriptionState({
    this.offerings = const [],
    this.isLoading = false,
    this.error,
    this.message,
  });

  final List<IapOffering> offerings;
  final bool isLoading;
  final String? error;
  final String? message;
}

class SubscriptionNotifier extends AsyncNotifier<SubscriptionState> {
  @override
  Future<SubscriptionState> build() async {
    final iap = ref.read(iapGatewayProvider);
    final offerings = await iap.getOfferings();
    return SubscriptionState(offerings: offerings);
  }

  Future<void> purchase(String packageId) async {
    final offerings = state.value?.offerings ?? const <IapOffering>[];
    state = const AsyncLoading<SubscriptionState>().copyWithPrevious(state);
    try {
      final iap = ref.read(iapGatewayProvider);
      final purchased = await iap.purchase(packageId);
      if (!purchased) {
        state = AsyncData(
          SubscriptionState(
            offerings: offerings,
            error: 'subscription-purchase-failed',
          ),
        );
        return;
      }
      ref.invalidate(profileNotifierProvider);
      ref.invalidate(effectiveVipProvider);
      state = AsyncData(
        SubscriptionState(
          offerings: offerings,
          message: 'subscription-purchased',
        ),
      );
    } catch (error) {
      state = AsyncData(
        SubscriptionState(
          offerings: offerings,
          error: 'subscription-purchase-failed',
        ),
      );
    }
  }

  Future<void> restorePurchases() async {
    final offerings = state.value?.offerings ?? const <IapOffering>[];
    state = AsyncData(SubscriptionState(offerings: offerings, isLoading: true));
    try {
      final restored = await ref.read(iapGatewayProvider).restorePurchases();
      if (restored) {
        ref.invalidate(profileNotifierProvider);
        ref.invalidate(effectiveVipProvider);
      }
      state = AsyncData(
        SubscriptionState(
          offerings: offerings,
          message: restored
              ? 'subscription-restored'
              : 'no-active-vip-purchase',
        ),
      );
    } catch (error) {
      state = AsyncData(
        SubscriptionState(
          offerings: offerings,
          error: 'subscription-restore-failed',
        ),
      );
    }
  }

  Future<void> resetTestVip() async {
    if (!ref.read(vipTestModeProvider)) {
      return;
    }
    final offerings = state.value?.offerings ?? const <IapOffering>[];
    await ref.read(testVipEntitlementStoreProvider).reset();
    ref.invalidate(effectiveVipProvider);
    ref.invalidate(profileNotifierProvider);
    state = AsyncData(
      SubscriptionState(offerings: offerings, message: 'test-vip-reset'),
    );
  }
}

final subscriptionNotifierProvider =
    AsyncNotifierProvider<SubscriptionNotifier, SubscriptionState>(
      SubscriptionNotifier.new,
    );
