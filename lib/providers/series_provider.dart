import 'package:flutter/material.dart';
import '../data/dummy_data.dart';
import '../data/models/series_model.dart';
import '../data/models/episode_model.dart';

class SeriesProvider extends ChangeNotifier {
  final List<SeriesModel> _seriesList = List.from(DummyData.seriesList);
  String _searchQuery = '';
  String _selectedCategory = 'Semua';
  final Set<String> _likedEpisodes = {'cdc-ep1'};

  List<SeriesModel> get allSeries => _seriesList;
  String get searchQuery => _searchQuery;
  String get selectedCategory => _selectedCategory;

  SeriesModel get featuredSeries => _seriesList.firstWhere(
        (s) => s.id == 'cara-deketin-cewek',
        orElse: () => _seriesList.first,
      );

  List<SeriesModel> get popularSeries =>
      _seriesList.where((s) => s.isPopular).toList();

  List<SeriesModel> get newSeries =>
      _seriesList.where((s) => s.isNew).toList();

  List<SeriesModel> get freeSeries =>
      _seriesList.where((s) => s.isFreeAvailable).toList();

  List<SeriesModel> get recommendedSeries =>
      _seriesList.reversed.toList();

  List<SeriesModel> get filteredSeries {
    return _seriesList.where((series) {
      final matchesQuery = _searchQuery.isEmpty ||
          series.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          series.genre.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          series.synopsis.toLowerCase().contains(_searchQuery.toLowerCase());

      final matchesCategory = _selectedCategory == 'Semua' ||
          series.genre.toLowerCase().contains(_selectedCategory.toLowerCase()) ||
          series.tag.toLowerCase().contains(_selectedCategory.toLowerCase());

      return matchesQuery && matchesCategory;
    }).toList();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void setCategory(String category) {
    _selectedCategory = category;
    notifyListeners();
  }

  bool isEpisodeLiked(String episodeId) => _likedEpisodes.contains(episodeId);

  void toggleEpisodeLike(String episodeId) {
    if (_likedEpisodes.contains(episodeId)) {
      _likedEpisodes.remove(episodeId);
    } else {
      _likedEpisodes.add(episodeId);
    }
    notifyListeners();
  }

  SeriesModel? getSeriesById(String seriesId) {
    try {
      return _seriesList.firstWhere((s) => s.id == seriesId);
    } catch (_) {
      return null;
    }
  }

  EpisodeModel? getEpisode(String seriesId, String episodeId) {
    final series = getSeriesById(seriesId);
    if (series == null) return null;
    try {
      return series.episodes.firstWhere((e) => e.id == episodeId);
    } catch (_) {
      return null;
    }
  }
}
