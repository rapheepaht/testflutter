import 'package:flutter/material.dart';

/// Wraps any widget with a press-down scale animation.
/// Uses [Listener] (not GestureDetector) so child button onPressed still fires.
class TapScaleWidget extends StatefulWidget {
  final Widget child;
  final double pressedScale;

  const TapScaleWidget({
    super.key,
    required this.child,
    this.pressedScale = 0.93,
  });

  @override
  State<TapScaleWidget> createState() => _TapScaleWidgetState();
}

class _TapScaleWidgetState extends State<TapScaleWidget> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (_) => setState(() => _isPressed = true),
      onPointerUp: (_) => setState(() => _isPressed = false),
      onPointerCancel: (_) => setState(() => _isPressed = false),
      child: AnimatedScale(
        scale: _isPressed ? widget.pressedScale : 1.0,
        duration: const Duration(milliseconds: 80),
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}
