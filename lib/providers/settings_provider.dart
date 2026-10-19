import 'package:flutter/material.dart';

class SettingsProvider extends ChangeNotifier {
  // Video playback settings
  bool _autoPlayNext = true;
  bool _dataSaverMode = false;
  double _defaultPlaybackSpeed = 1.0;

  // Notification settings
  bool _notifNewReleases = true;
  bool _notifPromos = true;
  bool _notifContinueWatch = true;

  // Cache
  double _cacheSizeMb = 48.5;

  bool get autoPlayNext => _autoPlayNext;
  bool get dataSaverMode => _dataSaverMode;
  double get defaultPlaybackSpeed => _defaultPlaybackSpeed;

  bool get notifNewReleases => _notifNewReleases;
  bool get notifPromos => _notifPromos;
  bool get notifContinueWatch => _notifContinueWatch;
  double get cacheSizeMb => _cacheSizeMb;

  void toggleAutoPlay(bool value) {
    _autoPlayNext = value;
    notifyListeners();
  }

  void toggleDataSaver(bool value) {
    _dataSaverMode = value;
    notifyListeners();
  }

  void setPlaybackSpeed(double speed) {
    _defaultPlaybackSpeed = speed;
    notifyListeners();
  }

  void toggleNotifNewReleases(bool value) {
    _notifNewReleases = value;
    notifyListeners();
  }

  void toggleNotifPromos(bool value) {
    _notifPromos = value;
    notifyListeners();
  }

  void toggleNotifContinueWatch(bool value) {
    _notifContinueWatch = value;
    notifyListeners();
  }

  void clearCache() {
    _cacheSizeMb = 0.0;
    notifyListeners();
  }
}
