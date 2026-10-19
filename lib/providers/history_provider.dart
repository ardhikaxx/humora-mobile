import 'package:flutter/material.dart';
import '../data/dummy_data.dart';
import '../data/models/history_item_model.dart';

class HistoryProvider extends ChangeNotifier {
  final List<HistoryItemModel> _history = List.from(DummyData.initialHistory);

  List<HistoryItemModel> get allHistory => _history;

  List<HistoryItemModel> get continuingHistory =>
      _history.where((item) => !item.isCompleted).toList();

  List<HistoryItemModel> get completedHistory =>
      _history.where((item) => item.isCompleted).toList();

  int get totalCount => _history.length;

  void removeHistory(String id) {
    _history.removeWhere((item) => item.id == id);
    notifyListeners();
  }

  void clearAll() {
    _history.clear();
    notifyListeners();
  }

  void addOrUpdateProgress({
    required String seriesId,
    required String seriesTitle,
    required String episodeNumberText,
    required String episodeTitle,
    required String thumbnailPath,
    required int progressPercent,
  }) {
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
    );

    if (existingIndex != -1) {
      _history[existingIndex] = item;
    } else {
      _history.insert(0, item);
    }
    notifyListeners();
  }
}
