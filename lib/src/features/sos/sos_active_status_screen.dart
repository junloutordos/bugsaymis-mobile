import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/api_client.dart';
import '../../core/theme.dart';
import 'sos_status_poller.dart';
import 'sos_status_provider.dart';

const _steps = ['triggered', 'acknowledged', 'verified', 'resolved'];
const _stepLabels = {
  'triggered': 'Alert sent',
  'acknowledged': 'Acknowledged by responders',
  'verified': 'Verified — help dispatched',
  'escalated': 'Escalated to next responder tier',
  'resolved': 'Resolved',
  'false_alarm': 'Marked as false alarm',
};

/// Full-screen "Help is on the way" experience, shown after a successful
/// non-silent SOS trigger. Never reached for silent/duress triggers — see
/// sos_trigger_sheet.dart, which only navigates here on the non-silent path.
class SosActiveStatusScreen extends ConsumerWidget {
  final int alertId;
  const SosActiveStatusScreen({super.key, required this.alertId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(sosStatusProvider(alertId));

    return Scaffold(
      backgroundColor: Colors.red.shade600,
      body: SafeArea(
        child: status.when(
          loading: () => const Center(child: CircularProgressIndicator(color: Colors.white)),
          error: (_, _) => _ErrorState(onClose: () => context.go('/student/home')),
          data: (data) => _StatusBody(alertId: alertId, data: data),
        ),
      ),
    );
  }
}

class _StatusBody extends StatelessWidget {
  final int alertId;
  final Map<String, dynamic> data;
  const _StatusBody({required this.alertId, required this.data});

  bool get _isTerminal => kSosTerminalStatuses.contains(data['status']);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(AppSpacing.xl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (!_isTerminal)
            const _RadarPulse()
          else
            const Icon(Icons.check_circle_rounded, color: Colors.white, size: 96),
          SizedBox(height: AppSpacing.xl),
          Text(
            _isTerminal ? 'You are marked safe' : 'Help is on the way',
            textAlign: TextAlign.center,
            style: AppTextStyles.custom(
                fontSize: 22, fontWeight: FontWeight.w800, color: Colors.white),
          ),
          SizedBox(height: AppSpacing.xxl),
          _StatusStepper(currentStatus: data['status'] as String),
          const Spacer(),
          if (!_isTerminal)
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Colors.white),
                  minimumSize: const Size(88, 52),
                ),
                onPressed: () => _confirmEnd(context, alertId),
                child: const Text("End SOS — I'm safe"),
              ),
            )
          else
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white, foregroundColor: Colors.red.shade600),
                onPressed: () => context.go('/student/home'),
                child: const Text('Done'),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _confirmEnd(BuildContext context, int alertId) async {
    // Capture the container before the await — context may not be safe to
    // derive values from afterward (see project convention re: async gaps).
    final container = ProviderScope.containerOf(context, listen: false);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('End this SOS alert?'),
        content: const Text(
            'This tells responders you are safe. Only do this if the emergency has ended.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(true), child: const Text("Yes, I'm safe")),
        ],
      ),
    );

    if (confirmed != true) return;

    await endSosAlert(container.read(apiClientProvider), alertId);
  }
}

class _StatusStepper extends StatelessWidget {
  final String currentStatus;
  const _StatusStepper({required this.currentStatus});

  @override
  Widget build(BuildContext context) {
    final currentIndex = _steps
        .indexOf(currentStatus == 'false_alarm' ? 'resolved' : currentStatus)
        .clamp(0, _steps.length - 1);

    return Column(
      children: [
        for (var i = 0; i < _steps.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                Icon(
                  i <= currentIndex
                      ? Icons.check_circle_rounded
                      : Icons.radio_button_unchecked_rounded,
                  color: Colors.white,
                  size: 20,
                ),
                SizedBox(width: AppSpacing.sm),
                Text(
                  _stepLabels[_steps[i]] ?? _steps[i],
                  style: AppTextStyles.custom(
                    fontSize: 14,
                    fontWeight: i == currentIndex ? FontWeight.w700 : FontWeight.w400,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _RadarPulse extends StatefulWidget {
  const _RadarPulse();

  @override
  State<_RadarPulse> createState() => _RadarPulseState();
}

class _RadarPulseState extends State<_RadarPulse> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 2))
      ..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => SizedBox(
        width: 160,
        height: 160,
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) => CustomPaint(
            painter: _RadarPainter(progress: _controller.value),
            child: const Center(
              child: Icon(Icons.emergency_rounded, color: Colors.white, size: 48),
            ),
          ),
        ),
      );
}

class _RadarPainter extends CustomPainter {
  final double progress;
  _RadarPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final maxRadius = size.width / 2;
    for (final offset in [0.0, 0.5]) {
      final ringProgress = (progress + offset) % 1.0;
      final radius = maxRadius * ringProgress;
      final opacity = (1.0 - ringProgress).clamp(0.0, 1.0);
      canvas.drawCircle(
        center,
        radius,
        Paint()..color = Colors.white.withValues(alpha: opacity * 0.5),
      );
    }
    canvas.drawCircle(
        center, maxRadius * 0.35, Paint()..color = Colors.white.withValues(alpha: 0.9));
  }

  @override
  bool shouldRepaint(covariant _RadarPainter oldDelegate) => oldDelegate.progress != progress;
}

class _ErrorState extends StatelessWidget {
  final VoidCallback onClose;
  const _ErrorState({required this.onClose});

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.wifi_off_rounded, color: Colors.white, size: 48),
              SizedBox(height: AppSpacing.md),
              const Text('Could not load alert status.', style: TextStyle(color: Colors.white)),
              SizedBox(height: AppSpacing.lg),
              OutlinedButton(
                style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white, side: const BorderSide(color: Colors.white)),
                onPressed: onClose,
                child: const Text('Close'),
              ),
            ],
          ),
        ),
      );
}
