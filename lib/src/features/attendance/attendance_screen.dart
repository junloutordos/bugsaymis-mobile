import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/api_client.dart';
import '../../core/theme.dart';
import '../../shared/widgets/hero_header.dart';
import '../../shared/widgets/shimmer_card.dart';

// ── Provider ──────────────────────────────────────────────────────────────────

final _attendanceLogsProvider = FutureProvider.autoDispose
    .family<Map<String, dynamic>, ({int? studentId, String date})>(
        (ref, args) async {
  final client = ref.read(apiClientProvider);
  final response = await client.get('/attendance', params: {
    'date': args.date,
    if (args.studentId != null) 'student_id': args.studentId.toString(),
  });
  return response.data as Map<String, dynamic>;
});

// ── Screen ────────────────────────────────────────────────────────────────────

class AttendanceScreen extends ConsumerStatefulWidget {
  final int? studentId;
  final String? studentName;

  const AttendanceScreen({super.key, this.studentId, this.studentName});

  @override
  ConsumerState<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends ConsumerState<AttendanceScreen> {
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
    final logs = ref.watch(
        _attendanceLogsProvider((studentId: widget.studentId, date: dateStr)));

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          HeroHeader(
            leading: context.canPop() ? HeroBackButton(onTap: () => context.pop()) : null,
            greeting: 'Attendance',
            name: widget.studentName ?? 'History',
            subtitle: DateFormat('EEEE, MMMM d').format(_selectedDate),
            actionIcon: Icons.calendar_today_outlined,
            actionTooltip: 'Pick date',
            onActionTap: () async {
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
          Container(
            color: Colors.white,
            child: SizedBox(
              height: 76,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                itemCount: _weekDays.length,
                itemBuilder: (_, i) {
                  final day = _weekDays[i];
                  final isSelected = DateFormat('yyyy-MM-dd').format(day) ==
                      DateFormat('yyyy-MM-dd').format(_selectedDate);
                  final isToday = DateFormat('yyyy-MM-dd').format(day) ==
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
          ),

          const Divider(height: 1),

          // ── Body ──────────────────────────────────────────────────────
          Expanded(
            child: logs.when(
              loading: () =>
                  const ShimmerList(count: 4, itemHeight: 72),
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
                      onPressed: () => ref.invalidate(_attendanceLogsProvider),
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
                      ref.invalidate(_attendanceLogsProvider),
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

// ── Timeline list ─────────────────────────────────────────────────────────────

// ignore: library_private_types_in_public_api (intentionally exported for student screen)
class TimelineList extends StatelessWidget {
  final List logs;
  final DateTime date;
  const TimelineList({super.key, required this.logs, required this.date});

  @override
  Widget build(BuildContext context) => ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
        children: [
          SummaryStrip(logs: logs),
          const SizedBox(height: 20),
          const SectionLabel('GATE SCAN TIMELINE'),
          ...List.generate(logs.length, (i) {
            final log = logs[i] as Map<String, dynamic>;
            final isLast = i == logs.length - 1;
            return TimelineItem(log: log, isLast: isLast);
          }),
        ],
      );
}

class SummaryStrip extends StatelessWidget {
  final List logs;
  const SummaryStrip({super.key, required this.logs});

  @override
  Widget build(BuildContext context) {
    final lastLog = logs.isNotEmpty ? logs.last as Map<String, dynamic> : null;
    final isLastIn = lastLog?['type'] == 'in';
    final color = isLastIn ? AppColors.success : AppColors.warning;
    String lastTime = '—';
    if (lastLog?['scan_time'] != null) {
      try {
        lastTime = DateFormat('h:mm a')
            .format(DateTime.parse(lastLog!['scan_time']).toLocal());
      } catch (_) {}
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        boxShadow: kCardShadow,
      ),
      child: Row(
        children: [
          Icon(Icons.bar_chart_rounded,
              color: AppColors.textSecondary, size: 18),
          const SizedBox(width: 8),
          Text('${logs.length} scan${logs.length == 1 ? '' : 's'}',
              style: AppTextStyles.custom(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
          const Spacer(),
          if (lastLog != null) ...[
            Text('Last: ',
                style: AppTextStyles.custom(fontSize: 12, color: AppColors.textSecondary)),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(10)),
              child: Text(
                '${isLastIn ? 'Time In' : 'Time Out'}  $lastTime',
                style: AppTextStyles.custom(fontSize: 12, fontWeight: FontWeight.w600, color: color),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class TimelineItem extends StatelessWidget {
  final Map<String, dynamic> log;
  final bool isLast;
  const TimelineItem({super.key, required this.log, required this.isLast});

  @override
  Widget build(BuildContext context) {
    final isIn = log['type'] == 'in';
    final color = isIn ? AppColors.success : AppColors.warning;
    final bg    = isIn ? AppColors.successBg : AppColors.warningBg;

    String time = '—';
    try {
      time = DateFormat('h:mm:ss a')
          .format(DateTime.parse(log['scan_time']).toLocal());
    } catch (_) {}

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Timeline rail
          SizedBox(
            width: 40,
            child: Column(
              children: [
                Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                            color: color.withValues(alpha: 0.35),
                            blurRadius: 6,
                            spreadRadius: 1)
                      ]),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      color: AppColors.border,
                      margin: const EdgeInsets.symmetric(vertical: 4),
                    ),
                  ),
                if (isLast) const SizedBox(height: 24),
              ],
            ),
          ),

          // Content card
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppRadius.card),
                  boxShadow: kCardShadow,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration:
                          BoxDecoration(color: bg, shape: BoxShape.circle),
                      child: Icon(
                        isIn ? Icons.login_rounded : Icons.logout_rounded,
                        color: color,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (log['student_name'] != null)
                            Text(log['student_name'],
                                style: AppTextStyles.fieldLabel),
                          Text(time,
                              style: AppTextStyles.custom(fontSize: 13, fontWeight: log['student_name'] != null
                                      ? FontWeight.w400
                                      : FontWeight.w600, color: AppColors.textPrimary)),
                          if (log['gate_location'] != null)
                            Text(log['gate_location'],
                                style: AppTextStyles.custom(fontSize: 12, color: AppColors.textSecondary)),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: bg,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        log['type_label'] ?? (isIn ? 'Time In' : 'Time Out'),
                        style: AppTextStyles.custom(fontSize: 11, fontWeight: FontWeight.w700, color: color),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class EmptyDayView extends StatelessWidget {
  final DateTime date;
  const EmptyDayView({super.key, required this.date});

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
              child: const Icon(Icons.event_busy_rounded,
                  size: 36, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),
            Text('No scans on this day',
                style: AppTextStyles.custom(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
            const SizedBox(height: 6),
            Text(DateFormat('MMMM d, y').format(date),
                style: AppTextStyles.custom(fontSize: 13, color: AppColors.textSecondary)),
          ],
        ),
      );
}
