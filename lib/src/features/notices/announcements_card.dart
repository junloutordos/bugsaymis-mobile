import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/api_client.dart';
import '../../core/theme.dart';
import '../../shared/widgets/app_card.dart';
import 'announcement_detail_sheet.dart';
import 'announcement_poster_image.dart';
import 'notices_provider.dart';

class AnnouncementsCard extends ConsumerWidget {
  const AnnouncementsCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notices = ref.watch(noticesProvider);

    return notices.when(
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
      data: (data) {
        if (data.announcements.isEmpty) return const SizedBox.shrink();
        final items = data.announcements.take(5).toList();

        return AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text('Announcements', style: AppTextStyles.cardTitle),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.accentBg,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      '${data.announcements.length}',
                      style: AppTextStyles.custom(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.accent),
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => context.push('/announcements'),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('See all',
                            style: AppTextStyles.custom(
                                fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.accent)),
                        const Icon(Icons.chevron_right_rounded, size: 16, color: AppColors.accent),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 190,
                child: PageView.builder(
                  controller: PageController(viewportFraction: 0.7),
                  itemCount: items.length,
                  itemBuilder: (context, i) {
                    final item = items[i];
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      child: _AnnouncementSquareCard(
                        title: item.title,
                        posterPath: item.posterPath,
                        onTap: () => showAnnouncementDetail(
                          context,
                          title: item.title,
                          body: item.body,
                          posterPath: item.posterPath,
                          isRead: false,
                          onAcknowledge: () async {
                            await acknowledgeNotice(ref.read(apiClientProvider), item);
                            // Without this, the dashboard card keeps showing the
                            // now-acknowledged item until the screen fully
                            // rebuilds — same gotcha already fixed once for the
                            // forced notice queue (notice_queue_dialog.dart:38-41).
                            ref.invalidate(noticesProvider);
                          },
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _AnnouncementSquareCard extends StatelessWidget {
  final String title;
  final String? posterPath;
  final VoidCallback onTap;

  const _AnnouncementSquareCard({required this.title, required this.posterPath, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AspectRatio(
        aspectRatio: 1,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.card),
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (posterPath != null)
                AnnouncementPosterImage(posterPath: posterPath!)
              else
                Container(
                  color: AppColors.accentBg,
                  child: const Center(
                    child: Icon(Icons.campaign_rounded, color: AppColors.accent, size: 40),
                  ),
                ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.transparent, Color(0xCC0F172A)],
                    ),
                  ),
                  child: Text(
                    title,
                    style: AppTextStyles.custom(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
