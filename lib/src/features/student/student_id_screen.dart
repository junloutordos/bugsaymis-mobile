import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:screen_brightness/screen_brightness.dart';
import 'dart:math' as math;
import '../../core/theme.dart';
import '../../shared/widgets/pressable.dart';
import 'student_id_card_back.dart';
import 'student_id_card_front.dart';
import 'student_provider.dart';

/// Full-screen digital student ID, opened from Profile → "Digital Student
/// ID". Mirrors the physical CR-80 card printed via
/// resources/js/Pages/Students/IdCard.vue field-for-field (see
/// StudentIdCardFront/StudentIdCardBack); the button below the card flips
/// between the front and back faces the same way the physical card's two
/// sides do. Boosts screen brightness while visible so gate scanners can
/// read the front's barcode.
class StudentIdScreen extends ConsumerStatefulWidget {
  const StudentIdScreen({super.key});

  @override
  ConsumerState<StudentIdScreen> createState() => _StudentIdScreenState();
}

class _StudentIdScreenState extends ConsumerState<StudentIdScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _flipController;
  bool _showingBack = false;

  @override
  void initState() {
    super.initState();
    _flipController = AnimationController(vsync: this, duration: AppMotion.slow);
    ScreenBrightness.instance
        .setApplicationScreenBrightness(1.0)
        .catchError((_) {});
  }

  @override
  void dispose() {
    _flipController.dispose();
    ScreenBrightness.instance
        .resetApplicationScreenBrightness()
        .catchError((_) {});
    super.dispose();
  }

  void _flip() {
    setState(() => _showingBack = !_showingBack);
    if (_showingBack) {
      _flipController.forward();
    } else {
      _flipController.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    final card = ref.watch(studentIdCardProvider);

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
                    child: Icon(Icons.close_rounded, color: Colors.white, size: 26),
                  ),
                ),
              ),
            ),
            Expanded(
              child: Center(
                child: card.when(
                  loading: () => const CircularProgressIndicator(
                      color: Colors.white, strokeWidth: 2.5),
                  error: (_, _) => _ErrorView(
                    onRetry: () => ref.invalidate(studentIdCardProvider),
                  ),
                  data: (c) => LayoutBuilder(
                    builder: (context, constraints) {
                      // Nearly fills the screen: fit by width, then by
                      // whatever height is left after the flip button
                      // below it, whichever is smaller — keeps the card
                      // at its true 54:86 CR-80 aspect ratio on every
                      // device instead of overflowing vertically.
                      const cardAspect = 54 / 86;
                      final widthBudget = constraints.maxWidth - 24;
                      final heightBudget = constraints.maxHeight - 80;
                      final cardWidth = widthBudget < heightBudget * cardAspect
                          ? widthBudget
                          : heightBudget * cardAspect;
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            AnimatedBuilder(
                              animation: _flipController,
                              builder: (context, _) {
                                final angle = _flipController.value * math.pi;
                                final isBackHalf = _flipController.value >= 0.5;
                                return Transform(
                                  alignment: Alignment.center,
                                  transform: Matrix4.identity()
                                    ..setEntry(3, 2, 0.0015)
                                    ..rotateY(angle),
                                  child: isBackHalf
                                      ? Transform(
                                          alignment: Alignment.center,
                                          transform: Matrix4.identity()..rotateY(math.pi),
                                          child: StudentIdCardBack(card: c, cardWidth: cardWidth),
                                        )
                                      : StudentIdCardFront(card: c, cardWidth: cardWidth),
                                );
                              },
                            ),
                            SizedBox(height: AppSpacing.lg),
                            OutlinedButton.icon(
                              onPressed: _flip,
                              icon: const Icon(Icons.flip_camera_ios_outlined, color: Colors.white, size: 18),
                              label: Text(
                                _showingBack ? 'Show Front' : 'Show Back',
                                style: AppTextStyles.custom(
                                    fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white),
                              ),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.white,
                                side: const BorderSide(color: Colors.white38),
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(AppRadius.button)),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
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
