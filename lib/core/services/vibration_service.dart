import 'package:flutter/services.dart';
import 'package:vibration/vibration.dart';

class VibrationService {
  static bool disableInTests = false;

  /// Subtle light haptic feedback (like button, double-tap, tab select)
  static Future<void> lightImpact() async {
    if (disableInTests) return;
    try {
      final hasVibrator = await Vibration.hasVibrator();
      if (hasVibrator == true) {
        await Vibration.vibrate(duration: 25, amplitude: 60);
      } else {
        await HapticFeedback.lightImpact();
      }
    } catch (_) {
      try {
        await HapticFeedback.lightImpact();
      } catch (_) {}
    }
  }

  /// Medium haptic feedback (bookmark, VIP package select, episode switch)
  static Future<void> mediumImpact() async {
    if (disableInTests) return;
    try {
      final hasVibrator = await Vibration.hasVibrator();
      if (hasVibrator == true) {
        await Vibration.vibrate(duration: 45, amplitude: 120);
      } else {
        await HapticFeedback.mediumImpact();
      }
    } catch (_) {
      try {
        await HapticFeedback.mediumImpact();
      } catch (_) {}
    }
  }

  /// Success haptic pattern (VIP purchase success, saved offline)
  static Future<void> successPattern() async {
    if (disableInTests) return;
    try {
      final hasCustom = await Vibration.hasCustomVibrationsSupport();
      if (hasCustom == true) {
        await Vibration.vibrate(pattern: [0, 30, 60, 40], intensities: [0, 80, 0, 150]);
      } else {
        await HapticFeedback.heavyImpact();
      }
    } catch (_) {
      try {
        await HapticFeedback.heavyImpact();
      } catch (_) {}
    }
  }
}
