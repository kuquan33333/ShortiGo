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
          return SeriesDetailContent(series: series, episodes: state.episodes);
        },
      ),
    );
  }
}

Future<int?> showSeriesDetailSheet(
  BuildContext context, {
  required Series series,
  required List<Episode> episodes,
  int initialTab = 0,
  int currentIndex = -1,
}) {
  return showModalBottomSheet<int>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (sheetContext) => SafeArea(
      child: SizedBox(
        height: MediaQuery.sizeOf(sheetContext).height * .82,
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 38,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 4),
            Expanded(
              child: SeriesDetailContent(
                series: series,
                episodes: episodes,
                initialTab: initialTab,
                currentIndex: currentIndex,
                onEpisodeSelected: (index) =>
                    Navigator.of(sheetContext).pop(index),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class SeriesDetailContent extends StatelessWidget {
  const SeriesDetailContent({
    super.key,
    required this.series,
    required this.episodes,
    this.initialTab = 0,
    this.currentIndex = -1,
    this.onEpisodeSelected,
  });

  final Series series;
  final List<Episode> episodes;
  final int initialTab;
  final int currentIndex;
  final ValueChanged<int>? onEpisodeSelected;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return DefaultTabController(
      length: 2,
      initialIndex: initialTab.clamp(0, 1),
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
                    currentIndex: currentIndex,
                    onSelect: (index) {
                      if (onEpisodeSelected != null) {
                        onEpisodeSelected!(index);
                        return;
                      }
                      final episode = episodes[index];
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

class _IntroTab extends StatefulWidget {
  const _IntroTab({required this.series});

  final Series series;

  @override
  State<_IntroTab> createState() => _IntroTabState();
}

class _IntroTabState extends State<_IntroTab> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final series = widget.series;
    final tags = [...series.genres, ...series.tags].toSet().toList();
    final hasMore = series.description.length > 180;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 32),
      children: [
        Text(
          series.description.isEmpty ? l10n.noDescription : series.description,
          maxLines: hasMore && !_expanded ? 4 : null,
          overflow: hasMore && !_expanded
              ? TextOverflow.ellipsis
              : TextOverflow.visible,
          style: const TextStyle(color: AppColors.textSecondary, height: 1.45),
        ),
        if (hasMore)
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              onPressed: () => setState(() => _expanded = !_expanded),
              child: Text(_expanded ? l10n.collapse : l10n.readMore),
            ),
          ),
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
