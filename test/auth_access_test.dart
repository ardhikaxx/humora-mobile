import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:humora_mobile/data/models/user_model.dart';
import 'package:humora_mobile/providers/auth_provider.dart';

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

  group('HUMORA Episode Access & Paywall Rules', () {
    late AuthProvider auth;

    setUp(() {
      auth = AuthProvider();
    });

    test('Guest and Free users can access Episode 1 and Episode 2 in standard 4-episode series', () {
      // Free user tier
      auth.switchTier(UserTier.free);

      // Episode 1 (Part 1)
      expect(
        auth.canAccessEpisode(
          1,
          episodeId: 1,
          seriesTotalEpisodes: 4,
          isFreeEpisode: true,
        ),
        isTrue,
        reason: 'Episode 1 should always be free',
      );

      // Episode 2 (Part 2) - Should NEVER trigger paywall modal!
      expect(
        auth.canAccessEpisode(
          2,
          episodeId: 2,
          seriesTotalEpisodes: 4,
          isFreeEpisode: true,
        ),
        isTrue,
        reason: 'Episode 2 should be free trial and not trigger paywall',
      );

      // Episode 2 even if seriesTotalEpisodes is not yet loaded (null or 0)
      expect(
        auth.canAccessEpisode(
          2,
          episodeId: 2,
          seriesTotalEpisodes: null,
          isFreeEpisode: true,
        ),
        isTrue,
        reason: 'Episode 2 should be free trial even without total episodes metadata',
      );
    });

    test('Episode 3 and Episode 4 are locked for Free/Guest users and require VIP', () {
      auth.switchTier(UserTier.free);

      // Episode 3 (Part 3 - VIP)
      expect(
        auth.canAccessEpisode(
          3,
          episodeId: 3,
          seriesTotalEpisodes: 4,
          isFreeEpisode: false,
        ),
        isFalse,
        reason: 'Episode 3 should be locked for Free tier to show paywall modal',
      );

      // Episode 4 (Part 4 - VIP)
      expect(
        auth.canAccessEpisode(
          4,
          episodeId: 4,
          seriesTotalEpisodes: 4,
          isFreeEpisode: false,
        ),
        isFalse,
        reason: 'Episode 4 should be locked for Free tier to show paywall modal',
      );
    });

    test('VIP user with full access can access all episodes (including Part 3 & Part 4)', () {
      auth.switchTier(UserTier.premium);

      expect(
        auth.canAccessEpisode(
          3,
          episodeId: 3,
          seriesTotalEpisodes: 4,
          isFreeEpisode: false,
        ),
        isTrue,
        reason: 'VIP user should be able to watch Episode 3',
      );

      expect(
        auth.canAccessEpisode(
          4,
          episodeId: 4,
          seriesTotalEpisodes: 4,
          isFreeEpisode: false,
        ),
        isTrue,
        reason: 'VIP user should be able to watch Episode 4',
      );
    });

    test('Short series with only 2 episodes total only has Episode 1 free', () {
      auth.switchTier(UserTier.free);

      expect(
        auth.canAccessEpisode(
          1,
          episodeId: 1,
          seriesTotalEpisodes: 2,
          isFreeEpisode: true,
        ),
        isTrue,
      );

      expect(
        auth.canAccessEpisode(
          2,
          episodeId: 2,
          seriesTotalEpisodes: 2,
          isFreeEpisode: false,
        ),
        isFalse,
        reason: 'In short 2-episode series, Episode 2 is VIP',
      );
    });
  });
}
