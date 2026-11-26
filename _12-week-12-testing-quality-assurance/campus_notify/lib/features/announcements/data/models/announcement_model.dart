import '../../domain/entities/announcement.dart';

class AnnouncementModel extends Announcement {
  const AnnouncementModel({
    required super.id,
    required super.title,
    required super.summary,
    required super.content,
  });

  factory AnnouncementModel.fromJson(Map<String, Object?> json) {
    return AnnouncementModel(
      id: '${json['id'] ?? ''}',
      title: json['title'] as String? ?? '',
      summary: json['summary'] as String? ?? '',
      content: json['content'] as String? ?? '',
    );
  }

  Map<String, Object?> toJson() => {
    'id': id,
    'title': title,
    'summary': summary,
    'content': content,
  };
}
