import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/error/friendly_error.dart';
import '../../../core/theme/app_colors.dart';
import '../../../domain/entities/episode.dart';
import '../../../domain/entities/series.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/format/compact_count.dart';
import '../../../shared/widgets/episode_picker_grid.dart';
import '../../../shared/widgets/error_view.dart';
import '../../../shared/widgets/loading_view.dart';
import '../../../shared/widgets/save_series_button.dart';
import '../application/series_detail_notifier.dart';

class SeriesDetailPage extends ConsumerWidget {
  const SeriesDetailPage({super.key, required this.seriesId});

  final String seriesId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(seriesDetailNotifierProvider(seriesId));
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.info),
        actions: [
          IconButton(
            tooltip: AppLocalizations.of(context)!.watchAll,
            onPressed: () => context.push('/watch/$seriesId'),
            icon: const Icon(Icons.play_arrow_rounded),
          ),
        ],
      ),
      body: async.when(
        loading: () => const LoadingView(),
        error: (error, _) => ErrorView(
          error: localizedFriendlyErrorFor(context, error),
          onRetry: () => ref.invalidate(seriesDetailNotifierProvider(seriesId)),
        ),
        data: (state) {
          final series = state.series;
          if (series == null) {
            return Center(
                child: Text(AppLocalizations.of(context)!.seriesNotFound));
          }
          return _SeriesDetailContent(series: series, episodes: state.episodes);
        },
      ),
    );
  }
}

class _SeriesDetailContent extends StatelessWidget {
  const _SeriesDetailContent({required this.series, required this.episodes});

  final Series series;
  final List<Episode> episodes;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return DefaultTabController(
      length: 2,
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
              child: _Header(series: series, episodes: episodes)),
          SliverToBoxAdapter(
            child: TabBar(
              labelColor: AppColors.textPrimary,
              unselectedLabelColor: AppColors.textMuted,
              indicatorColor: AppColors.primary,
              tabs: [Tab(text: l10n.intro), Tab(text: l10n.chooseEpisode)],
            ),
          ),
          SliverFillRemaining(
            hasScrollBody: true,
            child: TabBarView(
              children: [
                _IntroTab(series: series),
                SingleChildScrollView(
                  padding: const EdgeInsets.only(top: 14),
                  child: EpisodePickerGrid(
                    episodes: episodes,
                    currentIndex: -1,
                    onSelect: (index) {
                      final episode = episodes[index];
                      if (episode.sourceLocked || !episode.sourceAvailable)
                        return;
                      context.push(
                          '/watch/${series.id}?episodeId=${Uri.encodeComponent(episode.id)}');
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.series, required this.episodes});

  final Series series;
  final List<Episode> episodes;

  @override
  Widget build(BuildContext context) {
    final count = series.watchCount > 0 ? series.watchCount : series.popularity;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 102,
            height: 142,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: series.coverUrl.isEmpty
                  ? const ColoredBox(
                      color: AppColors.surfaceElevated,
                      child: Icon(Icons.movie_outlined, size: 38))
                  : CachedNetworkImage(
                      imageUrl: series.coverUrl,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => const ColoredBox(
                          color: AppColors.surfaceElevated,
                          child: Center(child: Icon(Icons.movie_outlined))),
                      errorWidget: (_, __, ___) => const ColoredBox(
                          color: AppColors.surfaceElevated,
                          child: Icon(Icons.movie_outlined, size: 38)),
                    ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(series.title,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge
                        ?.copyWith(fontWeight: FontWeight.w800)),
                const SizedBox(height: 10),
                Text(AppLocalizations.of(context)!.views(compactCount(count)),
                    style: const TextStyle(color: AppColors.textSecondary)),
                const SizedBox(height: 4),
                Text(
                    AppLocalizations.of(context)!.episodeCount(episodes.length),
                    style: const TextStyle(color: AppColors.textMuted)),
                const SizedBox(height: 14),
                SaveSeriesFilledButton(seriesId: series.id, series: series),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _IntroTab extends StatelessWidget {
  const _IntroTab({required this.series});

  final Series series;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final tags = [...series.genres, ...series.tags].toSet().toList();
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 32),
      children: [
        Text(
            series.description.isEmpty
                ? l10n.noDescription
                : series.description,
            style:
                const TextStyle(color: AppColors.textSecondary, height: 1.45)),
        if (tags.isNotEmpty) ...[
          const SizedBox(height: 18),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final tag in tags)
                Chip(
                    label: Text(tag),
                    backgroundColor: AppColors.surfaceElevated,
                    side: BorderSide.none,
                    labelStyle:
                        const TextStyle(color: AppColors.textSecondary)),
            ],
          ),
        ],
        const SizedBox(height: 24),
        if (series.isDubbed || series.audioType != null)
          Text(series.audioType ?? l10n.dubbed,
              style: const TextStyle(
                  color: AppColors.primaryLight, fontWeight: FontWeight.w700)),
      ],
    );
  }
}
