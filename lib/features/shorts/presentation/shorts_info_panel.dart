import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../domain/entities/episode.dart';
import '../../../domain/entities/series.dart';
import '../../../l10n/app_localizations.dart';

/// Frosted series info panel shown above the bottom nav on the Shorts tab.
class ShortsInfoPanel extends ConsumerWidget {
  const ShortsInfoPanel({
    super.key,
    required this.series,
    required this.episode,
    this.onTitle,
    this.onWatchAll,
    this.onCollapse,
  });

  final Series series;
  final Episode episode;
  final VoidCallback? onTitle;
  final VoidCallback? onWatchAll;

  /// Invoked when the user swipes the panel to the right to collapse it.
  final VoidCallback? onCollapse;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final description = series.description.trim();

    return GestureDetector(
      behavior: HitTestBehavior.deferToChild,
      onHorizontalDragEnd: (details) {
        final velocity = details.primaryVelocity ?? 0;
        if (velocity > 250) {
          onCollapse?.call();
        }
      },
      child: SafeArea(
        minimum: const EdgeInsets.fromLTRB(16, 0, 82, 34),
        child: Padding(
          padding: const EdgeInsets.only(top: 42),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              InkWell(
                onTap: onTitle,
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        series.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 19,
                          fontWeight: FontWeight.w800,
                          height: 1.18,
                          shadows: [
                            Shadow(color: Colors.black87, blurRadius: 10)
                          ],
                        ),
                      ),
                    ),
                    const Icon(Icons.chevron_right_rounded,
                        color: Colors.white),
                  ],
                ),
              ),
              const SizedBox(height: 5),
              Text(
                'EP.${episode.order}',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  shadows: [Shadow(color: Colors.black87, blurRadius: 8)],
                ),
              ),
              if (description.isNotEmpty) ...[
                const SizedBox(height: 8),
                _DescriptionPreview(
                  description: description,
                  onReadMore: () => _showDescriptionSheet(context, series),
                ),
              ],
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: FilledButton(
                  onPressed: onWatchAll,
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.white.withValues(alpha: .18),
                    foregroundColor: Colors.white,
                  ),
                  child: Text(AppLocalizations.of(context)!.watchAll),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDescriptionSheet(BuildContext context, Series series) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  series.title,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: AppColors.textPrimary,
                      ),
                ),
                const SizedBox(height: 12),
                ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.sizeOf(context).height * 0.5,
                  ),
                  child: SingleChildScrollView(
                    child: Text(
                      series.description,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        height: 1.45,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Circular ripple reveal that grows/collapses from the bottom-right corner,
/// where the [SeriesInfoFab] sits. Combined with a fade for a smooth feel.
class ShortsPanelReveal extends StatelessWidget {
  const ShortsPanelReveal({
    super.key,
    required this.animation,
    required this.child,
  });

  final Animation<double> animation;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final curved = CurvedAnimation(
      parent: animation,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );

    return FadeTransition(
      opacity: curved,
      child: AnimatedBuilder(
        animation: curved,
        builder: (context, child) {
          return ClipPath(
            clipper: _CornerRevealClipper(curved.value),
            child: child,
          );
        },
        child: child,
      ),
    );
  }
}

class _CornerRevealClipper extends CustomClipper<Path> {
  const _CornerRevealClipper(this.fraction);

  final double fraction;

  @override
  Path getClip(Size size) {
    // Origin near the FAB center (bottom-right, accounting for 16/22 insets).
    final center = Offset(size.width - 41, size.height - 47);
    final maxRadius = size.longestSide * 1.25;
    final radius = (maxRadius * fraction).clamp(0.0, maxRadius);
    return Path()..addOval(Rect.fromCircle(center: center, radius: radius));
  }

  @override
  bool shouldReclip(_CornerRevealClipper oldClipper) =>
      oldClipper.fraction != fraction;
}

/// Collapsed representation of [ShortsInfoPanel]; tap or swipe left to expand.
class SeriesInfoFab extends StatelessWidget {
  const SeriesInfoFab({
    super.key,
    required this.onExpand,
  });

  final VoidCallback onExpand;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onHorizontalDragEnd: (details) {
        final velocity = details.primaryVelocity ?? 0;
        if (velocity < -250) {
          onExpand();
        }
      },
      child: Material(
        color: Colors.transparent,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onExpand,
          child: ClipOval(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.08),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.18),
                    width: 0.8,
                  ),
                ),
                child: Icon(
                  Icons.chevron_left,
                  color: Colors.white.withValues(alpha: 0.85),
                  size: 26,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DescriptionPreview extends StatelessWidget {
  const _DescriptionPreview({
    required this.description,
    required this.onReadMore,
  });

  final String description;
  final VoidCallback onReadMore;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Text(
            description,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 13,
              height: 1.35,
            ),
          ),
        ),
        const SizedBox(width: 8),
        TextButton(
          onPressed: onReadMore,
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            backgroundColor: Colors.white.withValues(alpha: 0.12),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: Text(
            AppLocalizations.of(context)?.readMore ?? 'Read more',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}
