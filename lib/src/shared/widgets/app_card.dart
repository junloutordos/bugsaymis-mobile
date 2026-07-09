import 'package:flutter/material.dart';
import '../../core/theme.dart';

/// The app's canonical white card: [AppRadius.card] corners + [kCardShadow].
/// Pass [onTap] to make the whole card tappable with a matching ink ripple.
class AppCard extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final content = Padding(padding: padding, child: child);

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.all(Radius.circular(AppRadius.card)),
        boxShadow: kCardShadow,
      ),
      child: onTap == null
          ? content
          : Material(
              color: Colors.transparent,
              borderRadius:
                  const BorderRadius.all(Radius.circular(AppRadius.card)),
              child: InkWell(
                onTap: onTap,
                borderRadius:
                    const BorderRadius.all(Radius.circular(AppRadius.card)),
                child: content,
              ),
            ),
    );
  }
}
