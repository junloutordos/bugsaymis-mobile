import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme.dart';
import '../../shared/widgets/empty_state.dart';
import '../../shared/widgets/shimmer_card.dart';
import '../schedule/schedule_provider.dart';
import '../schedule/schedule_screen.dart' show ClassCard, InfoChip;
import 'package:go_router/go_router.dart';

class StudentScheduleScreen extends ConsumerStatefulWidget {
  const StudentScheduleScreen({super.key});

  @override
  ConsumerState<StudentScheduleScreen> createState() =>
      _StudentScheduleScreenState();
}

class _StudentScheduleScreenState
    extends ConsumerState<StudentScheduleScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;

  static const _days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday'];
  static const _dayLabels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri'];

  @override
  void initState() {
    super.initState();
    final todayIdx = (DateTime.now().weekday - 1).clamp(0, 4);
    _tabCtrl = TabController(
        length: _days.length, vsync: this, initialIndex: todayIdx);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final todayIdx = (DateTime.now().weekday - 1).clamp(0, 4);

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
                    padding: const EdgeInsets.fromLTRB(4, 8, 20, 0),
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back_ios_new_rounded,
                              color: AppColors.textPrimary, size: 20),
                          onPressed: () => context.canPop()
                              ? context.pop()
                              : context.go('/student/home'),
                        ),
                        Text(
                          'My Schedule',
                          style: AppTextStyles.stat,
                        ),
                      ],
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
                    tabs: List.generate(
                      _days.length,
                      (i) => Tab(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(_dayLabels[i]),
                              if (i == todayIdx)
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
                        ),
                      ),
                    ),
                  ),
                  const Divider(height: 1),
                ],
              ),
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabCtrl,
              children: _days
                  .map((day) => _StudentDayView(day: day))
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _StudentDayView extends ConsumerWidget {
  final String day;
  const _StudentDayView({required this.day});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(studentScheduleProvider);

    return data.when(
      loading: () => const ShimmerList(count: 4, itemHeight: 88),
      error: (e, _) => ErrorRetryView(
        onRetry: () => ref.invalidate(studentScheduleProvider),
      ),
      data: (d) {
        final slots = d.byDay[day] ?? [];

        return RefreshIndicator(
          color: AppColors.accent,
          onRefresh: () async => ref.invalidate(studentScheduleProvider),
          child: slots.isEmpty
              ? Center(
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
                )
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
                                label:
                                    'Grade ${d.gradeLevel} — ${d.sectionName}',
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
