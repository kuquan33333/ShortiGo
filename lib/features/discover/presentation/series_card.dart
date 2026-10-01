import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../domain/entities/series.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/format/compact_count.dart';

class SeriesCard extends StatelessWidget {
  const SeriesCard({super.key, required this.series, required this.onTap});

  final Series series;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final badge = series.isNew
        ? l10n.newUpdates
        : series.isDubbed
            ? l10n.dubbed
            : series.popularity > 0
                ? l10n.hot
                : null;
    final genre = series.genres.isNotEmpty
        ? series.genres.first
        : series.tags.isNotEmpty
            ? series.tags.first
            : null;
    final count = series.watchCount > 0 ? series.watchCount : series.popularity;
    return GestureDetector(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(7),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (series.coverUrl.isNotEmpty)
                    CachedNetworkImage(
                      imageUrl: series.coverUrl,
                      fit: BoxFit.cover,
                      placeholder: (_, __) =>
                          const ColoredBox(color: AppColors.surfaceElevated),
                      errorWidget: (_, __, ___) => const ColoredBox(
                          color: AppColors.surfaceElevated,
                          child: Icon(Icons.broken_image_outlined,
                              color: AppColors.textMuted)),
                    )
                  else
                    const ColoredBox(
                        color: AppColors.surfaceElevated,
                        child: Icon(Icons.movie_outlined,
                            color: AppColors.textMuted)),
                  if (badge != null)
                    Positioned(
                      top: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 3),
                        color:
                            series.isNew ? AppColors.primary : AppColors.accent,
                        child: Text(badge,
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.w800)),
                      ),
                    ),
                  if (count > 0)
                    Positioned(
                      bottom: 5,
                      right: 5,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                            color: Colors.black54,
                            borderRadius: BorderRadius.circular(4)),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 4, vertical: 2),
                          child: Row(children: [
                            const Icon(Icons.play_arrow_rounded,
                                color: Colors.white, size: 12),
                            Text(compactCount(count),
                                style: const TextStyle(
                                    color: Colors.white, fontSize: 10))
                          ]),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(series.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  height: 1.12)),
          const SizedBox(height: 2),
          Text(genre ?? l10n.episodeCount(series.episodeCount),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                  color: AppColors.textSecondary, fontSize: 12)),
        ],
      ),
    );
  }
}
