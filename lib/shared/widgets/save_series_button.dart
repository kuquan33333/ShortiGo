import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/error/friendly_error.dart';
import '../../core/providers.dart';
import '../../data/local/local_library_repository.dart';
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
    final library = ref.read(localLibraryRepositoryProvider);
    final scope = LocalLibraryRepository.scopeFor(null);
    if (isSaved) {
      await favorites.remove(seriesId);
      await library.removeSeries(scope, seriesId);
    } else {
      await favorites.save(series);
      await library.saveSeries(scope, series);
    }
    ref.invalidate(guestFavoriteSavedProvider(seriesId));
    ref.invalidate(myListNotifierProvider);
    return;
  }

  if (isSaved) {
    await ref
        .read(socialActionsGatewayProvider)
        .setSeriesSaved(seriesId: seriesId, saved: false);
    await ref
        .read(localLibraryRepositoryProvider)
        .removeSeries(LocalLibraryRepository.scopeFor(user.id), seriesId);
  } else {
    await ref
        .read(socialActionsGatewayProvider)
        .setSeriesSaved(seriesId: seriesId, saved: true);
    if (series != null) {
      await ref
          .read(localLibraryRepositoryProvider)
          .saveSeries(LocalLibraryRepository.scopeFor(user.id), series);
    }
  }
  ref.invalidate(myListNotifierProvider);
}

/// Full-width save button for series detail.
class SaveSeriesFilledButton extends ConsumerStatefulWidget {
  const SaveSeriesFilledButton(
      {super.key, required this.seriesId, this.series});

  final String seriesId;
  final Series? series;

  @override
  ConsumerState<SaveSeriesFilledButton> createState() =>
      _SaveSeriesFilledButtonState();
}

class _SaveSeriesFilledButtonState
    extends ConsumerState<SaveSeriesFilledButton> {
  bool? _optimisticSaved;

  @override
  void didUpdateWidget(covariant SaveSeriesFilledButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.seriesId != widget.seriesId) _optimisticSaved = null;
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentAppUserDocProvider).value;
    final guestSaved = ref.watch(guestFavoriteSavedProvider(widget.seriesId));
    final remoteSaved = user?.favoriteSeriesIds.contains(widget.seriesId) ??
        (guestSaved.value ?? false);
    final isSaved = _optimisticSaved ?? remoteSaved;
    final l10n = AppLocalizations.of(context)!;

    return FilledButton.icon(
      onPressed: () => _toggle(context, user, isSaved),
      icon: Icon(isSaved ? Icons.bookmark : Icons.bookmark_outline),
      label: Text(isSaved ? l10n.saved : l10n.save),
    );
  }

  Future<void> _toggle(
      BuildContext context, AppUser? user, bool isSaved) async {
    final next = !isSaved;
    setState(() => _optimisticSaved = next);
    try {
      await toggleSeriesSaved(
        context: context,
        ref: ref,
        seriesId: widget.seriesId,
        series: widget.series,
        user: user,
        isSaved: isSaved,
      );
      if (mounted) setState(() => _optimisticSaved = null);
    } catch (error) {
      if (!mounted) return;
      setState(() => _optimisticSaved = isSaved);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(localizedFriendlyErrorFor(context, error).message)),
      );
    }
  }
}

/// Circular glass save control for Shorts info panel.
class SaveSeriesCircleButton extends ConsumerStatefulWidget {
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
  ConsumerState<SaveSeriesCircleButton> createState() =>
      _SaveSeriesCircleButtonState();
}

class _SaveSeriesCircleButtonState
    extends ConsumerState<SaveSeriesCircleButton> {
  bool? _optimisticSaved;

  @override
  void didUpdateWidget(covariant SaveSeriesCircleButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.seriesId != widget.seriesId) _optimisticSaved = null;
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentAppUserDocProvider).value;
    final guestSaved = ref.watch(guestFavoriteSavedProvider(widget.seriesId));
    final remoteSaved = user?.favoriteSeriesIds.contains(widget.seriesId) ??
        (guestSaved.value ?? false);
    final isSaved = _optimisticSaved ?? remoteSaved;

    return _GlassActionButton(
      icon: isSaved ? Icons.bookmark : Icons.bookmark_border,
      label: widget.countLabel,
      onPressed: () => _toggle(context, user, isSaved),
    );
  }

  Future<void> _toggle(
      BuildContext context, AppUser? user, bool isSaved) async {
    final next = !isSaved;
    setState(() => _optimisticSaved = next);
    try {
      await toggleSeriesSaved(
        context: context,
        ref: ref,
        seriesId: widget.seriesId,
        series: widget.series,
        user: user,
        isSaved: isSaved,
      );
      if (mounted) setState(() => _optimisticSaved = null);
    } catch (error) {
      if (!mounted) return;
      setState(() => _optimisticSaved = isSaved);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(localizedFriendlyErrorFor(context, error).message)),
      );
    }
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
