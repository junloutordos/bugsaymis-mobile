import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/api_client.dart';
import '../../core/theme.dart';
import '../../shared/widgets/radial_progress_ring.dart';
import '../../shared/widgets/shimmer_card.dart';
import '../../shared/widgets/trend_chart.dart';
import '../attendance/attendance_screen.dart'
    show TimelineList, EmptyDayView;
import 'attendance_summary_provider.dart';

final _studentAttendanceProvider = FutureProvider.autoDispose
    .family<Map<String, dynamic>, String>((ref, date) async {
  final client = ref.read(apiClientProvider);
  final response = await client.get('/student/attendance', params: {'date': date});
  return response.data as Map<String, dynamic>;
});

class StudentAttendanceScreen extends ConsumerStatefulWidget {
  const StudentAttendanceScreen({super.key});

  @override
  ConsumerState<StudentAttendanceScreen> createState() =>
      _StudentAttendanceScreenState();
}

class _StudentAttendanceScreenState
    extends ConsumerState<StudentAttendanceScreen> {
  late DateTime _selectedDate;

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
  }

  /// Rolling 7-day window ending at [_selectedDate] — not a fixed
  /// calendar week, and not hardcoded to "today", so paging the selected
  /// date backward (via the chevrons or the date picker) moves the whole
  /// strip into past weeks/months instead of always showing the current
  /// week regardless of what's selected.
  List<DateTime> get _weekDays => List.generate(
      7, (i) => _selectedDate.subtract(Duration(days: 6 - i)));

  bool get _isCurrentWeek {
    final today = DateTime.now();
    return DateFormat('yyyy-MM-dd').format(_selectedDate) ==
        DateFormat('yyyy-MM-dd').format(today);
  }

  void _shiftWeek(int days) {
    final next = _selectedDate.add(Duration(days: days));
    if (next.isAfter(DateTime.now())) return;
    setState(() => _selectedDate = next);
  }

  @override
  Widget build(BuildContext context) {
    final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
    final logs = ref.watch(_studentAttendanceProvider(dateStr));
    final summary = ref.watch(attendanceSummaryProvider);

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
                    padding: const EdgeInsets.fromLTRB(4, 8, 8, 0),
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back_ios_new_rounded,
                              color: AppColors.textPrimary, size: 20),
                          onPressed: () => context.canPop()
                              ? context.pop()
                              : context.go('/student/home'),
                        ),
                        Expanded(
                          child: Text(
                            'My Attendance',
                            style: AppTextStyles.title,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.calendar_today_outlined,
                              color: AppColors.textSecondary, size: 20),
                          tooltip: 'Pick date',
                          style: IconButton.styleFrom(
                            backgroundColor: AppColors.neutralBg,
                            shape: const CircleBorder(),
                          ),
                          onPressed: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: _selectedDate,
                              firstDate: DateTime(2024),
                              lastDate: DateTime.now(),
                            );
                            if (picked != null) {
                              setState(() => _selectedDate = picked);
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 0),
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.chevron_left_rounded,
                              color: AppColors.textSecondary),
                          tooltip: 'Previous week',
                          onPressed: () => _shiftWeek(-7),
                        ),
                        Expanded(
                          child: Text(
                            _isCurrentWeek
                                ? 'This week'
                                : '${DateFormat('MMM d').format(_weekDays.first)} – ${DateFormat('MMM d').format(_weekDays.last)}',
                            textAlign: TextAlign.center,
                            style: AppTextStyles.custom(
                                fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.chevron_right_rounded,
                              color: AppColors.textSecondary),
                          tooltip: 'Next week',
                          onPressed: _selectedDate.add(const Duration(days: 7)).isAfter(DateTime.now())
                              ? null
                              : () => _shiftWeek(7),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    height: 76,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                      itemCount: _weekDays.length,
                      itemBuilder: (_, i) {
                        final day = _weekDays[i];
                        final isSelected =
                            DateFormat('yyyy-MM-dd').format(day) ==
                                DateFormat('yyyy-MM-dd').format(_selectedDate);
                        final isToday =
                            DateFormat('yyyy-MM-dd').format(day) ==
                                DateFormat('yyyy-MM-dd').format(DateTime.now());

                        return GestureDetector(
                          onTap: () => setState(() => _selectedDate = day),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            width: 48,
                            margin: const EdgeInsets.only(right: 8),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppColors.accent
                                  : AppColors.neutralBg,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  DateFormat('E').format(day)[0],
                                  style: AppTextStyles.custom(fontSize: 11, fontWeight: FontWeight.w500, color: isSelected
                                          ? Colors.white70
                                          : AppColors.textSecondary),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  DateFormat('d').format(day),
                                  style: AppTextStyles.custom(fontSize: 15, fontWeight: FontWeight.w800, color: isSelected
                                          ? Colors.white
                                          : AppColors.textPrimary),
                                ),
                                if (isToday)
                                  Container(
                                    margin: const EdgeInsets.only(top: 3),
                                    width: 4,
                                    height: 4,
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? Colors.white54
                                          : AppColors.accent,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
          const Divider(height: 1),
          summary.maybeWhen(
            data: (s) => Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
              child: Row(
                children: [
                  RadialProgressRing(
                    value: s.monthPresent.toDouble(),
                    max: s.monthSchoolDays.toDouble(),
                    size: 72,
                    strokeWidth: 8,
                    colors: const [AppColors.success, Color(0xFF6EE7B7)],
                    center: Text(
                      s.monthRate != null ? '${(s.monthRate! * 100).round()}%' : '—',
                      style: AppTextStyles.custom(
                          fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.success),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TrendChart(
                      values: s.weekly.map((w) => (w.rate ?? 0) * 100).toList(),
                      labels: s.weekly
                          .map((w) => DateFormat('M/d').format(DateTime.parse(w.weekStart)))
                          .toList(),
                      color: AppColors.success,
                      height: 90,
                    ),
                  ),
                ],
              ),
            ),
            orElse: () => const SizedBox.shrink(),
          ),
          Expanded(
            child: logs.when(
              loading: () => const ShimmerList(count: 4, itemHeight: 72),
              error: (e, _) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.wifi_off_rounded,
                        color: AppColors.textSecondary, size: 48),
                    const SizedBox(height: 12),
                    Text('Could not load logs',
                        style: AppTextStyles.custom(fontSize: 14, color: AppColors.textSecondary)),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: () =>
                          ref.invalidate(_studentAttendanceProvider),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
              data: (data) {
                final list = data['data'] as List;
                return RefreshIndicator(
                  color: AppColors.accent,
                  onRefresh: () async =>
                      ref.invalidate(_studentAttendanceProvider),
                  child: list.isEmpty
                      ? EmptyDayView(date: _selectedDate)
                      : TimelineList(logs: list, date: _selectedDate),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
