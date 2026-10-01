import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

int shortsSeekTargetMilliseconds(double fraction, int durationMs) {
  if (durationMs <= 0) return 0;
  return (fraction.clamp(0.0, 1.0) * durationMs).round();
}

/// Thin, seekable playback progress with a larger invisible touch target.
class ShortsVideoProgressBar extends StatelessWidget {
  const ShortsVideoProgressBar({
    super.key,
    required this.progress,
    required this.durationMs,
    this.visible = true,
    this.onSeekStart,
    this.onSeekChanged,
    this.onSeekEnd,
  });

  /// Normalized playback position in `[0, 1]`.
  final double progress;
  final int durationMs;
  final bool visible;
  final ValueChanged<double>? onSeekStart;
  final ValueChanged<double>? onSeekChanged;
  final ValueChanged<double>? onSeekEnd;

  @override
  Widget build(BuildContext context) {
    final target = progress.clamp(0.0, 1.0).toDouble();
    final active = visible && durationMs > 0 && onSeekChanged != null;
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return AnimatedOpacity(
      opacity: visible ? 1 : 0,
      duration: const Duration(milliseconds: 220),
      child: Padding(
        padding: EdgeInsets.fromLTRB(12, 0, 12, bottomInset + 4),
        child: SliderTheme(
          data: SliderTheme.of(context).copyWith(
            trackHeight: 2,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 3),
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
            activeTrackColor: AppColors.primary,
            inactiveTrackColor: Colors.white38,
            thumbColor: Colors.white,
            overlayColor: AppColors.primary.withValues(alpha: .18),
          ),
          child: Slider(
            value: target,
            min: 0,
            max: 1,
            onChangeStart: active ? onSeekStart : null,
            onChanged: active ? onSeekChanged : null,
            onChangeEnd: active ? onSeekEnd : null,
          ),
        ),
      ),
    );
  }
}
