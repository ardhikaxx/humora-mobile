class HistoryItemModel {
  final String id;
  final String seriesId;
  final String seriesTitle;
  final String episodeNumberText; // e.g. "Video 1"
  final String episodeTitle;      // e.g. "Tipe Bawel"
  final String thumbnailPath;
  final int progressPercent;      // e.g. 63 or 100
  final String dateText;          // e.g. "15 Februari 2026"
  final bool isCompleted;
  final int? episodeId;
  final int lastPosition;

  const HistoryItemModel({
    required this.id,
    required this.seriesId,
    required this.seriesTitle,
    required this.episodeNumberText,
    required this.episodeTitle,
    required this.thumbnailPath,
    required this.progressPercent,
    required this.dateText,
    required this.isCompleted,
    this.episodeId,
    this.lastPosition = 0,
  });

  factory HistoryItemModel.fromJson(Map<String, dynamic> json) {
    final epNum = json['episode_number']?.toString() ?? '1';
    final progress = json['progress_percent'] != null
        ? int.tryParse(json['progress_percent'].toString()) ?? 0
        : 0;

    return HistoryItemModel(
      id: json['id']?.toString() ?? '',
      seriesId: json['series_id']?.toString() ?? '',
      seriesTitle: json['series_title']?.toString() ?? '',
      episodeNumberText: 'Video $epNum',
      episodeTitle: json['episode_title']?.toString() ?? 'Episode $epNum',
      thumbnailPath: json['thumbnail_url']?.toString() ??
          'assets/images/thumbnails/thumb_caradeketin.png',
      progressPercent: progress,
      dateText: json['updated_at'] != null
          ? json['updated_at'].toString().split('T').first
          : 'Hari ini',
      isCompleted: json['is_completed'] == true,
      episodeId: json['episode_id'] != null
          ? int.tryParse(json['episode_id'].toString())
          : null,
      lastPosition: json['last_position'] != null
          ? int.tryParse(json['last_position'].toString()) ?? 0
          : 0,
    );
  }

  HistoryItemModel copyWith({
    String? id,
    String? seriesId,
    String? seriesTitle,
    String? episodeNumberText,
    String? episodeTitle,
    String? thumbnailPath,
    int? progressPercent,
    String? dateText,
    bool? isCompleted,
    int? episodeId,
    int? lastPosition,
  }) {
    return HistoryItemModel(
      id: id ?? this.id,
      seriesId: seriesId ?? this.seriesId,
      seriesTitle: seriesTitle ?? this.seriesTitle,
      episodeNumberText: episodeNumberText ?? this.episodeNumberText,
      episodeTitle: episodeTitle ?? this.episodeTitle,
      thumbnailPath: thumbnailPath ?? this.thumbnailPath,
      progressPercent: progressPercent ?? this.progressPercent,
      dateText: dateText ?? this.dateText,
      isCompleted: isCompleted ?? this.isCompleted,
      episodeId: episodeId ?? this.episodeId,
      lastPosition: lastPosition ?? this.lastPosition,
    );
  }
}
