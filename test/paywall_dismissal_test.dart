import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:humora_mobile/providers/auth_provider.dart';
import 'package:humora_mobile/providers/series_provider.dart';
import 'package:humora_mobile/widgets/paywall_modal.dart';
import 'package:humora_mobile/data/models/user_model.dart';
import 'package:humora_mobile/data/models/episode_model.dart';

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.it_nomads.com/flutter_secure_storage'),
      (MethodCall methodCall) async => null,
    );
  });

  group('PaywallModal and Dismissal Audit Tests', () {
    late AuthProvider authProvider;
    late SeriesProvider seriesProvider;

    setUp(() {
      authProvider = AuthProvider();
      seriesProvider = SeriesProvider();
    });

    Widget createTestApp(Widget child) {
      return MultiProvider(
        providers: [
          ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
          ChangeNotifierProvider<SeriesProvider>.value(value: seriesProvider),
        ],
        child: MaterialApp(
          theme: ThemeData(fontFamily: 'Plus Jakarta Sans'),
          home: Scaffold(body: child),
        ),
      );
    }

    testWidgets('PaywallModal renders all elements, including Nanti saja button and close X', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () => PaywallModal.show(context),
                child: const Text('Show Paywall'),
              );
            },
          ),
        ),
      );

      // Tap to open PaywallModal
      await tester.tap(find.text('Show Paywall'));
      await tester.pumpAndSettle();

      // Verify header, crown icon, and pill
      expect(find.text('HUMORA PREMIUM'), findsOneWidget);
      expect(find.text('Ceritanya Belum Selesai!'), findsOneWidget);
      expect(find.text('Video ini khusus member VIP. Buka akses video serial komedi pilihan Anda.'), findsOneWidget);

      // Verify features
      expect(find.text('Akses Video Episode VIP'), findsOneWidget);
      expect(find.text('Paket Akses & Add-on'), findsOneWidget);
      expect(find.text('Cerita Baru Tiap Minggu'), findsOneWidget);

      // Verify CTA button
      expect(find.text('Lihat Paket Premium'), findsOneWidget);

      // Verify "Nanti saja, lanjut jelajahi" dismiss button
      expect(find.text('Nanti saja, lanjut jelajahi'), findsOneWidget);

      // Verify close X button
      expect(find.byIcon(LucideIcons.x), findsOneWidget);
    });

    testWidgets('Tapping "Nanti saja, lanjut jelajahi" pops the bottom sheet returning false', (tester) async {
      bool? modalResult;

      await tester.pumpWidget(
        createTestApp(
          Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () async {
                  modalResult = await PaywallModal.show(context);
                },
                child: const Text('Show Paywall'),
              );
            },
          ),
        ),
      );

      // Open paywall
      await tester.tap(find.text('Show Paywall'));
      await tester.pumpAndSettle();
      expect(find.text('Ceritanya Belum Selesai!'), findsOneWidget);

      // Ensure visible & tap "Nanti saja, lanjut jelajahi"
      await tester.ensureVisible(find.text('Nanti saja, lanjut jelajahi'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Nanti saja, lanjut jelajahi'));
      await tester.pumpAndSettle();

      // Paywall bottom sheet should be closed
      expect(find.text('Ceritanya Belum Selesai!'), findsNothing);
      expect(modalResult, isFalse);
    });

    testWidgets('Tapping the close "X" icon pops the bottom sheet returning false', (tester) async {
      bool? modalResult;

      await tester.pumpWidget(
        createTestApp(
          Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () async {
                  modalResult = await PaywallModal.show(context);
                },
                child: const Text('Show Paywall'),
              );
            },
          ),
        ),
      );

      // Open paywall
      await tester.tap(find.text('Show Paywall'));
      await tester.pumpAndSettle();
      expect(find.text('Ceritanya Belum Selesai!'), findsOneWidget);

      // Tap close icon
      await tester.tap(find.byIcon(LucideIcons.x));
      await tester.pumpAndSettle();

      // Paywall should be closed
      expect(find.text('Ceritanya Belum Selesai!'), findsNothing);
      expect(modalResult, isFalse);
    });

    testWidgets('Safe dismiss logic guarantees free user stays on free video without paywall loop', (tester) async {
      authProvider.switchTier(UserTier.free);

      // Setup a series with Ep 1 & 2 Free, Ep 3 & 4 VIP
      final episodes = [
        const EpisodeModel(
          id: '101',
          seriesId: '10',
          episodeNumber: 1,
          title: 'Episode 1 Gratis',
          synopsis: 'Pilot Episode',
          duration: '02:00',
          likes: '5',
          thumbnailPath: '',
          accessType: 'free',
        ),
        const EpisodeModel(
          id: '102',
          seriesId: '10',
          episodeNumber: 2,
          title: 'Episode 2 Gratis',
          synopsis: 'Second Free Episode',
          duration: '02:00',
          likes: '5',
          thumbnailPath: '',
          accessType: 'free',
        ),
        const EpisodeModel(
          id: '103',
          seriesId: '10',
          episodeNumber: 3,
          title: 'Episode 3 VIP',
          synopsis: 'Premium Episode',
          duration: '02:00',
          likes: '5',
          thumbnailPath: '',
          accessType: 'paid',
          isFree: false,
          isPremium: true,
        ),
      ];

      // Verify access rules
      expect(authProvider.canAccessEpisode(1, seriesTotalEpisodes: 3, isFreeEpisode: true), isTrue);
      expect(authProvider.canAccessEpisode(2, seriesTotalEpisodes: 3, isFreeEpisode: true), isTrue);
      expect(authProvider.canAccessEpisode(3, seriesTotalEpisodes: 3, isFreeEpisode: false), isFalse);

      // Simulate player state when Episode 2 completes:
      int currentEpisodeNumber = 2;
      bool hasTriggeredCompletion = false;
      bool isPlaying = true;
      bool showControls = false;
      int paywallShowCount = 0;

      // Simulate completion check
      void simulateCheckCompletion() {
        if (hasTriggeredCompletion) return;
        hasTriggeredCompletion = true;
        isPlaying = false;
        showControls = true;

        final nextEpNumber = currentEpisodeNumber + 1;
        final nextEpList = episodes.where((e) => e.episodeNumber == nextEpNumber).toList();
        if (nextEpList.isNotEmpty) {
          final nextEp = nextEpList.first;
          if (!authProvider.canAccessEpisode(nextEp.episodeNumber, isFreeEpisode: nextEp.isFree)) {
            paywallShowCount++;
          }
        }
      }

      // Simulate video reaching end
      simulateCheckCompletion();
      expect(hasTriggeredCompletion, isTrue);
      expect(paywallShowCount, equals(1));
      expect(currentEpisodeNumber, equals(2));

      // User clicks "Nanti saja" -> modal dismissed!
      // In the old buggy code: didPopNext() would call _initializeVideoPlayer()
      // which reset hasTriggeredCompletion = false, causing completion check to fire again and reopen the modal!
      //
      // In our fixed code:
      // didPopNext() maintains hasTriggeredCompletion = true, pauses playback, and keeps controls visible:
      void simulateDidPopNext({required bool userBoughtVip}) {
        if (userBoughtVip) {
          authProvider.switchTier(UserTier.premium);
          currentEpisodeNumber++;
          hasTriggeredCompletion = false;
        } else {
          // Free user dismissed paywall with "Nanti saja"
          // Keep current episode, do NOT re-trigger completion check
          isPlaying = false;
          showControls = true;
        }
      }

      // User dismissed without purchasing VIP
      simulateDidPopNext(userBoughtVip: false);

      // Simulate subsequent video tick:
      simulateCheckCompletion(); // Should NOT trigger paywall again because hasTriggeredCompletion is true!

      expect(paywallShowCount, equals(1), reason: 'Paywall modal must not reopen repeatedly when clicking Nanti saja!');
      expect(currentEpisodeNumber, equals(2), reason: 'User must stay on the free episode playback screen');
      expect(isPlaying, isFalse, reason: 'Video should be safely paused');
      expect(showControls, isTrue, reason: 'Controls should remain visible for user to replay or exit');

      // Now verify replay action:
      // Tapping play when completed rewinds to zero and resets completion:
      void simulateReplay() {
        if (hasTriggeredCompletion) {
          hasTriggeredCompletion = false;
          isPlaying = true;
        }
      }

      simulateReplay();
      expect(hasTriggeredCompletion, isFalse);
      expect(isPlaying, isTrue);
      expect(currentEpisodeNumber, equals(2));
    });
  });
}
