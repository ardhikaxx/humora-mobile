class EpisodeModel {
  final String id;
  final String seriesId;
  final int episodeNumber;
  final String title;
  final String synopsis;
  final String duration;
  final int durationSeconds;
  final String likes;
  final int likesCount;
  final String thumbnailPath;
  final bool isPremium;
  final bool isFree;
  final bool isLocked;
  final bool isWatched;
  final double watchProgress; // 0.0 to 1.0
  final int lastPosition;
  final String? streamUrl;
  final String accessType;
  final bool isLiked;

  const EpisodeModel({
    required this.id,
    required this.seriesId,
    required this.episodeNumber,
    required this.title,
    required this.synopsis,
    required this.duration,
    this.durationSeconds = 120,
    required this.likes,
    this.likesCount = 0,
    required this.thumbnailPath,
    this.isPremium = false,
    this.isFree = true,
    this.isLocked = false,
    this.isWatched = false,
    this.watchProgress = 0.0,
    this.lastPosition = 0,
    this.streamUrl,
    this.accessType = 'free',
    this.isLiked = false,
  });

  factory EpisodeModel.fromJson(Map<String, dynamic> json) {
    final epNum = json['episode_number'] != null
        ? int.tryParse(json['episode_number'].toString()) ?? 1
        : 1;
    final accessType = json['access_type']?.toString() ?? 'free';
    final isFree = json['is_free'] != null
        ? json['is_free'] == true
        : (accessType == 'free');
    final isPremium = json['is_premium'] != null
        ? json['is_premium'] == true
        : (!isFree);
    final isLocked = json['is_locked'] == true;
    final epLikesCount = json['likes_count'] != null
        ? int.tryParse(json['likes_count'].toString()) ?? 0
        : 0;
    final epLikesStr = epLikesCount > 0
        ? (epLikesCount >= 1000 ? '${(epLikesCount / 1000).toStringAsFixed(1)}k Suka' : '$epLikesCount Suka')
        : '0 Suka';
    final isLiked = json['is_liked'] == true;

    return EpisodeModel(
      id: json['id']?.toString() ?? '',
      seriesId: json['series_id']?.toString() ?? '',
      episodeNumber: epNum,
      title: json['title']?.toString() ?? 'Episode $epNum',
      synopsis: json['synopsis']?.toString() ?? '',
      duration: json['duration']?.toString() ?? '02:00',
      durationSeconds: json['duration_seconds'] != null
          ? int.tryParse(json['duration_seconds'].toString()) ?? 120
          : 120,
      likes: epLikesStr,
      likesCount: epLikesCount,
      thumbnailPath: json['thumbnail_url']?.toString() ??
          json['thumbnail_path']?.toString() ??
          '',
      isPremium: isPremium,
      isFree: isFree,
      isLocked: isLocked,
      isWatched: json['is_watched'] == true,
      watchProgress: json['watch_progress'] != null
          ? (double.tryParse(json['watch_progress'].toString()) ?? 0.0)
          : 0.0,
      lastPosition: json['last_position'] != null
          ? int.tryParse(json['last_position'].toString()) ?? 0
          : 0,
      streamUrl: json['stream_url']?.toString(),
      accessType: json['access_type']?.toString() ?? (isFree ? 'free' : 'premium'),
      isLiked: isLiked,
    );
  }

  EpisodeModel copyWith({
    String? id,
    String? seriesId,
    int? episodeNumber,
    String? title,
    String? synopsis,
    String? duration,
    int? durationSeconds,
    String? likes,
    int? likesCount,
    String? thumbnailPath,
    bool? isPremium,
    bool? isFree,
    bool? isLocked,
    bool? isWatched,
    double? watchProgress,
    int? lastPosition,
    String? streamUrl,
    String? accessType,
    bool? isLiked,
  }) {
    return EpisodeModel(
      id: id ?? this.id,
      seriesId: seriesId ?? this.seriesId,
      episodeNumber: episodeNumber ?? this.episodeNumber,
      title: title ?? this.title,
      synopsis: synopsis ?? this.synopsis,
      duration: duration ?? this.duration,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      likes: likes ?? this.likes,
      likesCount: likesCount ?? this.likesCount,
      thumbnailPath: thumbnailPath ?? this.thumbnailPath,
      isPremium: isPremium ?? this.isPremium,
      isFree: isFree ?? this.isFree,
      isLocked: isLocked ?? this.isLocked,
      isWatched: isWatched ?? this.isWatched,
      watchProgress: watchProgress ?? this.watchProgress,
      lastPosition: lastPosition ?? this.lastPosition,
      streamUrl: streamUrl ?? this.streamUrl,
      accessType: accessType ?? this.accessType,
      isLiked: isLiked ?? this.isLiked,
    );
  }
}
