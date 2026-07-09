import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/theme.dart';
import '../../shared/widgets/empty_state.dart';
import '../../shared/widgets/shimmer_card.dart';
import '../home/home_provider.dart';
import 'schedule_provider.dart';

class ScheduleScreen extends ConsumerStatefulWidget {
  const ScheduleScreen({super.key});

  @override
  ConsumerState<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends ConsumerState<ScheduleScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  int _selectedStudentIndex = 0;

  static const _days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday'];
  static const _dayLabels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri'];

  @override
  void initState() {
    super.initState();
    final todayIdx = _todayIndex();
    _tabCtrl = TabController(
      length: _days.length,
      vsync: this,
      initialIndex: todayIdx,
    );
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  int _todayIndex() {
    final weekday = DateTime.now().weekday; // 1=Mon … 5=Fri
    final idx = weekday - 1;
    return idx.clamp(0, _days.length - 1);
  }

  @override
  Widget build(BuildContext context) {
    final students = ref.watch(linkedStudentsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // ── Header ────────────────────────────────────────────────────
          Container(
            color: Colors.white,
            child: SafeArea(
              bottom: false,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                    child: Text(
                      'Class Schedule',
                      style: AppTextStyles.screenTitle,
                    ),
                  ),

                  // Child selector chips (if multiple children)
                  students.maybeWhen(
                    data: (list) => list.length > 1
                        ? _ChildChips(
                            students: list,
                            selected: _selectedStudentIndex,
                            onSelect: (i) =>
                                setState(() => _selectedStudentIndex = i),
                          )
                        : const SizedBox(height: 12),
                    orElse: () => const SizedBox(height: 12),
                  ),

                  // Day tabs
                  TabBar(
                    controller: _tabCtrl,
                    isScrollable: false,
                    labelColor: AppColors.accent,
                    unselectedLabelColor: AppColors.textSecondary,
                    indicatorColor: AppColors.accent,
                    indicatorSize: TabBarIndicatorSize.label,
                    labelStyle: AppTextStyles.custom(fontSize: 13, fontWeight: FontWeight.w700),
                    unselectedLabelStyle: AppTextStyles.custom(fontSize: 13, fontWeight: FontWeight.w500),
                    tabs: List.generate(
                      _days.length,
                      (i) => Tab(
                        child: _DayTab(
                          label: _dayLabels[i],
                          isToday: i == _todayIndex(),
                        ),
                      ),
                    ),
                  ),
                  const Divider(height: 1),
                ],
              ),
            ),
          ),

          // ── Body ──────────────────────────────────────────────────────
          Expanded(
            child: students.when(
              loading: () => const ShimmerList(count: 4, itemHeight: 88),
              error: (e, _) => ErrorRetryView(
                onRetry: () => ref.invalidate(linkedStudentsProvider),
              ),
              data: (list) {
                if (list.isEmpty) {
                  return const EmptyState(
                    icon: Icons.grid_view_rounded,
                    headline: 'No children linked',
                    subtext: 'Link a child first to view their schedule.',
                  );
                }
                final student = list[_selectedStudentIndex.clamp(0, list.length - 1)];
                return TabBarView(
                  controller: _tabCtrl,
                  children: _days.map((day) => _DayTab2(
                        studentId: student.id,
                        day: day,
                      )).toList(),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ── Child selector chips ──────────────────────────────────────────────────────

class _ChildChips extends StatelessWidget {
  final List<LinkedStudent> students;
  final int selected;
  final ValueChanged<int> onSelect;

  const _ChildChips({
    required this.students,
    required this.selected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) => SizedBox(
        height: 44,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
          itemCount: students.length,
          itemBuilder: (_, i) {
            final s = students[i];
            final active = i == selected;
            return GestureDetector(
              onTap: () => onSelect(i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                margin: const EdgeInsets.only(right: 8),
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: active ? AppColors.accent : AppColors.neutralBg,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  s.fullName.split(',').first.trim(),
                  style: AppTextStyles.custom(fontSize: 12, fontWeight: FontWeight.w600, color: active ? Colors.white : AppColors.textSecondary),
                ),
              ),
            );
          },
        ),
      );
}

// ── Day tab indicator ─────────────────────────────────────────────────────────

class _DayTab extends StatelessWidget {
  final String label;
  final bool isToday;

  const _DayTab({required this.label, required this.isToday});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label),
            if (isToday)
              Container(
                margin: const EdgeInsets.only(top: 3),
                width: 4,
                height: 4,
                decoration: const BoxDecoration(
                  color: AppColors.accent,
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
      );
}

// ── Day content ───────────────────────────────────────────────────────────────

class _DayTab2 extends ConsumerWidget {
  final int studentId;
  final String day;

  const _DayTab2({required this.studentId, required this.day});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(scheduleProvider(studentId));

    return data.when(
      loading: () => const ShimmerList(count: 4, itemHeight: 88),
      error: (e, _) => ErrorRetryView(
        onRetry: () => ref.invalidate(scheduleProvider(studentId)),
      ),
      data: (d) {
        final slots = d.byDay[day] ?? [];

        if (d.sectionName != null || d.schoolYear != null)
        {}

        return RefreshIndicator(
          color: AppColors.accent,
          onRefresh: () async => ref.invalidate(scheduleProvider(studentId)),
          child: slots.isEmpty
              ? _EmptyDay(day: day)
              : ListView(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                  children: [
                    if (d.sectionName != null || d.schoolYear != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Row(
                          children: [
                            if (d.sectionName != null)
                              InfoChip(
                                icon: Icons.group_outlined,
                                label: 'Grade ${d.gradeLevel} — ${d.sectionName}',
                              ),
                            const Spacer(),
                            if (d.schoolYear != null)
                              Text('S.Y. ${d.schoolYear}',
                                  style: AppTextStyles.custom(fontSize: 12, color: AppColors.textSecondary)),
                          ],
                        ),
                      ),
                    const SectionLabel('CLASSES'),
                    ...slots.map((s) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: ClassCard(slot: s),
                        )),
                  ],
                ),
        );
      },
    );
  }
}

class _EmptyDay extends StatelessWidget {
  final String day;
  const _EmptyDay({required this.day});

  @override
  Widget build(BuildContext context) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: const BoxDecoration(
                  color: AppColors.neutralBg, shape: BoxShape.circle),
              child: const Icon(Icons.free_breakfast_outlined,
                  size: 34, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),
            Text('No classes on $day',
                style: AppTextStyles.custom(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
            const SizedBox(height: 6),
            Text('Enjoy the free day',
                style: AppTextStyles.custom(fontSize: 13, color: AppColors.textSecondary)),
          ],
        ),
      );
}

class InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const InfoChip({super.key, required this.icon, required this.label});

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: AppColors.textSecondary),
          const SizedBox(width: 4),
          Text(label,
              style: AppTextStyles.custom(fontSize: 12, color: AppColors.textSecondary)),
        ],
      );
}

// ── Class card ────────────────────────────────────────────────────────────────

class ClassCard extends StatelessWidget {
  final ClassSlot slot;
  const ClassCard({super.key, required this.slot});

  @override
  Widget build(BuildContext context) {
    final start = _fmt(slot.startTime);
    final end = _fmt(slot.endTime);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: const Border(
            left: BorderSide(color: AppColors.accent, width: 3)),
        boxShadow: kCardShadow,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Time column
          SizedBox(
            width: 60,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(start,
                    style: AppTextStyles.custom(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.accent)),
                Text(end,
                    style: AppTextStyles.custom(fontSize: 11, color: AppColors.textSecondary)),
                if (slot.durationMin != null) ...[
                  const SizedBox(height: 4),
                  Text('${slot.durationMin}m',
                      style: AppTextStyles.custom(fontSize: 10, color: AppColors.textDisabled)),
                ],
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Subject + teacher
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  slot.subjectName,
                  style: AppTextStyles.custom(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                ),
                if (slot.subjectCode != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    slot.subjectCode!,
                    style: AppTextStyles.custom(fontSize: 11, color: AppColors.textSecondary),
                  ),
                ],
                if (slot.teacherName != null) ...[
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.person_outline_rounded,
                          size: 12, color: AppColors.textSecondary),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          slot.teacherName!,
                          style: AppTextStyles.custom(fontSize: 12, color: AppColors.textSecondary),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _fmt(String timeStr) {
    try {
      final t = DateFormat('HH:mm:ss').parse(timeStr);
      return DateFormat('h:mm a').format(t);
    } catch (_) {
      return timeStr;
    }
  }
}
