import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/error/friendly_error.dart';
import '../../core/providers.dart';
import '../../core/theme/app_colors.dart';
import '../../domain/entities/episode.dart';
import '../../domain/entities/series.dart';
import '../../domain/entities/user.dart';
import '../../features/my_list/application/my_list_notifier.dart';
import '../../l10n/app_localizations.dart';
import 'app_pressable.dart';
import 'save_series_button.dart';

/// Shared optimistic save action used by the full player and Shorts.
class PlayerSaveAction extends ConsumerStatefulWidget {
  const PlayerSaveAction({
    super.key,
    required this.series,
    this.label,
  });

  final Series series;
  final String? label;

  @override
  ConsumerState<PlayerSaveAction> createState() => _PlayerSaveActionState();
}

class _PlayerSaveActionState extends ConsumerState<PlayerSaveAction> {
  bool? _optimisticSaved;

  @override
  void didUpdateWidget(covariant PlayerSaveAction oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.series.id != widget.series.id) {
      _optimisticSaved = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentAppUserDocProvider).value;
    final guestSaved = ref.watch(guestFavoriteSavedProvider(widget.series.id));
    final remoteSaved = user != null
        ? user.favoriteSeriesIds.contains(widget.series.id)
        : guestSaved.value ?? false;
    final saved = _optimisticSaved ?? remoteSaved;
    final l10n = AppLocalizations.of(context)!;

    return _PlayerActionButton(
      icon: saved ? Icons.bookmark : Icons.bookmark_border,
      color: saved ? AppColors.primary : Colors.white,
      label: widget.label ?? l10n.save,
      onTap: () => _toggle(context, user, saved),
    );
  }

  Future<void> _toggle(
    BuildContext context,
    AppUser? user,
    bool saved,
  ) async {
    final next = !saved;
    setState(() => _optimisticSaved = next);
    try {
      await toggleSeriesSaved(
        context: context,
        ref: ref,
        seriesId: widget.series.id,
        series: widget.series,
        user: user,
        isSaved: saved,
      );
      ref.invalidate(myListNotifierProvider);
      if (mounted) setState(() => _optimisticSaved = null);
    } catch (error) {
      if (!mounted) return;
      setState(() => _optimisticSaved = saved);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(localizedFriendlyErrorFor(context, error).message)),
      );
    }
  }
}

/// Shared optimistic like action used by the full player and Shorts.
class PlayerLikeAction extends ConsumerStatefulWidget {
  const PlayerLikeAction({super.key, required this.episode});

  final Episode episode;

  @override
  ConsumerState<PlayerLikeAction> createState() => _PlayerLikeActionState();
}

class _PlayerLikeActionState extends ConsumerState<PlayerLikeAction> {
  bool? _optimisticLiked;

  @override
  void didUpdateWidget(covariant PlayerLikeAction oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.episode.id != widget.episode.id) {
      _optimisticLiked = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentAppUserDocProvider).value;
    final liked = _optimisticLiked ??
        (user?.likedEpisodeIds.contains(widget.episode.id) ?? false);
    final l10n = AppLocalizations.of(context)!;
    return _PlayerActionButton(
      icon: liked ? Icons.favorite : Icons.favorite_border,
      color: liked ? AppColors.primary : Colors.white,
      label: l10n.like,
      onTap: () => _toggle(context, user, liked),
    );
  }

  Future<void> _toggle(
    BuildContext context,
    AppUser? user,
    bool liked,
  ) async {
    if (user == null) {
      unawaited(context.push('/login'));
      return;
    }
    final next = !liked;
    setState(() => _optimisticLiked = next);
    try {
      await ref.read(socialActionsGatewayProvider).setEpisodeLiked(
            episodeId: widget.episode.id,
            liked: next,
          );
      ref.invalidate(currentAppUserDocProvider);
      if (mounted) setState(() => _optimisticLiked = null);
    } catch (error) {
      if (!mounted) return;
      setState(() => _optimisticLiked = liked);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(localizedFriendlyErrorFor(context, error).message)),
      );
    }
  }
}

class _PlayerActionButton extends StatelessWidget {
  const _PlayerActionButton({
    required this.icon,
    required this.color,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AppPressable(
      onTap: onTap,
      semanticsLabel: label,
      child: SizedBox(
        width: 64,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: color,
              size: 31,
              shadows: const [Shadow(color: Colors.black87, blurRadius: 8)],
            ),
            const SizedBox(height: 3),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                shadows: [Shadow(color: Colors.black87, blurRadius: 6)],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
