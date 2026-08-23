import 'package:flutter_test/flutter_test.dart';
import 'package:atlasgo/src/features/notices/announcement_list_item.dart';

void main() {
  test('parses a full history item from JSON', () {
    final item = AnnouncementListItem.fromJson({
      'id': 5,
      'title': 'Foundation Day',
      'body': 'Classes suspended campus-wide.',
      'poster_path': 'announcements/5_123.jpg',
      'published_at': '2026-08-20T08:00:00+00:00',
      'is_read': true,
    });

    expect(item.id, 5);
    expect(item.title, 'Foundation Day');
    expect(item.posterPath, 'announcements/5_123.jpg');
    expect(item.publishedAt, DateTime.parse('2026-08-20T08:00:00+00:00'));
    expect(item.isRead, isTrue);
  });

  test('handles a null poster_path and published_at', () {
    final item = AnnouncementListItem.fromJson({
      'id': 6, 'title': 'No Poster', 'body': 'Body', 'poster_path': null,
      'published_at': null, 'is_read': false,
    });

    expect(item.posterPath, isNull);
    expect(item.publishedAt, isNull);
    expect(item.isRead, isFalse);
  });
}
