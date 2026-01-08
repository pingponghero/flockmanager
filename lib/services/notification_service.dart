import 'dart:io';

import 'package:flutter/material.dart' show TimeOfDay;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
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

    // Initialize timezone data
    tz.initializeTimeZones();

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
      settings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Create notification channels for Android
    if (Platform.isAndroid) {
      await _createAndroidChannels();
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
        importance: Importance.defaultImportance,
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
    await _notifications.cancel(notificationId);
  }

  /// Cancel a withdrawal notification.
  Future<void> cancelWithdrawalNotification(String medicationId) async {
    final notificationId =
        _withdrawalIdPrefix + medicationId.hashCode.abs() % 1000;
    await _notifications.cancel(notificationId);
  }

  /// Cancel an expense reminder notification.
  Future<void> cancelExpenseNotification(String expenseId) async {
    final notificationId = _expenseIdPrefix + expenseId.hashCode.abs() % 1000;
    await _notifications.cancel(notificationId);
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

    await _scheduleNotification(
      id: _eggReminderId,
      channelId: _eggReminderChannelId,
      title: 'Time to check for eggs!',
      body: "You haven't logged any eggs today 🥚",
      scheduledDate: scheduledDate,
      payload: 'egg_reminder',
    );
  }

  /// Cancel the egg reminder notification.
  Future<void> cancelEggReminder() async {
    await _notifications.cancel(_eggReminderId);
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

    await _notifications.zonedSchedule(
      id,
      title,
      body,
      tzScheduledDate,
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: payload,
    );
  }

  /// Handle notification tap.
  void _onNotificationTapped(NotificationResponse response) {
    // Handle egg reminder tap - open quick log sheet
    if (response.payload == 'egg_reminder' && onEggReminderTapped != null) {
      onEggReminderTapped!();
    }
  }
}
