import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api_client.dart';
import '../../core/theme.dart';
import 'announcement_detail_sheet.dart';
import 'announcement_list_item.dart';
import 'announcement_poster_image.dart';
import 'notices_provider.dart';

class AnnouncementListScreen extends ConsumerStatefulWidget {
  const AnnouncementListScreen({super.key});

  @override
  ConsumerState<AnnouncementListScreen> createState() => _AnnouncementListScreenState();
}

class _AnnouncementListScreenState extends ConsumerState<AnnouncementListScreen> {
  final _items = <AnnouncementListItem>[];
  final _scrollController = ScrollController();
  int _page = 1;
  bool _hasMore = true;
  bool _loadingMore = false;
  bool _initialLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadPage();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_hasMore || _loadingMore || !_scrollController.hasClients) return;
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 300) {
      _loadPage();
    }
  }

  Future<void> _loadPage() async {
    setState(() => _loadingMore = true);
    try {
      final res = await ref.read(apiClientProvider).get('/notices/history', params: {'page': _page});
      final data = res.data as Map<String, dynamic>;
      final newItems = (data['data'] as List<dynamic>)
          .map((e) => AnnouncementListItem.fromJson(e as Map<String, dynamic>))
          .toList();
      setState(() {
        _items.addAll(newItems);
        _hasMore = data['next_page_url'] != null;
        _page++;
        _error = null;
      });
    } catch (_) {
      setState(() => _error = 'Could not load announcements.');
    } finally {
      setState(() {
        _loadingMore = false;
        _initialLoading = false;
      });
    }
  }

  void _markRead(int index) {
    setState(() => _items[index] = _items[index].copyWithRead());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Announcements')),
      body: _initialLoading
          ? const Center(child: CircularProgressIndicator())
          : _items.isEmpty
              ? Center(
                  child: Text(_error ?? 'No announcements yet.', style: AppTextStyles.body),
                )
              : GridView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 0.85,
                  ),
                  itemCount: _items.length + (_hasMore ? 1 : 0),
                  itemBuilder: (context, i) {
                    if (i >= _items.length) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final item = _items[i];
                    return _AnnouncementTile(
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
                                _markRead(i);
                                ref.invalidate(noticesProvider);
                              },
                      ),
                    );
                  },
                ),
    );
  }
}

class _AnnouncementTile extends StatelessWidget {
  final AnnouncementListItem item;
  final VoidCallback onTap;

  const _AnnouncementTile({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
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
                child: const Center(child: Icon(Icons.campaign_rounded, color: AppColors.accent, size: 32)),
              ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Color(0xCC0F172A)],
                  ),
                ),
                child: Text(
                  item.title,
                  style: AppTextStyles.custom(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white),
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
    );
  }
}
