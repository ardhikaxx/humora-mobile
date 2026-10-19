class NotificationModel {
  final String id;
  final String title;
  final String message;
  final String timeAgo;
  final bool isRead;
  final String? thumbnailPath;
  final String? iconType; // 'tag', 'card', 'video'
  final String type;

  const NotificationModel({
    required this.id,
    required this.title,
    required this.message,
    required this.timeAgo,
    this.isRead = false,
    this.thumbnailPath,
    this.iconType,
    this.type = 'system',
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    final typeStr = json['type']?.toString() ?? 'system';
    String icon = 'card';
    if (typeStr == 'transaction') {
      icon = 'card';
    } else if (typeStr == 'content') {
      icon = 'video';
    } else {
      icon = 'tag';
    }

    final createdAt = json['created_at']?.toString();
    String timeStr = 'Baru saja';
    if (createdAt != null) {
      try {
        final dt = DateTime.parse(createdAt);
        final diff = DateTime.now().difference(dt);
        if (diff.inMinutes < 60) {
          timeStr = '${diff.inMinutes}m lalu';
        } else if (diff.inHours < 24) {
          timeStr = '${diff.inHours}j lalu';
        } else {
          timeStr = '${diff.inDays}h lalu';
        }
      } catch (_) {
        timeStr = 'Hari ini';
      }
    }

    return NotificationModel(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? 'Pemberitahuan',
      message: json['message']?.toString() ?? '',
      timeAgo: timeStr,
      isRead: json['is_read'] == true,
      iconType: icon,
      type: typeStr,
    );
  }

  NotificationModel copyWith({
    String? id,
    String? title,
    String? message,
    String? timeAgo,
    bool? isRead,
    String? thumbnailPath,
    String? iconType,
    String? type,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      title: title ?? this.title,
      message: message ?? this.message,
      timeAgo: timeAgo ?? this.timeAgo,
      isRead: isRead ?? this.isRead,
      thumbnailPath: thumbnailPath ?? this.thumbnailPath,
      iconType: iconType ?? this.iconType,
      type: type ?? this.type,
    );
  }
}
