import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:humora_mobile/main.dart';
import 'package:humora_mobile/data/models/user_model.dart';
import 'package:humora_mobile/providers/auth_provider.dart';
import 'package:humora_mobile/providers/series_provider.dart';
import 'package:humora_mobile/providers/history_provider.dart';
import 'package:humora_mobile/providers/notification_provider.dart';
import 'package:humora_mobile/providers/settings_provider.dart';

void main() {
  testWidgets('Humora app smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => AuthProvider()),
          ChangeNotifierProvider(create: (_) => SeriesProvider()),
          ChangeNotifierProvider(create: (_) => HistoryProvider()),
          ChangeNotifierProvider(create: (_) => NotificationProvider()),
          ChangeNotifierProvider(create: (_) => SettingsProvider()),
        ],
        child: const HumoraApp(),
      ),
    );

    // Verify initial Beranda UI components are present
    expect(find.text('Beranda'), findsOneWidget);
    expect(find.text('Cari'), findsOneWidget);
    expect(find.text('Riwayat'), findsWidgets);
    expect(find.text('Profil'), findsOneWidget);
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
}
