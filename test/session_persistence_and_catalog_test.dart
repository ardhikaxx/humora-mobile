import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:humora_mobile/core/network/api_service.dart';
import 'package:humora_mobile/data/models/user_model.dart';
import 'package:humora_mobile/providers/auth_provider.dart';
import 'package:humora_mobile/providers/series_provider.dart';
import 'package:humora_mobile/providers/history_provider.dart';
import 'package:humora_mobile/providers/notification_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final Map<String, dynamic> mockSecureStorage = {};

  setUpAll(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.it_nomads.com/flutter_secure_storage'),
      (MethodCall methodCall) async {
        final key = methodCall.arguments?['key'] as String?;
        if (methodCall.method == 'read') {
          return mockSecureStorage[key];
        } else if (methodCall.method == 'write') {
          final value = methodCall.arguments?['value'];
          mockSecureStorage[key!] = value;
          return null;
        } else if (methodCall.method == 'delete') {
          mockSecureStorage.remove(key);
          return null;
        } else if (methodCall.method == 'deleteAll') {
          mockSecureStorage.clear();
          return null;
        }
        return null;
      },
    );
  });

  setUp(() async {
    mockSecureStorage.clear();
    SharedPreferences.setMockInitialValues({});
    await ApiService().clearToken();
  });

  group('Session Persistence & Auto-login Tests', () {
    const testUser = UserModel(
      id: '42',
      name: 'Rian Komika',
      email: 'rian@humora.id',
      phone: '081234567890',
      gender: 'Laki-laki',
      memberSince: 'Januari 2026',
      tier: UserTier.premium,
      hasFullAccess: true,
      status: 'active',
    );

    test('UserModel serializes to JSON and back accurately', () {
      final json = testUser.toJson();
      final restored = UserModel.fromJson(json);

      expect(restored.id, equals('42'));
      expect(restored.name, equals('Rian Komika'));
      expect(restored.email, equals('rian@humora.id'));
      expect(restored.tier, equals(UserTier.premium));
      expect(restored.hasFullAccess, isTrue);
    });

    test('AuthProvider immediately restores cached user on startup before network completes', () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('humora_auth_cached_user', jsonEncode(testUser.toJson()));
      await prefs.setString('humora_auth_token_prefs', 'fake_valid_token_123');

      final auth = AuthProvider();
      await auth.initialize();

      // User must be restored immediately from local cache
      expect(auth.user.id, equals('42'));
      expect(auth.user.name, equals('Rian Komika'));
      expect(auth.isPremium, isTrue);
      expect(auth.isGuest, isFalse);
    });

    test('Transient network errors or timeouts DO NOT clear token or session', () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('humora_auth_cached_user', jsonEncode(testUser.toJson()));
      await prefs.setString('humora_auth_token_prefs', 'persistent_token_456');

      final auth = AuthProvider();
      await auth.initialize();

      // Token and user should still exist even if network was unavailable during initialize
      final api = ApiService();
      final token = await api.getToken();
      expect(token, equals('persistent_token_456'));
      expect(auth.user.name, equals('Rian Komika'));
      expect(auth.isGuest, isFalse);
    });

    test('Manual logout clears token, user cache, and resets state to Tamu Humora', () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('humora_auth_cached_user', jsonEncode(testUser.toJson()));
      await prefs.setString('humora_auth_token_prefs', 'token_to_logout');

      final auth = AuthProvider();
      await auth.initialize();
      expect(auth.isGuest, isFalse);

      // Perform manual logout
      await auth.logout();

      expect(auth.isGuest, isTrue);
      expect(auth.user.name, equals('Tamu Humora'));
      expect(prefs.getString('humora_auth_cached_user'), isNull);
      expect(prefs.getString('humora_auth_token_prefs'), isNull);

      final api = ApiService();
      expect(await api.getToken(), isNull);
    });
  });

  group('Guest Video Catalog Load & Cache Resilience Tests', () {
    final sampleSeriesList = [
      {
        'id': 1,
        'slug': 'baru-jadian-vs-lama-jadian',
        'title': 'Baru Jadian vs Lama Jadian',
        'synopsis': 'Perbandingan lucu antara pasangan',
        'release_year': '2026',
        'total_episodes': 4,
        'is_featured': false,
        'is_popular': true,
        'is_new': true,
        'is_free_available': true,
        'likes_count': 100,
        'categories': ['Romantis', 'Komedi'],
        'episodes': [
          {
            'id': 1,
            'series_id': 1,
            'episode_number': 1,
            'title': 'Episode 1',
            'is_free': true,
            'access_type': 'free',
          },
          {
            'id': 2,
            'series_id': 1,
            'episode_number': 2,
            'title': 'Episode 2',
            'is_free': true,
            'access_type': 'free',
          },
        ],
      }
    ];

    test('SeriesProvider immediately loads cached series so home is never empty on launch', () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('humora_cached_series_list_v2', jsonEncode(sampleSeriesList));

      final seriesProv = SeriesProvider();
      // Allow synchronous load
      await Future.delayed(const Duration(milliseconds: 50));

      expect(seriesProv.seriesList, isNotEmpty);
      expect(seriesProv.seriesList.first.title, equals('Baru Jadian vs Lama Jadian'));
      expect(seriesProv.freeSeries, isNotEmpty);
    });

    test('HistoryProvider and NotificationProvider clearLocal() safely resets memory on logout', () {
      final historyProv = HistoryProvider();
      final notifProv = NotificationProvider();

      historyProv.clearLocal();
      notifProv.clearLocal();

      expect(historyProv.allHistory, isEmpty);
      expect(historyProv.totalCount, equals(0));
      expect(notifProv.allNotifications, isEmpty);
      expect(notifProv.unreadCount, equals(0));
    });

    test('ApiService removes Authorization header when token is cleared or null', () async {
      final api = ApiService();
      await api.saveToken('test_auth_token_789');
      expect(await api.getToken(), equals('test_auth_token_789'));

      await api.clearToken();
      expect(await api.getToken(), isNull);
      expect(api.dio.options.headers.containsKey('Authorization'), isFalse);
    });
  });
}
