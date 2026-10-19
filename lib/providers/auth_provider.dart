import 'package:flutter/material.dart';
import '../data/models/user_model.dart';
import '../data/models/subscription_plan_model.dart';

class AuthProvider extends ChangeNotifier {
  UserModel _user = _defaultGuestUser;

  static const UserModel _defaultGuestUser = UserModel(
    id: 'guest-0',
    name: 'Tamu Humora',
    email: '',
    phone: '',
    gender: 'Laki-laki',
    memberSince: 'Hari ini',
    tier: UserTier.guest,
  );

  static const UserModel _defaultFreeUser = UserModel(
    id: 'user-free-1',
    name: 'Ardhika Pradana',
    email: 'ardhika@humora.id',
    phone: '0812-8899-7766',
    gender: 'Laki-laki',
    memberSince: '12 Januari 2026',
    tier: UserTier.free,
  );

  static const UserModel _defaultPremiumUser = UserModel(
    id: 'user-premium-1',
    name: 'Ardhika Pradana',
    email: 'ardhika@humora.id',
    phone: '0812-8899-7766',
    gender: 'Laki-laki',
    memberSince: '12 Januari 2026',
    tier: UserTier.premium,
    activePlanName: 'Paket 3 Bulan',
    validUntil: '16 Januari 2027',
    remainingDays: 90,
  );

  static const UserModel _defaultExpiredUser = UserModel(
    id: 'user-expired-1',
    name: 'Ardhika Pradana',
    email: 'ardhika@humora.id',
    phone: '0812-8899-7766',
    gender: 'Laki-laki',
    memberSince: '12 Januari 2026',
    tier: UserTier.expired,
    activePlanName: 'Paket 3 Bulan (Kedaluwarsa)',
    validUntil: '15 Oktober 2026',
    remainingDays: 0,
  );

  // Default to Guest mode as specified in the prompt
  UserModel get user => _user;
  UserTier get currentTier => _user.tier;

  bool get isGuest => _user.tier == UserTier.guest;
  bool get isFree => _user.tier == UserTier.free;
  bool get isPremium => _user.tier == UserTier.premium;
  bool get isExpired => _user.tier == UserTier.expired;

  // Helper check if episode can be played without paywall
  bool canAccessEpisode(int episodeNumber) {
    if (isPremium) {
      return true; // All unlocked without locks
    }
    // Tamu, User Gratis, Expired only can access episode 1 & 2
    return episodeNumber <= 2;
  }

  void switchTier(UserTier newTier) {
    switch (newTier) {
      case UserTier.guest:
        _user = _defaultGuestUser;
        break;
      case UserTier.free:
        _user = _defaultFreeUser;
        break;
      case UserTier.premium:
        _user = _defaultPremiumUser;
        break;
      case UserTier.expired:
        _user = _defaultExpiredUser;
        break;
    }
    notifyListeners();
  }

  void login({required String identifier, required String password}) {
    _user = _defaultFreeUser.copyWith(
      email: identifier.contains('@') ? identifier : 'ardhika@humora.id',
      phone: !identifier.contains('@') ? identifier : '0812-8899-7766',
    );
    notifyListeners();
  }

  void register({
    required String fullName,
    required String identifier,
    required String password,
  }) {
    _user = UserModel(
      id: 'user-${DateTime.now().millisecondsSinceEpoch}',
      name: fullName.isNotEmpty ? fullName : 'Ardhika Pradana',
      email: identifier.contains('@') ? identifier : 'ardhika@humora.id',
      phone: !identifier.contains('@') ? identifier : '0812-8899-7766',
      gender: 'Laki-laki',
      memberSince: '18 Oktober 2026',
      tier: UserTier.free,
    );
    notifyListeners();
  }

  void activateSubscription(SubscriptionPlanModel plan) {
    _user = _user.copyWith(
      tier: UserTier.premium,
      activePlanName: plan.name,
      validUntil: '16 Januari 2027',
      remainingDays: 90,
    );
    notifyListeners();
  }

  void updateProfile({
    required String name,
    required String email,
    required String phone,
    required String gender,
  }) {
    _user = _user.copyWith(
      name: name,
      email: email,
      phone: phone,
      gender: gender,
    );
    notifyListeners();
  }

  void logout() {
    _user = _defaultGuestUser;
    notifyListeners();
  }
}
