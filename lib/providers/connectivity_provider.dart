import 'dart:async';
import 'package:flutter/material.dart';
import '../core/services/connectivity_service.dart';

class ConnectivityProvider extends ChangeNotifier {
  final ConnectivityService _service = ConnectivityService();

  bool _isOnline = true;
  bool _showReconnectedBanner = false;
  Timer? _reconnectedTimer;

  bool get isOnline => _isOnline;
  bool get isOffline => !_isOnline;
  bool get showReconnectedBanner => _showReconnectedBanner;

  final List<VoidCallback> _onReconnectListeners = [];

  ConnectivityProvider() {
    _init();
  }

  void _init() {
    _isOnline = _service.isOnline;
    _service.initialize(onStatusChanged: (online) {
      final wasOffline = !_isOnline;
      _isOnline = online;

      if (wasOffline && online) {
        // Trigger auto-retry callbacks
        _handleReconnection();
      }

      notifyListeners();
    });
  }

  void _handleReconnection() {
    _showReconnectedBanner = true;
    notifyListeners();

    // Trigger registered retry callbacks
    for (final callback in List<VoidCallback>.from(_onReconnectListeners)) {
      try {
        callback();
      } catch (e) {
        debugPrint('Error running reconnect listener: $e');
      }
    }

    _reconnectedTimer?.cancel();
    _reconnectedTimer = Timer(const Duration(seconds: 3), () {
      _showReconnectedBanner = false;
      notifyListeners();
    });
  }

  void registerReconnectCallback(VoidCallback callback) {
    if (!_onReconnectListeners.contains(callback)) {
      _onReconnectListeners.add(callback);
    }
  }

  void unregisterReconnectCallback(VoidCallback callback) {
    _onReconnectListeners.remove(callback);
  }

  Future<void> manualRetry() async {
    final online = await _service.checkConnection();
    _isOnline = online;
    if (online) {
      _handleReconnection();
    }
    notifyListeners();
  }

  void setMockStatusForTesting({required bool isOnline}) {
    _isOnline = isOnline;
    _service.setMockOnlineForTesting(isOnline);
    notifyListeners();
  }

  @override
  void dispose() {
    _reconnectedTimer?.cancel();
    super.dispose();
  }
}
