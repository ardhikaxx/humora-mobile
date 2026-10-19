import 'package:shared_preferences/shared_preferences.dart';

class ApiConfig {
  /// Default server IP and port as requested by user
  static const String defaultBaseUrl = 'http://192.168.1.4:8000/api/v1';
  static const String _keyBaseUrl = 'humora_api_base_url';

  static String _currentBaseUrl = defaultBaseUrl;

  static String get baseUrl => _currentBaseUrl;

  static Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _currentBaseUrl = prefs.getString(_keyBaseUrl) ?? defaultBaseUrl;
    } catch (_) {
      _currentBaseUrl = defaultBaseUrl;
    }
  }

  static Future<void> setBaseUrl(String newUrl) async {
    _currentBaseUrl = newUrl.endsWith('/') ? newUrl.substring(0, newUrl.length - 1) : newUrl;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyBaseUrl, _currentBaseUrl);
  }
}
