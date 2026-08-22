import 'package:flutter/material.dart';
import '../../core/theme.dart';

/// The app's canonical white card: [AppRadius.card] corners + [AppElevation.resting].
/// Pass [onTap] to make the whole card tappable with a matching ink ripple
/// and a subtle press-scale for tactile feedback.
class AppCard extends StatefulWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;

  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.onTap,
  });

  @override
  State<AppCard> createState() => _AppCardState();
}

class _AppCardState extends State<AppCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final content = Padding(padding: widget.padding, child: widget.child);

    final card = Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.all(Radius.circular(AppRadius.card)),
        boxShadow: AppElevation.resting,
      ),
      child: widget.onTap == null
          ? content
          : Material(
              color: Colors.transparent,
              borderRadius: const BorderRadius.all(Radius.circular(AppRadius.card)),
              child: InkWell(
                onTap: widget.onTap,
                onTapDown: (_) => setState(() => _pressed = true),
                onTapCancel: () => setState(() => _pressed = false),
                onTapUp: (_) => setState(() => _pressed = false),
                borderRadius: const BorderRadius.all(Radius.circular(AppRadius.card)),
                child: content,
              ),
            ),
    );

    if (widget.onTap == null) return card;

    return AnimatedScale(
      scale: _pressed ? 0.98 : 1.0,
      duration: AppMotion.fast,
      curve: AppMotion.standard,
      child: card,
    );
  }
}
