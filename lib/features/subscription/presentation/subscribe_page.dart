import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/error/friendly_error.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/error_view.dart';
import '../../../shared/widgets/loading_view.dart';
import '../../../l10n/app_localizations.dart';
import '../application/subscription_notifier.dart';

class SubscribePage extends ConsumerWidget {
  const SubscribePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(subscriptionNotifierProvider);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.subscribeToVip)),
      body: async.when(
        loading: () => const LoadingView(),
        error: (error, _) => ErrorView(
          error: localizedFriendlyErrorFor(context, error),
          onRetry: () => ref.invalidate(subscriptionNotifierProvider),
        ),
        data: (state) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.vipGold, AppColors.accent],
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.vipMembership,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      l10n.vipBenefits,
                      style: TextStyle(color: Colors.white70),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              if (state.offerings.isEmpty)
                Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    l10n.noOfferingsAvailable,
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                )
              else
                ...state.offerings.expand((offering) => offering.packages).map(
                      (package) => Card(
                        child: ListTile(
                          title: Text(package.identifier),
                          trailing: Text(
                            package.priceString,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          onTap: () {
                            ref
                                .read(subscriptionNotifierProvider.notifier)
                                .purchase(package.identifier);
                          },
                        ),
                      ),
                    ),
              const SizedBox(height: 12),
              TextButton.icon(
                onPressed: state.isLoading
                    ? null
                    : () {
                        ref
                            .read(subscriptionNotifierProvider.notifier)
                            .restorePurchases();
                      },
                icon: const Icon(Icons.restore),
                label: Text(l10n.restorePurchases),
              ),
              if (state.message != null) ...[
                const SizedBox(height: 12),
                Text(
                  _messageFor(l10n, state.message!),
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
              ],
              if (state.error != null) ...[
                const SizedBox(height: 12),
                Text(
                  localizedFriendlyErrorFor(context, state.error!).message,
                  style: const TextStyle(color: AppColors.error),
                ),
              ],
            ],
          );
        },
      ),
    );
  }

  String _messageFor(AppLocalizations l10n, String code) {
    return switch (code) {
      'subscription-restored' => l10n.subscriptionRestored,
      'no-active-vip-purchase' => l10n.noActiveVipPurchase,
      _ => code,
    };
  }
}
