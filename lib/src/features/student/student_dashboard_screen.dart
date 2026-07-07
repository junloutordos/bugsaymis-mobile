import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../core/theme.dart';
import '../../shared/widgets/shimmer_card.dart';
import '../auth/auth_provider.dart';
import '../grades/grades_provider.dart';
import '../portal/portal_provider.dart';
import '../portal/portal_widgets.dart';
import 'student_nav.dart';
import 'student_provider.dart';

class StudentDashboardScreen extends ConsumerWidget {
  const StudentDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user    = ref.watch(authStateProvider).value;
    final profile = ref.watch(studentProfileProvider);
    final today   = ref.watch(studentTodayProvider);
    final grades  = ref.watch(studentGradesProvider);
    final portal  = ref.watch(portalDashboardProvider);

    final firstName = user?.name.split(' ').first ?? 'Student';
    final greeting  = _greeting();
    final dateStr   = DateFormat('EEEE, MMMM d').format(DateTime.now());

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // ── Header ──────────────────────────────────────────────────────
          AppHeader(
            greeting: greeting,
            name: firstName,
            subtitle: dateStr,
            actions: [
              Padding(
                padding: const EdgeInsets.only(left: 4),
                child: IconButton(
                  icon: const Icon(Icons.logout_rounded, size: 20),
                  tooltip: 'Sign out',
                  style: IconButton.styleFrom(
                    foregroundColor: AppColors.textSecondary,
                    backgroundColor: AppColors.neutralBg,
                    shape: const CircleBorder(),
                    minimumSize: const Size(38, 38),
                    maximumSize: const Size(38, 38),
                    padding: EdgeInsets.zero,
                  ),
                  constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
                  onPressed: () async {
                    await ref.read(authStateProvider.notifier).logout();
                    if (context.mounted) context.go('/login');
                  },
                ),
              ),
            ],
          ),

          // ── Body ──────────────────────────────────────────────────────
          Expanded(
            child: RefreshIndicator(
              color: AppColors.accent,
              onRefresh: () async {
                ref.invalidate(studentProfileProvider);
                ref.invalidate(studentTodayProvider);
                ref.invalidate(studentGradesProvider);
                ref.invalidate(portalDashboardProvider);
              },
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
                children: [
                  // ── Profile card ────────────────────────────────────
                  profile.when(
                    loading: () => const ShimmerCard(height: 100),
                    error: (_, __) => const SizedBox.shrink(),
                    data: (p) => _ProfileCard(profile: p),
                  ),

                  const SizedBox(height: 20),
                  const SectionLabel("TODAY'S GATE STATUS"),

                  // ── Today status ────────────────────────────────────
                  today.when(
                    loading: () => const ShimmerCard(height: 80),
                    error: (_, __) => const SizedBox.shrink(),
                    data: (t) => _TodayCard(summary: t),
                  ),

                  const SizedBox(height: 20),
                  const SectionLabel('LATEST GRADES'),

                  // ── Grade summary ───────────────────────────────────
                  grades.when(
                    loading: () => const ShimmerCard(height: 120),
                    error: (_, __) => _GradesUnavailable(),
                    data: (d) => _GradeSummaryCard(
                      grades: d,
                      onTap: () => context.go('/student/grades'),
                    ),
                  ),

                  // ── Portal to-dos (forms / clearance / RH) ──────────
                  portal.maybeWhen(
                    data: (p) => _PortalTodoSection(portal: p),
                    orElse: () => const SizedBox.shrink(),
                  ),

                  const SizedBox(height: 20),
                  const SectionLabel('QUICK ACTIONS'),

                  Row(
                    children: [
                      Expanded(
                        child: _QuickAction(
                          icon: Icons.calendar_month_rounded,
                          label: 'Attendance',
                          onTap: () => context.go('/student/attendance'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _QuickAction(
                          icon: Icons.grid_view_rounded,
                          label: 'Schedule',
                          onTap: () => context.go('/student/schedule'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _QuickAction(
                          icon: Icons.widgets_rounded,
                          label: 'Services',
                          onTap: () => context.go('/student/services'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: const StudentBottomNav(currentIndex: 0),
    );
  }

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good morning,';
    if (h < 17) return 'Good afternoon,';
    return 'Good evening,';
  }
}

class _ProfileCard extends StatelessWidget {
  final StudentProfile profile;
  const _ProfileCard({required this.profile});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1A3557), Color(0xFF2563EB)],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: const [
            BoxShadow(
                color: Color(0x282563EB),
                blurRadius: 20,
                offset: Offset(0, 6)),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  profile.name.isNotEmpty ? profile.name[0] : '?',
                  style: GoogleFonts.plusJakartaSans(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(profile.name,
                      style: GoogleFonts.plusJakartaSans(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w700)),
                  if (profile.gradeLevel != null && profile.section != null)
                    Text('Grade ${profile.gradeLevel} — ${profile.section}',
                        style: GoogleFonts.plusJakartaSans(
                            color: Colors.white70, fontSize: 12)),
                  if (profile.schoolYear != null)
                    Text('S.Y. ${profile.schoolYear}',
                        style: GoogleFonts.plusJakartaSans(
                            color: Colors.white54, fontSize: 11)),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text('Student',
                  style: GoogleFonts.plusJakartaSans(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      );
}

class _TodayCard extends StatelessWidget {
  final StudentTodaySummary summary;
  const _TodayCard({required this.summary});

  @override
  Widget build(BuildContext context) {
    final isIn  = summary.lastStatus == 'in';
    final isOut = summary.lastStatus == 'out';
    final color = isIn
        ? AppColors.success
        : isOut
            ? AppColors.warning
            : AppColors.textSecondary;
    final bg = isIn
        ? AppColors.successBg
        : isOut
            ? AppColors.warningBg
            : AppColors.neutralBg;
    final label = isIn
        ? 'At School'
        : isOut
            ? 'Left School'
            : 'No Scan Today';
    final icon = isIn
        ? Icons.check_circle_rounded
        : isOut
            ? Icons.home_rounded
            : Icons.radio_button_unchecked_rounded;

    String timeStr = '';
    if (summary.lastScan != null) {
      try {
        timeStr = DateFormat('h:mm a')
            .format(DateTime.parse(summary.lastScan!).toLocal());
      } catch (_) {}
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
              color: Color(0x0A000000), blurRadius: 16, offset: Offset(0, 3))
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary)),
                if (timeStr.isNotEmpty)
                  Text('Last scan at $timeStr',
                      style: GoogleFonts.plusJakartaSans(
                          fontSize: 12, color: AppColors.textSecondary)),
              ],
            ),
          ),
          if (summary.totalScans > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text('${summary.totalScans} scan${summary.totalScans == 1 ? '' : 's'}',
                  style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: color)),
            ),
        ],
      ),
    );
  }
}

class _GradeSummaryCard extends StatelessWidget {
  final GradesData grades;
  final VoidCallback onTap;
  const _GradeSummaryCard({required this.grades, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final gwa = grades.gwa;
    final topSubjects = grades.grades.take(3).toList();

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: const [
              BoxShadow(
                  color: Color(0x0A000000), blurRadius: 16, offset: Offset(0, 3))
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text('S.Y. ${grades.schoolYear ?? '—'}',
                      style: GoogleFonts.plusJakartaSans(
                          fontSize: 12, color: AppColors.textSecondary)),
                  const Spacer(),
                  if (gwa != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 3),
                      decoration: BoxDecoration(
                        color: _gwaColor(gwa).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text('GWA ${gwa.toStringAsFixed(2)}',
                          style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: _gwaColor(gwa))),
                    ),
                  const SizedBox(width: 8),
                  const Icon(Icons.chevron_right_rounded,
                      size: 16, color: AppColors.textDisabled),
                ],
              ),
              if (topSubjects.isNotEmpty) ...[
                const SizedBox(height: 12),
                const Divider(height: 1),
                const SizedBox(height: 10),
                ...topSubjects.map((g) => Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(g.subjectName,
                                style: GoogleFonts.plusJakartaSans(
                                    fontSize: 13,
                                    color: AppColors.textPrimary)),
                          ),
                          Text(
                            g.finalGe != null
                                ? g.finalGe!.toStringAsFixed(2)
                                : '—',
                            style: GoogleFonts.plusJakartaSans(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: g.finalGe != null
                                    ? _gwaColor(g.finalGe!)
                                    : AppColors.textDisabled),
                          ),
                        ],
                      ),
                    )),
                if (grades.grades.length > 3)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      '+${grades.grades.length - 3} more subjects',
                      style: GoogleFonts.plusJakartaSans(
                          fontSize: 11, color: AppColors.textSecondary),
                    ),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Color _gwaColor(double gwa) {
    if (gwa <= 1.5) return AppColors.success;
    if (gwa <= 3.0) return AppColors.accent;
    return Colors.red.shade600;
  }
}

/// Compact "needs your attention" section fed by the portal dashboard:
/// pending annual forms, clearance progress, dormer status.
class _PortalTodoSection extends StatelessWidget {
  final PortalDashboard portal;
  const _PortalTodoSection({required this.portal});

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];

    if (portal.total > 0 && portal.totalDone < portal.total) {
      rows.add(_todoRow(
        context,
        icon: Icons.assignment_rounded,
        iconColor: AppColors.accent,
        iconBg: AppColors.accentBg,
        title: 'Annual forms',
        subtitle:
            '${portal.totalDone} of ${portal.total} sections completed — tap to continue',
        route: '/student/portal/forms',
      ));
    }

    final c = portal.clearance;
    if (c != null && c.status != 'not_generated') {
      rows.add(_todoRow(
        context,
        icon: Icons.verified_rounded,
        iconColor: AppColors.success,
        iconBg: AppColors.successBg,
        title: c.periodTitle ?? 'Year-End Clearance',
        subtitle: c.holds > 0
            ? '${c.pending} pending · ${c.holds} on hold'
            : '${c.done} of ${c.total} requirements cleared',
        route: '/student/portal/clearance',
      ));
    }

    if (portal.isDormer) {
      rows.add(_todoRow(
        context,
        icon: Icons.night_shelter_rounded,
        iconColor: const Color(0xFF7C3AED),
        iconBg: const Color(0xFFF3E8FF),
        title: 'Residence Hall',
        subtitle: 'Active dormer — file leave passes here',
        route: '/student/portal/leave-passes',
      ));
    }

    if (rows.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
        const SectionLabel('NEEDS YOUR ATTENTION'),
        WhiteCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              for (var i = 0; i < rows.length; i++) ...[
                if (i > 0) const Divider(height: 1, indent: 66),
                rows[i],
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _todoRow(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required String title,
    required String subtitle,
    required String route,
  }) =>
      InkWell(
        onTap: () => context.push(route),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration:
                    BoxDecoration(color: iconBg, shape: BoxShape.circle),
                child: Icon(icon, size: 18, color: iconColor),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: GoogleFonts.plusJakartaSans(
                            fontSize: 13, fontWeight: FontWeight.w700)),
                    Text(subtitle,
                        style: GoogleFonts.plusJakartaSans(
                            fontSize: 11, color: AppColors.textSecondary)),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded,
                  size: 18, color: AppColors.textDisabled),
            ],
          ),
        ),
      );
}

class _GradesUnavailable extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(
                color: Color(0x0A000000), blurRadius: 16, offset: Offset(0, 3))
          ],
        ),
        child: Text('Grades not available yet.',
            style: GoogleFonts.plusJakartaSans(
                fontSize: 13, color: AppColors.textSecondary)),
      );
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _QuickAction(
      {required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) => Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 18),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              boxShadow: const [
                BoxShadow(
                    color: Color(0x0A000000),
                    blurRadius: 16,
                    offset: Offset(0, 3))
              ],
            ),
            child: Column(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: const BoxDecoration(
                    color: AppColors.accentBg,
                    shape: BoxShape.circle,
                  ),
                  child:
                      Icon(icon, color: AppColors.accent, size: 22),
                ),
                const SizedBox(height: 10),
                Text(label,
                    style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary)),
              ],
            ),
          ),
        ),
      );
}
