import 'dart:io';

import 'package:android_intent_plus/android_intent.dart';
import 'package:battery_optimization_helper/battery_optimization_helper.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter/material.dart' show TimeOfDay;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import '../models/medication_log.dart';

/// Service for managing local notifications.
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;

  // Notification channel IDs
  static const String _medicationChannelId = 'medication_reminders';
  static const String _withdrawalChannelId = 'withdrawal_alerts';
  static const String _expenseChannelId = 'expense_reminders';
  static const String _eggReminderChannelId = 'egg_reminders';

  // Notification ID prefixes (to avoid collisions)
  static const int _medicationIdPrefix = 1000;
  static const int _withdrawalIdPrefix = 2000;
  static const int _expenseIdPrefix = 3000;
  static const int _eggReminderId = 4000;

  // Callback for notification tap navigation
  static void Function()? onEggReminderTapped;

  /// Initialize the notification service.
  Future<void> initialize() async {
    if (_isInitialized) return;

    // Initialize timezone data and set local timezone
    tz.initializeTimeZones();
    final timezoneInfo = await FlutterTimezone.getLocalTimezone();
    final timeZoneName = timezoneInfo.identifier;
    tz.setLocalLocation(tz.getLocation(timeZoneName));
    debugPrint('🔔 Timezone initialized. Local: ${tz.local.name}');

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(
      settings: settings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Create notification channels for Android
    if (Platform.isAndroid) {
      await _createAndroidChannels();

      // Check exact alarm permission
      final androidPlugin =
          _notifications.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      if (androidPlugin != null) {
        final canScheduleExact = await androidPlugin.canScheduleExactNotifications();
        debugPrint('🔔 Can schedule exact notifications: $canScheduleExact');
        if (canScheduleExact != true) {
          debugPrint('🔔 WARNING: Exact alarm permission not granted!');
        }
      }
    }

    _isInitialized = true;
  }

  /// Create Android notification channels.
  Future<void> _createAndroidChannels() async {
    final androidPlugin =
        _notifications.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    if (androidPlugin == null) return;

    await androidPlugin.createNotificationChannel(
      const AndroidNotificationChannel(
        _medicationChannelId,
        'Medication Reminders',
        description: 'Reminders when medication treatments end',
        importance: Importance.high,
      ),
    );

    await androidPlugin.createNotificationChannel(
      const AndroidNotificationChannel(
        _withdrawalChannelId,
        'Withdrawal Alerts',
        description: 'Alerts when egg withdrawal periods end',
        importance: Importance.high,
      ),
    );

    await androidPlugin.createNotificationChannel(
      const AndroidNotificationChannel(
        _expenseChannelId,
        'Expense Reminders',
        description: 'Reminders for recurring expenses',
        importance: Importance.defaultImportance,
      ),
    );

    await androidPlugin.createNotificationChannel(
      const AndroidNotificationChannel(
        _eggReminderChannelId,
        'Egg Reminders',
        description: 'Daily reminders to log eggs',
        importance: Importance.high,
      ),
    );
  }

  /// Request notification permissions.
  Future<bool> requestPermissions() async {
    if (Platform.isIOS) {
      final iosPlugin = _notifications.resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>();
      final result = await iosPlugin?.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
      return result ?? false;
    }

    if (Platform.isAndroid) {
      final androidPlugin =
          _notifications.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      final result = await androidPlugin?.requestNotificationsPermission();
      return result ?? false;
    }

    return false;
  }

  /// Check if notifications are permitted.
  Future<bool> areNotificationsEnabled() async {
    if (Platform.isAndroid) {
      final androidPlugin =
          _notifications.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      return await androidPlugin?.areNotificationsEnabled() ?? false;
    }
    // iOS doesn't have a simple check, assume true after permission granted
    return true;
  }

  /// Schedule a notification when a medication treatment ends.
  Future<void> scheduleMedicationEnd(MedicationLog medication) async {
    if (medication.endDate == null) return;

    final endDate = medication.endDate!;
    if (endDate.isBefore(DateTime.now())) return;

    // Schedule for 9 AM on the end date
    final scheduledDate = DateTime(
      endDate.year,
      endDate.month,
      endDate.day,
      9,
      0,
    );

    if (scheduledDate.isBefore(DateTime.now())) return;

    final notificationId =
        _medicationIdPrefix + medication.id.hashCode.abs() % 1000;

    await _scheduleNotification(
      id: notificationId,
      channelId: _medicationChannelId,
      title: 'Medication Ending',
      body: '${medication.medicationName} treatment ends today',
      scheduledDate: scheduledDate,
    );
  }

  /// Schedule a notification when a withdrawal period ends.
  Future<void> scheduleWithdrawalEnd(MedicationLog medication) async {
    final withdrawalEnd = medication.withdrawalEndDate;
    if (withdrawalEnd == null) return;
    if (withdrawalEnd.isBefore(DateTime.now())) return;

    // Schedule for 9 AM on the withdrawal end date
    final scheduledDate = DateTime(
      withdrawalEnd.year,
      withdrawalEnd.month,
      withdrawalEnd.day,
      9,
      0,
    );

    if (scheduledDate.isBefore(DateTime.now())) return;

    final notificationId =
        _withdrawalIdPrefix + medication.id.hashCode.abs() % 1000;

    await _scheduleNotification(
      id: notificationId,
      channelId: _withdrawalChannelId,
      title: 'Eggs Safe to Eat',
      body:
          'Withdrawal period for ${medication.medicationName} is complete. Eggs are safe to eat again!',
      scheduledDate: scheduledDate,
    );
  }

  /// Schedule a recurring expense reminder.
  Future<void> scheduleExpenseReminder({
    required String expenseId,
    required String description,
    required DateTime reminderDate,
  }) async {
    if (reminderDate.isBefore(DateTime.now())) return;

    // Schedule for 10 AM on the reminder date
    final scheduledDate = DateTime(
      reminderDate.year,
      reminderDate.month,
      reminderDate.day,
      10,
      0,
    );

    if (scheduledDate.isBefore(DateTime.now())) return;

    final notificationId = _expenseIdPrefix + expenseId.hashCode.abs() % 1000;

    await _scheduleNotification(
      id: notificationId,
      channelId: _expenseChannelId,
      title: 'Expense Reminder',
      body: 'Time to: $description',
      scheduledDate: scheduledDate,
    );
  }

  /// Cancel a medication notification.
  Future<void> cancelMedicationNotification(String medicationId) async {
    final notificationId =
        _medicationIdPrefix + medicationId.hashCode.abs() % 1000;
    await _notifications.cancel(id: notificationId);
  }

  /// Cancel a withdrawal notification.
  Future<void> cancelWithdrawalNotification(String medicationId) async {
    final notificationId =
        _withdrawalIdPrefix + medicationId.hashCode.abs() % 1000;
    await _notifications.cancel(id: notificationId);
  }

  /// Cancel an expense reminder notification.
  Future<void> cancelExpenseNotification(String expenseId) async {
    final notificationId = _expenseIdPrefix + expenseId.hashCode.abs() % 1000;
    await _notifications.cancel(id: notificationId);
  }

  /// Schedule a daily egg reminder notification.
  /// If [tomorrow] is true, schedules for tomorrow regardless of current time.
  Future<void> scheduleEggReminder(TimeOfDay time, {bool tomorrow = false}) async {
    // Cancel any existing egg reminder first
    await cancelEggReminder();

    final now = DateTime.now();
    var scheduledDate = DateTime(
      now.year,
      now.month,
      now.day,
      time.hour,
      time.minute,
    );

    // If time has passed today or tomorrow is requested, schedule for tomorrow
    if (tomorrow || scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    debugPrint('🔔 Scheduling egg reminder for: $scheduledDate (now: $now)');

    await _scheduleNotification(
      id: _eggReminderId,
      channelId: _eggReminderChannelId,
      title: 'Time to check for eggs!',
      body: "You haven't logged any eggs today 🥚",
      scheduledDate: scheduledDate,
      payload: 'egg_reminder',
    );

    debugPrint('🔔 Egg reminder scheduled successfully');
  }

  /// Cancel the egg reminder notification.
  Future<void> cancelEggReminder() async {
    await _notifications.cancel(id: _eggReminderId);
  }

  /// Show an immediate test notification (for debugging)
  Future<void> showTestNotification() async {
    const androidDetails = AndroidNotificationDetails(
      _eggReminderChannelId,
      'Egg Reminders',
      importance: Importance.high,
      priority: Priority.high,
    );
    const details = NotificationDetails(android: androidDetails);
    await _notifications.show(
      id: 9999,
      title: 'Test Notification',
      body: 'This is a test notification',
      notificationDetails: details,
    );
    debugPrint('🔔 Test notification shown');
  }

  /// Cancel all notifications.
  Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
  }

  /// Get all pending notification requests.
  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    return _notifications.pendingNotificationRequests();
  }

  /// Internal method to schedule a notification.
  Future<void> _scheduleNotification({
    required int id,
    required String channelId,
    required String title,
    required String body,
    required DateTime scheduledDate,
    String? payload,
  }) async {
    String channelName;
    switch (channelId) {
      case _medicationChannelId:
        channelName = 'Medication Reminders';
      case _withdrawalChannelId:
        channelName = 'Withdrawal Alerts';
      case _eggReminderChannelId:
        channelName = 'Egg Reminders';
      default:
        channelName = 'Expense Reminders';
    }

    final androidDetails = AndroidNotificationDetails(
      channelId,
      channelName,
      importance: Importance.high,
      priority: Priority.high,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    final tzScheduledDate = tz.TZDateTime.from(scheduledDate, tz.local);
    debugPrint('🔔 TZ local: ${tz.local.name}, tzScheduledDate: $tzScheduledDate');

    try {
      await _notifications.zonedSchedule(
        id: id,
        title: title,
        body: body,
        scheduledDate: tzScheduledDate,
        notificationDetails: details,
        androidScheduleMode: AndroidScheduleMode.alarmClock,
        payload: payload,
      );
      debugPrint('🔔 zonedSchedule completed for id $id (alarmClock mode)');

      // Check pending notifications
      final pending = await _notifications.pendingNotificationRequests();
      debugPrint('🔔 Pending notifications: ${pending.length}');
      for (final p in pending) {
        debugPrint('🔔   - id: ${p.id}, title: ${p.title}');
      }
    } catch (e) {
      debugPrint('🔔 ERROR scheduling notification: $e');
    }
  }

  /// Handle notification tap.
  void _onNotificationTapped(NotificationResponse response) {
    // Handle egg reminder tap - open quick log sheet
    if (response.payload == 'egg_reminder' && onEggReminderTapped != null) {
      onEggReminderTapped!();
    }
  }

  /// Check if battery optimization is disabled for this app.
  /// Returns true if battery optimization is already disabled (good for notifications).
  Future<bool> isBatteryOptimizationDisabled() async {
    if (!Platform.isAndroid) return true;
    final isEnabled = await BatteryOptimizationHelper.isBatteryOptimizationEnabled();
    // Return true if optimization is disabled (i.e., NOT enabled)
    return !isEnabled;
  }

  /// Request the user to disable battery optimization.
  /// Shows system dialog and attempts OEM-specific settings on Samsung/other OEMs.
  Future<void> requestDisableBatteryOptimization() async {
    if (!Platform.isAndroid) return;

    // First, try the standard Android battery optimization dialog
    await BatteryOptimizationHelper.ensureOptimizationDisabled();

    // Also try to open OEM-specific auto-start settings (for Samsung, Xiaomi, etc.)
    // This handles Samsung's "Sleeping apps" and similar on other OEMs
    await BatteryOptimizationHelper.openAutoStartSettings();
  }

  /// Check if the device is a Samsung device.
  Future<bool> isSamsungDevice() async {
    if (!Platform.isAndroid) return false;

    final deviceInfo = DeviceInfoPlugin();
    final androidInfo = await deviceInfo.androidInfo;
    final manufacturer = androidInfo.manufacturer.toLowerCase();
    return manufacturer == 'samsung';
  }

  /// Open Samsung's battery optimization settings.
  /// This opens the "Background usage limits" or "Never sleeping apps" screen.
  Future<void> openSamsungBatterySettings() async {
    if (!Platform.isAndroid) return;

    try {
      // Try to open Samsung's Device Care battery settings directly
      const intent = AndroidIntent(
        action: 'android.intent.action.MAIN',
        package: 'com.samsung.android.lool',
        componentName: 'com.samsung.android.lool.activities.MainActivity',
      );
      await intent.launch();
    } catch (e) {
      debugPrint('🔔 Could not open Samsung Device Care: $e');
      // Fallback to standard battery optimization settings
      try {
        const fallbackIntent = AndroidIntent(
          action: 'android.settings.IGNORE_BATTERY_OPTIMIZATION_SETTINGS',
        );
        await fallbackIntent.launch();
      } catch (e2) {
        debugPrint('🔔 Could not open battery settings: $e2');
      }
    }
  }
}
