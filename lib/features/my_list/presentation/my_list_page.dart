import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/error/friendly_error.dart';
import '../../../shared/widgets/error_view.dart';
import '../../../shared/widgets/loading_view.dart';
import '../../../shared/widgets/app_pressable.dart';
import '../../discover/presentation/series_card.dart';
import '../../../l10n/app_localizations.dart';
import '../../../core/theme/app_colors.dart';
import '../../../domain/entities/watch_history_entry.dart';
import '../../../domain/entities/series.dart';
import '../application/my_list_notifier.dart';

class MyListPage extends ConsumerWidget {
  const MyListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(myListNotifierProvider);
    final l10n = AppLocalizations.of(context)!;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              TabBar(
                overlayColor: const WidgetStatePropertyAll(Colors.transparent),
                dividerColor: Colors.transparent,
                dividerHeight: 0,
                indicatorColor: AppColors.primary,
                tabs: [
                  Tab(text: l10n.watchHistory),
                  Tab(text: l10n.savedSeries),
                ],
              ),
              Expanded(
                child: async.when(
                  loading: () => const LoadingView(),
                  error: (error, _) => ErrorView(
                    error: localizedFriendlyErrorFor(context, error),
                    onRetry: () => ref.invalidate(myListNotifierProvider),
                  ),
                  data: (state) {
                    return TabBarView(
                      children: [
                        _HistoryList(history: state.history),
                        _SavedGrid(series: state.series),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SavedGrid extends StatelessWidget {
  const _SavedGrid({required this.series});

  final List<Series> series;

  @override
  Widget build(BuildContext context) {
    if (series.isEmpty) return const _EmptyMyList();
    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 9 / 16,
      ),
      itemCount: series.length,
      itemBuilder: (_, index) {
        final item = series[index];
        return SeriesCard(
          series: item,
          onTap: () => context.push('/watch/${item.id}'),
        );
      },
    );
  }
}

class _HistoryList extends StatelessWidget {
  const _HistoryList({required this.history});

  final List<WatchHistoryEntry> history;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (history.isEmpty) {
      return Center(
        child: Text(l10n.noWatchHistory,
            style: const TextStyle(color: AppColors.textSecondary)),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 28),
      itemCount: history.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, index) {
        final entry = history[index];
        final progress = entry.durationMs > 0
            ? (entry.positionMs / entry.durationMs).clamp(0.0, 1.0)
            : 0.0;
        return AppPressable(
          onTap: () => context.push(
            '/watch/${entry.seriesId}?episodeId=${Uri.encodeComponent(entry.episodeId)}&resumeMs=${entry.positionMs}',
          ),
          child: Row(
            children: [
              SizedBox(
                width: 82,
                height: 112,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: entry.series.coverUrl.isEmpty
                      ? const ColoredBox(
                          color: AppColors.surfaceElevated,
                          child: Icon(Icons.movie_outlined),
                        )
                      : CachedNetworkImage(
                          imageUrl: entry.series.coverUrl,
                          fit: BoxFit.cover,
                          errorWidget: (_, __, ___) => const ColoredBox(
                            color: AppColors.surfaceElevated,
                            child: Icon(Icons.broken_image_outlined),
                          ),
                        ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(entry.series.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 16)),
                    const SizedBox(height: 8),
                    Text(l10n.episodeLabel(entry.episodeOrder),
                        style: const TextStyle(color: AppColors.textSecondary)),
                    if (entry.durationMs > 0) ...[
                      const SizedBox(height: 12),
                      LinearProgressIndicator(value: progress),
                    ],
                  ],
                ),
              ),
              const Icon(Icons.play_circle_outline_rounded),
            ],
          ),
        );
      },
    );
  }
}

class _EmptyMyList extends StatelessWidget {
  const _EmptyMyList();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.bookmark_outline, size: 44),
            SizedBox(height: 12),
            Text(
              l10n.noSavedSeries,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(height: 6),
            Text(
              l10n.saveSeriesHint,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
