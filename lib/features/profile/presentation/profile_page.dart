import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/error/friendly_error.dart';
import '../../../core/providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../l10n/app_localizations.dart';
import '../../../domain/entities/transaction.dart';
import '../../../domain/entities/user.dart';
import '../../../shared/widgets/error_view.dart';
import '../../../shared/widgets/loading_view.dart';
import '../../subscription/application/subscription_notifier.dart';
import '../application/account_deletion_notifier.dart';
import '../application/profile_notifier.dart';
import 'account_actions_section.dart';
import 'transaction_presentation.dart';

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(profileNotifierProvider);
    final deletion = ref.watch(accountDeletionNotifierProvider);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.profile)),
      body: async.when(
        loading: () => const LoadingView(),
        error: (error, _) => ErrorView(
          error: localizedFriendlyErrorFor(context, error),
          onRetry: () => ref.invalidate(profileNotifierProvider),
        ),
        data: (state) {
          final user = state.user;
          if (user == null) {
            return const _GuestProfile();
          }

          final initial = _initialFor(user.displayName ?? user.email);
          final rewardsEarned = state.transactions
              .where((transaction) => transaction.bonusDelta > 0)
              .fold<int>(0, (sum, transaction) => sum + transaction.bonusDelta);

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: AppColors.surface,
                    backgroundImage:
                        user.photoUrl != null && user.photoUrl!.isNotEmpty
                            ? NetworkImage(user.photoUrl!)
                            : null,
                    child: user.photoUrl == null || user.photoUrl!.isEmpty
                        ? Text(initial)
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user.displayName ?? user.email,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        Text(
                          user.email,
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _ViewerStatus(user: user),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _WalletCell(label: l10n.coins, value: user.coins),
                      _WalletCell(label: l10n.bonus, value: user.bonus),
                      _WalletCell(
                        label: l10n.vip,
                        value: user.isVip ? l10n.yes : l10n.no,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _SnapshotCell(
                      icon: Icons.bookmark,
                      value: '${user.favoriteSeriesIds.length}',
                      label: l10n.saved,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _SnapshotCell(
                      icon: Icons.bolt,
                      value: '$rewardsEarned',
                      label: l10n.earned,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _SnapshotCell(
                      icon: Icons.lock_open,
                      value: '${user.unlockedEpisodeIds.length}',
                      label: l10n.unlocked,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              if (state.transactions.isNotEmpty) ...[
                Text(
                  l10n.recentActivity,
                  style: TextStyle(color: AppColors.textSecondary),
                ),
                const SizedBox(height: 8),
                ...state.transactions.take(10).map(
                      (transaction) => ListTile(
                        dense: true,
                        leading: Icon(
                          _iconFor(transaction.type),
                          color: AppColors.primary,
                        ),
                        title: Text(transaction.friendlyTitle(l10n)),
                        trailing: Text(
                          transaction.walletDeltaLabel(l10n),
                          style: TextStyle(
                            color: transaction.bonusDelta < 0 ||
                                    transaction.coinsDelta < 0
                                ? AppColors.textSecondary
                                : AppColors.success,
                          ),
                        ),
                      ),
                    ),
              ],
              if (kDebugMode) ...[
                const SizedBox(height: 24),
                const _AdDiagnostics(),
              ],
              if (!user.isVip) ...[
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () => context.push('/subscribe'),
                  child: Text(l10n.getVip),
                ),
              ],
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.settings_outlined),
                title: Text(l10n.settings),
                onTap: () => context.push('/settings'),
              ),
              const SizedBox(height: 16),
              AccountActionsSection(
                isDeleting: deletion.isDeleting,
                error: deletion.error,
                onRestorePurchases: () async {
                  await ref
                      .read(subscriptionNotifierProvider.notifier)
                      .restorePurchases();
                  if (!context.mounted) {
                    return;
                  }
                  final result =
                      ref.read(subscriptionNotifierProvider).valueOrNull;
                  final message = result?.message == 'subscription-restored'
                      ? l10n.subscriptionRestored
                      : result?.message == 'no-active-vip-purchase'
                          ? l10n.noActiveVipPurchase
                          : result?.error != null
                              ? localizedFriendlyErrorFor(
                                  context,
                                  result!.error!,
                                ).message
                              : null;
                  if (message != null) {
                    ScaffoldMessenger.of(context)
                        .showSnackBar(SnackBar(content: Text(message)));
                  }
                },
                onDeleteAccount: () async {
                  final deleted = await ref
                      .read(accountDeletionNotifierProvider.notifier)
                      .deleteAccount();
                  if (deleted && context.mounted) {
                    context.go('/onboarding');
                  }
                },
              ),
              const SizedBox(height: 16),
              FilledButton.tonal(
                onPressed: () async => ref.read(firebaseAuthProvider).signOut(),
                child: Text(l10n.signOut),
              ),
            ],
          );
        },
      ),
    );
  }

  static String _initialFor(String value) {
    if (value.isEmpty) {
      return '?';
    }
    return value.substring(0, 1).toUpperCase();
  }

  static IconData _iconFor(TxType type) {
    return switch (type) {
      TxType.adReward => Icons.bolt,
      TxType.dailyCheckIn => Icons.calendar_today,
      TxType.purchase => Icons.shopping_cart,
      TxType.spend => Icons.remove_circle,
      TxType.refund => Icons.undo,
    };
  }
}

class _GuestProfile extends StatelessWidget {
  const _GuestProfile();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const Icon(Icons.person_outline, size: 64),
        const SizedBox(height: 16),
        Text(
          l10n.guestMode,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 8),
        Text(l10n.guestMessage, textAlign: TextAlign.center),
        const SizedBox(height: 20),
        FilledButton(
          onPressed: () => context.push('/login'),
          child: Text(l10n.signIn),
        ),
        const SizedBox(height: 8),
        OutlinedButton(
          onPressed: () => context.push('/login'),
          child: Text(l10n.createAccount),
        ),
        const SizedBox(height: 24),
        ListTile(
          leading: const Icon(Icons.settings_outlined),
          title: Text(l10n.settings),
          onTap: () => context.push('/settings'),
        ),
      ],
    );
  }
}

class _ViewerStatus extends StatelessWidget {
  const _ViewerStatus({required this.user});

  final AppUser user;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: user.isVip
            ? AppColors.vipGold.withValues(alpha: 0.12)
            : AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: user.isVip ? AppColors.vipGold : AppColors.divider,
        ),
      ),
      child: Row(
        children: [
          Icon(
            user.isVip ? Icons.workspace_premium : Icons.play_circle_outline,
            color: user.isVip ? AppColors.vipGold : AppColors.primaryLight,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(user.isVip ? l10n.vipViewer : l10n.freeViewer),
                Text(
                  user.isVip ? l10n.vipEpisodeOpen : l10n.bonusSelectedEpisodes,
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SnapshotCell extends StatelessWidget {
  const _SnapshotCell({
    required this.icon,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Icon(icon, size: 20, color: AppColors.primaryLight),
          const SizedBox(height: 6),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w700)),
          Text(label, style: const TextStyle(color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}

class _AdDiagnostics extends ConsumerWidget {
  const _AdDiagnostics();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final gateway = ref.watch(adGatewayProvider);
    final status =
        ref.watch(adStatusProvider).valueOrNull ?? gateway.currentStatus;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.adDiagnostics),
            const SizedBox(height: 6),
            Text(
              '${status.phase.name}${status.isTestAd ? ' · ${l10n.testMode}' : ''}',
              style: const TextStyle(color: AppColors.textSecondary),
            ),
            if (status.message != null) ...[
              const SizedBox(height: 4),
              Text(status.message!),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                OutlinedButton.icon(
                  onPressed: () => gateway.preloadRewarded(),
                  icon: const Icon(Icons.refresh),
                  label: Text(l10n.retry),
                ),
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  onPressed: () => gateway.openAdInspector(),
                  icon: const Icon(Icons.troubleshoot),
                  label: Text(l10n.inspector),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _WalletCell extends StatelessWidget {
  const _WalletCell({
    required this.label,
    required this.value,
  });

  final String label;
  final Object value;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          '$value',
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
        ),
        Text(label, style: const TextStyle(color: AppColors.textSecondary)),
      ],
    );
  }
}
