import 'episode_model.dart';

class SeriesModel {
  final String id;
  final String title;
  final String synopsis;
  final String genre;
  final String releaseYear;
  final int totalEpisodes;
  final String likes;
  final String thumbnailPath;
  final bool isNew;
  final bool isPopular;
  final bool isFreeAvailable;
  final String tag;
  final List<EpisodeModel> episodes;

  const SeriesModel({
    required this.id,
    required this.title,
    required this.synopsis,
    required this.genre,
    required this.releaseYear,
    required this.totalEpisodes,
    required this.likes,
    required this.thumbnailPath,
    this.isNew = false,
    this.isPopular = false,
    this.isFreeAvailable = true,
    this.tag = 'KOMEDI',
    this.episodes = const [],
  });

  SeriesModel copyWith({
    String? id,
    String? title,
    String? synopsis,
    String? genre,
    String? releaseYear,
    int? totalEpisodes,
    String? likes,
    String? thumbnailPath,
    bool? isNew,
    bool? isPopular,
    bool? isFreeAvailable,
    String? tag,
    List<EpisodeModel>? episodes,
  }) {
    return SeriesModel(
      id: id ?? this.id,
      title: title ?? this.title,
      synopsis: synopsis ?? this.synopsis,
      genre: genre ?? this.genre,
      releaseYear: releaseYear ?? this.releaseYear,
      totalEpisodes: totalEpisodes ?? this.totalEpisodes,
      likes: likes ?? this.likes,
      thumbnailPath: thumbnailPath ?? this.thumbnailPath,
      isNew: isNew ?? this.isNew,
      isPopular: isPopular ?? this.isPopular,
      isFreeAvailable: isFreeAvailable ?? this.isFreeAvailable,
      tag: tag ?? this.tag,
      episodes: episodes ?? this.episodes,
    );
  }
}
