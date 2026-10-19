import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class LocalNotificationService {
  static final LocalNotificationService _instance = LocalNotificationService._internal();
  factory LocalNotificationService() => _instance;
  LocalNotificationService._internal();

  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static bool _isInitialized = false;
  static bool disableInTests = false;

  // Channel IDs
  static const String vipChannelId = 'humora_vip_channel';
  static const String contentChannelId = 'humora_content_channel';
  static const String promoChannelId = 'humora_promo_channel';

  /// Initialize local notification plugin and create channels
  static Future<void> initialize() async {
    if (_isInitialized || disableInTests) return;

    try {
      const AndroidInitializationSettings androidSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');

      const DarwinInitializationSettings iosSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      const InitializationSettings initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      await _notificationsPlugin.initialize(
        settings: initSettings,
        onDidReceiveNotificationResponse: (NotificationResponse response) {
          debugPrint('Notification clicked: ${response.payload}');
        },
      );

      // Create Android Notification Channels for Android 8.0+
      if (Platform.isAndroid) {
        final androidPlugin = _notificationsPlugin
            .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

        if (androidPlugin != null) {
          await androidPlugin.requestNotificationsPermission();

          // 1. VIP & Transaction channel (Max importance, alert, lockscreen visible)
          await androidPlugin.createNotificationChannel(
            const AndroidNotificationChannel(
              vipChannelId,
              'Notifikasi VIP & Transaksi',
              description: 'Pemberitahuan persetujuan dan masa aktif langganan VIP HUMORA',
              importance: Importance.max,
              enableVibration: true,
              playSound: true,
              showBadge: true,
            ),
          );

          // 2. Video & Episode Channel
          await androidPlugin.createNotificationChannel(
            const AndroidNotificationChannel(
              contentChannelId,
              'Rilis Video & Konten Populer',
              description: 'Pemberitahuan video baru dan konten komedi viral pilihan',
              importance: Importance.high,
              enableVibration: true,
              playSound: true,
              showBadge: true,
            ),
          );

          // 3. Promo & Recommendation Channel
          await androidPlugin.createNotificationChannel(
            const AndroidNotificationChannel(
              promoChannelId,
              'Promo & Rekomendasi Langganan',
              description: 'Ajakan berlangganan dan info penawaran menarik HUMORA',
              importance: Importance.defaultImportance,
              enableVibration: true,
              playSound: true,
            ),
          );
        }
      }

      _isInitialized = true;
      debugPrint('LocalNotificationService initialized successfully.');
    } catch (e) {
      debugPrint('Error initializing LocalNotificationService: $e');
    }
  }

  // =========================================================================
  // 1. NOTIFIKASI VERIFIKASI PREMIUM DISETUJUI ADMIN
  // =========================================================================
  static Future<void> showVipApprovedNotification({
    required String trxCode,
    String? planName,
  }) async {
    if (disableInTests) return;

    final planStr = planName != null ? ' ($planName)' : '';
    const id = 1001;

    final androidDetails = AndroidNotificationDetails(
      vipChannelId,
      'Notifikasi VIP & Transaksi',
      channelDescription: 'Pemberitahuan persetujuan dan masa aktif langganan VIP HUMORA',
      importance: Importance.max,
      priority: Priority.high,
      color: const Color(0xFF43135C),
      icon: '@mipmap/ic_launcher',
      enableVibration: true,
      visibility: NotificationVisibility.public,
      styleInformation: BigTextStyleInformation(
        'Selamat! Pembayaran transaksi $trxCode$planStr Anda telah disetujui admin. Semua video premium HUMORA kini terbuka tanpa batas!',
        contentTitle: '🎉 Akun VIP HUMORA Anda Telah Aktif!',
        summaryText: 'Transaksi Berhasil',
      ),
    );

    final notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: const DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );

    await _notificationsPlugin.show(
      id: id,
      title: '🎉 Akun VIP HUMORA Anda Telah Aktif!',
      body: 'Pembayaran transaksi $trxCode$planStr telah disetujui admin. Nikmati tontonan komedi tanpa batas!',
      notificationDetails: notificationDetails,
      payload: 'vip_approved',
    );
  }

  // =========================================================================
  // 2. NOTIFIKASI VIDEO BARU
  // =========================================================================
  static Future<void> showNewVideoNotification({
    required String title,
    String? episodeName,
  }) async {
    if (disableInTests) return;

    const id = 2001;
    final epStr = episodeName != null ? ' - $episodeName' : '';

    final androidDetails = AndroidNotificationDetails(
      contentChannelId,
      'Rilis Video & Konten Populer',
      channelDescription: 'Pemberitahuan video baru dan konten komedi viral pilihan',
      importance: Importance.high,
      priority: Priority.high,
      color: const Color(0xFF43135C),
      icon: '@mipmap/ic_launcher',
      enableVibration: true,
      visibility: NotificationVisibility.public,
      styleInformation: BigTextStyleInformation(
        'Episode terbaru "$title$epStr" sudah siap ditonton! Buka aplikasi sekarang dan tertawalah sepuasnya.',
        contentTitle: '🎬 Episode Baru Rilis di HUMORA!',
        summaryText: 'Konten Baru',
      ),
    );

    final notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: const DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );

    await _notificationsPlugin.show(
      id: id,
      title: '🎬 Episode Baru Rilis di HUMORA!',
      body: '"$title$epStr" sudah tayang! Nonton sekarang dan segarkan harimu.',
      notificationDetails: notificationDetails,
      payload: 'new_video',
    );
  }

  // =========================================================================
  // 3. NOTIFIKASI VIDEO POPULER
  // =========================================================================
  static Future<void> showPopularVideoNotification({
    required String title,
    String? totalLikes,
  }) async {
    if (disableInTests) return;

    const id = 3001;
    final likeStr = totalLikes != null ? ' ($totalLikes suka)' : '';

    final androidDetails = AndroidNotificationDetails(
      contentChannelId,
      'Rilis Video & Konten Populer',
      channelDescription: 'Pemberitahuan video baru dan konten komedi viral pilihan',
      importance: Importance.high,
      priority: Priority.high,
      color: const Color(0xFF43135C),
      icon: '@mipmap/ic_launcher',
      enableVibration: true,
      visibility: NotificationVisibility.public,
      styleInformation: BigTextStyleInformation(
        'Judul "$title"$likeStr lagi trending dan paling banyak ditonton minggu ini! Jangan sampai ketinggalan kelucuannya.',
        contentTitle: '🔥 Video Komedi Terpopuler Minggu Ini!',
        summaryText: 'Trending',
      ),
    );

    final notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: const DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );

    await _notificationsPlugin.show(
      id: id,
      title: '🔥 Video Komedi Terpopuler Minggu Ini!',
      body: '"$title" sedang ramai ditonton! Tonton sekarang bareng teman-temanmu.',
      notificationDetails: notificationDetails,
      payload: 'popular_video',
    );
  }

  // =========================================================================
  // 4. NOTIFIKASI AJAKAN BERLANGGANAN (UPGRADE VIP)
  // =========================================================================
  static Future<void> showSubscriptionInviteNotification() async {
    if (disableInTests) return;

    const id = 4001;

    final androidDetails = AndroidNotificationDetails(
      promoChannelId,
      'Promo & Rekomendasi Langganan',
      channelDescription: 'Ajakan berlangganan dan info penawaran menarik HUMORA',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
      color: const Color(0xFF43135C),
      icon: '@mipmap/ic_launcher',
      styleInformation: const BigTextStyleInformation(
        'Mau nonton semua episode tanpa jeda dan tanpa batas? Dapatkan akses VIP mulai dari Rp15.000 saja. Cek paket sekarang!',
        contentTitle: '⭐ Upgrade Akun HUMORA ke VIP Sekarang!',
        summaryText: 'Penawaran Spesial',
      ),
    );

    final notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: const DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );

    await _notificationsPlugin.show(
      id: id,
      title: '⭐ Upgrade Akun HUMORA ke VIP Sekarang!',
      body: 'Buka semua episode komedi eksklusif tanpa batas dengan paket VIP.',
      notificationDetails: notificationDetails,
      payload: 'subscribe_invite',
    );
  }

  // =========================================================================
  // 5. NOTIFIKASI MASA LANGGANAN SEGERA HABIS
  // =========================================================================
  static Future<void> showExpiringSubscriptionNotification({
    required int remainingDays,
  }) async {
    if (disableInTests) return;

    const id = 5001;
    final dayStr = remainingDays <= 0 ? 'hari ini' : '$remainingDays hari lagi';

    final androidDetails = AndroidNotificationDetails(
      vipChannelId,
      'Notifikasi VIP & Transaksi',
      channelDescription: 'Pemberitahuan persetujuan dan masa aktif langganan VIP HUMORA',
      importance: Importance.max,
      priority: Priority.high,
      color: const Color(0xFFD97706),
      icon: '@mipmap/ic_launcher',
      enableVibration: true,
      visibility: NotificationVisibility.public,
      styleInformation: BigTextStyleInformation(
        'Masa aktif langganan VIP HUMORA Anda akan berakhir dalam $dayStr. Perpanjang sekarang agar tontonan komedimu tidak terhenti!',
        contentTitle: '⚠️ Masa Aktif VIP Anda Segera Berakhir!',
        summaryText: 'Masa Aktif VIP',
      ),
    );

    final notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: const DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );

    await _notificationsPlugin.show(
      id: id,
      title: '⚠️ Masa Aktif VIP Anda Segera Berakhir!',
      body: 'Masa aktif VIP tersisa $dayStr. Perpanjang paketmu sekarang agar tetap seru!',
      notificationDetails: notificationDetails,
      payload: 'expiring_vip',
    );
  }

  /// Schedule periodic background notifications (e.g. daily comedy reminder)
  /// so that even when user is using other apps or device is asleep, notification pops up!
  static Future<void> scheduleDailyComedyReminder() async {
    if (disableInTests) return;

    try {
      const id = 9001;

      final androidDetails = AndroidNotificationDetails(
        contentChannelId,
        'Rilis Video & Konten Populer',
        channelDescription: 'Pemberitahuan video baru dan konten komedi viral pilihan',
        importance: Importance.high,
        priority: Priority.high,
        color: const Color(0xFF43135C),
        icon: '@mipmap/ic_launcher',
        enableVibration: true,
        visibility: NotificationVisibility.public,
        styleInformation: const BigTextStyleInformation(
          'Waktunya rileks sejenak! Buka HUMORA dan temukan video komedi lucu yang siap mencerahkan harimu.',
          contentTitle: '😂 Butuh Hiburan Hari Ini?',
          summaryText: 'scroll, laugh, repeat',
        ),
      );

      final notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: const DarwinNotificationDetails(),
      );

      // Periodically trigger daily
      await _notificationsPlugin.periodicallyShow(
        id: id,
        title: '😂 Butuh Hiburan Hari Ini?',
        body: 'Scroll, laugh, repeat! Buka HUMORA untuk hiburan komedi seru.',
        repeatInterval: RepeatInterval.daily,
        notificationDetails: notificationDetails,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        payload: 'daily_reminder',
      );
    } catch (e) {
      debugPrint('Error scheduling daily reminder: $e');
    }
  }

  /// Cancel all local notifications
  static Future<void> cancelAll() async {
    if (disableInTests) return;
    await _notificationsPlugin.cancelAll();
  }
}
