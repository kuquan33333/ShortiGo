import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/error/friendly_error.dart';
import '../../../core/providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/error_view.dart';
import '../../../shared/widgets/loading_view.dart';
import '../application/episode_player_notifier.dart';
import '../application/episode_access.dart';
import 'episode_player_view.dart';

class EpisodePlayerPage extends ConsumerWidget {
  const EpisodePlayerPage({
    super.key,
    required this.seriesId,
    required this.episodeId,
  });

  final String seriesId;
  final String episodeId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final args = EpisodePlayerArgs(seriesId: seriesId, episodeId: episodeId);
    final async = ref.watch(episodePlayerNotifierProvider(args));

    return Scaffold(
      backgroundColor: Colors.black,
      body: async.when(
        loading: () => const LoadingView(),
        error: (error, _) => ErrorView(
          error: localizedFriendlyErrorFor(context, error),
          onRetry: () => ref.invalidate(episodePlayerNotifierProvider(args)),
        ),
        data: (state) {
          final l10n = AppLocalizations.of(context)!;
          final user = ref.watch(currentAppUserDocProvider).value;
          final effectiveVip =
              ref.watch(effectiveVipProvider).value ?? user?.isVip ?? false;
          final episode = state.episode;
          final access = episode == null
              ? EpisodeAccessState.open
              : accessFor(episode, user, effectiveVip: effectiveVip);
          if (access == EpisodeAccessState.vipRequired) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.lock, size: 64, color: AppColors.vipGold),
                  const SizedBox(height: 16),
                  Text(l10n.vipEpisode, style: TextStyle(color: Colors.white)),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: () => context.push('/subscribe'),
                    child: Text(l10n.getVip),
                  ),
                ],
              ),
            );
          }
          if (access == EpisodeAccessState.bonusRequired) {
            return _BonusUnlock(
              cost: episode!.bonusUnlockCost!,
              balance: user?.bonus ?? 0,
              l10n: l10n,
              onUnlock: () async {
                try {
                  await ref
                      .read(rewardGatewayProvider)
                      .unlockEpisode(episode.id);
                } catch (error) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          localizedFriendlyErrorFor(context, error).message,
                        ),
                      ),
                    );
                  }
                }
              },
            );
          }

          if (access == EpisodeAccessState.sourceLocked ||
              access == EpisodeAccessState.sourceUnavailable) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      access == EpisodeAccessState.sourceLocked
                          ? Icons.lock_outline
                          : Icons.warning_amber_rounded,
                      color: Colors.white,
                      size: 64,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      access == EpisodeAccessState.sourceLocked
                          ? l10n.sourceLocked
                          : l10n.sourceUnavailable,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white),
                    ),
                  ],
                ),
              ),
            );
          }

          return state.controller == null
              ? Center(child: Text(l10n.sourceUnavailable))
              : EpisodePlayerView(controller: state.controller!);
        },
      ),
    );
  }
}

class _BonusUnlock extends StatelessWidget {
  const _BonusUnlock({
    required this.cost,
    required this.balance,
    required this.l10n,
    required this.onUnlock,
  });

  final int cost;
  final int balance;
  final AppLocalizations l10n;
  final Future<void> Function() onUnlock;

  @override
  Widget build(BuildContext context) {
    final canAfford = balance >= cost;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.lock_open,
              size: 64,
              color: AppColors.primaryLight,
            ),
            const SizedBox(height: 16),
            Text(
              l10n.unlockThisEpisode,
              style: TextStyle(color: Colors.white, fontSize: 18),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.bonusBalance(cost, balance),
              style: const TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: canAfford ? onUnlock : () => context.go('/rewards'),
              icon: Icon(canAfford ? Icons.bolt : Icons.card_giftcard),
              label: Text(canAfford ? l10n.unlockThisEpisode : l10n.earnBonus),
            ),
          ],
        ),
      ),
    );
  }
}
