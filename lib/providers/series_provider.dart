import 'package:flutter/material.dart';
import '../core/network/api_service.dart';
import '../data/models/series_model.dart';
import '../data/models/episode_model.dart';

class SeriesProvider extends ChangeNotifier {
  final ApiService _api = ApiService();

  static const SeriesModel _emptySeries = SeriesModel(
    id: '',
    title: '',
    synopsis: '',
    genre: '',
    releaseYear: '2026',
    totalEpisodes: 0,
    likes: '0',
    thumbnailPath: '',
    episodes: [],
  );

  List<SeriesModel> _seriesList = [];
  List<String> _categories = ['Semua'];
  String _searchQuery = '';
  String _selectedCategory = 'Semua';
  final Set<String> _likedEpisodes = {};
  final Set<String> _likedSeries = {};
  bool _isLoading = true;
  String? _errorMessage;

  List<SeriesModel> get allSeries => _seriesList;
  List<SeriesModel> get seriesList => _seriesList;
  List<String> get categories => _categories;
  String get searchQuery => _searchQuery;
  String get selectedCategory => _selectedCategory;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  SeriesProvider() {
    fetchSeries();
    fetchCategories();
  }

  SeriesModel get featuredSeries {
    if (_seriesList.isEmpty) return _emptySeries;
    try {
      return _seriesList.firstWhere((s) => s.isNew || s.isPopular);
    } catch (_) {
      return _seriesList.first;
    }
  }

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
          series.tag.toLowerCase().contains(_selectedCategory.toLowerCase()) ||
          series.categories.any((c) => c.toLowerCase() == _selectedCategory.toLowerCase());

      return matchesQuery && matchesCategory;
    }).toList();
  }

  Future<void> fetchSeries() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final res = await _api.getSeries();
      if (res.data != null && res.data['data'] is List) {
        final parsed = (res.data['data'] as List)
            .map((item) => SeriesModel.fromJson(item as Map<String, dynamic>))
            .toList();

        _seriesList = parsed;

        // Synchronize initial liked state for all series and episodes
        for (final s in _seriesList) {
          if (s.isLiked) {
            _likedSeries.add(s.id);
          }
          for (final ep in s.episodes) {
            if (ep.isLiked) {
              _likedEpisodes.add(ep.id);
            }
          }
        }
      }
    } catch (e) {
      _errorMessage = 'Gagal memuat series: ${e.toString()}';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchCategories() async {
    try {
      final res = await _api.getCategories();
      if (res.data != null && res.data['data'] is List) {
        final list = (res.data['data'] as List)
            .map((item) => item['name']?.toString() ?? '')
            .where((s) => s.isNotEmpty)
            .toList();

        _categories = ['Semua', ...list];
        notifyListeners();
      }
    } catch (_) {}
  }

  Future<SeriesModel?> fetchSeriesDetail(String slugOrId) async {
    try {
      final res = await _api.getSeriesDetail(slugOrId);
      if (res.data != null && res.data['data'] != null) {
        final detail = SeriesModel.fromJson(
          res.data['data'] as Map<String, dynamic>,
        );

        // Update in list
        final index = _seriesList.indexWhere((s) => s.id == detail.id || s.slug == detail.slug);
        if (index != -1) {
          _seriesList[index] = detail;
        } else {
          _seriesList.add(detail);
        }

        if (detail.isLiked) {
          _likedSeries.add(detail.id);
        }

        for (final ep in detail.episodes) {
          if (ep.isLiked) {
            _likedEpisodes.add(ep.id);
          }
        }

        notifyListeners();
        return detail;
      }
    } catch (_) {}
    return getSeriesById(slugOrId);
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

  Future<bool> toggleEpisodeLike(String episodeId) async {
    final epIdInt = int.tryParse(episodeId);

    final wasLiked = _likedEpisodes.contains(episodeId);
    final optimisticLiked = !wasLiked;

    if (optimisticLiked) {
      _likedEpisodes.add(episodeId);
    } else {
      _likedEpisodes.remove(episodeId);
    }

    // Optimistically update episode in series list
    _updateEpisodeLikeInState(episodeId, optimisticLiked);
    notifyListeners();

    if (epIdInt != null) {
      try {
        final res = await _api.toggleEpisodeLike(epIdInt);
        if (res.data != null && res.data['data'] is Map<String, dynamic>) {
          final data = res.data['data'] as Map<String, dynamic>;
          final serverIsLiked = data['is_liked'] == true;
          final serverLikesCount = int.tryParse(data['likes_count'].toString()) ?? 0;

          if (serverIsLiked) {
            _likedEpisodes.add(episodeId);
          } else {
            _likedEpisodes.remove(episodeId);
          }

          _applyServerEpisodeLike(episodeId, serverIsLiked, serverLikesCount);
          notifyListeners();
          return true;
        }
      } catch (e) {
        // Rollback state on error
        if (wasLiked) {
          _likedEpisodes.add(episodeId);
        } else {
          _likedEpisodes.remove(episodeId);
        }
        _updateEpisodeLikeInState(episodeId, wasLiked);
        notifyListeners();
        return false;
      }
    }

    return true;
  }

  void _updateEpisodeLikeInState(String episodeId, bool isLiked) {
    for (int i = 0; i < _seriesList.length; i++) {
      final s = _seriesList[i];
      final epIdx = s.episodes.indexWhere((e) => e.id == episodeId);
      if (epIdx != -1) {
        final ep = s.episodes[epIdx];
        final newCount = isLiked ? ep.likesCount + 1 : (ep.likesCount > 0 ? ep.likesCount - 1 : 0);
        final newLikesStr = newCount > 0
            ? (newCount >= 1000 ? '${(newCount / 1000).toStringAsFixed(1)}k Suka' : '$newCount Suka')
            : '0 Suka';
        final updatedEpList = List<EpisodeModel>.from(s.episodes);
        updatedEpList[epIdx] = ep.copyWith(
          likesCount: newCount,
          likes: newLikesStr,
          isLiked: isLiked,
        );
        _seriesList[i] = s.copyWith(episodes: updatedEpList);
        break;
      }
    }
  }

  void _applyServerEpisodeLike(String episodeId, bool isLiked, int count) {
    final likesStr = count > 0
        ? (count >= 1000 ? '${(count / 1000).toStringAsFixed(1)}k Suka' : '$count Suka')
        : '0 Suka';

    for (int i = 0; i < _seriesList.length; i++) {
      final s = _seriesList[i];
      final epIdx = s.episodes.indexWhere((e) => e.id == episodeId);
      if (epIdx != -1) {
        final ep = s.episodes[epIdx];
        final updatedEpList = List<EpisodeModel>.from(s.episodes);
        updatedEpList[epIdx] = ep.copyWith(
          likesCount: count,
          likes: likesStr,
          isLiked: isLiked,
        );
        _seriesList[i] = s.copyWith(episodes: updatedEpList);
        break;
      }
    }
  }

  /// Real-time sync for episode like status and count from server
  Future<void> syncEpisodeLikeStatus(String episodeId) async {
    final epIdInt = int.tryParse(episodeId);
    if (epIdInt == null) return;
    try {
      final res = await _api.getEpisodeLikeStatus(epIdInt);
      if (res.data != null && res.data['data'] is Map<String, dynamic>) {
        final data = res.data['data'] as Map<String, dynamic>;
        final serverIsLiked = data['is_liked'] == true;
        final serverLikesCount = int.tryParse(data['likes_count'].toString()) ?? 0;

        final wasLiked = _likedEpisodes.contains(episodeId);
        bool changed = false;

        if (serverIsLiked != wasLiked) {
          if (serverIsLiked) {
            _likedEpisodes.add(episodeId);
          } else {
            _likedEpisodes.remove(episodeId);
          }
          changed = true;
        }

        for (final s in _seriesList) {
          final epIdx = s.episodes.indexWhere((e) => e.id == episodeId);
          if (epIdx != -1) {
            if (s.episodes[epIdx].likesCount != serverLikesCount || s.episodes[epIdx].isLiked != serverIsLiked) {
              changed = true;
            }
            break;
          }
        }

        if (changed) {
          _applyServerEpisodeLike(episodeId, serverIsLiked, serverLikesCount);
          notifyListeners();
        }
      }
    } catch (_) {}
  }

  bool isSeriesLiked(String seriesId) => _likedSeries.contains(seriesId);

  Future<bool> toggleSeriesLike(String seriesId) async {
    final sIdInt = int.tryParse(seriesId);

    final wasLiked = _likedSeries.contains(seriesId);
    final optimisticLiked = !wasLiked;

    if (optimisticLiked) {
      _likedSeries.add(seriesId);
    } else {
      _likedSeries.remove(seriesId);
    }

    _updateSeriesLikeInState(seriesId, optimisticLiked);
    notifyListeners();

    if (sIdInt != null) {
      try {
        final res = await _api.toggleSeriesLike(sIdInt);
        if (res.data != null && res.data['data'] is Map<String, dynamic>) {
          final data = res.data['data'] as Map<String, dynamic>;
          final serverIsLiked = data['is_liked'] == true;
          final serverLikesCount = int.tryParse(data['likes_count'].toString()) ?? 0;

          if (serverIsLiked) {
            _likedSeries.add(seriesId);
          } else {
            _likedSeries.remove(seriesId);
          }

          _applyServerSeriesLike(seriesId, serverIsLiked, serverLikesCount);
          notifyListeners();
          return true;
        }
      } catch (e) {
        if (wasLiked) {
          _likedSeries.add(seriesId);
        } else {
          _likedSeries.remove(seriesId);
        }
        _updateSeriesLikeInState(seriesId, wasLiked);
        notifyListeners();
        return false;
      }
    }

    return true;
  }

  void _updateSeriesLikeInState(String seriesId, bool isLiked) {
    final sIdx = _seriesList.indexWhere((s) => s.id == seriesId || s.slug == seriesId);
    if (sIdx != -1) {
      final s = _seriesList[sIdx];
      final newCount = isLiked ? s.likesCount + 1 : (s.likesCount > 0 ? s.likesCount - 1 : 0);
      final newLikesStr = newCount > 0
          ? (newCount >= 1000 ? '${(newCount / 1000).toStringAsFixed(1)}k Suka' : '$newCount Suka')
          : '0 Suka';
      _seriesList[sIdx] = s.copyWith(likesCount: newCount, likes: newLikesStr, isLiked: isLiked);
    }
  }

  void _applyServerSeriesLike(String seriesId, bool isLiked, int count) {
    final sIdx = _seriesList.indexWhere((s) => s.id == seriesId || s.slug == seriesId);
    if (sIdx != -1) {
      final s = _seriesList[sIdx];
      final newLikesStr = count > 0
          ? (count >= 1000 ? '${(count / 1000).toStringAsFixed(1)}k Suka' : '$count Suka')
          : '0 Suka';
      _seriesList[sIdx] = s.copyWith(likesCount: count, likes: newLikesStr, isLiked: isLiked);
    }
  }

  SeriesModel? getSeriesById(String seriesId) {
    try {
      return _seriesList.firstWhere(
        (s) => s.id == seriesId || s.slug == seriesId,
      );
    } catch (_) {
      return null;
    }
  }

  @visibleForTesting
  void setSeriesForTesting(List<SeriesModel> list) {
    _seriesList = list;
    notifyListeners();
  }

  @visibleForTesting
  void setIsLoadingForTesting(bool val) {
    _isLoading = val;
    notifyListeners();
  }
}
