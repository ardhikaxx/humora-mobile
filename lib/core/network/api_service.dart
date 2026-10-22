import 'dart:io';
import 'dart:math';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'api_config.dart';

class ApiResponse<T> {
  final bool success;
  final String message;
  final T? data;
  final String? errorCode;
  final Map<String, dynamic>? errors;

  ApiResponse({
    required this.success,
    required this.message,
    this.data,
    this.errorCode,
    this.errors,
  });

  factory ApiResponse.fromJson(
    Map<String, dynamic> json,
    T Function(dynamic data)? fromJsonData,
  ) {
    return ApiResponse<T>(
      success: json['success'] == true,
      message: json['message']?.toString() ?? '',
      errorCode: json['error_code']?.toString(),
      errors: json['errors'] is Map<String, dynamic> ? json['errors'] : null,
      data: json['data'] != null && fromJsonData != null
          ? fromJsonData(json['data'])
          : json['data'] as T?,
    );
  }
}

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;

  late final Dio _dio;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  static const String _tokenKey = 'humora_auth_token';
  String? _cachedToken;

  ApiService._internal() {
    _dio = Dio(
      BaseOptions(
        baseUrl: ApiConfig.baseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
      ),
    );

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          options.baseUrl = ApiConfig.baseUrl;

          // Always attach persistent session/device ID for guest & member analytics/likes
          final sessionId = await getSessionId();
          options.headers['X-Session-ID'] = sessionId;

          final token = await getToken();
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
        onError: (DioException e, handler) {
          if (e.response?.statusCode == 401) {
            // Unauthorized, token might be expired/invalid
          }
          return handler.next(e);
        },
      ),
    );
  }

  Dio get dio => _dio;

  // --- TOKEN MANAGEMENT ---
  Future<String?> getToken() async {
    _cachedToken ??= await _storage.read(key: _tokenKey);
    return _cachedToken;
  }

  Future<void> saveToken(String token) async {
    _cachedToken = token;
    await _storage.write(key: _tokenKey, value: token);
  }

  Future<void> clearToken() async {
    _cachedToken = null;
    await _storage.delete(key: _tokenKey);
  }

  // --- DEVICE & GUEST SESSION MANAGEMENT ---
  static const String _sessionKey = 'humora_device_session_id';
  String? _cachedSessionId;

  Future<String> getSessionId() async {
    if (_cachedSessionId != null && _cachedSessionId!.isNotEmpty) {
      return _cachedSessionId!;
    }
    try {
      _cachedSessionId = await _storage.read(key: _sessionKey);
    } catch (_) {}

    if (_cachedSessionId == null || _cachedSessionId!.isEmpty) {
      final now = DateTime.now().millisecondsSinceEpoch;
      final rand = Random().nextInt(0x7FFFFFFF);
      _cachedSessionId = 'device_${now}_$rand';
      try {
        await _storage.write(key: _sessionKey, value: _cachedSessionId!);
      } catch (_) {}
    }
    return _cachedSessionId!;
  }

  // --- AUTHENTICATION ---
  Future<Response> register({
    required String name,
    String? email,
    String? phone,
    required String password,
    String? gender,
  }) async {
    return await _dio.post(
      '/auth/register',
      data: {
        'name': name,
        if (email != null && email.isNotEmpty) 'email': email,
        if (phone != null && phone.isNotEmpty) 'phone': phone,
        'password': password,
        'gender': gender ?? 'Laki-laki',
      },
    );
  }

  Future<Response> login({
    required String identifier,
    required String password,
  }) async {
    return await _dio.post(
      '/auth/login',
      data: {
        'identifier': identifier,
        'email': identifier,
        'login': identifier,
        'password': password,
      },
    );
  }

  Future<Response> getMe() async {
    return await _dio.get('/auth/me');
  }

  Future<Response> updateProfile({
    required String name,
    String? email,
    String? phone,
    String? gender,
  }) async {
    final data = <String, dynamic>{'name': name};
    if (email != null) data['email'] = email;
    if (phone != null) data['phone'] = phone;
    if (gender != null) data['gender'] = gender;

    return await _dio.put(
      '/auth/profile',
      data: data,
    );
  }

  Future<Response> updatePassword({
    required String currentPassword,
    required String password,
    required String passwordConfirmation,
  }) async {
    return await _dio.put(
      '/auth/password',
      data: {
        'current_password': currentPassword,
        'password': password,
        'password_confirmation': passwordConfirmation,
      },
    );
  }

  Future<Response> logout() async {
    try {
      final res = await _dio.post('/auth/logout');
      await clearToken();
      return res;
    } catch (e) {
      await clearToken();
      rethrow;
    }
  }

  Future<Response> verifyForgotPasswordEmail(String email) async {
    return await _dio.post(
      '/auth/forgot-password',
      data: {'email': email},
    );
  }

  Future<Response> resetPassword({
    required String email,
    required String password,
    required String passwordConfirmation,
  }) async {
    return await _dio.post(
      '/auth/reset-password',
      data: {
        'email': email,
        'password': password,
        'password_confirmation': passwordConfirmation,
      },
    );
  }

  // --- CATALOG & DISCOVERY ---
  Future<Response> getSeries({
    String? search,
    String? category,
    bool? isFeatured,
  }) async {
    final Map<String, dynamic> query = {};
    if (search != null && search.isNotEmpty) query['search'] = search;
    if (category != null && category.isNotEmpty && category != 'Semua') {
      query['category'] = category;
    }
    if (isFeatured != null) query['is_featured'] = isFeatured ? '1' : '0';

    return await _dio.get('/series', queryParameters: query);
  }

  Future<Response> getSeriesDetail(String slugOrId) async {
    return await _dio.get('/series/$slugOrId');
  }

  Future<Response> getCategories() async {
    return await _dio.get('/categories');
  }

  Future<Response> getEpisodeDetail(int id) async {
    return await _dio.get('/episodes/$id');
  }

  // --- SUBSCRIPTIONS & PAYMENT ---
  Future<Response> getSubscriptionPlans() async {
    return await _dio.get('/subscription/plans');
  }

  Future<Response> getPaymentInfo() async {
    return await _dio.get('/settings/payment-info');
  }

  Future<Response> getSubscriptionStatus() async {
    return await _dio.get('/subscription/status');
  }

  Future<Response> uploadPaymentProof({
    required int planId,
    required String paymentMethod,
    required File proofFile,
    int? transactionId,
    String? trxCode,
  }) async {
    final fileName = proofFile.path.split(Platform.pathSeparator).last;
    final map = <String, dynamic>{
      'plan_id': planId,
      'payment_method': paymentMethod,
      'proof_file': await MultipartFile.fromFile(
        proofFile.path,
        filename: fileName,
      ),
    };
    if (transactionId != null) map['transaction_id'] = transactionId;
    if (trxCode != null) map['trx_code'] = trxCode;
    final formData = FormData.fromMap(map);

    return await _dio.post(
      '/transactions/upload-proof',
      data: formData,
      options: Options(
        headers: {
          'Content-Type': 'multipart/form-data',
        },
      ),
    );
  }

  Future<Response> getTransactions() async {
    return await _dio.get('/transactions');
  }

  Future<Response> getTransactionDetail(int id) async {
    return await _dio.get('/transactions/$id');
  }

  // --- WATCH HISTORY ---
  Future<Response> getWatchHistory() async {
    return await _dio.get('/watch-history');
  }

  Future<Response> updateWatchProgress({
    required int episodeId,
    int? seriesId,
    required int lastPosition,
    required int durationSeconds,
    int? progressPercent,
    String? sessionId,
  }) async {
    final data = <String, dynamic>{
      'episode_id': episodeId,
      'last_position': lastPosition,
      'duration_seconds': durationSeconds,
    };
    if (seriesId != null) data['series_id'] = seriesId;
    if (progressPercent != null) data['progress_percent'] = progressPercent;
    if (sessionId != null) data['session_id'] = sessionId;

    return await _dio.post(
      '/watch-history/progress',
      data: data,
    );
  }

  /// Realtime Viewing Event & Watch Time Tracking
  Future<Response> trackVideoView({
    required int episodeId,
    int? seriesId,
    required String sessionId,
    required int watchedSeconds,
    required int lastPosition,
    required int durationSeconds,
    int? progressPercent,
  }) async {
    final data = <String, dynamic>{
      'episode_id': episodeId,
      'session_id': sessionId,
      'watched_seconds': watchedSeconds,
      'last_position': lastPosition,
      'duration_seconds': durationSeconds,
    };
    if (seriesId != null) data['series_id'] = seriesId;
    if (progressPercent != null) data['progress_percent'] = progressPercent;

    return await _dio.post(
      '/videos/track-view',
      data: data,
    );
  }

  Future<Response> clearWatchHistory() async {
    return await _dio.delete('/watch-history');
  }

  // --- SOCIAL LIKES ---
  Future<Response> toggleSeriesLike(int seriesId) async {
    return await _dio.post('/series/$seriesId/like');
  }

  Future<Response> toggleEpisodeLike(int episodeId) async {
    return await _dio.post('/episodes/$episodeId/like');
  }

  Future<Response> getEpisodeLikeStatus(int episodeId) async {
    return await _dio.get('/episodes/$episodeId/like-status');
  }

  // --- NOTIFICATIONS ---
  Future<Response> getNotifications() async {
    return await _dio.get('/notifications');
  }

  Future<Response> markNotificationAsRead(int id) async {
    return await _dio.put('/notifications/$id/read');
  }

  Future<Response> markAllNotificationsAsRead() async {
    return await _dio.put('/notifications/read-all');
  }
}
