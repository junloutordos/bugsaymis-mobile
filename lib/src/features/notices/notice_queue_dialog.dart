import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api_client.dart';
import 'notices_provider.dart';

/// Call unconditionally near the top of a dashboard screen's `build()` —
/// shows the full unread queue (emergency alerts first) as a sequence of
/// non-dismissible dialogs the first time `noticesProvider` resolves,
/// mirroring the web NoticeQueueModal's behavior. Uses `ref.listen` rather
/// than an imperative one-shot call so pull-to-refresh (which rebuilds these
/// stateless ConsumerWidget screens repeatedly) never re-triggers the
/// queue — the callback only fires on an actual state transition of
/// `noticesProvider`, not on every rebuild of the calling screen.
void watchPendingNotices(BuildContext context, WidgetRef ref) {
  ref.listen<AsyncValue<NoticesData>>(noticesProvider, (previous, next) {
    final data = next.value;
    if (data == null || data.queue.isEmpty) return;
    if (!context.mounted) return;
    _showQueue(context, ref, List<NoticeItem>.from(data.queue));
  });
}

Future<void> _showQueue(BuildContext context, WidgetRef ref, List<NoticeItem> queue) async {
  if (queue.isEmpty) return;
  final item = queue.first;

  await showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) => PopScope(
      canPop: false,
      child: NoticeQueueDialog(
        item: item,
        position: '1 of ${queue.length}',
        showPosition: queue.length > 1,
        onAcknowledge: () async {
          await acknowledgeNotice(ref.read(apiClientProvider), item);
          if (dialogContext.mounted) Navigator.of(dialogContext).pop();
        },
      ),
    ),
  );

  if (context.mounted) {
    await _showQueue(context, ref, queue.sublist(1));
  }
}

class NoticeQueueDialog extends StatelessWidget {
  final NoticeItem item;
  final String position;
  final bool showPosition;
  final Future<void> Function() onAcknowledge;

  const NoticeQueueDialog({
    super.key,
    required this.item,
    required this.position,
    required this.showPosition,
    required this.onAcknowledge,
  });

  bool get _isEmergency => item.kind == 'emergency-alert';

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: _isEmergency ? const BorderSide(color: Colors.red, width: 4) : BorderSide.none,
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (showPosition)
              Text(position, style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
            if (_isEmergency) ...[
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(999)),
                child: const Text('EMERGENCY ALERT',
                    style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
              ),
            ],
            const SizedBox(height: 8),
            Text(item.title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Text(item.body, style: const TextStyle(fontSize: 14)),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isEmergency ? Colors.red.shade700 : Theme.of(context).colorScheme.primary,
                ),
                onPressed: onAcknowledge,
                child: Text(_isEmergency ? 'Acknowledge' : 'Mark as Read'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
