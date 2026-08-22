import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme.dart';
import '../../shared/widgets/empty_state.dart';
import '../../shared/widgets/hero_header.dart';
import '../../shared/widgets/shimmer_card.dart';
import '../home/home_provider.dart';
import 'grades_provider.dart';

class GradesScreen extends ConsumerStatefulWidget {
  const GradesScreen({super.key});

  @override
  ConsumerState<GradesScreen> createState() => _GradesScreenState();
}

class _GradesScreenState extends ConsumerState<GradesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  int _selectedStudentIndex = 0;

  static const _quarters = ['Q1', 'Q2', 'Q3', 'Q4', 'Final'];

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: _quarters.length, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final students = ref.watch(linkedStudentsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          const HeroHeader(
            greeting: 'Track progress',
            name: 'Grades',
            subtitle: 'Quarterly and final marks',
          ),
          Container(
            color: Colors.white,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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

                // Quarter tabs
                TabBar(
                  controller: _tabCtrl,
                  isScrollable: false,
                  labelColor: AppColors.accent,
                  unselectedLabelColor: AppColors.textSecondary,
                  indicatorColor: AppColors.accent,
                  indicatorSize: TabBarIndicatorSize.label,
                  labelStyle: AppTextStyles.custom(fontSize: 13, fontWeight: FontWeight.w700),
                  unselectedLabelStyle: AppTextStyles.custom(fontSize: 13, fontWeight: FontWeight.w500),
                  tabs: _quarters.map((q) => Tab(text: q)).toList(),
                ),
                const Divider(height: 1),
              ],
            ),
          ),

          // ── Body ──────────────────────────────────────────────────────
          Expanded(
            child: students.when(
              loading: () => const ShimmerList(count: 5, itemHeight: 64),
              error: (e, _) => ErrorRetryView(
                onRetry: () => ref.invalidate(linkedStudentsProvider),
              ),
              data: (list) {
                if (list.isEmpty) {
                  return const EmptyState(
                    icon: Icons.bar_chart_rounded,
                    headline: 'No children linked',
                    subtext: 'Link a child first to view their grades.',
                  );
                }
                final student = list[_selectedStudentIndex.clamp(0, list.length - 1)];
                return TabBarView(
                  controller: _tabCtrl,
                  children: List.generate(
                    _quarters.length,
                    (qi) => _GradesTab(
                      studentId: student.id,
                      quarterIndex: qi < 4 ? qi + 1 : 0,
                    ),
                  ),
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

// ── Quarter tab content ───────────────────────────────────────────────────────

class _GradesTab extends ConsumerWidget {
  final int studentId;
  final int quarterIndex; // 1-4 or 0 = final

  const _GradesTab({required this.studentId, required this.quarterIndex});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(gradesProvider(studentId));

    return data.when(
      loading: () => const ShimmerList(count: 6, itemHeight: 64),
      error: (e, _) => ErrorRetryView(
        onRetry: () => ref.invalidate(gradesProvider(studentId)),
      ),
      data: (d) {
        if (d.grades.isEmpty) {
          return const EmptyState(
            icon: Icons.assignment_outlined,
            headline: 'No grades recorded',
            subtext: 'Grades will appear here once they are encoded.',
          );
        }

        final gwa = quarterIndex == 0 ? d.gwa : _quarterGwa(d.grades, quarterIndex);

        return RefreshIndicator(
          color: AppColors.accent,
          onRefresh: () async => ref.invalidate(gradesProvider(studentId)),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            children: [
              if (d.schoolYear != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      Text('S.Y. ${d.schoolYear}',
                          style: AppTextStyles.custom(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.textSecondary)),
                      const Spacer(),
                      if (gwa != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: _gwaColor(gwa).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            'GWA ${gwa.toStringAsFixed(2)}',
                            style: AppTextStyles.custom(fontSize: 12, fontWeight: FontWeight.w700, color: _gwaColor(gwa)),
                          ),
                        ),
                    ],
                  ),
                ),
              const SectionLabel('SUBJECTS'),
              ...d.grades.map((g) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: GradeCard(
                        grade: g, quarterIndex: quarterIndex),
                  )),
            ],
          ),
        );
      },
    );
  }

  double? _quarterGwa(List<GradeEntry> grades, int q) {
    final valid = grades.where((g) => g.gradeForQuarter(q) != null).toList();
    if (valid.isEmpty) return null;
    return valid.fold(0.0, (s, g) => s + g.gradeForQuarter(q)!) / valid.length;
  }

  Color _gwaColor(double gwa) {
    if (gwa <= 1.5) return AppColors.success;
    if (gwa <= 3.0) return AppColors.accent;
    return Colors.red.shade600;
  }
}

// ── Grade card ────────────────────────────────────────────────────────────────

class GradeCard extends StatelessWidget {
  final GradeEntry grade;
  final int quarterIndex;

  const GradeCard({super.key, required this.grade, required this.quarterIndex});

  @override
  Widget build(BuildContext context) {
    final value = grade.gradeForQuarter(quarterIndex);
    final passed = value != null ? value <= 3.0 : grade.isPassed;
    final color = value == null
        ? AppColors.textDisabled
        : value <= 1.5
            ? AppColors.success
            : value <= 3.0
                ? AppColors.accent
                : Colors.red.shade600;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.card),
        boxShadow: kCardShadow,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  grade.subjectName,
                  style: AppTextStyles.bodySemibold,
                ),
                if (quarterIndex == 0 && grade.adjectival.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(
                    grade.adjectival,
                    style: AppTextStyles.custom(fontSize: 11, color: AppColors.textSecondary),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                value != null ? value.toStringAsFixed(2) : '—',
                style: AppTextStyles.custom(fontSize: 18, fontWeight: FontWeight.w800, color: color),
              ),
              if (value != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: (passed ? AppColors.success : Colors.red.shade600)
                        .withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    passed ? 'Passed' : 'Failed',
                    style: AppTextStyles.custom(fontSize: 10, fontWeight: FontWeight.w700, color: passed
                          ? AppColors.success
                          : Colors.red.shade600),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
