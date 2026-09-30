import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/error/friendly_error.dart';
import '../../../domain/entities/category.dart';
import '../../../shared/widgets/error_view.dart';
import '../../../shared/widgets/loading_view.dart';
import '../../../l10n/app_localizations.dart';
import '../application/discover_notifier.dart';
import '../application/discover_state.dart';
import 'category_tabs.dart';
import 'series_card.dart';
import 'section_title_localizer.dart';

class DiscoverPage extends ConsumerWidget {
  const DiscoverPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(discoverNotifierProvider);

    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.discover),
        actions: [
          IconButton(
            tooltip: l10n.search,
            onPressed: () => context.push('/search'),
            icon: const Icon(Icons.search),
          ),
        ],
      ),
      body: async.when(
        loading: () => const LoadingView(),
        error: (error, _) => ErrorView(
          error: localizedFriendlyErrorFor(context, error),
          onRetry: () => ref.invalidate(discoverNotifierProvider),
        ),
        data: (state) => Column(
          children: [
            const SizedBox(height: 8),
            CategoryTabs(
              current: state.currentCategory,
              onSelect: (category) => ref
                  .read(discoverNotifierProvider.notifier)
                  .selectCategory(category),
            ),
            const SizedBox(height: 12),
            Expanded(child: _content(context, state)),
          ],
        ),
      ),
    );
  }

  Widget _content(BuildContext context, DiscoverState state) {
    if (state.currentCategory == Category.forYou && state.sections.isNotEmpty) {
      return ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          if (state.hero != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: SizedBox(
                height: 210,
                child: SeriesCard(
                  series: state.hero!,
                  onTap: () => context.push('/series/${state.hero!.id}'),
                ),
              ),
            ),
          for (final section in state.sections) _section(context, section),
        ],
      );
    }
    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 9 / 16,
      ),
      itemCount: state.series.length,
      itemBuilder: (_, index) => SeriesCard(
        series: state.series[index],
        onTap: () => context.push('/series/${state.series[index].id}'),
      ),
    );
  }

  Widget _section(BuildContext context, DiscoverSection section) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: Text(
            localizedSectionTitle(l10n, section.slug, section.title),
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
        SizedBox(
          height: 220,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: section.series.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (_, index) {
              final series = section.series[index];
              return SizedBox(
                width: 124,
                child: SeriesCard(
                  series: series,
                  onTap: () => context.push('/series/${series.id}'),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
