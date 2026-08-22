import 'package:flutter/material.dart';
import '../../core/theme.dart';

/// Replaces the pinned white `AppHeader` on screens that show a real
/// personalized greeting (Home, Student Dashboard) with a scrolling
/// gradient hero: greeting/name/date, a translucent circular action button
/// (profile on Home, sign-out on Student Dashboard — hence the generic
/// icon/tooltip/callback rather than a hardcoded "profile" action), and one
/// optional glanceable stat.
class HeroHeader extends StatelessWidget {
  final Widget? leading;
  final String greeting;
  final String name;
  final String subtitle;
  final IconData? actionIcon;
  final String? actionTooltip;
  final VoidCallback? onActionTap;
  final Widget? trailing;
  final VoidCallback? onTap;

  const HeroHeader({
    super.key,
    this.leading,
    required this.greeting,
    required this.name,
    required this.subtitle,
    this.actionIcon,
    this.actionTooltip,
    this.onActionTap,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final content = Padding(
      padding: EdgeInsets.fromLTRB(
          AppSpacing.xl, AppSpacing.lg, AppSpacing.xl, AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (leading != null) ...[
                leading!,
                SizedBox(width: AppSpacing.sm),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(greeting,
                        style: AppTextStyles.custom(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: Colors.white70)),
                    const SizedBox(height: 2),
                    Text(name,
                        style: AppTextStyles.custom(
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: -0.3)),
                    const SizedBox(height: 2),
                    Text(subtitle,
                        style: AppTextStyles.custom(
                            fontSize: 13,
                            fontWeight: FontWeight.w400,
                            color: Colors.white70)),
                  ],
                ),
              ),
              if (actionIcon != null && onActionTap != null) ...[
                SizedBox(width: AppSpacing.md),
                _HeroActionButton(
                  icon: actionIcon!,
                  tooltip: actionTooltip ?? '',
                  onTap: onActionTap!,
                ),
              ],
            ],
          ),
          if (trailing != null) ...[
            SizedBox(height: AppSpacing.lg),
            trailing!,
          ],
        ],
      ),
    );

    return SafeArea(
      bottom: false,
      child: Container(
        width: double.infinity,
        margin: EdgeInsets.fromLTRB(
            AppSpacing.lg, AppSpacing.md, AppSpacing.lg, 0),
        decoration: BoxDecoration(
          gradient: AppGradients.hero,
          borderRadius: BorderRadius.circular(AppRadius.card),
        ),
        child: onTap == null
            ? content
            : Material(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(AppRadius.card),
                child: InkWell(
                  onTap: onTap,
                  borderRadius: BorderRadius.circular(AppRadius.card),
                  child: content,
                ),
              ),
      ),
    );
  }
}

class _HeroActionButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  const _HeroActionButton(
      {required this.icon, required this.tooltip, required this.onTap});

  @override
  Widget build(BuildContext context) => Semantics(
        label: tooltip,
        button: true,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.16),
            shape: BoxShape.circle,
          ),
          child: IconButton(
            icon: Icon(icon, size: 20),
            tooltip: tooltip,
            onPressed: onTap,
            style: IconButton.styleFrom(
              foregroundColor: Colors.white,
              shape: const CircleBorder(),
              minimumSize: const Size(40, 40),
              maximumSize: const Size(40, 40),
              padding: EdgeInsets.zero,
            ),
            constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
          ),
        ),
      );
}

/// Translucent-white circular icon button for use as [HeroHeader.leading]
/// (a back button on the gradient) — visually matches [_HeroActionButton]
/// but is exposed for the leading slot instead of the trailing action slot.
class HeroBackButton extends StatelessWidget {
  final VoidCallback onTap;
  const HeroBackButton({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.16),
          shape: BoxShape.circle,
        ),
        child: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          tooltip: 'Back',
          onPressed: onTap,
          style: IconButton.styleFrom(
            foregroundColor: Colors.white,
            shape: const CircleBorder(),
            minimumSize: const Size(40, 40),
            maximumSize: const Size(40, 40),
            padding: EdgeInsets.zero,
          ),
          constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
        ),
      );
}
