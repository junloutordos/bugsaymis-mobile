import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/theme.dart';
import '../../shared/widgets/empty_state.dart';
import '../../shared/widgets/shimmer_card.dart';
import 'portal_provider.dart';
import 'portal_widgets.dart';

/// Annual forms overview — 6 guidance + 4 medical sections with
/// per-section completion state for the current school year.
class FormsOverviewScreen extends ConsumerWidget {
  const FormsOverviewScreen({super.key});

  static const _icons = <String, IconData>{
    'academic': Icons.menu_book_rounded,
    'activities': Icons.emoji_events_rounded,
    'social': Icons.diversity_3_rounded,
    'career': Icons.work_outline_rounded,
    'residence': Icons.home_work_rounded,
    'health': Icons.monitor_heart_rounded,
    'allergies': Icons.warning_amber_rounded,
    'immunizations': Icons.vaccines_rounded,
    'medical_history': Icons.history_edu_rounded,
    'vitamins': Icons.medication_rounded,
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboard = ref.watch(portalDashboardProvider);

    return PortalSubScreen(
      title: 'Annual Forms',
      body: RefreshIndicator(
        color: AppColors.accent,
        onRefresh: () async => ref.invalidate(portalDashboardProvider),
        child: dashboard.when(
          loading: () => const ShimmerList(count: 6, itemHeight: 68),
          error: (e, _) => ListView(
            padding: const EdgeInsets.fromLTRB(20, 60, 20, 24),
            children: [
              ErrorRetryView(
                message: friendlyError(e),
                onRetry: () => ref.invalidate(portalDashboardProvider),
              ),
            ],
          ),
          data: (d) {
            final profile =
                d.completion.where((s) => s.group == 'profile').toList();
            final medical =
                d.completion.where((s) => s.group == 'medical').toList();

            return ListView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
              children: [
                if (d.schoolYear != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Text(
                      'Please complete every section once for S.Y. ${d.schoolYear}.',
                      style: AppTextStyles.custom(fontSize: 13, color: AppColors.textSecondary, height: 1.5),
                    ),
                  ),
                const SectionLabel('GUIDANCE PROFILE'),
                AppCard(
                  padding: EdgeInsets.zero,
                  child: Column(
                    children: [
                      for (var i = 0; i < profile.length; i++) ...[
                        if (i > 0) const Divider(height: 1, indent: 66),
                        _SectionTile(
                          section: profile[i],
                          icon: _icons[profile[i].key] ??
                              Icons.description_rounded,
                          onTap: () => context.push(
                              '/student/portal/forms/profile/${profile[i].key}'),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                const SectionLabel('MEDICAL RECORDS'),
                AppCard(
                  padding: EdgeInsets.zero,
                  child: Column(
                    children: [
                      for (var i = 0; i < medical.length; i++) ...[
                        if (i > 0) const Divider(height: 1, indent: 66),
                        _SectionTile(
                          section: medical[i],
                          icon: _icons[medical[i].key] ??
                              Icons.description_rounded,
                          onTap: () => context.push(
                              '/student/portal/forms/medical/${medical[i].key}'),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _SectionTile extends StatelessWidget {
  final PortalSection section;
  final IconData icon;
  final VoidCallback onTap;

  const _SectionTile(
      {required this.section, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    String? subtitle;
    if (section.submitted && section.submittedAt != null) {
      try {
        subtitle =
            'Submitted ${DateFormat('MMM d, y').format(DateTime.parse(section.submittedAt!))}';
      } catch (_) {
        subtitle = 'Submitted';
      }
    }

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: section.submitted
                    ? AppColors.successBg
                    : AppColors.accentBg,
                shape: BoxShape.circle,
              ),
              child: Icon(icon,
                  size: 18,
                  color: section.submitted
                      ? AppColors.success
                      : AppColors.accent),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(section.label,
                      style: AppTextStyles.custom(fontSize: 14, fontWeight: FontWeight.w600)),
                  if (subtitle != null)
                    Text(subtitle,
                        style: AppTextStyles.custom(fontSize: 11, color: AppColors.textSecondary)),
                ],
              ),
            ),
            if (section.submitted)
              const Icon(Icons.check_circle_rounded,
                  size: 18, color: AppColors.success)
            else
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.warningBg,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text('To do',
                    style: AppTextStyles.custom(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.warningText)),
              ),
            const SizedBox(width: 6),
            const Icon(Icons.chevron_right_rounded,
                size: 18, color: AppColors.textDisabled),
          ],
        ),
      ),
    );
  }
}
