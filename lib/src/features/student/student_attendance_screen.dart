import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../core/api_client.dart';
import '../../core/theme.dart';
import '../../shared/widgets/shimmer_card.dart';
import '../attendance/attendance_screen.dart'
    show TimelineList, EmptyDayView;
import 'student_nav.dart';

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

  List<DateTime> get _weekDays {
    final today = DateTime.now();
    return List.generate(7, (i) => today.subtract(Duration(days: 6 - i)));
  }

  @override
  Widget build(BuildContext context) {
    final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
    final logs = ref.watch(_studentAttendanceProvider(dateStr));

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
                            style: GoogleFonts.plusJakartaSans(
                                color: AppColors.textPrimary,
                                fontSize: 17,
                                fontWeight: FontWeight.w700),
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
                                  style: GoogleFonts.plusJakartaSans(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500,
                                      color: isSelected
                                          ? Colors.white70
                                          : AppColors.textSecondary),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  DateFormat('d').format(day),
                                  style: GoogleFonts.plusJakartaSans(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w800,
                                      color: isSelected
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
                        style: GoogleFonts.plusJakartaSans(
                            color: AppColors.textSecondary, fontSize: 14)),
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
      bottomNavigationBar: const StudentBottomNav(currentIndex: 1),
    );
  }
}
