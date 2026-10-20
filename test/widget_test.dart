import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:humora_mobile/main.dart';
import 'package:humora_mobile/data/models/user_model.dart';
import 'package:humora_mobile/data/models/series_model.dart';
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
import 'package:humora_mobile/core/theme/app_colors.dart';
import 'package:humora_mobile/screens/home/home_screen.dart';
import 'package:humora_mobile/screens/profile/profile_screen.dart';
import 'package:humora_mobile/screens/about/about_screen.dart';
import 'package:humora_mobile/screens/legal/terms_screen.dart';
import 'package:humora_mobile/screens/legal/privacy_policy_screen.dart';
import 'package:humora_mobile/core/services/permission_service.dart';
import 'package:humora_mobile/core/services/local_notification_service.dart';
import 'package:humora_mobile/core/services/connectivity_service.dart';
import 'package:humora_mobile/core/services/wakelock_service.dart';
import 'package:humora_mobile/core/services/vibration_service.dart';
import 'package:humora_mobile/core/services/showcase_service.dart';
import 'package:humora_mobile/core/services/floating_service.dart';
import 'package:humora_mobile/providers/connectivity_provider.dart';

class MockHomeSeriesProvider extends SeriesProvider {
  bool _mockLoading = false;

  @override
  bool get isLoading => _mockLoading;

  void setMockLoading(bool value) {
    _mockLoading = value;
    notifyListeners();
  }

  @override
  Future<void> fetchSeries() async {}

  @override
  Future<void> fetchCategories() async {}
}

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    PermissionService.disableAutoPromptForTesting = true;
    LocalNotificationService.disableInTests = true;
    ConnectivityService.disableInTests = true;
    WakelockService.disableInTests = true;
    VibrationService.disableInTests = true;
    ShowcaseService.disableInTests = true;
    FloatingService.disableInTests = true;

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

    final mockTempDir = Directory('${Directory.systemTemp.path}/humora_test_cache');
    if (!mockTempDir.existsSync()) {
      mockTempDir.createSync(recursive: true);
    }

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      (MethodCall methodCall) async {
        return mockTempDir.path;
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
          ChangeNotifierProvider(create: (_) => ConnectivityProvider()),
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
          ChangeNotifierProvider(create: (_) => ConnectivityProvider()),
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

  testWidgets('NotificationScreen renders correctly and marks all as read', (WidgetTester tester) async {
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
    expect(find.text('Tandai dibaca'), findsOneWidget);
    expect(find.text('Tes Push'), findsNothing);

    // Tap "Tandai dibaca"
    await tester.tap(find.text('Tandai dibaca'));
    await tester.pumpAndSettle();

    // Verify confirmation snackbar
    expect(find.text('Semua notifikasi telah ditandai dibaca.'), findsOneWidget);
  });

  testWidgets('AboutScreen renders legal items, excludes Hak Cipta, and navigates to TermsScreen and PrivacyPolicyScreen', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(500, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(
      const MaterialApp(
        home: AboutScreen(),
      ),
    );
    await tester.pumpAndSettle();

    // 1. Verify "Tentang HUMORA" is loaded
    expect(find.text('Tentang HUMORA'), findsOneWidget);

    // 2. Verify "Hak Cipta & Lisensi Konten" is removed
    expect(find.text('Hak Cipta & Lisensi Konten'), findsNothing);

    // 3. Scroll to "Syarat & Ketentuan Layanan" and tap
    await tester.ensureVisible(find.text('Syarat & Ketentuan Layanan'));
    await tester.pumpAndSettle();
    expect(find.text('Syarat & Ketentuan Layanan'), findsOneWidget);
    expect(find.text('Kebijakan Privasi'), findsOneWidget);

    await tester.tap(find.text('Syarat & Ketentuan Layanan'));
    await tester.pumpAndSettle();

    // 4. Verify TermsScreen is opened with content
    expect(find.byType(TermsScreen), findsOneWidget);
    expect(find.text('DOKUMEN HUKUM RESMI'), findsOneWidget);
    expect(find.text('Penerimaan Ketentuan'), findsOneWidget);
    expect(find.text('Langganan VIP & Verifikasi Pembayaran'), findsOneWidget);

    // Pop back to AboutScreen
    await tester.tap(find.byIcon(LucideIcons.chevronLeft));
    await tester.pumpAndSettle();

    // 5. Scroll to and tap "Kebijakan Privasi"
    await tester.ensureVisible(find.text('Kebijakan Privasi'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Kebijakan Privasi'));
    await tester.pumpAndSettle();

    // 6. Verify PrivacyPolicyScreen is opened with content
    expect(find.byType(PrivacyPolicyScreen), findsOneWidget);
    expect(find.text('KEPATUHAN UU PDP RI'), findsOneWidget);
    expect(find.text('Penggunaan Izin Native Perangkat (Permissions)'), findsOneWidget);
    expect(find.text('Jaminan Keamanan Data'), findsOneWidget);
  });

  testWidgets('TermsScreen renders all legal articles and details', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(500, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(
      const MaterialApp(
        home: TermsScreen(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Syarat & Ketentuan'), findsOneWidget);
    expect(find.text('Syarat & Ketentuan Layanan'), findsOneWidget);
    expect(find.text('PASAL 01'), findsOneWidget);
    expect(find.text('Penerimaan Ketentuan'), findsOneWidget);
    expect(find.text('PASAL 03'), findsOneWidget);
    expect(find.text('Hak Kekayaan Intelektual & Lisensi Konten'), findsOneWidget);
    expect(find.text('PASAL 04'), findsOneWidget);
    expect(find.text('Langganan VIP & Verifikasi Pembayaran'), findsOneWidget);
  });

  testWidgets('PrivacyPolicyScreen renders UU PDP compliance and permissions disclosures', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(500, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(
      const MaterialApp(
        home: PrivacyPolicyScreen(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Kebijakan Privasi'), findsOneWidget);
    expect(find.text('Kebijakan Privasi HUMORA'), findsOneWidget);
    expect(find.text('KEPATUHAN UU PDP RI'), findsOneWidget);
    expect(find.text('BAGIAN 01'), findsOneWidget);
    expect(find.text('Komitmen Privasi & Landasan Regulasi'), findsOneWidget);
    expect(find.text('BAGIAN 03'), findsOneWidget);
    expect(find.text('Penggunaan Izin Native Perangkat (Permissions)'), findsOneWidget);
    expect(find.text('privacy@humora.id'), findsOneWidget);
  });

  testWidgets('HomeScreen section headers use Lucide icons and no emoticons', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(500, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    final seriesProv = SeriesProvider();
    seriesProv.setSeriesForTesting([
      const SeriesModel(
        id: '1',
        title: 'Keluarga Cemoro',
        synopsis: 'Komedi keluarga',
        genre: 'Komedi',
        releaseYear: '2026',
        totalEpisodes: 5,
        likes: '100',
        thumbnailPath: '',
        isPopular: true,
        isNew: true,
        isFreeAvailable: true,
        episodes: [],
      ),
    ]);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => AuthProvider()),
          ChangeNotifierProvider.value(value: seriesProv),
          ChangeNotifierProvider(create: (_) => HistoryProvider()),
          ChangeNotifierProvider(create: (_) => NotificationProvider()),
        ],
        child: const MaterialApp(
          home: HomeScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Verify "Video Populer" exists without 🌶️ emoticon
    expect(find.text('Video Populer'), findsOneWidget);
    expect(find.textContaining('🌶️'), findsNothing);

    // Verify "Terbaru di HUMORA" exists without ✨ emoticon
    expect(find.text('Terbaru di HUMORA'), findsOneWidget);
    expect(find.textContaining('✨'), findsNothing);

    // Verify Lucide icons are present
    expect(find.byIcon(LucideIcons.flame), findsWidgets);
    expect(find.byIcon(LucideIcons.sparkles), findsWidgets);
  });

  testWidgets('ProfileScreen and AboutScreen use subtle dividers and borders', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(500, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    // 1. ProfileScreen
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => AuthProvider()),
        ],
        child: const MaterialApp(
          home: ProfileScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final profileDividers = tester.widgetList<Divider>(find.byType(Divider));
    expect(profileDividers, isNotEmpty);
    for (final divider in profileDividers) {
      expect(divider.color, equals(AppColors.dividerSubtle));
    }

    // 2. AboutScreen
    await tester.pumpWidget(
      const MaterialApp(
        home: AboutScreen(),
      ),
    );
    await tester.pumpAndSettle();

    final aboutDividers = tester.widgetList<Divider>(find.byType(Divider));
    expect(aboutDividers, isNotEmpty);
    expect(aboutDividers.first.color, equals(AppColors.dividerSubtle));
  });

  testWidgets('HomeScreen displays Skeletonizer and does not show empty state while isLoading is true and seriesList is empty', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(500, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    final seriesProv = MockHomeSeriesProvider();
    seriesProv.setSeriesForTesting([]);
    seriesProv.setMockLoading(true);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => AuthProvider()),
          ChangeNotifierProvider<SeriesProvider>.value(value: seriesProv),
          ChangeNotifierProvider(create: (_) => HistoryProvider()),
          ChangeNotifierProvider(create: (_) => NotificationProvider()),
        ],
        child: const MaterialApp(
          home: HomeScreen(),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));

    // Verify Skeletonizer is rendered
    expect(find.byWidgetPredicate((w) => w is Skeletonizer), findsOneWidget);

    // Verify HumoraEmptyState is NOT displayed while loading
    expect(find.text('Katalog Video Belum Tersedia'), findsNothing);
    expect(find.text('Muat Ulang Halaman'), findsNothing);
  });

  testWidgets('HomeScreen displays HumoraEmptyState when isLoading is false and seriesList is empty', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(500, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    final seriesProv = MockHomeSeriesProvider();
    seriesProv.setSeriesForTesting([]);
    seriesProv.setMockLoading(false);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => AuthProvider()),
          ChangeNotifierProvider<SeriesProvider>.value(value: seriesProv),
          ChangeNotifierProvider(create: (_) => HistoryProvider()),
          ChangeNotifierProvider(create: (_) => NotificationProvider()),
        ],
        child: const MaterialApp(
          home: HomeScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Verify Skeletonizer is not rendered
    expect(find.byWidgetPredicate((w) => w is Skeletonizer), findsNothing);

    // Verify HumoraEmptyState is displayed
    expect(find.text('Katalog Video Belum Tersedia'), findsOneWidget);
    expect(find.text('Muat Ulang Halaman'), findsOneWidget);
  });

  testWidgets('ConnectivityProvider and MainNavigationShell display offline banner and retry action', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(500, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    final connProvider = ConnectivityProvider();
    connProvider.setMockStatusForTesting(isOnline: false);

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
          ChangeNotifierProvider.value(value: connProvider),
        ],
        child: const HumoraApp(),
      ),
    );
    await tester.pumpAndSettle();

    // Verify offline banner and button are rendered
    expect(find.text('Koneksi internet terputus. Mode offline aktif.'), findsOneWidget);
    expect(find.text('Coba Lagi'), findsOneWidget);
    expect(find.byIcon(LucideIcons.wifiOff), findsOneWidget);

    // Tap "Coba Lagi"
    await tester.tap(find.text('Coba Lagi'));
    await tester.pump(const Duration(milliseconds: 100));

    // Switch back to online
    connProvider.setMockStatusForTesting(isOnline: true);
    await tester.pumpAndSettle();

    // Verify offline banner is dismissed
    expect(find.text('Koneksi internet terputus. Mode offline aktif.'), findsNothing);

    // Advance past reconnect banner auto-dismiss timer (3 seconds)
    await tester.pump(const Duration(seconds: 4));
    connProvider.dispose();
  });

  test('SettingsProvider clearCache sets cache size to 0.0', () async {
    final settingsProvider = SettingsProvider();
    await settingsProvider.init();

    await settingsProvider.clearCache();
    expect(settingsProvider.cacheSizeMb, equals(0.0));
  });

  test('WakelockService and FloatingService run safely without exceptions in tests', () async {
    WakelockService.disableInTests = true;
    await WakelockService.enable();
    await WakelockService.disable();
    expect(await WakelockService.isEnabled(), isFalse);

    FloatingService.disableInTests = true;
    expect(await FloatingService.isPipAvailable(), isFalse);
    await FloatingService.enablePip();
  });

  test('VibrationService provides light, medium, and success patterns safely', () async {
    VibrationService.disableInTests = true;
    await VibrationService.lightImpact();
    await VibrationService.mediumImpact();
    await VibrationService.successPattern();
  });

  test('ShowcaseService tracks completion and reset states', () async {
    ShowcaseService.disableInTests = false;
    await ShowcaseService.resetShowcase();
    expect(await ShowcaseService.shouldShowShowcase(), isTrue);

    await ShowcaseService.markShowcaseCompleted();
    expect(await ShowcaseService.shouldShowShowcase(), isFalse);

    await ShowcaseService.resetShowcase();
    expect(await ShowcaseService.shouldShowShowcase(), isTrue);
    ShowcaseService.disableInTests = true;
  });
}

