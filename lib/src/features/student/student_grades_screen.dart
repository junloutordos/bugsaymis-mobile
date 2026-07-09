import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme.dart';
import '../../shared/widgets/empty_state.dart';
import '../../shared/widgets/shimmer_card.dart';
import '../grades/grades_provider.dart';
import '../grades/grades_screen.dart' show GradeCard;

class StudentGradesScreen extends ConsumerStatefulWidget {
  const StudentGradesScreen({super.key});

  @override
  ConsumerState<StudentGradesScreen> createState() =>
      _StudentGradesScreenState();
}

class _StudentGradesScreenState extends ConsumerState<StudentGradesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
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
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
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
                      'My Grades',
                      style: AppTextStyles.screenTitle,
                    ),
                  ),
                  const SizedBox(height: 4),
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
          ),
          Expanded(
            child: TabBarView(
              controller: _tabCtrl,
              children: List.generate(
                _quarters.length,
                (qi) => _StudentGradesTab(quarterIndex: qi < 4 ? qi + 1 : 0),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StudentGradesTab extends ConsumerWidget {
  final int quarterIndex;
  const _StudentGradesTab({required this.quarterIndex});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(studentGradesProvider);

    return data.when(
      loading: () => const ShimmerList(count: 6, itemHeight: 64),
      error: (e, _) => ErrorRetryView(
        onRetry: () => ref.invalidate(studentGradesProvider),
      ),
      data: (d) {
        if (d.grades.isEmpty) {
          return const EmptyState(
            icon: Icons.assignment_outlined,
            headline: 'No grades recorded',
            subtext: 'Grades will appear here once they are encoded.',
          );
        }

        final gwa = quarterIndex == 0
            ? d.gwa
            : _quarterGwa(d.grades, quarterIndex);

        return RefreshIndicator(
          color: AppColors.accent,
          onRefresh: () async => ref.invalidate(studentGradesProvider),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            children: [
              if (d.schoolYear != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      Text('S.Y. ${d.schoolYear}',
                          style: AppTextStyles.custom(fontSize: 12, color: AppColors.textSecondary)),
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
                    child: GradeCard(grade: g, quarterIndex: quarterIndex),
                  )),
            ],
          ),
        );
      },
    );
  }

  double? _quarterGwa(List<GradeEntry> grades, int q) {
    final valid =
        grades.where((g) => g.gradeForQuarter(q) != null).toList();
    if (valid.isEmpty) return null;
    return valid.fold(0.0, (s, g) => s + g.gradeForQuarter(q)!) /
        valid.length;
  }

  Color _gwaColor(double gwa) {
    if (gwa <= 1.5) return AppColors.success;
    if (gwa <= 3.0) return AppColors.accent;
    return Colors.red.shade600;
  }
}
