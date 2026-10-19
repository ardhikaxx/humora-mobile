import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:humora_mobile/main.dart';
import 'package:humora_mobile/data/models/user_model.dart';
import 'package:humora_mobile/providers/auth_provider.dart';
import 'package:humora_mobile/providers/series_provider.dart';
import 'package:humora_mobile/providers/history_provider.dart';
import 'package:humora_mobile/providers/notification_provider.dart';
import 'package:flutter/services.dart';
import 'package:humora_mobile/providers/settings_provider.dart';
import 'package:humora_mobile/providers/subscription_provider.dart';
import 'package:humora_mobile/providers/transaction_provider.dart';

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.it_nomads.com/flutter_secure_storage'),
      (MethodCall methodCall) async {
        return null;
      },
    );
  });
  testWidgets('Humora app smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => AuthProvider()),
          ChangeNotifierProvider(create: (_) => SeriesProvider()),
          ChangeNotifierProvider(create: (_) => HistoryProvider()),
          ChangeNotifierProvider(create: (_) => NotificationProvider()),
          ChangeNotifierProvider(create: (_) => SettingsProvider()),
          ChangeNotifierProvider(create: (_) => SubscriptionProvider()),
          ChangeNotifierProvider(create: (_) => TransactionProvider()),
        ],
        child: const HumoraApp(),
      ),
    );
    await tester.pumpAndSettle();

    // Verify initial Beranda UI components are present
    expect(find.text('Beranda'), findsOneWidget);
    expect(find.text('Cari'), findsOneWidget);
    expect(find.text('Riwayat'), findsWidgets);
    expect(find.text('Profil'), findsOneWidget);
  });

  testWidgets('Navbar responsive test on narrow screens and profil tab selection', (WidgetTester tester) async {
    // Test on narrow phone width (360x640)
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => AuthProvider()),
          ChangeNotifierProvider(create: (_) => SeriesProvider()),
          ChangeNotifierProvider(create: (_) => HistoryProvider()),
          ChangeNotifierProvider(create: (_) => NotificationProvider()),
          ChangeNotifierProvider(create: (_) => SettingsProvider()),
          ChangeNotifierProvider(create: (_) => SubscriptionProvider()),
          ChangeNotifierProvider(create: (_) => TransactionProvider()),
        ],
        child: const HumoraApp(),
      ),
    );
    await tester.pumpAndSettle();

    // Tap Profil tab (index 3)
    await tester.tap(find.text('Profil'));
    await tester.pumpAndSettle();

    // Verify profil screen is rendered without overflow
    expect(find.text('Profil Saya'), findsOneWidget);

    // Tap Riwayat tab (index 2)
    await tester.tap(find.text('Riwayat').last);
    await tester.pumpAndSettle();

    // Tap Cari tab (index 1)
    await tester.tap(find.text('Cari'));
    await tester.pumpAndSettle();

    // Tap Beranda tab (index 0)
    await tester.tap(find.text('Beranda'));
    await tester.pumpAndSettle();
  });

  test('AuthProvider 4 user tiers access control test', () {
    final auth = AuthProvider();

    // 1. Tamu (Guest)
    auth.switchTier(UserTier.guest);
    expect(auth.isGuest, isTrue);
    expect(auth.canAccessEpisode(1), isTrue);
    expect(auth.canAccessEpisode(2), isTrue);
    expect(auth.canAccessEpisode(3), isFalse);
    expect(auth.canAccessEpisode(4), isFalse);

    // 2. User Gratis (Free)
    auth.switchTier(UserTier.free);
    expect(auth.isFree, isTrue);
    expect(auth.canAccessEpisode(1), isTrue);
    expect(auth.canAccessEpisode(2), isTrue);
    expect(auth.canAccessEpisode(3), isFalse);

    // 3. Premium Aktif (3 Bulan)
    auth.switchTier(UserTier.premium);
    expect(auth.isPremium, isTrue);
    expect(auth.canAccessEpisode(1), isTrue);
    expect(auth.canAccessEpisode(2), isTrue);
    expect(auth.canAccessEpisode(3), isTrue);
    expect(auth.canAccessEpisode(4), isTrue);

    // 4. Expired
    auth.switchTier(UserTier.expired);
    expect(auth.isExpired, isTrue);
    expect(auth.canAccessEpisode(1), isTrue);
    expect(auth.canAccessEpisode(2), isTrue);
    expect(auth.canAccessEpisode(3), isFalse);
  });

  test('Video 2 auto-transition to Video 3 paywall rule validation', () {
    final guestAuth = AuthProvider()..switchTier(UserTier.guest);
    final freeAuth = AuthProvider()..switchTier(UserTier.free);
    final vipAuth = AuthProvider()..switchTier(UserTier.premium);

    // Episode 2 is playable for free and guest
    expect(guestAuth.canAccessEpisode(2), isTrue);
    expect(freeAuth.canAccessEpisode(2), isTrue);
    expect(vipAuth.canAccessEpisode(2), isTrue);

    // Next Episode (Episode 3) requires VIP paywall modal for guest and free
    expect(guestAuth.canAccessEpisode(3), isFalse);
    expect(freeAuth.canAccessEpisode(3), isFalse);

    // But VIP can seamlessly access Episode 3
    expect(vipAuth.canAccessEpisode(3), isTrue);
  });
}
