import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';
import '../network/api_config.dart';
import '../network/api_service.dart';
import 'local_notification_service.dart';
import '../../data/models/notification_model.dart';
import '../../data/models/series_model.dart';
import '../../data/models/transaction_model.dart';

const String humoraBackgroundPeriodicTask = 'humora_periodic_check_task';
const String humoraBackgroundPeriodicTaskTag = 'humora_background_sync';

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((taskName, inputData) async {
    try {
      return await BackgroundTaskService.handleBackgroundTask(taskName);
    } catch (e, stack) {
      debugPrint('[Workmanager] Background task unhandled error: $e\n$stack');
      return true;
    }
  });
}

class BackgroundTaskService {
  static const String keyNotifiedNotifs = 'humora_bg_notified_notif_ids';
  static const String keyNotifiedTrx = 'humora_bg_notified_trx_codes';
  static const String keyLastSeriesId = 'humora_bg_last_notified_series_id';

  /// Initialize Workmanager and schedule 15-minute periodic background check
  static Future<void> initialize() async {
    if (kIsWeb) return;
    if (!Platform.isAndroid && !Platform.isIOS) return;

    try {
      await Workmanager().initialize(
        callbackDispatcher,
      );

      await Workmanager().registerPeriodicTask(
        humoraBackgroundPeriodicTask,
        humoraBackgroundPeriodicTask,
        tag: humoraBackgroundPeriodicTaskTag,
        frequency: const Duration(minutes: 15),
        constraints: Constraints(
          networkType: NetworkType.connected,
        ),
        existingWorkPolicy: ExistingPeriodicWorkPolicy.update,
      );

      debugPrint('[BackgroundTaskService] Periodic task registered (15 min interval).');
    } catch (e) {
      debugPrint('[BackgroundTaskService] Error initializing Workmanager: $e');
    }
  }

  /// Entry point called by executeTask in background isolate
  static Future<bool> handleBackgroundTask(String taskName) async {
    WidgetsFlutterBinding.ensureInitialized();
    await ApiConfig.init();
    await LocalNotificationService.initialize();

    debugPrint('[BackgroundTaskService] Executing background task: $taskName at ${DateTime.now()}');

    await checkVipAndTransactions();
    await checkNewSeriesContent();

    return true;
  }

  /// Check whether user's VIP subscription has been approved
  static Future<void> checkVipAndTransactions() async {
    try {
      final api = ApiService();
      final token = await api.getToken();
      if (token == null || token.isEmpty) {
        // User not logged in, skip VIP checks
        return;
      }

      final prefs = await SharedPreferences.getInstance();

      // 1. Check unread notifications from API
      try {
        final notifRes = await api.getNotifications();
        if (notifRes.data != null &&
            notifRes.data['data'] != null &&
            notifRes.data['data']['notifications'] is List) {
          final List rawList = notifRes.data['data']['notifications'] as List;
          final List<NotificationModel> notifications = rawList
              .map((item) => NotificationModel.fromJson(item as Map<String, dynamic>))
              .toList();

          final notifiedIds = prefs.getStringList(keyNotifiedNotifs) ?? [];
          final updatedNotified = List<String>.from(notifiedIds);

          for (final notif in notifications) {
            if (!notif.isRead && !updatedNotified.contains(notif.id)) {
              updatedNotified.add(notif.id);
              final titleLower = notif.title.toLowerCase();
              final msgLower = notif.message.toLowerCase();

              if (notif.type == 'transaction' ||
                  titleLower.contains('disetujui') ||
                  msgLower.contains('disetujui') ||
                  titleLower.contains('aktif')) {
                await LocalNotificationService.showVipApprovedNotification(
                  trxCode: notif.title,
                  planName: 'VIP HUMORA',
                );
              }
            }
          }
          await prefs.setStringList(keyNotifiedNotifs, updatedNotified);
        }
      } catch (e) {
        debugPrint('[BackgroundTaskService] Error fetching notifications: $e');
      }

      // 2. Check transactions directly (fallback if notification is not generated yet)
      try {
        final trxRes = await api.getTransactions();
        if (trxRes.data != null &&
            trxRes.data['data'] != null &&
            trxRes.data['data']['transactions'] is List) {
          final List rawTrx = trxRes.data['data']['transactions'] as List;
          final List<TransactionModel> transactions = rawTrx
              .map((item) => TransactionModel.fromJson(item as Map<String, dynamic>))
              .toList();

          final notifiedTrx = prefs.getStringList(keyNotifiedTrx) ?? [];
          final updatedTrx = List<String>.from(notifiedTrx);

          for (final trx in transactions) {
            if (trx.isSuccess && !updatedTrx.contains(trx.trxCode)) {
              updatedTrx.add(trx.trxCode);
              await LocalNotificationService.showVipApprovedNotification(
                trxCode: trx.trxCode,
                planName: trx.planName,
              );
            }
          }
          await prefs.setStringList(keyNotifiedTrx, updatedTrx);
        }
      } catch (e) {
        debugPrint('[BackgroundTaskService] Error fetching transactions: $e');
      }
    } catch (e) {
      debugPrint('[BackgroundTaskService] Error in checkVipAndTransactions: $e');
    }
  }

  /// Check whether any new series / comedy video has been published
  static Future<void> checkNewSeriesContent() async {
    try {
      final api = ApiService();
      final prefs = await SharedPreferences.getInstance();

      final seriesRes = await api.getSeries();
      if (seriesRes.data != null && seriesRes.data['data'] != null) {
        final dynamic raw = seriesRes.data['data'];
        final List list = raw is List
            ? raw
            : (raw is Map && raw['series'] is List ? raw['series'] as List : []);

        if (list.isEmpty) return;

        final List<SeriesModel> allSeries = list
            .map((s) => SeriesModel.fromJson(s as Map<String, dynamic>))
            .toList();

        final newSeriesList = allSeries.where((s) => s.isNew).toList();
        if (newSeriesList.isNotEmpty) {
          final latestNewSeries = newSeriesList.first;
          final lastNotifiedSeriesId = prefs.getString(keyLastSeriesId);

          if (lastNotifiedSeriesId == null) {
            // First run, register latest ID to prevent alerting immediately for existing content
            await prefs.setString(keyLastSeriesId, latestNewSeries.id);
          } else if (lastNotifiedSeriesId != latestNewSeries.id) {
            // Brand new content detected!
            await LocalNotificationService.showNewVideoNotification(
              title: latestNewSeries.title,
            );
            await prefs.setString(keyLastSeriesId, latestNewSeries.id);
          }
        }
      }
    } catch (e) {
      debugPrint('[BackgroundTaskService] Error in checkNewSeriesContent: $e');
    }
  }
}
