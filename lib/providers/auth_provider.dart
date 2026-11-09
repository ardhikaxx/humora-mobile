import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/network/api_service.dart';
import '../core/services/local_notification_service.dart';
import '../data/models/user_model.dart';

class AuthProvider extends ChangeNotifier {
  final ApiService _api = ApiService();
  static const String _userCacheKey = 'humora_auth_cached_user';

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
    totalQuota: 0,
    usedQuota: 0,
    remainingQuota: 0,
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

  Future<void> _saveUserToCache(UserModel user) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_userCacheKey, jsonEncode(user.toJson()));
    } catch (e) {
      debugPrint('AuthProvider: Failed to cache user: $e');
    }
  }

  Future<void> _clearUserCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_userCacheKey);
    } catch (e) {
      debugPrint('AuthProvider: Failed to clear cached user: $e');
    }
  }

  Future<void> initialize() async {
    // 1. Immediately restore cached user from local storage (eliminates guest flicker)
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedJson = prefs.getString(_userCacheKey);
      if (cachedJson != null && cachedJson.isNotEmpty) {
        final Map<String, dynamic> decoded = jsonDecode(cachedJson);
        _user = UserModel.fromJson(decoded);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('AuthProvider: Error reading cached user: $e');
    }

    // 2. Read persistent token
    final token = await _api.getToken();
    if (token == null || token.isEmpty) {
      if (_user.tier != UserTier.guest) {
        _user = _defaultGuestUser;
        await _clearUserCache();
        notifyListeners();
      }
      return;
    }

    // 3. If token exists, validate and refresh user data with backend in background
    try {
      final res = await _api.getMe();
      if (res.data != null && res.data['data'] != null && res.data['data']['user'] != null) {
        _user = UserModel.fromJson(res.data['data']['user'] as Map<String, dynamic>);
        await _saveUserToCache(_user);
        _checkSubscriptionNotifications();
      }
    } catch (e) {
      // ONLY clear token if backend explicitly returns HTTP 401 Unauthorized (token deleted/revoked)
      if (e is DioException && e.response?.statusCode == 401) {
        debugPrint('AuthProvider: Token is invalid (401 Unauthorized). Resetting to guest.');
        await _api.clearToken();
        await _clearUserCache();
        _user = _defaultGuestUser;
      } else {
        // Network timeout, offline startup, socket exception, 500 server error:
        // NEVER log the user out! Keep existing logged-in session intact!
        debugPrint('AuthProvider: Transient network or server error during getMe ($e). Keeping user session active.');
      }
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
  int get totalQuota => _user.currentTotalQuota;
  int get usedQuota => _user.currentUsedQuota;
  int get remainingQuota => _user.currentRemainingQuota;

  // Access permission rule for video playback:
  // - If series has <= 2 total episodes, only Episode 1 is free trial (Episode 2 is locked).
  // - If series has > 2 total episodes, Episodes 1 & 2 are free trial (Episode 3+ are locked).
  // - For locked episodes:
  //   * If user has active Full Access -> accessible!
  //   * If episodeId is in accessibleEpisodeIds -> accessible!
  //   * If user has active weekly package and has remaining quota > 0 -> accessible!
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

    // 5. If specific episodeId is provided, check if it's already in user's active quota
    if (episodeId != null && episodeId > 0) {
      if (_user.accessibleEpisodeIds.contains(episodeId)) {
        return true;
      }
    }

    // 6. If user has active weekly package and has remaining quota > 0, they can choose ANY video!
    if (_user.hasWeeklyActive && (_user.remainingQuota ?? 0) > 0) {
      return true;
    }

    // 7. Fallback for demo/tier switching or legacy VIP without specific episode lists
    if (_user.accessibleEpisodeIds.isEmpty && isPremium && !_user.hasWeeklyActive) {
      return true;
    }

    return false;
  }

  /// Unlock an episode using available weekly/add-on quota
  Future<bool> unlockEpisode(int episodeId) async {
    if (!isPremium || !_user.hasWeeklyActive || (_user.remainingQuota ?? 0) <= 0) {
      return false;
    }

    try {
      final res = await _api.unlockEpisode(episodeId);
      if (res.data != null && res.data['success'] == true) {
        final data = res.data['data'] as Map<String, dynamic>;
        final newRemaining = int.tryParse(data['remaining_quota']?.toString() ?? '0') ?? 0;
        final newUsed = int.tryParse(data['used_quota']?.toString() ?? '0') ?? 0;
        final newTotal = int.tryParse(data['total_quota']?.toString() ?? '15') ?? 15;
        final effectiveTierStr = (data['effective_tier'] ?? 'free').toString();

        final updatedIds = List<int>.from(_user.accessibleEpisodeIds);
        if (!updatedIds.contains(episodeId)) {
          updatedIds.add(episodeId);
        }

        UserTier tier = _user.tier;
        if (effectiveTierStr == 'free' || newRemaining <= 0) {
          tier = UserTier.free;
        }

        _user = _user.copyWith(
          tier: tier,
          accessibleEpisodeIds: updatedIds,
          accessibleEpisodesCount: updatedIds.length,
          remainingQuota: newRemaining,
          usedQuota: newUsed,
          totalQuota: newTotal,
          hasWeeklyActive: newRemaining > 0,
        );

        await _saveUserToCache(_user);
        notifyListeners();
        return true;
      }
    } catch (e) {
      debugPrint('AuthProvider: Failed to unlock episode: $e');
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
          totalQuota: 0,
          usedQuota: 0,
          remainingQuota: 0,
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
          hasWeeklyActive: true,
          totalQuota: 15,
          usedQuota: 4,
          remainingQuota: 11,
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
          totalQuota: 15,
          usedQuota: 15,
          remainingQuota: 0,
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
          await _saveUserToCache(_user);
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
          await _saveUserToCache(_user);
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
        await _saveUserToCache(_user);
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
        await _saveUserToCache(_user);
        notifyListeners();
        _checkSubscriptionNotifications();
      }
    } catch (e) {
      if (e is DioException && e.response?.statusCode == 401) {
        await logout();
      }
    }
  }

  Future<void> logout() async {
    _isLoading = true;
    notifyListeners();

    try {
      await _api.logout();
    } catch (_) {
      await _api.clearToken();
    } finally {
      await _clearUserCache();
      _user = _defaultGuestUser;
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> verifyForgotPasswordEmail(String email) async {
    return verifyForgotPasswordIdentifier(email);
  }

  Future<bool> verifyForgotPasswordIdentifier(String identifier) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final res = await _api.verifyForgotPasswordIdentifier(identifier.trim());
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
    String? identifier,
    String? email,
    required String password,
    required String passwordConfirmation,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final target = (identifier != null && identifier.trim().isNotEmpty)
          ? identifier.trim()
          : (email?.trim() ?? '');
      final res = await _api.resetPassword(
        identifier: target,
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
