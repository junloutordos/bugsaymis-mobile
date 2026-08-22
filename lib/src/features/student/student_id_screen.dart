import 'package:barcode_widget/barcode_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:screen_brightness/screen_brightness.dart';
import '../../core/theme.dart';
import '../../shared/widgets/pressable.dart';
import 'student_provider.dart';

/// The physical school IDs' symbology is not verifiable from this repo —
/// flip to Barcode.code39() if the gate scanners reject Code 128.
final _idSymbology = Barcode.code128();

/// Full-screen digital student ID, opened from the nav's center button.
/// Boosts screen brightness while visible so gate scanners can read it.
class StudentIdScreen extends ConsumerStatefulWidget {
  const StudentIdScreen({super.key});

  @override
  ConsumerState<StudentIdScreen> createState() => _StudentIdScreenState();
}

class _StudentIdScreenState extends ConsumerState<StudentIdScreen> {
  @override
  void initState() {
    super.initState();
    // Application-level brightness auto-restores when the app backgrounds.
    ScreenBrightness.instance
        .setApplicationScreenBrightness(1.0)
        .catchError((_) {});
  }

  @override
  void dispose() {
    ScreenBrightness.instance
        .resetApplicationScreenBrightness()
        .catchError((_) {});
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(studentProfileProvider);

    return Scaffold(
      backgroundColor: AppColors.primary,
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 12, 0),
                child: Pressable(
                  onTap: () => context.pop(),
                  borderRadius: BorderRadius.circular(24),
                  child: const Padding(
                    padding: EdgeInsets.all(8),
                    child: Icon(Icons.close_rounded,
                        color: Colors.white, size: 26),
                  ),
                ),
              ),
            ),
            Expanded(
              child: Center(
                child: profile.when(
                  loading: () => const CircularProgressIndicator(
                      color: Colors.white, strokeWidth: 2.5),
                  error: (_, _) => _ErrorView(
                    onRetry: () => ref.invalidate(studentProfileProvider),
                  ),
                  data: (p) => SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(28, 8, 28, 24),
                    child: _IdCard(profile: p),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _IdCard extends StatelessWidget {
  final StudentProfile profile;
  const _IdCard({required this.profile});

  @override
  Widget build(BuildContext context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.all(Radius.circular(AppRadius.sheet)),
          boxShadow: kFormShadow,
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _header(),
            Container(height: 4, decoration: const BoxDecoration(gradient: AppGradients.button)),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
              child: Column(
                children: [
                  _avatar(),
                  const SizedBox(height: 14),
                  Text(profile.name,
                      textAlign: TextAlign.center,
                      style: AppTextStyles.screenTitle.copyWith(fontSize: 20)),
                  const SizedBox(height: 4),
                  Text(
                    (profile.gradeLevel != null && profile.section != null)
                        ? 'Grade ${profile.gradeLevel} — ${profile.section}'
                        : 'Student',
                    style: AppTextStyles.bodyMedium
                        .copyWith(color: AppColors.textSecondary),
                  ),
                  if (profile.schoolYear != null) ...[
                    const SizedBox(height: 2),
                    Text('S.Y. ${profile.schoolYear}',
                        style: AppTextStyles.caption),
                  ],
                  const SizedBox(height: 20),
                  _barcodeBlock(),
                ],
              ),
            ),
            Container(
              width: double.infinity,
              color: AppColors.background,
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
              child: Text(
                'Present this screen at the campus gate scanner',
                textAlign: TextAlign.center,
                style: AppTextStyles.caption,
              ),
            ),
          ],
        ),
      );

  Widget _header() => Container(
        color: AppColors.primary,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: Row(
          children: [
            Image.asset(
              'assets/images/pshs_logo.png',
              height: 36,
              errorBuilder: (_, _, _) => const Icon(Icons.school_rounded,
                  color: Colors.white, size: 32),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Philippine Science High School',
                      style: AppTextStyles.caption.copyWith(
                          color: Colors.white70, fontSize: 11)),
                  Text('Caraga Region Campus',
                      style: AppTextStyles.cardTitle
                          .copyWith(color: Colors.white, fontSize: 13)),
                ],
              ),
            ),
            Image.asset(
              'assets/images/atlasgo_mark.png',
              height: 24,
              errorBuilder: (_, _, _) => const SizedBox.shrink(),
            ),
          ],
        ),
      );

  Widget _avatar() => Container(
        width: 72,
        height: 72,
        decoration: const BoxDecoration(
          gradient: AppGradients.button,
          shape: BoxShape.circle,
        ),
        child: Center(
          child: Text(
            profile.name.isNotEmpty ? profile.name[0].toUpperCase() : '?',
            style: AppTextStyles.screenTitle
                .copyWith(color: Colors.white, fontSize: 30),
          ),
        ),
      );

  Widget _barcodeBlock() {
    final barcode = profile.barcode;
    if (barcode == null || barcode.isEmpty) {
      return Column(
        children: [
          const Icon(Icons.qr_code_2_rounded,
              size: 48, color: AppColors.textDisabled),
          const SizedBox(height: 8),
          Text('No ID barcode on file',
              style: AppTextStyles.bodySemibold
                  .copyWith(color: AppColors.textSecondary)),
          const SizedBox(height: 4),
          Text('Contact the MIS office to have your ID activated',
              textAlign: TextAlign.center, style: AppTextStyles.caption),
        ],
      );
    }

    // White padding all around = the quiet zone scanners need.
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppRadius.field),
            border: Border.all(color: AppColors.borderLight),
          ),
          child: BarcodeWidget(
            barcode: _idSymbology,
            data: barcode,
            height: 88,
            drawText: false,
            color: Colors.black,
            errorBuilder: (_, _) => Text(barcode,
                textAlign: TextAlign.center,
                style: AppTextStyles.bodySemibold),
          ),
        ),
        const SizedBox(height: 8),
        Text(barcode,
            style: AppTextStyles.bodyMedium.copyWith(letterSpacing: 2)),
      ],
    );
  }
}

class _ErrorView extends StatelessWidget {
  final VoidCallback onRetry;
  const _ErrorView({required this.onRetry});

  @override
  Widget build(BuildContext context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.wifi_off_rounded, color: Colors.white54, size: 44),
          const SizedBox(height: 12),
          Text('Could not load your ID',
              style: AppTextStyles.bodyMedium.copyWith(color: Colors.white)),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: onRetry,
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white,
              side: const BorderSide(color: Colors.white38),
            ),
            child: const Text('Retry'),
          ),
        ],
      );
}
