import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/error/friendly_error.dart';
import '../../../core/providers.dart';
import '../../../l10n/app_localizations.dart';
import '../../../domain/entities/episode.dart';
import '../../../domain/entities/series.dart';
import '../../../shared/widgets/player_actions.dart';
import '../application/shorts_share_link.dart';

class ShortsActionRail extends ConsumerStatefulWidget {
  const ShortsActionRail({
    super.key,
    required this.series,
    required this.episode,
    this.onChooseEpisode,
  });

  final Series series;
  final Episode episode;
  final VoidCallback? onChooseEpisode;

  @override
  ConsumerState<ShortsActionRail> createState() => _ShortsActionRailState();
}

class _ShortsActionRailState extends ConsumerState<ShortsActionRail> {
  late int _shareCount;

  @override
  void initState() {
    super.initState();
    _resetCounts();
  }

  @override
  void didUpdateWidget(covariant ShortsActionRail oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.episode.id != widget.episode.id ||
        oldWidget.series.id != widget.series.id) {
      _resetCounts();
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      minimum: const EdgeInsets.only(right: 8, bottom: 28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          PlayerSaveAction(
            series: widget.series,
            label: AppLocalizations.of(context)!.save,
          ),
          const SizedBox(height: 14),
          PlayerLikeAction(episode: widget.episode),
          const SizedBox(height: 14),
          _RailButton(
            icon: Icons.playlist_play_rounded,
            label: AppLocalizations.of(context)!.chooseEpisode,
            onTap: widget.onChooseEpisode,
          ),
          const SizedBox(height: 14),
          _RailButton(
            icon: Icons.share,
            label: AppLocalizations.of(context)!.share,
            onTap: _recordShare,
          ),
        ],
      ),
    );
  }

  void _resetCounts() {
    _shareCount = widget.episode.shareCount;
  }

  Future<void> _recordShare() async {
    setState(() => _shareCount += 1);
    try {
      final box = context.findRenderObject() as RenderBox?;
      await SharePlus.instance.share(
        ShareParams(
          text: shortShareText(
            l10n: AppLocalizations.of(context)!,
            seriesTitle: widget.series.title,
            episodeOrder: widget.episode.order,
            seriesId: widget.series.id,
            episodeId: widget.episode.id,
          ),
          subject: AppLocalizations.of(context)!
              .watchOnShortiGo(widget.episode.order, widget.series.title),
          sharePositionOrigin:
              box == null ? null : box.localToGlobal(Offset.zero) & box.size,
        ),
      );
      if (ref.read(currentAppUserDocProvider).value != null) {
        await ref
            .read(socialActionsGatewayProvider)
            .recordEpisodeShare(episodeId: widget.episode.id);
      }
    } catch (error) {
      _showError(error);
    }
  }

  void _showError(Object error) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(localizedFriendlyErrorFor(context, error).message),
      ),
    );
  }
}

class _RailButton extends StatelessWidget {
  const _RailButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 48,
        child: Column(
          children: [
            Icon(
              icon,
              color: Colors.white,
              size: 31,
              shadows: const [
                Shadow(color: Colors.black54, blurRadius: 10),
              ],
            ),
            const SizedBox(height: 4),
            _RailLabel(label),
          ],
        ),
      ),
    );
  }
}

class _RailLabel extends StatelessWidget {
  const _RailLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      textAlign: TextAlign.center,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 11,
        fontWeight: FontWeight.w700,
        shadows: [Shadow(color: Colors.black87, blurRadius: 8)],
      ),
    );
  }
}
