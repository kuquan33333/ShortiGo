import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/error/friendly_error.dart';
import '../../../core/providers.dart';
import '../../../l10n/app_localizations.dart';
import '../../../domain/entities/episode.dart';
import '../../../domain/entities/series.dart';
import '../../../domain/entities/user.dart';
import '../../../shared/format/compact_count.dart';
import '../../my_list/application/my_list_notifier.dart';
import '../application/shorts_share_link.dart';

class ShortsActionRail extends ConsumerStatefulWidget {
  const ShortsActionRail({
    super.key,
    required this.series,
    required this.episode,
  });

  final Series series;
  final Episode episode;

  @override
  ConsumerState<ShortsActionRail> createState() => _ShortsActionRailState();
}

class _ShortsActionRailState extends ConsumerState<ShortsActionRail> {
  late int _likeCount;
  late int _saveCount;
  late int _shareCount;
  late int _followerCount;
  bool? _liked;
  bool? _saved;
  bool? _followed;

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
      _liked = null;
      _saved = null;
      _followed = null;
      _resetCounts();
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentAppUserDocProvider).value;
    final liked =
        _liked ?? (user?.likedEpisodeIds.contains(widget.episode.id) ?? false);
    final saved =
        _saved ?? (user?.favoriteSeriesIds.contains(widget.series.id) ?? false);
    final followed = _followed ??
        (user?.followedSeriesIds.contains(widget.series.id) ?? false);

    return SafeArea(
      minimum: const EdgeInsets.only(right: 8, bottom: 28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _FollowAvatar(
            imageUrl: widget.series.coverUrl,
            followed: followed,
            countLabel: compactCount(_followerCount),
            onTap: () => _toggleFollow(user, followed),
          ),
          const SizedBox(height: 12),
          _RailButton(
            icon: liked ? Icons.favorite : Icons.favorite_border,
            iconColor: liked ? const Color(0xFFFF2D55) : Colors.white,
            label: compactCount(_likeCount),
            onTap: () => _toggleLike(user, liked),
          ),
          const SizedBox(height: 11),
          _RailButton(
            icon: Icons.chat_bubble_outline,
            label: AppLocalizations.of(context)!.info,
            onTap: () => context.push('/series/${widget.series.id}'),
          ),
          const SizedBox(height: 11),
          _RailButton(
            icon: saved ? Icons.bookmark : Icons.bookmark_border,
            label: compactCount(_saveCount),
            onTap: () => _toggleSave(user, saved),
          ),
          const SizedBox(height: 11),
          _RailButton(
            icon: Icons.share,
            label: compactCount(_shareCount),
            onTap: _recordShare,
          ),
        ],
      ),
    );
  }

  void _resetCounts() {
    _likeCount = widget.episode.likeCount;
    _saveCount = widget.series.saveCount;
    _shareCount = widget.episode.shareCount;
    _followerCount = widget.series.followerCount;
  }

  Future<void> _toggleLike(AppUser? user, bool liked) async {
    if (!_requireUser(user)) return;
    final next = !liked;
    setState(() {
      _liked = next;
      _likeCount = (_likeCount + (next ? 1 : -1)).clamp(0, 1 << 31);
    });
    try {
      await ref.read(socialActionsGatewayProvider).setEpisodeLiked(
            episodeId: widget.episode.id,
            liked: next,
          );
    } catch (error) {
      _showError(error);
    }
  }

  Future<void> _toggleSave(AppUser? user, bool saved) async {
    final next = !saved;
    setState(() {
      _saved = next;
      _saveCount = (_saveCount + (next ? 1 : -1)).clamp(0, 1 << 31);
    });
    if (user == null) {
      final favorites = ref.read(guestFavoritesRepositoryProvider);
      if (next) {
        await favorites.save(widget.series);
      } else {
        await favorites.remove(widget.series.id);
      }
      ref.invalidate(guestFavoriteSavedProvider(widget.series.id));
      ref.invalidate(myListNotifierProvider);
      return;
    }
    try {
      await ref.read(socialActionsGatewayProvider).setSeriesSaved(
            seriesId: widget.series.id,
            saved: next,
          );
    } catch (error) {
      _showError(error);
    }
  }

  Future<void> _toggleFollow(AppUser? user, bool followed) async {
    if (!_requireUser(user)) return;
    final next = !followed;
    setState(() {
      _followed = next;
      _followerCount = (_followerCount + (next ? 1 : -1)).clamp(0, 1 << 31);
    });
    try {
      await ref.read(socialActionsGatewayProvider).setSeriesFollowed(
            seriesId: widget.series.id,
            followed: next,
          );
    } catch (error) {
      _showError(error);
    }
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

  bool _requireUser(AppUser? user) {
    if (user != null) return true;
    unawaited(context.push('/login'));
    return false;
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

class _FollowAvatar extends StatelessWidget {
  const _FollowAvatar({
    required this.imageUrl,
    required this.followed,
    required this.countLabel,
    required this.onTap,
  });

  final String imageUrl;
  final bool followed;
  final String countLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 48,
        child: Column(
          children: [
            Stack(
              alignment: Alignment.bottomCenter,
              clipBehavior: Clip.none,
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: Colors.white24,
                  backgroundImage:
                      imageUrl.isEmpty ? null : NetworkImage(imageUrl),
                  child: imageUrl.isEmpty
                      ? const Icon(Icons.person, color: Colors.white)
                      : null,
                ),
                Positioned(
                  bottom: -9,
                  child: Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: followed
                          ? const Color(0xFF23D18B)
                          : const Color(0xFFFF2D55),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: Icon(
                      followed ? Icons.check : Icons.add,
                      color: Colors.white,
                      size: 13,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            _RailLabel(countLabel),
          ],
        ),
      ),
    );
  }
}

class _RailButton extends StatelessWidget {
  const _RailButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.iconColor = Colors.white,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color iconColor;

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
              color: iconColor,
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
