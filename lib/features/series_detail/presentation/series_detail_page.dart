import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/error/friendly_error.dart';
import '../../../core/providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../domain/entities/category.dart';
import '../../../shared/widgets/error_view.dart';
import '../../../shared/widgets/loading_view.dart';
import '../../../shared/widgets/save_series_button.dart';
import '../../../l10n/app_localizations.dart';
import '../../episode_player/application/episode_access.dart';
import '../application/series_detail_notifier.dart';

class SeriesDetailPage extends ConsumerWidget {
  const SeriesDetailPage({super.key, required this.seriesId});

  final String seriesId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(seriesDetailNotifierProvider(seriesId));
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      body: async.when(
        loading: () => const LoadingView(),
        error: (error, _) => ErrorView(
          error: localizedFriendlyErrorFor(context, error),
          onRetry: () => ref.invalidate(seriesDetailNotifierProvider(seriesId)),
        ),
        data: (state) {
          final series = state.series;
          final user = ref.watch(currentAppUserDocProvider).value;
          if (series == null) {
            return Center(child: Text(l10n.seriesNotFound));
          }

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(seriesDetailNotifierProvider(seriesId));
              await ref.read(seriesDetailNotifierProvider(seriesId).future);
            },
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverAppBar(
                  expandedHeight: 320,
                  pinned: true,
                  backgroundColor: AppColors.bg,
                  flexibleSpace: FlexibleSpaceBar(
                    background: Stack(
                      fit: StackFit.expand,
                      children: [
                        CachedNetworkImage(
                          imageUrl: series.coverUrl,
                          fit: BoxFit.cover,
                        ),
                        const DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [Colors.transparent, AppColors.bg],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          series.title,
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${l10n.episodeCount(series.episodeCount)} - '
                          '${_categoryLabel(l10n, series.category)}',
                          style:
                              const TextStyle(color: AppColors.textSecondary),
                        ),
                        const SizedBox(height: 8),
                        Text(series.description),
                        const SizedBox(height: 16),
                        SaveSeriesFilledButton(
                            seriesId: series.id, series: series),
                      ],
                    ),
                  ),
                ),
                SliverList.builder(
                  itemCount: state.episodes.length,
                  itemBuilder: (_, index) {
                    final episode = state.episodes[index];

                    return ListTile(
                      leading: SizedBox(
                        width: 64,
                        height: 64,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: CachedNetworkImage(
                            imageUrl: episode.thumbnailUrl,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      title: Text('EP.${episode.order}'),
                      subtitle: episode.durationSec > 0
                          ? Text(l10n.durationSeconds(episode.durationSec))
                          : null,
                      trailing: switch (accessFor(episode, user)) {
                        EpisodeAccessState.vipRequired =>
                          const Icon(Icons.lock, color: AppColors.vipGold),
                        EpisodeAccessState.bonusRequired => Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.bolt,
                                size: 18,
                                color: AppColors.vipGold,
                              ),
                              Text(
                                '${episode.bonusUnlockCost}',
                                style:
                                    const TextStyle(color: AppColors.vipGold),
                              ),
                            ],
                          ),
                        EpisodeAccessState.open =>
                          const Icon(Icons.play_circle_outline),
                      },
                      onTap: () {
                        if (accessFor(episode, user) ==
                            EpisodeAccessState.vipRequired) {
                          context.push('/subscribe');
                          return;
                        }
                        context.push('/player/$seriesId/${episode.id}');
                      },
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

String _categoryLabel(AppLocalizations l10n, Category category) {
  return switch (category) {
    Category.forYou => l10n.forYou,
    Category.newReleases => l10n.newUpdates,
    Category.hot => l10n.hot,
    Category.adventure => l10n.adventure,
    Category.scary => l10n.scary,
    Category.anime => l10n.anime,
    Category.vip => l10n.vip,
  };
}
