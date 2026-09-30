import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/error/friendly_error.dart';
import '../../../shared/widgets/error_view.dart';
import '../../../shared/widgets/loading_view.dart';
import '../../discover/presentation/series_card.dart';
import '../../../l10n/app_localizations.dart';
import '../application/my_list_notifier.dart';

class MyListPage extends ConsumerWidget {
  const MyListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(myListNotifierProvider);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.myList)),
      body: async.when(
        loading: () => const LoadingView(),
        error: (error, _) => ErrorView(
          error: localizedFriendlyErrorFor(context, error),
          onRetry: () => ref.invalidate(myListNotifierProvider),
        ),
        data: (state) {
          if (state.requiresSignIn) {
            return const _SignInMyList();
          }

          if (state.series.isEmpty) {
            return const _EmptyMyList();
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
            itemBuilder: (_, index) {
              final series = state.series[index];
              return SeriesCard(
                series: series,
                onTap: () => context.push('/series/${series.id}'),
              );
            },
          );
        },
      ),
    );
  }
}

class _SignInMyList extends StatelessWidget {
  const _SignInMyList();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.bookmark_add_outlined, size: 44),
            const SizedBox(height: 12),
            Text(
              l10n.signInToUse,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              l10n.saveSeriesHint,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => context.push('/login'),
              child: Text(l10n.signIn),
            ),
          ],
        ),
      ),
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
