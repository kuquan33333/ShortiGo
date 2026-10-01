import 'package:flutter/material.dart';

/// A small, non-ripple press affordance for the app's dark surfaces.
///
/// Material's default splash is intentionally not used here because it paints
/// a grey rectangle over poster grids and navigation icons on iOS.
class AppPressable extends StatefulWidget {
  const AppPressable({
    super.key,
    required this.child,
    required this.onTap,
    this.semanticsLabel,
    this.pressedScale = .975,
    this.pressedOpacity = .9,
  });

  final Widget child;
  final VoidCallback? onTap;
  final String? semanticsLabel;
  final double pressedScale;
  final double pressedOpacity;

  @override
  State<AppPressable> createState() => _AppPressableState();
}

class _AppPressableState extends State<AppPressable> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (!mounted || _pressed == value) return;
    setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: widget.semanticsLabel,
      child: Listener(
        onPointerDown: widget.onTap == null ? null : (_) => _setPressed(true),
        onPointerUp: widget.onTap == null ? null : (_) => _setPressed(false),
        onPointerCancel:
            widget.onTap == null ? null : (_) => _setPressed(false),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: widget.onTap,
          child: AnimatedScale(
            scale: _pressed ? widget.pressedScale : 1,
            duration: const Duration(milliseconds: 100),
            curve: Curves.easeOutCubic,
            child: AnimatedOpacity(
              opacity: _pressed ? widget.pressedOpacity : 1,
              duration: const Duration(milliseconds: 100),
              child: widget.child,
            ),
          ),
        ),
      ),
    );
  }
}
