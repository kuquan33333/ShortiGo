import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../domain/entities/episode.dart';

/// Compact episode grid shared by the detail surface and player sheet.
class EpisodePickerGrid extends StatefulWidget {
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
  State<EpisodePickerGrid> createState() => _EpisodePickerGridState();
}

class _EpisodePickerGridState extends State<EpisodePickerGrid> {
  int _range = 0;

  @override
  void initState() {
    super.initState();
    _range = _rangeFor(widget.currentIndex);
  }

  @override
  void didUpdateWidget(covariant EpisodePickerGrid oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.episodes.length != widget.episodes.length ||
        oldWidget.currentIndex != widget.currentIndex) {
      final nextRange = _rangeFor(widget.currentIndex);
      if (nextRange != _range &&
          (oldWidget.episodes.length != widget.episodes.length ||
              widget.currentIndex != oldWidget.currentIndex)) {
        _range = nextRange;
      }
    }
  }

  int _rangeFor(int index) {
    if (index < 0) return 0;
    return index ~/ 30;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.episodes.isEmpty) return const SizedBox.shrink();
    final rangeCount = (widget.episodes.length + 29) ~/ 30;
    final start = _range * 30;
    final end = (start + 30).clamp(0, widget.episodes.length);
    final visibleCount = end - start;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (rangeCount > 1)
          SizedBox(
            height: 38,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: rangeCount,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, range) {
                final rangeStart = range * 30 + 1;
                final rangeEnd =
                    (rangeStart + 29).clamp(rangeStart, widget.episodes.length);
                final selected = range == _range;
                return ChoiceChip(
                  label: Text('$rangeStart–$rangeEnd'),
                  selected: selected,
                  onSelected: (_) => setState(() => _range = range),
                  selectedColor: AppColors.primary,
                  backgroundColor: AppColors.surfaceElevated,
                  labelStyle: TextStyle(
                    color: selected ? Colors.white : AppColors.textSecondary,
                    fontWeight: FontWeight.w700,
                  ),
                  side: BorderSide.none,
                  showCheckmark: false,
                );
              },
            ),
          ),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 6,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 1.08,
          ),
          itemCount: visibleCount,
          itemBuilder: (context, offset) {
            final index = start + offset;
            final episode = widget.episodes[index];
            final current = index == widget.currentIndex;
            final locked = episode.sourceLocked || episode.isVipLocked;
            final unavailable = !episode.sourceAvailable && !locked;
            final enabled = !locked && !unavailable;
            return Semantics(
              button: enabled,
              label: 'Episode ${episode.order}',
              child: InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: enabled ? () => widget.onSelect(index) : null,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color:
                        current ? AppColors.primary : AppColors.surfaceElevated,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color:
                          current ? AppColors.primaryLight : Colors.transparent,
                      width: 1.2,
                    ),
                  ),
                  child: Stack(
                    children: [
                      Center(
                        child: Text(
                          '${episode.order}',
                          style: TextStyle(
                            color: enabled ? Colors.white : AppColors.textMuted,
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
        ),
      ],
    );
  }
}
