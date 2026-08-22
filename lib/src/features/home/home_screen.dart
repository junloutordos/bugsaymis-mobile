import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/theme.dart';
import '../../shared/widgets/hero_header.dart';
import '../../shared/widgets/shimmer_card.dart';
import '../auth/auth_provider.dart';
import '../notices/announcements_card.dart';
import '../notices/notice_queue_dialog.dart';
import 'home_provider.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    watchPendingNotices(context, ref);

    final user     = ref.watch(authStateProvider).value;
    final students = ref.watch(linkedStudentsProvider);
    final greeting = _greeting();
    final firstName = user?.name.split(' ').first ?? 'Parent';
    final dateStr   = DateFormat('EEEE, MMMM d').format(DateTime.now());

    return Scaffold(
      backgroundColor: AppColors.background,
      body: RefreshIndicator(
        color: AppColors.accent,
        onRefresh: () async => ref.invalidate(linkedStudentsProvider),
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            HeroHeader(
              greeting: greeting,
              name: firstName,
              subtitle: dateStr,
              actionIcon: Icons.person_outline_rounded,
              actionTooltip: 'Profile',
              onActionTap: () => context.push('/profile'),
              trailing: students.maybeWhen(
                data: (list) => _LinkedCountChip(count: list.length),
                orElse: () => null,
              ),
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: AnnouncementsCard(),
            ),
            AnimatedSwitcher(
              duration: AppMotion.slow,
              switchInCurve: AppMotion.standard,
              switchOutCurve: AppMotion.standard,
              child: students.when(
                loading: () => const _HomeLoadingList(key: ValueKey('loading')),
                error: (e, _) => _ErrorView(
                    key: const ValueKey('error'),
                    onRetry: () => ref.invalidate(linkedStudentsProvider)),
                data: (list) => list.isEmpty
                    ? _EmptyState(key: const ValueKey('empty'))
                    : _StudentListColumn(
                        key: const ValueKey('list'), students: list),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good morning,';
    if (h < 17) return 'Good afternoon,';
    return 'Good evening,';
  }
}

// ── Student list ──────────────────────────────────────────────────────────────

class _StudentListColumn extends StatelessWidget {
  final List<LinkedStudent> students;
  const _StudentListColumn({super.key, required this.students});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionLabel('YOUR CHILDREN TODAY'),
            for (final s in students)
              Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: _StudentCard(student: s),
              ),
          ],
        ),
      );
}

class _HomeLoadingList extends StatelessWidget {
  const _HomeLoadingList({super.key});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
        child: Column(
          children: List.generate(
            3,
            (_) => const Padding(
              padding: EdgeInsets.only(bottom: 14),
              child: ShimmerCard(height: 130),
            ),
          ),
        ),
      );
}

class _LinkedCountChip extends StatelessWidget {
  final int count;
  const _LinkedCountChip({required this.count});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.16),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.family_restroom_rounded, size: 14, color: Colors.white),
            const SizedBox(width: 6),
            Text(
              count == 1 ? '1 child linked' : '$count children linked',
              style: AppTextStyles.custom(
                  fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white),
            ),
          ],
        ),
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
      error: (_, _) => _errorCard(student),
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
      onTap: () => context.go('/attendance',
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
                        style: AppTextStyles.cardTitle),
                    if (student.relationship != null)
                      Text(_capitalize(student.relationship!),
                          style: AppTextStyles.custom(fontSize: 12, color: AppColors.textSecondary)),
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
                    style: AppTextStyles.custom(fontSize: 12, color: AppColors.textSecondary)),
                if (s.logs.isNotEmpty && s.logs.last.gateLocation != null) ...[
                  const Text('  ·  ',
                      style: TextStyle(color: AppColors.textDisabled)),
                  Text(s.logs.last.gateLocation!,
                      style: AppTextStyles.custom(fontSize: 12, color: AppColors.textSecondary)),
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
                    style: AppTextStyles.custom(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.accent)),
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
          borderRadius: BorderRadius.circular(AppRadius.card),
          border: const Border(
              left: BorderSide(color: AppColors.textDisabled, width: 4)),
          boxShadow: kCardShadow,
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
                      style: AppTextStyles.cardTitle),
                  const SizedBox(height: 4),
                  Text('Could not load status',
                      style: AppTextStyles.custom(fontSize: 12, color: AppColors.textSecondary)),
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
            style: AppTextStyles.sectionHeader.copyWith(color: color),
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
              style: AppTextStyles.custom(fontSize: 9, fontWeight: FontWeight.w700, color: isIn ? AppColors.successText : AppColors.warningText)),
          Text(time,
              style: AppTextStyles.custom(fontSize: 10, color: isIn ? AppColors.successText : AppColors.warningText)),
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
                  style: AppTextStyles.title),
              const SizedBox(height: 8),
              Text(
                'Link your child\'s ID card to start\nreceiving gate notifications.',
                textAlign: TextAlign.center,
                style: AppTextStyles.custom(fontSize: 13, color: AppColors.textSecondary, height: 1.6),
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
                style: AppTextStyles.custom(fontSize: 14, color: AppColors.textSecondary)),
            const SizedBox(height: 12),
            TextButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      );
}
