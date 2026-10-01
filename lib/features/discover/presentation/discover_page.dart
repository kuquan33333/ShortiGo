import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/error/friendly_error.dart';
import '../../../core/theme/app_colors.dart';
import '../../../domain/entities/category.dart';
import '../../../domain/entities/series.dart';
import '../../../l10n/app_localizations.dart';
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
                error: (error, _) => ErrorView(
                  error: localizedFriendlyErrorFor(context, error),
                  onRetry: () => ref.invalidate(discoverNotifierProvider),
                ),
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
      return Column(
        children: [
          SizedBox(
            height: 200,
            child: _Categories(
              current: state.currentCategory,
              onSelected: (category) => unawaited(
                ref.read(discoverNotifierProvider.notifier).selectCategory(
                      category,
                    ),
              ),
            ),
          ),
          Expanded(child: _grid(context, state.series)),
        ],
      );
    }
    return _grid(context, state.series);
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
            child: InkWell(
              onTap: onSearch,
              borderRadius: BorderRadius.circular(8),
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
  Widget build(BuildContext context) =>
      IconButton(onPressed: onTap, icon: Icon(icon, color: color, size: 30));
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
              child: InkWell(
                onTap: () => onSelected(index),
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
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(l10n.categories, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 16),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            for (final category in categories)
              OutlinedButton(
                onPressed: () => onSelected(category),
                style: OutlinedButton.styleFrom(
                  foregroundColor: category == current
                      ? Colors.white
                      : AppColors.textSecondary,
                  backgroundColor: category == current
                      ? AppColors.primary
                      : AppColors.surface,
                  side: BorderSide(
                      color: category == current
                          ? AppColors.primary
                          : AppColors.divider),
                ),
                child: Text(_label(l10n, category)),
              ),
          ],
        ),
      ],
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
