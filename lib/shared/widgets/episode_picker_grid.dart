import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../domain/entities/episode.dart';

/// Compact episode grid shared by the detail surface and player sheet.
class EpisodePickerGrid extends StatelessWidget {
  const EpisodePickerGrid({
    super.key,
    required this.episodes,
    required this.currentIndex,
    required this.onSelect,
  });

  final List<Episode> episodes;
  final int currentIndex;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    if (episodes.isEmpty) return const SizedBox.shrink();
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 6,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 1.08,
      ),
      itemCount: episodes.length,
      itemBuilder: (context, index) {
        final episode = episodes[index];
        final current = index == currentIndex;
        final locked = episode.sourceLocked || episode.isVipLocked;
        final unavailable = !episode.sourceAvailable && !locked;
        return Semantics(
          button: true,
          label: 'Episode ${episode.order}',
          child: InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: () => onSelect(index),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: current ? AppColors.primary : AppColors.surfaceElevated,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: current ? AppColors.primaryLight : Colors.transparent,
                  width: 1.2,
                ),
              ),
              child: Stack(
                children: [
                  Center(
                    child: Text(
                      '${episode.order}',
                      style: TextStyle(
                        color: unavailable ? AppColors.textMuted : Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                  ),
                  if (locked)
                    const Positioned(
                      top: 5,
                      right: 5,
                      child: Icon(Icons.lock_rounded, size: 12),
                    )
                  else if (unavailable)
                    const Positioned(
                      top: 5,
                      right: 5,
                      child: Icon(
                        Icons.warning_amber_rounded,
                        size: 12,
                        color: AppColors.warning,
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
