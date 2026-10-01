import 'package:better_player_plus/better_player_plus.dart';
import 'package:flutter/material.dart';

class CompactPlaybackRetry extends StatelessWidget {
  const CompactPlaybackRetry({
    super.key,
    required this.label,
    required this.onPressed,
  });

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(24),
        splashColor: Colors.white12,
        highlightColor: Colors.white10,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.refresh_rounded, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class EpisodePlayerView extends StatefulWidget {
  const EpisodePlayerView({super.key, required this.controller});

  final BetterPlayerController controller;

  @override
  State<EpisodePlayerView> createState() => _EpisodePlayerViewState();
}

class _EpisodePlayerViewState extends State<EpisodePlayerView>
    with WidgetsBindingObserver {
  bool _isPausedByUser = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _togglePlayback,
      child: SizedBox.expand(
        child: Stack(
          fit: StackFit.expand,
          children: [
            LayoutBuilder(
              builder: (context, constraints) {
                final aspectRatio = episodePlayerViewportAspectRatio(
                  width: constraints.maxWidth,
                  height: constraints.maxHeight,
                );
                if (aspectRatio != null) {
                  widget.controller.setOverriddenAspectRatio(aspectRatio);
                }

                return BetterPlayer(controller: widget.controller);
              },
            ),
            Center(
              child: IgnorePointer(
                child: AnimatedOpacity(
                  opacity: _isPausedByUser ? 1 : 0,
                  duration: const Duration(milliseconds: 180),
                  child: Container(
                    width: 92,
                    height: 92,
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.22),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.play_arrow_rounded,
                      color: Colors.white,
                      size: 70,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    widget.controller.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (shouldPauseVideoForLifecycle(state)) {
      setState(() => _isPausedByUser = true);
      widget.controller.pause();
    }
  }

  void _togglePlayback() {
    final next = nextVideoPausedState(isPaused: _isPausedByUser);
    setState(() => _isPausedByUser = next);
    if (next) {
      widget.controller.pause();
    } else {
      widget.controller.play();
    }
  }
}

double? episodePlayerViewportAspectRatio({
  required double width,
  required double height,
}) {
  if (width <= 0 || height <= 0) {
    return null;
  }

  return width / height;
}

bool shouldPauseVideoForLifecycle(AppLifecycleState state) {
  return switch (state) {
    AppLifecycleState.resumed => false,
    AppLifecycleState.inactive ||
    AppLifecycleState.hidden ||
    AppLifecycleState.paused ||
    AppLifecycleState.detached =>
      true,
  };
}

bool nextVideoPausedState({required bool isPaused}) => !isPaused;
