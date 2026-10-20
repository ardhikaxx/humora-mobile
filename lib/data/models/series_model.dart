import 'episode_model.dart';

class SeriesModel {
  final String id;
  final String slug;
  final String title;
  final String synopsis;
  final String genre;
  final String releaseYear;
  final int totalEpisodes;
  final String likes;
  final int likesCount;
  final String thumbnailPath;
  final bool isNew;
  final bool isPopular;
  final bool isFreeAvailable;
  final bool isLiked;
  final String tag;
  final List<EpisodeModel> episodes;
  final List<String> categories;

  const SeriesModel({
    required this.id,
    this.slug = '',
    required this.title,
    required this.synopsis,
    required this.genre,
    required this.releaseYear,
    required this.totalEpisodes,
    required this.likes,
    this.likesCount = 0,
    required this.thumbnailPath,
    this.isNew = false,
    this.isPopular = false,
    this.isFreeAvailable = true,
    this.isLiked = false,
    this.tag = 'KOMEDI',
    this.episodes = const [],
    this.categories = const [],
  });

  factory SeriesModel.fromJson(Map<String, dynamic> json) {
    // Episodes list
    List<EpisodeModel> eps = [];
    if (json['episodes'] is List) {
      eps = (json['episodes'] as List)
          .map((e) => EpisodeModel.fromJson(e as Map<String, dynamic>))
          .toList();
    }

    // Categories list
    List<String> cats = [];
    if (json['categories'] is List) {
      cats = (json['categories'] as List).map((c) {
        if (c is Map) return c['name']?.toString() ?? '';
        return c.toString();
      }).where((s) => s.isNotEmpty).toList();
    }

    final genreStr = json['genre']?.toString() ?? (cats.isNotEmpty ? cats.join(', ') : 'Komedi');
    final tagStr = cats.isNotEmpty ? cats.first.toUpperCase() : 'KOMEDI';

    final totalEps = json['total_episodes'] != null
        ? int.tryParse(json['total_episodes'].toString()) ?? eps.length
        : eps.length;

    final likesCount = json['likes_count'] != null
        ? int.tryParse(json['likes_count'].toString()) ?? 0
        : 0;

    final String likesStr;
    if (likesCount <= 0) {
      likesStr = '0 Suka';
    } else if (likesCount >= 1000000) {
      likesStr = '${(likesCount / 1000000).toStringAsFixed(1)}M Suka';
    } else if (likesCount >= 1000) {
      likesStr = '${(likesCount / 1000).toStringAsFixed(1)}k Suka';
    } else {
      likesStr = '$likesCount Suka';
    }

    final thumbnail = json['thumbnail_url']?.toString() ??
        json['thumbnail_path']?.toString() ??
        '';

    return SeriesModel(
      id: json['id']?.toString() ?? '',
      slug: json['slug']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      synopsis: json['synopsis']?.toString() ?? '',
      genre: genreStr,
      releaseYear: json['release_year']?.toString() ?? '2026',
      totalEpisodes: totalEps,
      likes: likesStr,
      likesCount: likesCount,
      thumbnailPath: thumbnail,
      isNew: json['is_new'] == true || json['is_featured'] == true || totalEps > 0,
      isPopular: json['is_popular'] == true || likesCount > 0 || json['is_featured'] == true,
      isFreeAvailable: true,
      isLiked: json['is_liked'] == true,
      tag: tagStr,
      episodes: eps,
      categories: cats,
    );
  }

  SeriesModel copyWith({
    String? id,
    String? slug,
    String? title,
    String? synopsis,
    String? genre,
    String? releaseYear,
    int? totalEpisodes,
    String? likes,
    int? likesCount,
    String? thumbnailPath,
    bool? isNew,
    bool? isPopular,
    bool? isFreeAvailable,
    bool? isLiked,
    String? tag,
    List<EpisodeModel>? episodes,
    List<String>? categories,
  }) {
    return SeriesModel(
      id: id ?? this.id,
      slug: slug ?? this.slug,
      title: title ?? this.title,
      synopsis: synopsis ?? this.synopsis,
      genre: genre ?? this.genre,
      releaseYear: releaseYear ?? this.releaseYear,
      totalEpisodes: totalEpisodes ?? this.totalEpisodes,
      likes: likes ?? this.likes,
      likesCount: likesCount ?? this.likesCount,
      thumbnailPath: thumbnailPath ?? this.thumbnailPath,
      isNew: isNew ?? this.isNew,
      isPopular: isPopular ?? this.isPopular,
      isFreeAvailable: isFreeAvailable ?? this.isFreeAvailable,
      isLiked: isLiked ?? this.isLiked,
      tag: tag ?? this.tag,
      episodes: episodes ?? this.episodes,
      categories: categories ?? this.categories,
    );
  }
}
