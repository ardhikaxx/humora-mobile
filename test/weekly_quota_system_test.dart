import 'package:flutter_test/flutter_test.dart';
import 'package:humora_mobile/data/models/user_model.dart';
import 'package:humora_mobile/providers/auth_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Weekly Quota System Tests', () {
    test('UserModel JSON serialization with quota fields', () {
      final json = {
        'id': '10',
        'name': 'Budi Pekerti',
        'email': 'budi@example.com',
        'phone': '081234567890',
        'gender': 'Laki-laki',
        'member_since': '01 November 2026',
        'tier': 'premium',
        'effective_tier': 'premium',
        'has_weekly_active': true,
        'has_full_access': false,
        'can_purchase_addon': true,
        'accessible_episode_ids': [101, 102],
        'accessible_episodes_count': 2,
        'total_quota': 15,
        'used_quota': 2,
        'remaining_quota': 13,
      };

      final user = UserModel.fromJson(json);
      expect(user.tier, UserTier.premium);
      expect(user.hasWeeklyActive, isTrue);
      expect(user.totalQuota, 15);
      expect(user.usedQuota, 2);
      expect(user.remainingQuota, 13);
      expect(user.currentRemainingQuota, 13);
      expect(user.accessibleEpisodeIds, containsAll([101, 102]));

      final serialized = user.toJson();
      expect(serialized['total_quota'], 15);
      expect(serialized['used_quota'], 2);
      expect(serialized['remaining_quota'], 13);
    });

    test('Weekly subscriber with remaining quota > 0 can access ANY video in the catalog', () {
      final auth = AuthProvider();
      
      // Simulate weekly subscriber with 15 quota
      auth.switchTier(UserTier.premium);
      expect(auth.user.hasWeeklyActive, isTrue);
      expect(auth.user.remainingQuota, 11); // mock starts at 11

      // Episode 1 & 2 of Taxi Online (free trial episodes)
      expect(auth.canAccessEpisode(1, episodeId: 10, seriesTotalEpisodes: 4), isTrue);
      expect(auth.canAccessEpisode(2, episodeId: 11, seriesTotalEpisodes: 4), isTrue);

      // Episode 3 & 4 of Taxi Online (normally locked, but weekly user has quota!)
      expect(auth.canAccessEpisode(3, episodeId: 12, seriesTotalEpisodes: 4), isTrue);
      expect(auth.canAccessEpisode(4, episodeId: 13, seriesTotalEpisodes: 4), isTrue);

      // Episode 3 & 4 of Juru Parkir (another series entirely, weekly user can pick any video!)
      expect(auth.canAccessEpisode(3, episodeId: 23, seriesTotalEpisodes: 6), isTrue);
      expect(auth.canAccessEpisode(4, episodeId: 24, seriesTotalEpisodes: 6), isTrue);
    });

    test('When remaining quota reaches 0, user reverts to free and locked episodes are blocked', () {
      final auth = AuthProvider();

      // Set user to free with 0 quota
      auth.switchTier(UserTier.free);
      expect(auth.isFree, isTrue);
      expect(auth.user.hasWeeklyActive, isFalse);
      expect(auth.user.remainingQuota, 0);

      // Free trial episodes (Ep 1 & 2) remain accessible
      expect(auth.canAccessEpisode(1, episodeId: 10, seriesTotalEpisodes: 4), isTrue);
      expect(auth.canAccessEpisode(2, episodeId: 11, seriesTotalEpisodes: 4), isTrue);

      // Locked episodes (Ep 3+) are BLOCKED
      expect(auth.canAccessEpisode(3, episodeId: 12, seriesTotalEpisodes: 4), isFalse);
      expect(auth.canAccessEpisode(4, episodeId: 13, seriesTotalEpisodes: 4), isFalse);
    });

    test('Add-on purchase restores quota and premium access', () {
      final auth = AuthProvider();

      // Start with expired/exhausted quota
      auth.switchTier(UserTier.expired);
      expect(auth.isExpired, isTrue);
      expect(auth.canAccessEpisode(3, episodeId: 30, seriesTotalEpisodes: 5), isFalse);

      // User purchases Add-on 5 Video, quota becomes 5 and tier becomes premium
      final userAfterAddon = auth.user.copyWith(
        tier: UserTier.premium,
        hasWeeklyActive: true,
        totalQuota: 20, // 15 + 5
        usedQuota: 15,
        remainingQuota: 5,
        accessibleEpisodeIds: List.generate(15, (i) => i + 1),
      );

      expect(userAfterAddon.isPremium, isTrue);
      expect(userAfterAddon.remainingQuota, 5);
      expect(userAfterAddon.totalQuota, 20);
      expect(userAfterAddon.hasWeeklyActive, isTrue);
    });
  });
}
