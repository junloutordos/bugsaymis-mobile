import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme.dart';
import '../../shared/widgets/empty_state.dart';
import '../../shared/widgets/shimmer_card.dart';
import '../auth/auth_provider.dart';
import '../student/student_nav.dart';
import 'portal_provider.dart';
import 'portal_widgets.dart';

/// 5th student tab — gateway to the portal services: annual forms,
/// residence hall, clearance, and account actions.
class ServicesScreen extends ConsumerWidget {
  const ServicesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboard = ref.watch(portalDashboardProvider);
    final user = ref.watch(authStateProvider).value;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          AppHeader(
            greeting: 'Student services',
            name: 'Services',
            subtitle: dashboard.value?.schoolYear != null
                ? 'S.Y. ${dashboard.value!.schoolYear}'
                : 'Forms, dorm & clearance',
          ),
          Expanded(
            child: RefreshIndicator(
              color: AppColors.accent,
              onRefresh: () async => ref.invalidate(portalDashboardProvider),
              child: dashboard.when(
                loading: () => const ShimmerList(count: 4, itemHeight: 92),
                error: (e, _) => ListView(
                  padding: const EdgeInsets.fromLTRB(20, 60, 20, 24),
                  children: [
                    ErrorRetryView(
                      message: friendlyError(e),
                      onRetry: () => ref.invalidate(portalDashboardProvider),
                    ),
                  ],
                ),
                data: (d) => ListView(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
                  children: [
                    const SectionLabel('ANNUAL FORMS'),
                    _FormsCard(dashboard: d),
                    const SizedBox(height: 20),
                    const SectionLabel('RESIDENCE HALL'),
                    _ServiceTile(
                      icon: Icons.night_shelter_rounded,
                      iconColor: const Color(0xFF7C3AED),
                      iconBg: const Color(0xFFF3E8FF),
                      title: 'Accommodation Application',
                      subtitle: _rhSubtitle(d),
                      trailing: d.rhApplication != null
                          ? PortalStatusChip.forStatus(
                              d.isDormer
                                  ? 'active'
                                  : (d.rhApplication!['status'] as String? ??
                                      'pending'))
                          : null,
                      onTap: () => context.push('/student/portal/rh-application'),
                    ),
                    const SizedBox(height: 12),
                    _ServiceTile(
                      icon: Icons.assignment_return_rounded,
                      iconColor: const Color(0xFF0D9488),
                      iconBg: const Color(0xFFCCFBF1),
                      title: 'Leave Passes',
                      subtitle: d.isDormer
                          ? 'File and track your dorm leave passes'
                          : 'Available to active dormers',
                      onTap: () => context.push('/student/portal/leave-passes'),
                    ),
                    const SizedBox(height: 20),
                    const SectionLabel('CLEARANCE'),
                    _ServiceTile(
                      icon: Icons.verified_rounded,
                      iconColor: AppColors.success,
                      iconBg: AppColors.successBg,
                      title: 'Year-End Clearance',
                      subtitle: d.clearance == null
                          ? 'No clearance period yet'
                          : d.clearance!.status == 'not_generated'
                              ? '${d.clearance!.periodTitle ?? 'Clearance'} — not yet generated'
                              : '${d.clearance!.done} of ${d.clearance!.total} requirements cleared',
                      trailing: d.clearance != null &&
                              d.clearance!.status != 'not_generated'
                          ? PortalStatusChip.forStatus(d.clearance!.status)
                          : null,
                      onTap: () => context.push('/student/portal/clearance'),
                    ),
                    const SizedBox(height: 20),
                    const SectionLabel('ACCOUNT'),
                    WhiteCard(
                      padding: EdgeInsets.zero,
                      child: Column(
                        children: [
                          ListTile(
                            leading: const Icon(Icons.person_rounded,
                                color: AppColors.textSecondary, size: 20),
                            title: Text(user?.name ?? 'Student',
                                style: GoogleFonts.plusJakartaSans(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600)),
                            subtitle: Text(user?.email ?? '',
                                style: GoogleFonts.plusJakartaSans(
                                    fontSize: 12,
                                    color: AppColors.textSecondary)),
                          ),
                          const Divider(height: 1),
                          ListTile(
                            leading: const Icon(Icons.logout_rounded,
                                color: Colors.redAccent, size: 20),
                            title: Text('Sign out',
                                style: GoogleFonts.plusJakartaSans(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.redAccent)),
                            onTap: () async {
                              await ref
                                  .read(authStateProvider.notifier)
                                  .logout();
                              if (context.mounted) context.go('/login');
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: const StudentBottomNav(currentIndex: 4),
    );
  }

  String _rhSubtitle(PortalDashboard d) {
    if (d.isDormer) {
      final bed = d.intern!['bed_number'];
      return bed != null ? 'Active dormer — Bed $bed' : 'Active dormer';
    }
    if (d.rhApplication != null) {
      return 'Application for S.Y. ${d.schoolYear ?? '—'}';
    }
    return 'Apply for dormitory accommodation';
  }
}

class _FormsCard extends ConsumerWidget {
  final PortalDashboard dashboard;
  const _FormsCard({required this.dashboard});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progress =
        dashboard.total == 0 ? 0.0 : dashboard.totalDone / dashboard.total;

    return WhiteCard(
      padding: EdgeInsets.zero,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => context.push('/student/portal/forms'),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              SizedBox(
                width: 52,
                height: 52,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    CircularProgressIndicator(
                      value: progress,
                      strokeWidth: 5,
                      backgroundColor: AppColors.borderLight,
                      color: progress >= 1
                          ? AppColors.success
                          : AppColors.accent,
                    ),
                    Center(
                      child: Text('${dashboard.totalDone}/${dashboard.total}',
                          style: GoogleFonts.plusJakartaSans(
                              fontSize: 12, fontWeight: FontWeight.w800)),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Guidance & Medical Forms',
                        style: GoogleFonts.plusJakartaSans(
                            fontSize: 14, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 2),
                    Text(
                      progress >= 1
                          ? 'All sections completed — thank you!'
                          : 'Complete your annual student forms',
                      style: GoogleFonts.plusJakartaSans(
                          fontSize: 12, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded,
                  color: AppColors.textDisabled),
            ],
          ),
        ),
      ),
    );
  }
}

class _ServiceTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String title;
  final String subtitle;
  final Widget? trailing;
  final VoidCallback onTap;

  const _ServiceTile({
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.title,
    required this.subtitle,
    this.trailing,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => WhiteCard(
        padding: EdgeInsets.zero,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration:
                      BoxDecoration(color: iconBg, shape: BoxShape.circle),
                  child: Icon(icon, color: iconColor, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title,
                          style: GoogleFonts.plusJakartaSans(
                              fontSize: 14, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 2),
                      Text(subtitle,
                          style: GoogleFonts.plusJakartaSans(
                              fontSize: 12, color: AppColors.textSecondary)),
                    ],
                  ),
                ),
                if (trailing != null) ...[
                  trailing!,
                  const SizedBox(width: 4),
                ],
                const Icon(Icons.chevron_right_rounded,
                    color: AppColors.textDisabled),
              ],
            ),
          ),
        ),
      );
}
