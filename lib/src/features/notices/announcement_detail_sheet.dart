import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/theme.dart';
import 'announcement_poster_image.dart';

/// Opens a freely-dismissible bottom sheet with an announcement's full
/// details — used by both the dashboard swipeable cards and the full
/// history list's tiles, so tapping either always shows the same view.
Future<void> showAnnouncementDetail(
  BuildContext context, {
  required String title,
  required String body,
  String? posterPath,
  DateTime? publishedAt,
  bool isRead = true,
  Future<void> Function()? onAcknowledge,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => AnnouncementDetailSheet(
      title: title,
      body: body,
      posterPath: posterPath,
      publishedAt: publishedAt,
      isRead: isRead,
      onAcknowledge: onAcknowledge,
    ),
  );
}

class AnnouncementDetailSheet extends StatelessWidget {
  final String title;
  final String body;
  final String? posterPath;
  final DateTime? publishedAt;
  final bool isRead;
  final Future<void> Function()? onAcknowledge;

  const AnnouncementDetailSheet({
    super.key,
    required this.title,
    required this.body,
    this.posterPath,
    this.publishedAt,
    this.isRead = true,
    this.onAcknowledge,
  });

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.35,
      maxChildSize: 0.92,
      expand: false,
      builder: (context, scrollController) => Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.sheet)),
        ),
        child: ListView(
          controller: scrollController,
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 16),
            if (posterPath != null) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.card),
                child: AspectRatio(
                  aspectRatio: 16 / 9,
                  child: AnnouncementPosterImage(posterPath: posterPath!),
                ),
              ),
              const SizedBox(height: 16),
            ],
            Text(title, style: AppTextStyles.sectionHeader),
            if (publishedAt != null) ...[
              const SizedBox(height: 4),
              Text(DateFormat('MMMM d, yyyy').format(publishedAt!), style: AppTextStyles.caption),
            ],
            const SizedBox(height: 12),
            Text(body, style: AppTextStyles.body),
            const SizedBox(height: 20),
            if (!isRead && onAcknowledge != null)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    await onAcknowledge!();
                    if (context.mounted) Navigator.of(context).pop();
                  },
                  child: const Text('Mark as Read'),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
