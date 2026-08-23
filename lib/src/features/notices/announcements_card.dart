import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/api_client.dart';
import '../../core/theme.dart';
import '../../shared/widgets/app_card.dart';
import 'announcement_detail_sheet.dart';
import 'announcement_list_item.dart';
import 'announcement_poster_image.dart';
import 'notices_provider.dart';
import 'recent_announcements_provider.dart';

class AnnouncementsCard extends ConsumerWidget {
  const AnnouncementsCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recent = ref.watch(recentAnnouncementsProvider);

    return recent.when(
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
      data: (items) {
        if (items.isEmpty) return const SizedBox.shrink();
        final unreadCount = items.where((i) => !i.isRead).length;

        return AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text('Announcements', style: AppTextStyles.cardTitle),
                  if (unreadCount > 0) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.accentBg,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        '$unreadCount new',
                        style: AppTextStyles.custom(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.accent),
                      ),
                    ),
                  ],
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
                        item: item,
                        onTap: () => showAnnouncementDetail(
                          context,
                          title: item.title,
                          body: item.body,
                          posterPath: item.posterPath,
                          publishedAt: item.publishedAt,
                          isRead: item.isRead,
                          onAcknowledge: item.isRead
                              ? null
                              : () async {
                                  await ref
                                      .read(apiClientProvider)
                                      .post('/notices/announcement/${item.id}/acknowledge');
                                  // Both providers read the same acknowledgment
                                  // state from different endpoints (pending vs.
                                  // history) — invalidate both so the forced
                                  // queue modal and this card agree afterward.
                                  ref.invalidate(noticesProvider);
                                  ref.invalidate(recentAnnouncementsProvider);
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
  final AnnouncementListItem item;
  final VoidCallback onTap;

  const _AnnouncementSquareCard({required this.item, required this.onTap});

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
              if (item.posterPath != null)
                AnnouncementPosterImage(posterPath: item.posterPath!)
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
                    item.title,
                    style: AppTextStyles.custom(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              if (!item.isRead)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: const BoxDecoration(color: AppColors.accent, shape: BoxShape.circle),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
