import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/api_client.dart';
import '../../core/theme.dart';
import '../../shared/widgets/empty_state.dart';
import '../../shared/widgets/shimmer_card.dart';
import 'portal_provider.dart';
import 'portal_widgets.dart';

/// Residence Hall accommodation application — state-based:
/// active dormer / approved / under review / rejected / application form.
class RhApplicationScreen extends ConsumerWidget {
  const RhApplicationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(rhApplicationProvider);

    return PortalSubScreen(
      title: 'RH Application',
      body: RefreshIndicator(
        color: AppColors.accent,
        onRefresh: () async => ref.invalidate(rhApplicationProvider),
        child: data.when(
          loading: () => const ShimmerList(count: 3, itemHeight: 110),
          error: (e, _) => ListView(
            padding: const EdgeInsets.fromLTRB(20, 60, 20, 24),
            children: [
              ErrorRetryView(
                message: friendlyError(e),
                onRetry: () => ref.invalidate(rhApplicationProvider),
              ),
            ],
          ),
          data: (d) {
            final intern = d['intern'] as Map<String, dynamic>?;
            final application = d['application'] as Map<String, dynamic>?;
            final status = application?['status'] as String?;

            if (intern != null) {
              return _statusView(
                icon: Icons.night_shelter_rounded,
                color: AppColors.success,
                bg: AppColors.successBg,
                headline: 'You are an active dormer',
                body:
                    'You are currently accommodated in the Residence Hall for S.Y. ${d['school_year'] ?? '—'}. Visit the Leave Passes page to file a pass when going out.',
              );
            }
            if (status == 'approved') {
              return _statusView(
                icon: Icons.celebration_rounded,
                color: AppColors.success,
                bg: AppColors.successBg,
                headline: 'Application approved!',
                body:
                    'Your Residence Hall application has been approved. The RH staff will contact you about your room assignment and move-in.',
              );
            }
            if (status != null &&
                ['pending', 'evaluated', 'waitlisted'].contains(status)) {
              return _statusView(
                icon: Icons.hourglass_top_rounded,
                color: AppColors.warning,
                bg: AppColors.warningBg,
                headline: status == 'waitlisted'
                    ? 'You are on the waitlist'
                    : 'Application under review',
                body:
                    'Your application for the ${application!['preferred_hall']} was submitted${_submittedOn(application)}. The Residence Hall Committee will notify you of the result.',
              );
            }
            if (status == 'rejected') {
              return _statusView(
                icon: Icons.info_outline_rounded,
                color: Colors.red.shade600,
                bg: const Color(0xFFFEE2E2),
                headline: 'Application not approved',
                body:
                    'Unfortunately your Residence Hall application for this school year was not approved. You may contact the RH Committee for details.',
              );
            }

            return _ApplicationForm(data: d);
          },
        ),
      ),
    );
  }

  String _submittedOn(Map<String, dynamic> application) {
    final raw = application['created_at']?.toString();
    if (raw == null) return '';
    try {
      return ' on ${DateFormat('MMMM d, y').format(DateTime.parse(raw).toLocal())}';
    } catch (_) {
      return '';
    }
  }

  Widget _statusView({
    required IconData icon,
    required Color color,
    required Color bg,
    required String headline,
    required String body,
  }) =>
      ListView(
        padding: const EdgeInsets.fromLTRB(20, 40, 20, 24),
        children: [
          AppCard(
            padding: const EdgeInsets.all(28),
            child: Column(
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
                  child: Icon(icon, size: 34, color: color),
                ),
                const SizedBox(height: 18),
                Text(headline,
                    textAlign: TextAlign.center,
                    style: AppTextStyles.custom(fontSize: 17, fontWeight: FontWeight.w700)),
                const SizedBox(height: 10),
                Text(body,
                    textAlign: TextAlign.center,
                    style: AppTextStyles.custom(fontSize: 13, color: AppColors.textSecondary, height: 1.6)),
              ],
            ),
          ),
        ],
      );
}

class _ApplicationForm extends ConsumerStatefulWidget {
  final Map<String, dynamic> data;
  const _ApplicationForm({required this.data});

  @override
  ConsumerState<_ApplicationForm> createState() => _ApplicationFormState();
}

class _ApplicationFormState extends ConsumerState<_ApplicationForm> {
  bool _saving = false;
  String? _hall;
  late final TextEditingController _province;
  final _distance = TextEditingController();
  final _scholarship = TextEditingController();
  final _fosterName = TextEditingController();
  final _fosterContact = TextEditingController();
  final _fosterAddress = TextEditingController();

  @override
  void initState() {
    super.initState();
    _hall = widget.data['suggestedHall'] as String? ?? 'BRH';
    final student = widget.data['student'] as Map<String, dynamic>?;
    _province =
        TextEditingController(text: student?['province'] as String? ?? '');
  }

  @override
  void dispose() {
    _province.dispose();
    _distance.dispose();
    _scholarship.dispose();
    _fosterName.dispose();
    _fosterContact.dispose();
    _fosterAddress.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _saving = true);
    try {
      await ref.read(apiClientProvider).post(
        '/student/portal/rh-application',
        data: {
          'preferred_hall': _hall,
          'home_province': _province.text.trim(),
          'estimated_distance_km': int.tryParse(_distance.text.trim()),
          'scholarship_category': _scholarship.text.trim().isEmpty
              ? null
              : _scholarship.text.trim(),
          'foster_parent_name': _fosterName.text.trim(),
          'foster_parent_contact': _fosterContact.text.trim(),
          'foster_parent_address': _fosterAddress.text.trim(),
        },
      );
      refreshPortal(ref);
      if (mounted) {
        showSuccessSnack(context,
            'Application submitted. The RH Committee will review it.');
      }
    } catch (e) {
      if (mounted) showErrorSnack(context, friendlyError(e));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
        children: [
          Text(
            'Apply for dormitory accommodation for S.Y. ${widget.data['school_year'] ?? '—'}.',
            style: AppTextStyles.custom(fontSize: 13, color: AppColors.textSecondary, height: 1.5),
          ),
          const SizedBox(height: 16),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ChoicePicker(
                  label: 'Preferred hall',
                  options: const ['BRH', 'GRH'],
                  optionLabels: const [
                    "Boys' Residence Hall",
                    "Girls' Residence Hall"
                  ],
                  value: _hall,
                  onChanged: (v) => setState(() => _hall = v ?? 'BRH'),
                ),
                const SizedBox(height: 18),
                TextField(
                  controller: _province,
                  style: AppTextStyles.custom(fontSize: 14),
                  decoration:
                      const InputDecoration(labelText: 'Home province'),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _distance,
                  keyboardType: TextInputType.number,
                  style: AppTextStyles.custom(fontSize: 14),
                  decoration: const InputDecoration(
                      labelText: 'Estimated distance from campus (km)'),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _scholarship,
                  style: AppTextStyles.custom(fontSize: 14),
                  decoration: const InputDecoration(
                      labelText: 'Scholarship category (optional)'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const SectionLabel('FOSTER PARENT / GUARDIAN IN THE AREA'),
          AppCard(
            child: Column(
              children: [
                TextField(
                  controller: _fosterName,
                  style: AppTextStyles.custom(fontSize: 14),
                  decoration: const InputDecoration(labelText: 'Full name'),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _fosterContact,
                  keyboardType: TextInputType.phone,
                  style: AppTextStyles.custom(fontSize: 14),
                  decoration:
                      const InputDecoration(labelText: 'Contact number'),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _fosterAddress,
                  style: AppTextStyles.custom(fontSize: 14),
                  decoration: const InputDecoration(labelText: 'Address'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          GradientButton(
            text: 'Submit Application',
            isLoading: _saving,
            onPressed: _saving ? null : _submit,
          ),
        ],
      );
}
