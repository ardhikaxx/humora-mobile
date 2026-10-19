class NotificationModel {
  final String id;
  final String title;
  final String message;
  final String timeAgo;
  final bool isRead;
  final String? thumbnailPath;
  final String? iconType; // 'tag', 'card', 'video'

  const NotificationModel({
    required this.id,
    required this.title,
    required this.message,
    required this.timeAgo,
    this.isRead = false,
    this.thumbnailPath,
    this.iconType,
  });

  NotificationModel copyWith({
    String? id,
    String? title,
    String? message,
    String? timeAgo,
    bool? isRead,
    String? thumbnailPath,
    String? iconType,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      title: title ?? this.title,
      message: message ?? this.message,
      timeAgo: timeAgo ?? this.timeAgo,
      isRead: isRead ?? this.isRead,
      thumbnailPath: thumbnailPath ?? this.thumbnailPath,
      iconType: iconType ?? this.iconType,
    );
  }
}
