import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PermissionService {
  static const String _prefKey = 'humora_has_requested_initial_permissions';
  static bool disableAutoPromptForTesting = false;

  /// Check whether initial permissions have already been asked
  static Future<bool> hasRequestedPermissions() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_prefKey) ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Mark permissions as requested so it won't prompt repeatedly on app startup
  static Future<void> markPermissionsRequested() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_prefKey, true);
    } catch (_) {}
  }

  /// Reset permission flag (useful for testing or re-requesting)
  static Future<void> resetPermissionsFlag() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_prefKey);
    } catch (_) {}
  }

  /// Directly request native OS permissions sequentially without any modal bottom sheet
  static Future<void> requestNativePermissions() async {
    try {
      // 1. Notification permission first (crucial for push & local notifications)
      await Permission.notification.request();

      // 2. Camera permission (for payment receipt snapshot)
      await Permission.camera.request();

      // 3. Media / Photos permission (for receipt selection from gallery)
      if (Platform.isAndroid) {
        await Permission.photos.request();
        await Permission.storage.request();
      } else if (Platform.isIOS) {
        await Permission.photos.request();
      }
    } catch (e) {
      debugPrint('Error requesting native permissions: $e');
    }
  }

  /// Check and trigger the initial native OS permission prompts directly on first launch
  /// No modal bottom sheet or intermediate dialog is shown—directly triggers native OS dialogs.
  static Future<void> checkAndRequestInitialPermissions() async {
    if (disableAutoPromptForTesting) return;

    try {
      final alreadyRequested = await hasRequestedPermissions();
      if (alreadyRequested) return;

      await markPermissionsRequested();
      // Prompt native OS dialogs directly from the operating system
      await requestNativePermissions();
    } catch (e) {
      debugPrint('Error requesting initial native permissions: $e');
    }
  }
}
