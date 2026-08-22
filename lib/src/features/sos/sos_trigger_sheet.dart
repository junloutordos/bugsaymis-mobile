import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import '../../core/api_client.dart';
import '../../core/theme.dart';
import 'sos_provider.dart';

const _categories = [
  ('medical', 'Medical', Icons.favorite_rounded),
  ('security', 'Security', Icons.shield_rounded),
  ('fire_disaster', 'Fire / Disaster', Icons.local_fire_department_rounded),
  ('general', 'General', Icons.pan_tool_rounded),
];

/// Opens the SOS flow. `silent: true` skips straight to dispatch with no
/// visible UI (the long-press/duress path) — `silent: false` opens the
/// normal category-picker sheet.
void showSosTriggerSheet(BuildContext context, {required bool silent}) {
  if (silent) {
    HapticFeedback.mediumImpact();
    _dispatch(context, alertType: 'security', isSilent: true);
    return;
  }

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const _SosSheet(),
  );
}

class _SosSheet extends ConsumerStatefulWidget {
  const _SosSheet();

  @override
  ConsumerState<_SosSheet> createState() => _SosSheetState();
}

enum _Phase { picking, holding, counting, sent, blocked }

class _SosSheetState extends ConsumerState<_SosSheet> {
  _Phase _phase = _Phase.picking;
  String? _category;
  double _holdProgress = 0;
  int _countdown = 8;
  String? _blockedMessage;
  String? _hotline;
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _selectCategory(String value) => setState(() => _category = value);

  void _startHold(int holdSeconds) {
    setState(() {
      _phase = _Phase.holding;
      _holdProgress = 0;
    });
    const stepMs = 50;
    final totalSteps = (holdSeconds * 1000) / stepMs;
    var step = 0;
    _timer = Timer.periodic(const Duration(milliseconds: stepMs), (t) {
      step++;
      setState(() => _holdProgress = (step / totalSteps).clamp(0, 1));
      if (step >= totalSteps) {
        t.cancel();
        _startCountdown();
      }
    });
  }

  void _cancelHold() {
    _timer?.cancel();
    setState(() => _phase = _Phase.picking);
  }

  void _startCountdown() {
    final countdownSeconds = ref.read(sosConfigProvider).value?['countdown_seconds'] as int? ?? 8;
    setState(() {
      _phase = _Phase.counting;
      _countdown = countdownSeconds;
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      setState(() => _countdown--);
      if (_countdown <= 0) {
        t.cancel();
        _dispatch(context, alertType: _category!, isSilent: false).then((result) {
          if (!mounted) return;

          if (result.$1) {
            setState(() {
              _phase = _Phase.blocked;
              _blockedMessage = result.$2;
              _hotline = result.$3;
            });
            return;
          }

          final alertId = result.$4;
          if (alertId == null) {
            // Defensive fallback — the backend contract always returns
            // alert_id on success, but degrade to the static confirmation
            // rather than navigate nowhere if that ever changes.
            setState(() => _phase = _Phase.sent);
            return;
          }

          final router = GoRouter.of(context);
          Navigator.of(context).pop();
          router.push('/sos/active/$alertId');
        });
      }
    });
  }

  void _cancelCountdown() {
    _timer?.cancel();
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final config = ref.watch(sosConfigProvider);
    final holdSeconds = config.value?['hold_confirm_seconds'] as int? ?? 3;

    return Container(
      padding: EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.xl, AppSpacing.xl,
          AppSpacing.xl + MediaQuery.of(context).viewInsets.bottom),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.sheet)),
      ),
      child: switch (_phase) {
        _Phase.blocked => _BlockedView(message: _blockedMessage!, hotline: _hotline!),
        _Phase.sent => const _SentView(),
        _Phase.counting => _CountdownView(seconds: _countdown, onCancel: _cancelCountdown),
        _ => _PickerView(
            selected: _category,
            holding: _phase == _Phase.holding,
            holdProgress: _holdProgress,
            onSelect: _selectCategory,
            onHoldStart: () => _startHold(holdSeconds),
            onHoldCancel: _cancelHold,
          ),
      },
    );
  }
}

Future<(bool, String?, String?, int?)> _dispatch(
  BuildContext context, {
  required String alertType,
  required bool isSilent,
}) async {
  final container = ProviderScope.containerOf(context, listen: false);
  final coords = await _captureLocation();

  try {
    final response = await container.read(apiClientProvider).post(
      '/student/portal/sos/trigger',
      data: {
        'alert_type': alertType,
        'is_silent': isSilent,
        'lat': coords?.latitude,
        'lng': coords?.longitude,
        'accuracy': coords?.accuracy,
      },
    );
    final alertId = (response.data as Map)['alert_id'] as int?;
    return (false, null, null, alertId);
  } on DioException catch (e) {
    if (e.response?.statusCode == 422 && e.response?.data?['blocked'] == true) {
      return (
        true,
        e.response?.data['message'] as String?,
        e.response?.data['emergency_hotline'] as String?,
        null,
      );
    }
    rethrow;
  }
}

Future<Position?> _captureLocation() async {
  try {
    final permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      final requested = await Geolocator.requestPermission();
      if (requested == LocationPermission.denied ||
          requested == LocationPermission.deniedForever) {
        return null;
      }
    }
    return await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high, timeLimit: Duration(seconds: 5)),
    );
  } catch (_) {
    return null;
  }
}

class _PickerView extends StatelessWidget {
  final String? selected;
  final bool holding;
  final double holdProgress;
  final ValueChanged<String> onSelect;
  final VoidCallback onHoldStart;
  final VoidCallback onHoldCancel;

  const _PickerView({
    required this.selected,
    required this.holding,
    required this.holdProgress,
    required this.onSelect,
    required this.onHoldStart,
    required this.onHoldCancel,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Emergency SOS', style: AppTextStyles.title),
        SizedBox(height: AppSpacing.sm),
        Text('What kind of emergency is this?', style: AppTextStyles.body),
        SizedBox(height: AppSpacing.lg),
        GridView.count(
          shrinkWrap: true,
          crossAxisCount: 2,
          mainAxisSpacing: AppSpacing.sm,
          crossAxisSpacing: AppSpacing.sm,
          childAspectRatio: 2.4,
          physics: const NeverScrollableScrollPhysics(),
          children: _categories.map((c) {
            final isSelected = selected == c.$1;
            return OutlinedButton.icon(
              onPressed: () => onSelect(c.$1),
              icon: Icon(c.$3, size: 18),
              label: Text(c.$2),
              style: OutlinedButton.styleFrom(
                backgroundColor: isSelected ? AppColors.accentBg : null,
                foregroundColor: isSelected ? AppColors.accent : AppColors.textSecondary,
                side: BorderSide(color: isSelected ? AppColors.accent : AppColors.border),
              ),
            );
          }).toList(),
        ),
        if (selected != null) ...[
          SizedBox(height: AppSpacing.xl),
          GestureDetector(
            onLongPressStart: (_) => onHoldStart(),
            onLongPressEnd: (_) => onHoldCancel(),
            onLongPressCancel: onHoldCancel,
            child: Container(
              height: 52,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Colors.red.shade600,
                borderRadius: BorderRadius.circular(AppRadius.button),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  FractionallySizedBox(
                    widthFactor: holdProgress,
                    alignment: Alignment.centerLeft,
                    child: Container(color: Colors.red.shade900),
                  ),
                  Text(holding ? 'Keep holding…' : 'Hold to confirm', style: AppTextStyles.button),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _CountdownView extends StatelessWidget {
  final int seconds;
  final VoidCallback onCancel;

  const _CountdownView({required this.seconds, required this.onCancel});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('Sending SOS alert in', style: AppTextStyles.body),
        SizedBox(height: AppSpacing.sm),
        Text('${seconds}s', style: AppTextStyles.custom(fontSize: 40, fontWeight: FontWeight.w800, color: Colors.red.shade600)),
        SizedBox(height: AppSpacing.lg),
        OutlinedButton(onPressed: onCancel, child: const Text('Cancel')),
      ],
    );
  }
}

class _SentView extends StatelessWidget {
  const _SentView();

  @override
  Widget build(BuildContext context) {
    return Builder(builder: (context) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.check_circle_rounded, color: AppColors.success, size: 48),
          SizedBox(height: AppSpacing.md),
          Text('Help has been notified', style: AppTextStyles.title),
          SizedBox(height: AppSpacing.sm),
          Text('Responders and your emergency contact have been alerted.',
              textAlign: TextAlign.center, style: AppTextStyles.cardSubtitle),
          SizedBox(height: AppSpacing.lg),
          ElevatedButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Close')),
        ],
      );
    });
  }
}

class _BlockedView extends StatelessWidget {
  final String message;
  final String hotline;

  const _BlockedView({required this.message, required this.hotline});

  @override
  Widget build(BuildContext context) {
    return Builder(builder: (context) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(message, style: AppTextStyles.body.copyWith(color: Colors.red.shade700)),
          SizedBox(height: AppSpacing.sm),
          Text.rich(TextSpan(children: [
            const TextSpan(text: 'Emergency hotline: '),
            TextSpan(text: hotline, style: AppTextStyles.bodySemibold),
          ]), style: AppTextStyles.body),
          SizedBox(height: AppSpacing.lg),
          ElevatedButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Close')),
        ],
      );
    });
  }
}
