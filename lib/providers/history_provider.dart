import 'package:flutter/material.dart';
import '../core/network/api_service.dart';
import '../data/models/history_item_model.dart';

class HistoryProvider extends ChangeNotifier {
  final ApiService _api = ApiService();

  List<HistoryItemModel> _history = [];
  bool _isLoading = false;

  List<HistoryItemModel> get allHistory => _history;
  bool get isLoading => _isLoading;

  List<HistoryItemModel> get continuingHistory =>
      _history.where((item) => !item.isCompleted).toList();

  List<HistoryItemModel> get completedHistory =>
      _history.where((item) => item.isCompleted).toList();

  int get totalCount => _history.length;

  HistoryProvider() {
    fetchHistory();
  }

  Future<void> fetchHistory() async {
    _isLoading = true;
    notifyListeners();

    try {
      final res = await _api.getWatchHistory();
      if (res.data != null && res.data['data'] is List) {
        _history = (res.data['data'] as List)
            .map((item) => HistoryItemModel.fromJson(item as Map<String, dynamic>))
            .toList();
      }
    } catch (_) {} finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> removeHistory(String id) async {
    final item = _history.firstWhere((h) => h.id == id, orElse: () => _history.first);
    _history.removeWhere((item) => item.id == id);
    notifyListeners();

    if (item.episodeId != null) {
      try {
        await _api.clearWatchHistory();
      } catch (_) {}
    }
  }

  Future<void> clearAll() async {
    _history.clear();
    notifyListeners();

    try {
      await _api.clearWatchHistory();
    } catch (_) {}
  }

  Future<void> addOrUpdateProgress({
    required String seriesId,
    required String seriesTitle,
    required String episodeNumberText,
    required String episodeTitle,
    required String thumbnailPath,
    required int progressPercent,
    int? episodeId,
    int lastPosition = 0,
    int durationSeconds = 120,
  }) async {
    final isCompleted = progressPercent >= 90;
    final existingIndex = _history.indexWhere(
      (h) => h.seriesId == seriesId && h.episodeNumberText == episodeNumberText,
    );

    final item = HistoryItemModel(
      id: existingIndex != -1 ? _history[existingIndex].id : 'hist-${DateTime.now().millisecondsSinceEpoch}',
      seriesId: seriesId,
      seriesTitle: seriesTitle,
      episodeNumberText: episodeNumberText,
      episodeTitle: episodeTitle,
      thumbnailPath: thumbnailPath,
      progressPercent: progressPercent,
      dateText: 'Hari ini',
      isCompleted: isCompleted,
      episodeId: episodeId,
      lastPosition: lastPosition,
    );

    if (existingIndex != -1) {
      _history[existingIndex] = item;
    } else {
      _history.insert(0, item);
    }
    notifyListeners();

    if (episodeId != null) {
      try {
        await _api.updateWatchProgress(
          episodeId: episodeId,
          lastPosition: lastPosition,
          durationSeconds: durationSeconds,
        );
      } catch (_) {}
    }
  }
}
