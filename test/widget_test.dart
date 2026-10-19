import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:humora_mobile/main.dart';
import 'package:humora_mobile/data/models/user_model.dart';
import 'package:humora_mobile/providers/auth_provider.dart';
import 'package:humora_mobile/providers/series_provider.dart';
import 'package:humora_mobile/providers/history_provider.dart';
import 'package:humora_mobile/providers/notification_provider.dart';
import 'package:humora_mobile/providers/settings_provider.dart';
import 'package:humora_mobile/providers/subscription_provider.dart';
import 'package:humora_mobile/providers/transaction_provider.dart';
import 'package:humora_mobile/screens/auth/login_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:humora_mobile/screens/auth/forgot_password_screen.dart';
import 'package:humora_mobile/screens/auth/reset_password_screen.dart';
import 'package:humora_mobile/screens/notification/notification_screen.dart';
import 'package:humora_mobile/core/services/permission_service.dart';
import 'package:humora_mobile/core/services/local_notification_service.dart';

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    PermissionService.disableAutoPromptForTesting = true;
    LocalNotificationService.disableInTests = true;

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.it_nomads.com/flutter_secure_storage'),
      (MethodCall methodCall) async {
        return null;
      },
    );

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('flutter.baseflow.com/permissions/methods'),
      (MethodCall methodCall) async {
        return <int, int>{};
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

  testWidgets('ForgotPasswordScreen and ResetPasswordScreen flow widget test', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(500, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    // 1. Test ForgotPasswordScreen rendering
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => AuthProvider()),
        ],
        child: const MaterialApp(
          home: ForgotPasswordScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Lupa Kata Sandi'), findsWidgets);
    expect(find.text('scroll, laugh, repeat'), findsOneWidget);
    expect(find.text('Verifikasi Email'), findsOneWidget);
    expect(find.text('Masukkan alamat email'), findsOneWidget);

    // 2. Test ResetPasswordScreen rendering
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => AuthProvider()),
        ],
        child: const MaterialApp(
          home: ResetPasswordScreen(email: 'user@humora.id'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Ubah Kata Sandi Baru'), findsWidgets);
    expect(find.text('Akun Terverifikasi: user@humora.id'), findsOneWidget);
    expect(find.text('Simpan Kata Sandi Baru'), findsOneWidget);
    expect(find.text('Batal dan Kembali ke Login'), findsOneWidget);

    // 3. Test LoginScreen "Lupa sandi?" tap opens ForgotPasswordScreen
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => AuthProvider()),
        ],
        child: const MaterialApp(
          home: LoginScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Lupa sandi?'), findsOneWidget);
    await tester.tap(find.text('Lupa sandi?'));
    await tester.pumpAndSettle();

    expect(find.text('Verifikasi Email'), findsOneWidget);
  });

  test('PermissionService checkAndRequestInitialPermissions directly marks and requests permissions without modal sheet', () async {
    PermissionService.disableAutoPromptForTesting = false;

    // Reset flag
    await PermissionService.resetPermissionsFlag();
    expect(await PermissionService.hasRequestedPermissions(), isFalse);

    // Initial check should mark requested
    await PermissionService.checkAndRequestInitialPermissions();
    expect(await PermissionService.hasRequestedPermissions(), isTrue);

    // Clean up
    PermissionService.disableAutoPromptForTesting = true;
  });

  testWidgets('NotificationScreen test sheet displays all 5 notification options and triggers without error', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(500, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => NotificationProvider()),
        ],
        child: const MaterialApp(
          home: NotificationScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Verify NotificationScreen loaded
    expect(find.text('Notifikasi'), findsOneWidget);
    expect(find.text('Tes Push'), findsOneWidget);

    // Tap "Tes Push" button to open modal bottom sheet
    await tester.tap(find.text('Tes Push'));
    await tester.pumpAndSettle();

    // Verify all 5 notification types exist in the modal sheet
    expect(find.text('Simulasi Push Notifikasi'), findsOneWidget);
    expect(find.text('Verifikasi Premium Disetujui Admin'), findsOneWidget);
    expect(find.text('Video / Episode Baru Dirilis'), findsOneWidget);
    expect(find.text('Video Populer / Trending'), findsOneWidget);
    expect(find.text('Ajakan Berlangganan (Upgrade VIP)'), findsOneWidget);
    expect(find.text('Masa Langganan Segera Habis'), findsOneWidget);

    // Tap on "Verifikasi Premium Disetujui Admin"
    await tester.tap(find.text('Verifikasi Premium Disetujui Admin'));
    await tester.pumpAndSettle();

    // Verify snackbar confirmation is displayed
    expect(find.text('Notifikasi VIP Disetujui berhasil dikirim!'), findsOneWidget);
  });
}

