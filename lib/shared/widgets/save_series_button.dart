import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../../core/theme/app_colors.dart';
import '../../domain/entities/user.dart';
import '../../domain/entities/series.dart';
import '../../features/my_list/application/my_list_notifier.dart';
import '../../l10n/app_localizations.dart';

Future<void> toggleSeriesSaved({
  required BuildContext context,
  required WidgetRef ref,
  required String seriesId,
  Series? series,
  required AppUser? user,
  required bool isSaved,
}) async {
  if (user == null) {
    if (series == null) return;
    final favorites = ref.read(guestFavoritesRepositoryProvider);
    if (isSaved) {
      await favorites.remove(seriesId);
    } else {
      await favorites.save(series);
    }
    ref.invalidate(guestFavoriteSavedProvider(seriesId));
    ref.invalidate(myListNotifierProvider);
    return;
  }

  if (isSaved) {
    await ref
        .read(socialActionsGatewayProvider)
        .setSeriesSaved(seriesId: seriesId, saved: false);
  } else {
    await ref
        .read(socialActionsGatewayProvider)
        .setSeriesSaved(seriesId: seriesId, saved: true);
  }
}

/// Full-width save button for series detail.
class SaveSeriesFilledButton extends ConsumerWidget {
  const SaveSeriesFilledButton(
      {super.key, required this.seriesId, this.series});

  final String seriesId;
  final Series? series;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentAppUserDocProvider).value;
    final guestSaved =
        ref.watch(guestFavoriteSavedProvider(seriesId)).value ?? false;
    final isSaved = user?.favoriteSeriesIds.contains(seriesId) ?? guestSaved;
    final l10n = AppLocalizations.of(context)!;

    return FilledButton.icon(
      onPressed: () => toggleSeriesSaved(
        context: context,
        ref: ref,
        seriesId: seriesId,
        series: series,
        user: user,
        isSaved: isSaved,
      ),
      icon: Icon(isSaved ? Icons.bookmark : Icons.bookmark_outline),
      label: Text(isSaved ? l10n.saved : l10n.save),
    );
  }
}

/// Circular glass save control for Shorts info panel.
class SaveSeriesCircleButton extends ConsumerWidget {
  const SaveSeriesCircleButton({
    super.key,
    required this.seriesId,
    this.series,
    this.countLabel = 'SAVE',
  });

  final String seriesId;
  final Series? series;
  final String countLabel;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentAppUserDocProvider).value;
    final guestSaved =
        ref.watch(guestFavoriteSavedProvider(seriesId)).value ?? false;
    final isSaved = user?.favoriteSeriesIds.contains(seriesId) ?? guestSaved;

    return _GlassActionButton(
      icon: isSaved ? Icons.bookmark : Icons.bookmark_border,
      label: countLabel,
      onPressed: () => toggleSeriesSaved(
        context: context,
        ref: ref,
        seriesId: seriesId,
        series: series,
        user: user,
        isSaved: isSaved,
      ),
    );
  }
}

/// Circular glass action button (Save / Details style).
class GlassActionButton extends StatelessWidget {
  const GlassActionButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return _GlassActionButton(icon: icon, label: label, onPressed: onPressed);
  }
}

class _GlassActionButton extends StatelessWidget {
  const _GlassActionButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(24),
        splashColor: Colors.white12,
        highlightColor: Colors.white10,
        child: SizedBox(
          width: 64,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 48,
                height: 44,
                child: Icon(icon, color: Colors.white, size: 31),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
