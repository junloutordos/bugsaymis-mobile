import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../core/theme.dart';
import '../../shared/widgets/shimmer_card.dart';
import '../auth/auth_provider.dart';
import 'home_provider.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user     = ref.watch(authStateProvider).value;
    final students = ref.watch(linkedStudentsProvider);
    final greeting = _greeting();
    final firstName = user?.name.split(' ').first ?? 'Parent';
    final dateStr   = DateFormat('EEEE, MMMM d').format(DateTime.now());

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // ── White header ──────────────────────────────────────────────
          AppHeader(
            greeting: greeting,
            name: firstName,
            subtitle: dateStr,
            actions: [
              _HeaderIconBtn(
                icon: Icons.person_outline_rounded,
                tooltip: 'Profile',
                onTap: () => context.push('/profile'),
              ),
            ],
          ),

          // ── Body ──────────────────────────────────────────────────────
          Expanded(
            child: RefreshIndicator(
              color: AppColors.accent,
              onRefresh: () async => ref.invalidate(linkedStudentsProvider),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                switchInCurve: Curves.easeOut,
                switchOutCurve: Curves.easeIn,
                child: students.when(
                  loading: () => const ShimmerList(
                      key: ValueKey('loading'), count: 3, itemHeight: 130),
                  error: (e, _) => _ErrorView(
                      key: const ValueKey('error'),
                      onRetry: () => ref.invalidate(linkedStudentsProvider)),
                  data: (list) => list.isEmpty
                      ? _EmptyState(key: const ValueKey('empty'))
                      : _StudentList(key: const ValueKey('list'), students: list),
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: const BottomNav(currentIndex: 0),
    );
  }

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good morning,';
    if (h < 17) return 'Good afternoon,';
    return 'Good evening,';
  }
}

// ── Header icon button ────────────────────────────────────────────────────────

class _HeaderIconBtn extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  const _HeaderIconBtn(
      {required this.icon, required this.tooltip, required this.onTap});

  @override
  Widget build(BuildContext context) => Semantics(
        label: tooltip,
        button: true,
        child: Padding(
          padding: const EdgeInsets.only(left: 4),
          child: IconButton(
            icon: Icon(icon, size: 20),
            tooltip: tooltip,
            onPressed: onTap,
            style: IconButton.styleFrom(
              foregroundColor: AppColors.textSecondary,
              backgroundColor: AppColors.neutralBg,
              shape: const CircleBorder(),
              minimumSize: const Size(38, 38),
              maximumSize: const Size(38, 38),
              padding: EdgeInsets.zero,
            ),
            constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
          ),
        ),
      );
}

// ── Student list ──────────────────────────────────────────────────────────────

class _StudentList extends StatelessWidget {
  final List<LinkedStudent> students;
  const _StudentList({super.key, required this.students});

  @override
  Widget build(BuildContext context) => ListView.builder(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
        itemCount: students.length + 1,
        itemBuilder: (_, i) {
          if (i == 0) return const SectionLabel('YOUR CHILDREN TODAY');
          return Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: _StudentCard(student: students[i - 1]),
          );
        },
      );
}

// ── Student card ──────────────────────────────────────────────────────────────

class _StudentCard extends ConsumerWidget {
  final LinkedStudent student;
  const _StudentCard({required this.student});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summary = ref.watch(todaySummaryProvider(student.id));

    return summary.when(
      loading: () => _loadingCard(),
      error: (_, __) => _errorCard(student),
      data: (s) => _dataCard(context, s, student),
    );
  }

  Widget _dataCard(BuildContext context, TodaySummary s, LinkedStudent student) {
    final isIn  = s.lastStatus == 'in';
    final isOut = s.lastStatus == 'out';
    final accentColor = isIn
        ? AppColors.success
        : isOut
            ? AppColors.warning
            : AppColors.textDisabled;

    return AccentCard(
      accentColor: accentColor,
      onTap: () => context.push('/attendance',
          extra: {'studentId': student.id, 'studentName': student.fullName}),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Name row
          Row(
            children: [
              _Avatar(name: s.studentName, color: accentColor),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(s.studentName,
                        style: GoogleFonts.plusJakartaSans(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary)),
                    if (student.relationship != null)
                      Text(_capitalize(student.relationship!),
                          style: GoogleFonts.plusJakartaSans(
                              fontSize: 12, color: AppColors.textSecondary)),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded,
                  color: AppColors.textDisabled, size: 20),
            ],
          ),

          const SizedBox(height: 12),

          // Status badge
          StatusBadge(status: s.lastStatus),

          // Last scan info
          if (s.lastScan != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.access_time_rounded,
                    size: 13, color: AppColors.textSecondary),
                const SizedBox(width: 4),
                Text(_formatTime(s.lastScan!),
                    style: GoogleFonts.plusJakartaSans(
                        fontSize: 12, color: AppColors.textSecondary)),
                if (s.logs.isNotEmpty && s.logs.last.gateLocation != null) ...[
                  const Text('  ·  ',
                      style: TextStyle(color: AppColors.textDisabled)),
                  Text(s.logs.last.gateLocation!,
                      style: GoogleFonts.plusJakartaSans(
                          fontSize: 12, color: AppColors.textSecondary)),
                ],
              ],
            ),
          ],

          // Scan chips
          if (s.logs.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 10),
            Row(
              children: [
                ...s.logs.take(4).map((log) => _ScanChip(log: log)),
                const Spacer(),
                Text('View all →',
                    style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        color: AppColors.accent,
                        fontWeight: FontWeight.w600)),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _loadingCard() => const ShimmerCard(height: 130);

  Widget _errorCard(LinkedStudent student) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: const Border(
              left: BorderSide(color: AppColors.textDisabled, width: 4)),
          boxShadow: const [
            BoxShadow(
                color: Color(0x0A000000), blurRadius: 20, offset: Offset(0, 4))
          ],
        ),
        child: Row(
          children: [
            _Avatar(name: student.fullName, color: AppColors.textDisabled),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(student.fullName,
                      style: GoogleFonts.plusJakartaSans(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary)),
                  const SizedBox(height: 4),
                  Text('Could not load status',
                      style: GoogleFonts.plusJakartaSans(
                          fontSize: 12, color: AppColors.textSecondary)),
                ],
              ),
            ),
          ],
        ),
      );

  String _capitalize(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

  String _formatTime(String iso) {
    try {
      return DateFormat('h:mm a').format(DateTime.parse(iso).toLocal());
    } catch (_) {
      return '—';
    }
  }
}

class _Avatar extends StatelessWidget {
  final String name;
  final Color color;
  const _Avatar({required this.name, required this.color});

  @override
  Widget build(BuildContext context) => Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              color.withValues(alpha: 0.12),
              color.withValues(alpha: 0.24),
            ],
          ),
          shape: BoxShape.circle,
        ),
        child: Center(
          child: Text(
            name.isNotEmpty ? name[0].toUpperCase() : '?',
            style: GoogleFonts.plusJakartaSans(
                color: color, fontWeight: FontWeight.w700, fontSize: 18),
          ),
        ),
      );
}

class _ScanChip extends StatelessWidget {
  final ScanEntry log;
  const _ScanChip({required this.log});

  @override
  Widget build(BuildContext context) {
    final isIn = log.type == 'in';
    String time = '—';
    try {
      time = DateFormat('h:mm a')
          .format(DateTime.parse(log.scanTime).toLocal());
    } catch (_) {}

    return Container(
      margin: const EdgeInsets.only(right: 6),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isIn ? AppColors.successBg : AppColors.warningBg,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Text(isIn ? 'IN' : 'OUT',
              style: GoogleFonts.plusJakartaSans(
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  color: isIn ? AppColors.successText : AppColors.warningText)),
          Text(time,
              style: GoogleFonts.plusJakartaSans(
                  fontSize: 10,
                  color: isIn ? AppColors.successText : AppColors.warningText)),
        ],
      ),
    );
  }
}

// ── Empty / error states ──────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState({super.key});

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppColors.accentBg,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.person_search_rounded,
                    size: 40, color: AppColors.accent),
              ),
              const SizedBox(height: 20),
              Text('No children linked yet',
                  style: GoogleFonts.plusJakartaSans(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary)),
              const SizedBox(height: 8),
              Text(
                'Link your child\'s ID card to start\nreceiving gate notifications.',
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                    height: 1.6),
              ),
              const SizedBox(height: 28),
              SizedBox(
                width: 200,
                child: GradientButton(
                  text: 'Link Child',
                  icon: const Icon(Icons.add_rounded,
                      color: Colors.white, size: 18),
                  onPressed: () => context.push('/children/link'),
                ),
              ),
            ],
          ),
        ),
      );
}

class _ErrorView extends StatelessWidget {
  final VoidCallback onRetry;
  const _ErrorView({super.key, required this.onRetry});

  @override
  Widget build(BuildContext context) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.wifi_off_rounded,
                size: 48, color: AppColors.textSecondary),
            const SizedBox(height: 12),
            Text('Could not load data',
                style: GoogleFonts.plusJakartaSans(
                    fontSize: 14, color: AppColors.textSecondary)),
            const SizedBox(height: 12),
            TextButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      );
}

// ── Bottom nav — floating with rounded top ────────────────────────────────────

class BottomNav extends StatelessWidget {
  final int currentIndex;
  const BottomNav({super.key, required this.currentIndex});

  @override
  Widget build(BuildContext context) => Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          boxShadow: kNavShadow,
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          child: NavigationBar(
            selectedIndex: currentIndex,
            backgroundColor: AppColors.surface,
            elevation: 0,
            onDestinationSelected: (i) {
              switch (i) {
                case 0: context.go('/home');
                case 1: context.go('/attendance');
                case 2: context.go('/grades');
                case 3: context.go('/schedule');
              }
            },
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.home_outlined),
                selectedIcon: Icon(Icons.home_rounded),
                label: 'Home',
              ),
              NavigationDestination(
                icon: Icon(Icons.calendar_month_outlined),
                selectedIcon: Icon(Icons.calendar_month_rounded),
                label: 'Attendance',
              ),
              NavigationDestination(
                icon: Icon(Icons.bar_chart_rounded),
                selectedIcon: Icon(Icons.bar_chart_rounded),
                label: 'Grades',
              ),
              NavigationDestination(
                icon: Icon(Icons.grid_view_outlined),
                selectedIcon: Icon(Icons.grid_view_rounded),
                label: 'Schedule',
              ),
            ],
          ),
        ),
      );
}
