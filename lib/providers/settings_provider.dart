import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsProvider extends ChangeNotifier {
  static const String _keyAutoPlayNext = 'setting_auto_play_next';
  static const String _keyDefaultPlaybackSpeed = 'setting_default_playback_speed';
  static const String _keyNotifNewReleases = 'setting_notif_new_releases';
  static const String _keyNotifPromos = 'setting_notif_promos';
  static const String _keyNotifContinueWatch = 'setting_notif_continue_watch';

  // Video playback settings
  bool _autoPlayNext = true;
  double _defaultPlaybackSpeed = 1.0;

  // Notification settings
  bool _notifNewReleases = true;
  bool _notifPromos = true;
  bool _notifContinueWatch = true;

  // Cache
  double _cacheSizeMb = 48.5;
  bool _isInitialized = false;

  SettingsProvider() {
    init();
  }

  Future<void> init() async {
    await _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _autoPlayNext = prefs.getBool(_keyAutoPlayNext) ?? true;
      _defaultPlaybackSpeed = prefs.getDouble(_keyDefaultPlaybackSpeed) ?? 1.0;
      _notifNewReleases = prefs.getBool(_keyNotifNewReleases) ?? true;
      _notifPromos = prefs.getBool(_keyNotifPromos) ?? true;
      _notifContinueWatch = prefs.getBool(_keyNotifContinueWatch) ?? true;
      _isInitialized = true;
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading SharedPreferences: $e');
    }
  }

  // Getters
  bool get autoPlayNext => _autoPlayNext;
  double get defaultPlaybackSpeed => _defaultPlaybackSpeed;
  bool get notifNewReleases => _notifNewReleases;
  bool get notifPromos => _notifPromos;
  bool get notifContinueWatch => _notifContinueWatch;
  double get cacheSizeMb => _cacheSizeMb;
  bool get isInitialized => _isInitialized;

  // Setters with persistent storage
  Future<void> toggleAutoPlay(bool value) async {
    _autoPlayNext = value;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keyAutoPlayNext, value);
    } catch (e) {
      debugPrint('Error saving autoPlayNext: $e');
    }
  }

  Future<void> setPlaybackSpeed(double speed) async {
    _defaultPlaybackSpeed = speed;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble(_keyDefaultPlaybackSpeed, speed);
    } catch (e) {
      debugPrint('Error saving defaultPlaybackSpeed: $e');
    }
  }

  Future<void> toggleNotifNewReleases(bool value) async {
    _notifNewReleases = value;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keyNotifNewReleases, value);
    } catch (e) {
      debugPrint('Error saving notifNewReleases: $e');
    }
  }

  Future<void> toggleNotifPromos(bool value) async {
    _notifPromos = value;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keyNotifPromos, value);
    } catch (e) {
      debugPrint('Error saving notifPromos: $e');
    }
  }

  Future<void> toggleNotifContinueWatch(bool value) async {
    _notifContinueWatch = value;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keyNotifContinueWatch, value);
    } catch (e) {
      debugPrint('Error saving notifContinueWatch: $e');
    }
  }

  void clearCache() {
    _cacheSizeMb = 0.0;
    notifyListeners();
  }
}
