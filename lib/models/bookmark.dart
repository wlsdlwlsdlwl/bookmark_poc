// lib/models/bookmark.dart
class Bookmark {
  final String id;
  final String title;
  final List<String> tags;
  final bool wasOpened;

  Bookmark({
    required this.id,
    required this.title,
    required this.tags,
    required this.wasOpened,
  });

  factory Bookmark.fromJson(Map<String, dynamic> json) {
    return Bookmark(
      id: json['id'] as String,
      title: json['title'] as String,
      tags: List<String>.from(json['tags'] as List),
      wasOpened: json['wasOpened'] as bool,
    );
  }
}