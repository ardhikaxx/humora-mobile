import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import '../core/network/api_service.dart';
import '../core/services/local_notification_service.dart';
import '../data/models/user_model.dart';

class AuthProvider extends ChangeNotifier {
  final ApiService _api = ApiService();

  UserModel _user = _defaultGuestUser;
  bool _isLoading = false;
  String? _errorMessage;

  static const UserModel _defaultGuestUser = UserModel(
    id: '0',
    name: 'Tamu Humora',
    email: '',
    phone: '',
    gender: 'Laki-laki',
    memberSince: 'Hari ini',
    tier: UserTier.guest,
    status: 'active',
  );

  UserModel get user => _user;
  UserTier get currentTier => _user.tier;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  bool get isGuest => _user.tier == UserTier.guest;
  bool get isFree => _user.tier == UserTier.free;
  bool get isPremium => _user.tier == UserTier.premium;
  bool get isExpired => _user.tier == UserTier.expired;

  AuthProvider() {
    initialize();
  }

  Future<void> initialize() async {
    final token = await _api.getToken();
    if (token == null || token.isEmpty) {
      _user = _defaultGuestUser;
      notifyListeners();
      return;
    }

    try {
      final res = await _api.getMe();
      if (res.data != null && res.data['data'] != null && res.data['data']['user'] != null) {
        _user = UserModel.fromJson(res.data['data']['user'] as Map<String, dynamic>);
        _checkSubscriptionNotifications();
      }
    } catch (_) {
      // If token expired/invalid, clear it and fall back to guest
      await _api.clearToken();
      _user = _defaultGuestUser;
    } finally {
      notifyListeners();
    }
  }

  void _checkSubscriptionNotifications() {
    if (_user.isPremium && _user.remainingDays != null) {
      if (_user.remainingDays! <= 3 && _user.remainingDays! >= 0) {
        LocalNotificationService.showExpiringSubscriptionNotification(
          remainingDays: _user.remainingDays!,
        );
      }
    }
  }

  bool get hasFullAccess => _user.hasFullAccess;
  bool get hasWeeklyActive => _user.hasWeeklyActive;
  bool get canPurchaseAddon => _user.canPurchaseAddon;
  List<int> get accessibleEpisodeIds => _user.accessibleEpisodeIds;
  int get accessibleEpisodesCount => _user.accessibleEpisodesCount;

  // Access permission rule for video playback:
  // - If series has <= 2 total episodes, only Episode 1 is free trial (Episode 2 is locked).
  // - If series has > 2 total episodes, Episodes 1 & 2 are free trial (Episode 3+ are locked).
  // - For locked episodes:
  //   * If user has active Full Access -> accessible!
  //   * If episodeId is in accessibleEpisodeIds -> accessible!
  //   * Otherwise -> locked.
  bool canAccessEpisode(
    int episodeNumber, {
    int? episodeId,
    int? seriesTotalEpisodes,
    bool? isFreeEpisode,
  }) {
    // 1. Explicitly marked as free by backend resource
    if (isFreeEpisode == true) {
      return true;
    }

    // 2. HUMORA Free Trial Policy:
    // - Standard series: Episode 1 & 2 are free preview/trial for all users.
    // - Short series (explicitly having 1 or 2 episodes in total): only Episode 1 is free trial.
    // NOTE: If seriesTotalEpisodes is not yet loaded (null or 0), default to Episode 1 & 2 free trial.
    final bool isFreeTrial;
    if (seriesTotalEpisodes != null && (seriesTotalEpisodes == 1 || seriesTotalEpisodes == 2)) {
      isFreeTrial = episodeNumber <= 1;
    } else {
      isFreeTrial = episodeNumber <= 2;
    }

    if (isFreeTrial && isFreeEpisode != false) {
      return true;
    }

    // 3. Locked / VIP episode (e.g. Episode 3+) requires active subscription / premium
    if (!isPremium) {
      return false;
    }

    // 4. If user has active Full Access to whole catalog
    if (_user.hasFullAccess) {
      return true;
    }

    // 5. If specific episodeId is provided, check if it's in user's active quota
    if (episodeId != null && episodeId > 0) {
      if (_user.accessibleEpisodeIds.contains(episodeId)) {
        return true;
      }
    }

    // 6. Fallback for demo/tier switching or legacy VIP without specific episode lists
    if (_user.accessibleEpisodeIds.isEmpty && isPremium) {
      return true;
    }

    return false;
  }

  void switchTier(UserTier tier) {
    switch (tier) {
      case UserTier.guest:
        _user = _defaultGuestUser;
        break;
      case UserTier.free:
        _user = const UserModel(
          id: '1',
          name: 'Ardhika Pradana',
          email: 'ardhika@humora.id',
          phone: '081288997766',
          gender: 'Laki-laki',
          memberSince: 'Maret 2026',
          tier: UserTier.free,
          status: 'active',
        );
        break;
      case UserTier.premium:
        _user = const UserModel(
          id: '2',
          name: 'Budi Pratama',
          email: 'budi@humora.id',
          phone: '081299887766',
          gender: 'Laki-laki',
          memberSince: 'Januari 2026',
          tier: UserTier.premium,
          validUntil: '2026-12-31 23:59:59',
          status: 'active',
        );
        break;
      case UserTier.expired:
        _user = const UserModel(
          id: '3',
          name: 'Siti Nurhaliza',
          email: 'expired@humora.id',
          phone: '081277665544',
          gender: 'Perempuan',
          memberSince: 'November 2025',
          tier: UserTier.expired,
          validUntil: '2026-03-01 00:00:00',
          status: 'active',
        );
        break;
    }
    notifyListeners();
  }

  Future<bool> login({
    required String identifier,
    required String password,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final res = await _api.login(
        identifier: identifier.trim(),
        password: password,
      );

      if (res.data != null && res.data['data'] != null) {
        final token = res.data['data']['token']?.toString();
        if (token != null && token.isNotEmpty) {
          await _api.saveToken(token);
        }

        if (res.data['data']['user'] != null) {
          _user = UserModel.fromJson(res.data['data']['user'] as Map<String, dynamic>);
        } else {
          await refreshUser();
        }

        _isLoading = false;
        notifyListeners();
        return true;
      }
      _errorMessage = 'Respons login tidak valid.';
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _isLoading = false;
      _errorMessage = _parseError(e);
      notifyListeners();
      return false;
    }
  }

  Future<bool> register({
    required String fullName,
    required String identifier,
    required String password,
    String gender = 'Laki-laki',
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final isEmail = identifier.contains('@');

    try {
      final res = await _api.register(
        name: fullName.trim(),
        email: isEmail ? identifier.trim() : null,
        phone: !isEmail ? identifier.trim() : null,
        password: password,
        gender: gender,
      );

      if (res.data != null && res.data['data'] != null) {
        final token = res.data['data']['token']?.toString();
        if (token != null && token.isNotEmpty) {
          await _api.saveToken(token);
        }

        if (res.data['data']['user'] != null) {
          _user = UserModel.fromJson(res.data['data']['user'] as Map<String, dynamic>);
        }

        _isLoading = false;
        notifyListeners();
        return true;
      }
      _errorMessage = 'Pendaftaran gagal diproses.';
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _isLoading = false;
      _errorMessage = _parseError(e);
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateProfile({
    required String name,
    required String email,
    required String phone,
    required String gender,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final res = await _api.updateProfile(
        name: name,
        email: email.isNotEmpty ? email : null,
        phone: phone.isNotEmpty ? phone : null,
        gender: gender,
      );

      if (res.data != null && res.data['data'] != null && res.data['data']['user'] != null) {
        _user = UserModel.fromJson(res.data['data']['user'] as Map<String, dynamic>);
      }
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = _parseError(e);
      notifyListeners();
      return false;
    }
  }

  Future<void> refreshUser() async {
    try {
      final res = await _api.getMe();
      if (res.data != null && res.data['data'] != null && res.data['data']['user'] != null) {
        _user = UserModel.fromJson(res.data['data']['user'] as Map<String, dynamic>);
        notifyListeners();
        _checkSubscriptionNotifications();
      }
    } catch (_) {}
  }

  Future<void> logout() async {
    _isLoading = true;
    notifyListeners();

    try {
      await _api.logout();
    } catch (_) {
      await _api.clearToken();
    } finally {
      _user = _defaultGuestUser;
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> verifyForgotPasswordEmail(String email) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final res = await _api.verifyForgotPasswordEmail(email.trim());
      _isLoading = false;
      notifyListeners();
      return res.data != null && res.data['success'] == true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = _parseError(e);
      notifyListeners();
      return false;
    }
  }

  Future<bool> resetPassword({
    required String email,
    required String password,
    required String passwordConfirmation,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final res = await _api.resetPassword(
        email: email.trim(),
        password: password,
        passwordConfirmation: passwordConfirmation,
      );
      _isLoading = false;
      notifyListeners();
      return res.data != null && res.data['success'] == true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = _parseError(e);
      notifyListeners();
      return false;
    }
  }

  String _parseError(dynamic error) {
    if (error is DioException && error.response?.data != null) {
      final data = error.response!.data;
      if (data is Map) {
        if (data['message'] != null) {
          return data['message'].toString();
        }
        if (data['errors'] is Map) {
          final errMap = data['errors'] as Map;
          final firstKey = errMap.keys.firstOrNull;
          if (firstKey != null && errMap[firstKey] is List) {
            return (errMap[firstKey] as List).first.toString();
          }
        }
      }
    }
    return 'Terjadi kesalahan jaringan atau server. Pastikan server backend aktif.';
  }
}
