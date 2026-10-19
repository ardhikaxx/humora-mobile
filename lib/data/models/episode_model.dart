class EpisodeModel {
  final String id;
  final String seriesId;
  final int episodeNumber;
  final String title;
  final String synopsis;
  final String duration;
  final String likes;
  final String thumbnailPath;
  final bool isPremium;
  final bool isWatched;
  final double watchProgress; // 0.0 to 1.0

  const EpisodeModel({
    required this.id,
    required this.seriesId,
    required this.episodeNumber,
    required this.title,
    required this.synopsis,
    required this.duration,
    required this.likes,
    required this.thumbnailPath,
    this.isPremium = false,
    this.isWatched = false,
    this.watchProgress = 0.0,
  });

  EpisodeModel copyWith({
    String? id,
    String? seriesId,
    int? episodeNumber,
    String? title,
    String? synopsis,
    String? duration,
    String? likes,
    String? thumbnailPath,
    bool? isPremium,
    bool? isWatched,
    double? watchProgress,
  }) {
    return EpisodeModel(
      id: id ?? this.id,
      seriesId: seriesId ?? this.seriesId,
      episodeNumber: episodeNumber ?? this.episodeNumber,
      title: title ?? this.title,
      synopsis: synopsis ?? this.synopsis,
      duration: duration ?? this.duration,
      likes: likes ?? this.likes,
      thumbnailPath: thumbnailPath ?? this.thumbnailPath,
      isPremium: isPremium ?? this.isPremium,
      isWatched: isWatched ?? this.isWatched,
      watchProgress: watchProgress ?? this.watchProgress,
    );
  }
}
