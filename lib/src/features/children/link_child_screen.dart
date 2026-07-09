import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../core/api_client.dart';
import '../../core/theme.dart';
import '../home/home_provider.dart';

class LinkChildScreen extends ConsumerStatefulWidget {
  const LinkChildScreen({super.key});

  @override
  ConsumerState<LinkChildScreen> createState() => _LinkChildScreenState();
}

class _LinkChildScreenState extends ConsumerState<LinkChildScreen> {
  final _idCtrl = TextEditingController();
  final _scannerController = MobileScannerController();

  String _relationship = 'guardian';
  bool _submitting = false;
  bool _sent = false;

  @override
  void dispose() {
    _idCtrl.dispose();
    _scannerController.dispose();
    super.dispose();
  }

  void _openScanner() {
    try {
      showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.black,
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
        builder: (_) => SizedBox(
          height: 440,
          child: Column(
            children: [
              const SizedBox(height: 16),
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2)),
              ),
              const SizedBox(height: 14),
              Text('Point at student\'s ID barcode',
                  style: AppTextStyles.custom(fontSize: 13, color: Colors.white70)),
              const SizedBox(height: 14),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: kIsWeb
                        ? _noCameraPlaceholder()
                        : MobileScanner(
                            controller: _scannerController,
                            errorBuilder: (context, error) =>
                                _noCameraPlaceholder(),
                            onDetect: (capture) {
                              final barcode =
                                  capture.barcodes.firstOrNull?.rawValue;
                              if (barcode != null && barcode.isNotEmpty) {
                                if (context.canPop()) { context.pop(); } else { context.go('/children'); }
                                _idCtrl.text = barcode;
                              }
                            },
                          ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ).whenComplete(() {
        try {
          _scannerController.stop();
        } catch (_) {}
      });
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content:
                Text('Camera not available. Please type the ID manually.')),
      );
    }
  }

  Future<void> _sendRequest() async {
    final id = _idCtrl.text.trim();
    if (id.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter the student ID number.')),
      );
      return;
    }

    setState(() => _submitting = true);
    try {
      final client = ref.read(apiClientProvider);
      await client.post('/link-requests', data: {
        'student_id'  : id,
        'relationship': _relationship,
      });

      ref.invalidate(linkRequestsProvider);

      if (mounted) setState(() => _sent = true);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to send request. Check your connection.'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: AppColors.background,
        body: Column(
          children: [
            // ── White header with back button ──────────────────────────
            Container(
              color: Colors.white,
              child: SafeArea(
                bottom: false,
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(4, 8, 16, 12),
                      child: Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.arrow_back_ios_new_rounded,
                                color: AppColors.textPrimary, size: 20),
                            onPressed: () => context.pop(),
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Add a Child',
                                    style: AppTextStyles.title),
                                Text(
                                    'A confirmation will be sent to the student',
                                    style: AppTextStyles.custom(fontSize: 12, color: AppColors.textSecondary)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1),
                  ],
                ),
              ),
            ),

            Expanded(
              child: _sent ? _successState() : _formState(),
            ),
          ],
        ),
      );

  Widget _formState() => SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Privacy notice
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.accentBg,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                    color: AppColors.accent.withValues(alpha: 0.2)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.privacy_tip_outlined,
                      color: AppColors.accent, size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'For the student\'s privacy, their information is not shown. '
                      'A confirmation email will be sent to the student\'s registered email. '
                      'They must approve before you can track their attendance.',
                      style: AppTextStyles.custom(fontSize: 12, color: AppColors.accent, height: 1.5),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Student ID field
            LabelledField(
              label: 'Student PISAY System ID',
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _idCtrl,
                      decoration: const InputDecoration(
                        hintText: '24-XXXX-X-XXXX',
                        prefixIcon: Icon(Icons.badge_outlined,
                            color: AppColors.textSecondary, size: 18),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    height: 50,
                    width: 50,
                    child: OutlinedButton(
                      onPressed: _openScanner,
                      style: OutlinedButton.styleFrom(
                        padding: EdgeInsets.zero,
                        side: const BorderSide(color: AppColors.border),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Icon(Icons.qr_code_scanner_rounded,
                          color: AppColors.accent, size: 22),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Relationship selector
            Text('Your relationship to the student',
                style: AppTextStyles.fieldLabel),
            const SizedBox(height: 10),
            _RelationshipSelector(
              selected: _relationship,
              onChanged: (v) => setState(() => _relationship = v),
            ),

            const SizedBox(height: 28),

            // Submit button
            SizedBox(
              width: double.infinity,
              child: GradientButton(
                text: _submitting
                    ? 'Sending request…'
                    : 'Send Confirmation Request',
                isLoading: _submitting,
                icon: _submitting
                    ? null
                    : const Icon(Icons.send_rounded,
                        color: Colors.white, size: 18),
                onPressed: _submitting ? null : _sendRequest,
              ),
            ),
          ],
        ),
      );

  Widget _successState() => Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: const BoxDecoration(
                  color: AppColors.successBg,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.mark_email_read_rounded,
                    size: 40, color: AppColors.success),
              ),
              const SizedBox(height: 20),
              Text('Request Sent!',
                  style: AppTextStyles.custom(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
              const SizedBox(height: 12),
              Text(
                'A confirmation email has been sent to the student\'s registered email address.\n\n'
                'They must approve your request before you can track their attendance. '
                'You can check the status of pending requests in the Children screen.',
                textAlign: TextAlign.center,
                style: AppTextStyles.custom(fontSize: 13, color: AppColors.textSecondary, height: 1.6),
              ),
              const SizedBox(height: 28),
              SizedBox(
                width: 200,
                child: GradientButton(
                  text: 'Back to Children',
                  onPressed: () => context.pop(),
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => setState(() {
                  _sent = false;
                  _idCtrl.clear();
                  _relationship = 'guardian';
                }),
                child: Text('Add another child',
                    style: AppTextStyles.custom(fontSize: 13, color: AppColors.accent)),
              ),
            ],
          ),
        ),
      );

  Widget _noCameraPlaceholder() => Container(
        decoration: BoxDecoration(
          color: Colors.grey.shade900,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.videocam_off_rounded,
                color: Colors.white38, size: 48),
            const SizedBox(height: 12),
            Text('Camera not available',
                style: AppTextStyles.custom(fontSize: 14, color: Colors.white54)),
            const SizedBox(height: 6),
            Text('Please type the ID number manually',
                style: AppTextStyles.custom(fontSize: 12, color: Colors.white38)),
          ],
        ),
      );
}

class _RelationshipSelector extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onChanged;

  const _RelationshipSelector(
      {required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) => Row(
        children: [
          _Chip(
              label: 'Father',
              value: 'father',
              selected: selected,
              onTap: onChanged),
          const SizedBox(width: 8),
          _Chip(
              label: 'Mother',
              value: 'mother',
              selected: selected,
              onTap: onChanged),
          const SizedBox(width: 8),
          _Chip(
              label: 'Guardian',
              value: 'guardian',
              selected: selected,
              onTap: onChanged),
        ],
      );
}

class _Chip extends StatelessWidget {
  final String label;
  final String value;
  final String selected;
  final ValueChanged<String> onTap;

  const _Chip(
      {required this.label,
      required this.value,
      required this.selected,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isSelected = selected == value;
    return GestureDetector(
      onTap: () => onTap(value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.accent : AppColors.neutralBg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
              color: isSelected ? AppColors.accent : AppColors.border),
        ),
        child: Text(label,
            style: AppTextStyles.custom(fontSize: 13, fontWeight: FontWeight.w500, color: isSelected
                    ? Colors.white
                    : AppColors.textSecondary)),
      ),
    );
  }
}
