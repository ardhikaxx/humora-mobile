import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ShowcaseService {
  static const String _keyShowcaseCompleted = 'has_completed_showcase_v1';
  static bool disableInTests = false;

  static Future<bool> shouldShowShowcase() async {
    if (disableInTests) return false;
    try {
      final prefs = await SharedPreferences.getInstance();
      return !(prefs.getBool(_keyShowcaseCompleted) ?? false);
    } catch (e) {
      debugPrint('ShowcaseService: Error checking showcase status: $e');
      return false;
    }
  }

  static Future<void> markShowcaseCompleted() async {
    if (disableInTests) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keyShowcaseCompleted, true);
    } catch (e) {
      debugPrint('ShowcaseService: Error saving showcase status: $e');
    }
  }

  static Future<void> resetShowcase() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_keyShowcaseCompleted);
    } catch (e) {
      debugPrint('ShowcaseService: Error resetting showcase status: $e');
    }
  }
}
