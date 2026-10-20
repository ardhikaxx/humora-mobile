import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

class ConnectivityService {
  static final ConnectivityService _instance = ConnectivityService._internal();
  factory ConnectivityService() => _instance;
  ConnectivityService._internal();

  final Connectivity _connectivity = Connectivity();
  StreamSubscription<List<ConnectivityResult>>? _subscription;

  bool _isOnline = true;
  bool get isOnline => _isOnline;
  bool get isOffline => !_isOnline;

  // Testing flag to avoid native platform channel calls during widget tests
  static bool disableInTests = false;

  final ValueNotifier<bool> isOnlineNotifier = ValueNotifier<bool>(true);

  Future<void> initialize({void Function(bool isOnline)? onStatusChanged}) async {
    if (disableInTests) {
      _isOnline = true;
      isOnlineNotifier.value = true;
      return;
    }

    try {
      final results = await _connectivity.checkConnectivity();
      _updateConnectionStatus(results);
    } catch (e) {
      debugPrint('Error checking connectivity: $e');
    }

    _subscription = _connectivity.onConnectivityChanged.listen((results) {
      final wasOnline = _isOnline;
      _updateConnectionStatus(results);
      if (wasOnline != _isOnline) {
        onStatusChanged?.call(_isOnline);
      }
    });
  }

  void _updateConnectionStatus(List<ConnectivityResult> results) {
    final connected = results.isNotEmpty && results.any((r) => r != ConnectivityResult.none);
    _isOnline = connected;
    isOnlineNotifier.value = connected;
  }

  Future<bool> checkConnection() async {
    if (disableInTests) return true;
    try {
      final results = await _connectivity.checkConnectivity();
      _updateConnectionStatus(results);
      return _isOnline;
    } catch (_) {
      return _isOnline;
    }
  }

  void setMockOnlineForTesting(bool online) {
    _isOnline = online;
    isOnlineNotifier.value = online;
  }

  void dispose() {
    _subscription?.cancel();
  }
}
