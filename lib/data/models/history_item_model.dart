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
  });

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
    );
  }
}
