import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/api_client.dart';
import '../../core/theme.dart';
import '../../shared/widgets/empty_state.dart';
import '../../shared/widgets/shimmer_card.dart';
import 'portal_provider.dart';
import 'portal_widgets.dart';

const _purposeLabels = <String, String>{
  'go_home': 'Go Home',
  'school_activity': 'School Activity',
  'other': 'Other',
};

/// Dorm leave passes — history list + "File Leave Pass" bottom sheet.
/// Non-dormers see an eligibility message.
class LeavePassesScreen extends ConsumerWidget {
  const LeavePassesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(leavePassesProvider);
    final isDormer = data.value?['intern'] != null;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Leave Passes')),
      floatingActionButton: isDormer
          ? FloatingActionButton.extended(
              backgroundColor: AppColors.accent,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add_rounded),
              label: Text('File Leave Pass',
                  style: AppTextStyles.custom(fontSize: 13, fontWeight: FontWeight.w600)),
              onPressed: () => _openFileSheet(context, ref),
            )
          : null,
      body: RefreshIndicator(
        color: AppColors.accent,
        onRefresh: () async => ref.invalidate(leavePassesProvider),
        child: data.when(
          loading: () => const ShimmerList(count: 4, itemHeight: 92),
          error: (e, _) => ListView(
            padding: const EdgeInsets.fromLTRB(20, 60, 20, 24),
            children: [
              ErrorRetryView(
                message: friendlyError(e),
                onRetry: () => ref.invalidate(leavePassesProvider),
              ),
            ],
          ),
          data: (d) {
            if (d['intern'] == null) {
              return ListView(
                padding: const EdgeInsets.fromLTRB(20, 80, 20, 24),
                children: const [
                  EmptyState(
                    icon: Icons.night_shelter_rounded,
                    headline: 'For active dormers only',
                    subtext:
                        'Leave passes are available to students currently accommodated in the Residence Hall.',
                  ),
                ],
              );
            }

            final passes = (d['leavePasses'] as List?) ?? const [];
            if (passes.isEmpty) {
              return ListView(
                padding: const EdgeInsets.fromLTRB(20, 80, 20, 24),
                children: const [
                  EmptyState(
                    icon: Icons.assignment_return_rounded,
                    headline: 'No leave passes yet',
                    subtext:
                        'File a leave pass before going out of the Residence Hall. Your Dorm Manager approves it.',
                  ),
                ],
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 90),
              itemCount: passes.length,
              itemBuilder: (_, i) =>
                  _PassCard(pass: passes[i] as Map<String, dynamic>),
            );
          },
        ),
      ),
    );
  }

  void _openFileSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => const _FileLeavePassSheet(),
    );
  }
}

class _PassCard extends StatelessWidget {
  final Map<String, dynamic> pass;
  const _PassCard({required this.pass});

  String _fmt(dynamic raw) {
    if (raw == null) return '—';
    try {
      return DateFormat('MMM d, y · h:mm a')
          .format(DateTime.parse(raw.toString()).toLocal());
    } catch (_) {
      return raw.toString();
    }
  }

  @override
  Widget build(BuildContext context) {
    final purpose = pass['purpose']?.toString() ?? 'other';

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(_purposeLabels[purpose] ?? purpose,
                      style: AppTextStyles.custom(fontSize: 14, fontWeight: FontWeight.w700)),
                ),
                PortalStatusChip.forStatus(
                    pass['status']?.toString() ?? 'pending'),
              ],
            ),
            const SizedBox(height: 8),
            _InfoRow(
                icon: Icons.place_rounded,
                text: pass['destination']?.toString() ?? '—'),
            _InfoRow(
                icon: Icons.schedule_rounded,
                text: 'Return by ${_fmt(pass['expected_return_at'])}'),
            _InfoRow(
                icon: Icons.history_rounded,
                text: 'Filed ${_fmt(pass['created_at'])}'),
            if ((pass['remarks']?.toString() ?? '').isNotEmpty)
              _InfoRow(
                  icon: Icons.comment_rounded,
                  text: pass['remarks'].toString()),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;
  const _InfoRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Row(
          children: [
            Icon(icon, size: 14, color: AppColors.textSecondary),
            const SizedBox(width: 6),
            Expanded(
              child: Text(text,
                  style: AppTextStyles.custom(fontSize: 12, color: AppColors.textSecondary)),
            ),
          ],
        ),
      );
}

class _FileLeavePassSheet extends ConsumerStatefulWidget {
  const _FileLeavePassSheet();

  @override
  ConsumerState<_FileLeavePassSheet> createState() =>
      _FileLeavePassSheetState();
}

class _FileLeavePassSheetState extends ConsumerState<_FileLeavePassSheet> {
  bool _saving = false;
  String _purpose = 'go_home';
  DateTime? _returnAt;
  bool _withCompanion = false;
  final _destination = TextEditingController();
  final _companionName = TextEditingController();
  final _companionContact = TextEditingController();

  @override
  void dispose() {
    _destination.dispose();
    _companionName.dispose();
    _companionContact.dispose();
    super.dispose();
  }

  Future<void> _pickReturn() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now,
      lastDate: now.add(const Duration(days: 60)),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 17, minute: 0),
    );
    if (time == null) return;
    setState(() => _returnAt =
        DateTime(date.year, date.month, date.day, time.hour, time.minute));
  }

  Future<void> _submit() async {
    if (_destination.text.trim().isEmpty || _returnAt == null) {
      showErrorSnack(context, 'Destination and expected return are required.');
      return;
    }
    setState(() => _saving = true);
    try {
      await ref.read(apiClientProvider).post(
        '/student/portal/leave-passes',
        data: {
          'purpose': _purpose,
          'destination': _destination.text.trim(),
          'expected_return_at':
              DateFormat('yyyy-MM-dd HH:mm:ss').format(_returnAt!),
          'with_companion': _withCompanion,
          'companion_name': _withCompanion && _companionName.text.trim().isNotEmpty
              ? _companionName.text.trim()
              : null,
          'companion_contact':
              _withCompanion && _companionContact.text.trim().isNotEmpty
                  ? _companionContact.text.trim()
                  : null,
        },
      );
      ref.invalidate(leavePassesProvider);
      if (mounted) {
        Navigator.of(context).pop();
        showSuccessSnack(
            context, 'Leave pass filed. Await your Dorm Manager\'s approval.');
      }
    } catch (e) {
      if (mounted) showErrorSnack(context, friendlyError(e));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => Padding(
        padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                      color: AppColors.border,
                      borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: 16),
              Text('File a Leave Pass',
                  style: AppTextStyles.custom(fontSize: 17, fontWeight: FontWeight.w800)),
              const SizedBox(height: 16),
              ChoicePicker(
                label: 'Purpose',
                options: const ['go_home', 'school_activity', 'other'],
                optionLabels: const ['Go Home', 'School Activity', 'Other'],
                value: _purpose,
                onChanged: (v) => setState(() => _purpose = v ?? 'go_home'),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _destination,
                style: AppTextStyles.custom(fontSize: 14),
                decoration: const InputDecoration(labelText: 'Destination'),
              ),
              const SizedBox(height: 14),
              InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: _pickReturn,
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Expected return',
                    suffixIcon: Icon(Icons.schedule_rounded, size: 18),
                  ),
                  child: Text(
                    _returnAt == null
                        ? 'Select date & time'
                        : DateFormat('MMM d, y · h:mm a').format(_returnAt!),
                    style: AppTextStyles.custom(fontSize: 14, color: _returnAt == null
                            ? AppColors.textDisabled
                            : AppColors.textPrimary),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              SwitchListTile(
                value: _withCompanion,
                onChanged: (v) => setState(() => _withCompanion = v),
                title: Text('With companion',
                    style: AppTextStyles.custom(fontSize: 14)),
                contentPadding: EdgeInsets.zero,
                activeTrackColor: AppColors.accent,
              ),
              if (_withCompanion) ...[
                TextField(
                  controller: _companionName,
                  style: AppTextStyles.custom(fontSize: 14),
                  decoration:
                      const InputDecoration(labelText: 'Companion name'),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _companionContact,
                  keyboardType: TextInputType.phone,
                  style: AppTextStyles.custom(fontSize: 14),
                  decoration:
                      const InputDecoration(labelText: 'Companion contact'),
                ),
                const SizedBox(height: 8),
              ],
              const SizedBox(height: 12),
              GradientButton(
                text: 'File Leave Pass',
                isLoading: _saving,
                onPressed: _saving ? null : _submit,
              ),
            ],
          ),
        ),
      );
}
