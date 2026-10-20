import 'package:flutter/foundation.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

class WakelockService {
  static bool disableInTests = false;

  static Future<void> enable() async {
    if (disableInTests) return;
    try {
      await WakelockPlus.enable();
    } catch (e) {
      debugPrint('WakelockService: Error enabling wakelock: $e');
    }
  }

  static Future<void> disable() async {
    if (disableInTests) return;
    try {
      await WakelockPlus.disable();
    } catch (e) {
      debugPrint('WakelockService: Error disabling wakelock: $e');
    }
  }

  static Future<bool> isEnabled() async {
    if (disableInTests) return false;
    try {
      return await WakelockPlus.enabled;
    } catch (e) {
      debugPrint('WakelockService: Error checking wakelock: $e');
      return false;
    }
  }
}
