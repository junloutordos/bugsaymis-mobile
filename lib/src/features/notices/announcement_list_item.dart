class AnnouncementListItem {
  final int id;
  final String title;
  final String body;
  final String? posterPath;
  final DateTime? publishedAt;
  final bool isRead;

  AnnouncementListItem({
    required this.id,
    required this.title,
    required this.body,
    required this.isRead,
    this.posterPath,
    this.publishedAt,
  });

  factory AnnouncementListItem.fromJson(Map<String, dynamic> json) => AnnouncementListItem(
        id: json['id'] as int,
        title: json['title'] as String,
        body: (json['body'] ?? '') as String,
        posterPath: json['poster_path'] as String?,
        publishedAt: json['published_at'] != null
            ? DateTime.tryParse(json['published_at'] as String)
            : null,
        isRead: json['is_read'] as bool? ?? false,
      );

  AnnouncementListItem copyWithRead() => AnnouncementListItem(
        id: id, title: title, body: body, posterPath: posterPath, publishedAt: publishedAt, isRead: true,
      );
}
