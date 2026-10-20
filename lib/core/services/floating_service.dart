import 'package:flutter/foundation.dart';
import 'package:floating/floating.dart';

class FloatingService {
  static bool disableInTests = false;
  static final Floating _floating = Floating();

  static Floating get instance => _floating;

  static Future<bool> isPipAvailable() async {
    if (disableInTests) return false;
    try {
      return await _floating.isPipAvailable;
    } catch (e) {
      debugPrint('FloatingService: Error checking PiP availability: $e');
      return false;
    }
  }

  static Future<void> enablePip({Rational aspectRatio = const Rational.landscape()}) async {
    if (disableInTests) return;
    try {
      await _floating.enable(ImmediatePiP(aspectRatio: aspectRatio));
    } catch (e) {
      debugPrint('FloatingService: Error enabling PiP: $e');
    }
  }
}
