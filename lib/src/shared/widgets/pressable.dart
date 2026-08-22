import 'package:flutter/material.dart';
import '../../core/theme.dart';

/// The app's canonical tap feedback — ink ripple + a subtle press-scale —
/// for tappables that aren't already an [AppCard] (chips, list rows, nav
/// items). Extracted from AppCard's existing press-scale so both share one
/// implementation instead of duplicating the state-management boilerplate.
class Pressable extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final BorderRadius borderRadius;

  const Pressable({
    super.key,
    required this.child,
    required this.onTap,
    this.borderRadius = BorderRadius.zero,
  });

  @override
  State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: _pressed ? 0.96 : 1.0,
      duration: AppMotion.fast,
      curve: AppMotion.standard,
      child: Material(
        color: Colors.transparent,
        borderRadius: widget.borderRadius,
        child: InkWell(
          onTap: widget.onTap,
          onTapDown: (_) => setState(() => _pressed = true),
          onTapCancel: () => setState(() => _pressed = false),
          onTapUp: (_) => setState(() => _pressed = false),
          borderRadius: widget.borderRadius,
          child: widget.child,
        ),
      ),
    );
  }
}
