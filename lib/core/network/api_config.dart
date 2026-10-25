import 'package:shared_preferences/shared_preferences.dart';

class ApiConfig {
  static const String _keyBaseUrl = 'humora_api_base_url';

  static const String defaultBaseUrl = 'http://192.168.1.3:8000/api/v1';

  static String _currentBaseUrl = defaultBaseUrl;

  static String get baseUrl => _currentBaseUrl.isNotEmpty ? _currentBaseUrl : defaultBaseUrl;

  static Future<void> init() async {
    _currentBaseUrl = defaultBaseUrl;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyBaseUrl, defaultBaseUrl);
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
