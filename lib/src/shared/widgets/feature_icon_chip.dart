import 'package:flutter/material.dart';

/// A round, gradient-filled icon chip used to give a feature area (Portal,
/// Attendance, Grades, ...) a colored identity — replaces plain gray icons
/// as part of the bold/vibrant visual pass.
class FeatureIconChip extends StatelessWidget {
  final IconData icon;
  final Gradient gradient;
  final double size;

  const FeatureIconChip({
    super.key,
    required this.icon,
    required this.gradient,
    this.size = 44,
  });

  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(gradient: gradient, shape: BoxShape.circle),
        child: Icon(icon, color: Colors.white, size: size * 0.5),
      );
}
