import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/error/friendly_error.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/remote/content_api_models.dart';
import '../../../domain/entities/category.dart';
import '../../../domain/entities/series.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/format/compact_count.dart';
import '../../../shared/widgets/app_pressable.dart';
import '../../../shared/widgets/content_source_setup_view.dart';
import '../../../shared/widgets/error_view.dart';
import '../../../shared/widgets/loading_view.dart';
import '../application/discover_notifier.dart';
import '../application/discover_state.dart';
import 'series_card.dart';

class DiscoverPage extends ConsumerStatefulWidget {
  const DiscoverPage({super.key});

  @override
  ConsumerState<DiscoverPage> createState() => _DiscoverPageState();
}

class _DiscoverPageState extends ConsumerState<DiscoverPage> {
  @override
  Widget build(BuildContext context) {
    final async = ref.watch(discoverNotifierProvider);
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _HomeHeader(
              onSearch: () => context.push('/search'),
              onVip: () => context.push('/subscribe'),
              onGift: () => context.push('/rewards'),
            ),
            _HomeTabs(
              selected: async.valueOrNull?.selectedTab.index ?? 0,
              labels: [l10n.hotTab, l10n.newTab, l10n.ranking, l10n.categories],
              onSelected: (index) {
                unawaited(
                  ref.read(discoverNotifierProvider.notifier).selectTab(
                        DiscoverHomeTab.values[index],
                      ),
                );
              },
            ),
            Expanded(
              child: async.when(
                loading: () => const LoadingView(),
                error: (error, _) => _errorView(context, error),
                data: (state) => _content(context, state),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _content(BuildContext context, DiscoverState state) {
    if (state.selectedTab == DiscoverHomeTab.categories) {
      return CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: _Categories(
              current: state.currentCategory,
              onSelected: (category) => unawaited(
                ref.read(discoverNotifierProvider.notifier).selectCategory(
                      category,
                    ),
              ),
            ),
          ),
          _gridSliver(context, state.series),
        ],
      );
    }
    if (state.selectedTab == DiscoverHomeTab.ranking) {
      return _rankingList(context, state.series);
    }
    return _grid(context, state.series);
  }

  Widget _errorView(BuildContext context, Object error) {
    if (error is ContentApiException && error.code == 'not-configured') {
      return const ContentSourceSetupView();
    }
    return ErrorView(
      error: localizedFriendlyErrorFor(context, error),
      onRetry: () => ref.invalidate(discoverNotifierProvider),
    );
  }

  Widget _grid(BuildContext context, List<Series> series) {
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 18,
        crossAxisSpacing: 10,
        childAspectRatio: .49,
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

  SliverPadding _gridSliver(BuildContext context, List<Series> series) {
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 28),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          mainAxisSpacing: 18,
          crossAxisSpacing: 10,
          childAspectRatio: .49,
        ),
        delegate: SliverChildBuilderDelegate(
          (_, index) {
            final item = series[index];
            return SeriesCard(
              series: item,
              onTap: () => context.push('/watch/${item.id}'),
            );
          },
          childCount: series.length,
        ),
      ),
    );
  }

  Widget _rankingList(BuildContext context, List<Series> series) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
      itemCount: series.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, index) {
        final item = series[index];
        final count = item.watchCount > 0 ? item.watchCount : item.popularity;
        final rankColor = switch (index) {
          0 => AppColors.vipGold,
          1 => const Color(0xFFD2D6DD),
          2 => const Color(0xFFCD8B61),
          _ => AppColors.textSecondary,
        };
        final genre = item.genres.isNotEmpty
            ? item.genres.first
            : item.tags.isNotEmpty
                ? item.tags.first
                : null;
        return AppPressable(
          onTap: () => context.push('/watch/${item.id}'),
          semanticsLabel: item.title,
          child: SizedBox(
            height: 112,
            child: Row(
              children: [
                SizedBox(
                  width: 40,
                  child: Text(
                    '${index + 1}',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: rankColor,
                      fontSize: index < 3 ? 27 : 20,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                SizedBox(
                  width: 74,
                  height: 112,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(7),
                    child: item.coverUrl.isEmpty
                        ? const ColoredBox(
                            color: AppColors.surfaceElevated,
                            child: Icon(Icons.movie_outlined,
                                color: AppColors.textMuted),
                          )
                        : CachedNetworkImage(
                            imageUrl: item.coverUrl,
                            fit: BoxFit.cover,
                            placeholder: (_, __) => const ColoredBox(
                              color: AppColors.surfaceElevated,
                            ),
                            errorWidget: (_, __, ___) => const ColoredBox(
                              color: AppColors.surfaceElevated,
                              child: Icon(Icons.broken_image_outlined,
                                  color: AppColors.textMuted),
                            ),
                          ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        item.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          height: 1.15,
                        ),
                      ),
                      if (genre != null) ...[
                        const SizedBox(height: 6),
                        Text(genre,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                color: AppColors.textSecondary, fontSize: 13)),
                      ],
                      if (count > 0) ...[
                        const SizedBox(height: 6),
                        Text(compactCount(count),
                            style: const TextStyle(
                                color: AppColors.textMuted, fontSize: 12)),
                      ],
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded,
                    color: AppColors.textMuted),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _HomeHeader extends StatelessWidget {
  const _HomeHeader(
      {required this.onSearch, required this.onVip, required this.onGift});

  final VoidCallback onSearch;
  final VoidCallback onVip;
  final VoidCallback onGift;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 12, 8),
      child: Row(
        children: [
          Expanded(
            child: AppPressable(
              onTap: onSearch,
              semanticsLabel: l10n.search,
              child: Container(
                height: 42,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                    color: AppColors.surfaceElevated,
                    borderRadius: BorderRadius.circular(8)),
                child: Row(children: [
                  const Icon(Icons.search_rounded,
                      color: AppColors.textSecondary, size: 22),
                  const SizedBox(width: 8),
                  Text(l10n.searchHint,
                      style: const TextStyle(color: AppColors.textSecondary))
                ]),
              ),
            ),
          ),
          const SizedBox(width: 8),
          _Shortcut(
              icon: Icons.workspace_premium_rounded,
              color: AppColors.vipGold,
              onTap: onVip),
          _Shortcut(
              icon: Icons.card_giftcard_rounded,
              color: AppColors.primaryLight,
              onTap: onGift),
        ],
      ),
    );
  }
}

class _Shortcut extends StatelessWidget {
  const _Shortcut(
      {required this.icon, required this.color, required this.onTap});

  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => AppPressable(
        onTap: onTap,
        semanticsLabel: icon == Icons.workspace_premium_rounded
            ? AppLocalizations.of(context)!.vip
            : AppLocalizations.of(context)!.rewards,
        child: SizedBox(
          width: 44,
          height: 44,
          child: Icon(icon, color: color, size: 30),
        ),
      );
}

class _HomeTabs extends StatelessWidget {
  const _HomeTabs(
      {required this.selected, required this.labels, required this.onSelected});

  final int selected;
  final List<String> labels;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 46,
      child: Row(
        children: [
          for (var index = 0; index < labels.length; index++)
            Expanded(
              child: AppPressable(
                onTap: () => onSelected(index),
                semanticsLabel: labels[index],
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(labels[index],
                        style: TextStyle(
                            color: index == selected
                                ? Colors.white
                                : AppColors.textSecondary,
                            fontWeight: index == selected
                                ? FontWeight.w800
                                : FontWeight.w600,
                            fontSize: 15)),
                    const SizedBox(height: 7),
                    AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        width: index == selected ? 40 : 0,
                        height: 2,
                        color: AppColors.primary),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _Categories extends StatelessWidget {
  const _Categories({required this.current, required this.onSelected});

  final Category current;
  final ValueChanged<Category> onSelected;

  static const categories = [
    Category.recommended,
    Category.newReleases,
    Category.hot,
    Category.romance,
    Category.ceo,
    Category.revenge,
    Category.family,
    Category.action,
    Category.fantasy,
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.categories, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final category in categories)
                AppPressable(
                  onTap: () => onSelected(category),
                  semanticsLabel: _label(l10n, category),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: category == current
                          ? AppColors.primary.withValues(alpha: .18)
                          : AppColors.surface,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: category == current
                            ? AppColors.primary
                            : AppColors.divider,
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 13, vertical: 8),
                      child: Text(
                        _label(l10n, category),
                        style: TextStyle(
                          color: category == current
                              ? Colors.white
                              : AppColors.textSecondary,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  String _label(AppLocalizations l10n, Category category) => switch (category) {
        Category.recommended => l10n.recommended,
        Category.newReleases => l10n.newUpdates,
        Category.hot => l10n.hot,
        Category.romance => l10n.romance,
        Category.ceo => l10n.ceo,
        Category.revenge => l10n.revenge,
        Category.family => l10n.family,
        Category.action => l10n.action,
        Category.fantasy => l10n.fantasy,
        _ => l10n.discover,
      };
}
