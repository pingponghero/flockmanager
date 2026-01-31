import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter/material.dart' show Color, Colors, TimeOfDay;
import '../models/medication_log.dart';

/// Service for managing local notifications using awesome_notifications.
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  bool _isInitialized = false;

  // Notification channel keys
  static const String _medicationChannelKey = 'medication_reminders';
  static const String _withdrawalChannelKey = 'withdrawal_alerts';
  static const String _expenseChannelKey = 'expense_reminders';
  static const String _eggReminderChannelKey = 'egg_reminders_v2';

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

    await AwesomeNotifications().initialize(
      // Use default app icon
      null,
      [
        NotificationChannel(
          channelKey: _medicationChannelKey,
          channelName: 'Medication Reminders',
          channelDescription: 'Reminders when medication treatments end',
          importance: NotificationImportance.High,
          defaultColor: Colors.blue,
          ledColor: Colors.blue,
        ),
        NotificationChannel(
          channelKey: _withdrawalChannelKey,
          channelName: 'Withdrawal Alerts',
          channelDescription: 'Alerts when egg withdrawal periods end',
          importance: NotificationImportance.High,
          defaultColor: Colors.orange,
          ledColor: Colors.orange,
        ),
        NotificationChannel(
          channelKey: _expenseChannelKey,
          channelName: 'Expense Reminders',
          channelDescription: 'Reminders for recurring expenses',
          importance: NotificationImportance.Default,
          defaultColor: Colors.green,
          ledColor: Colors.green,
        ),
        NotificationChannel(
          channelKey: _eggReminderChannelKey,
          channelName: 'Egg Reminders',
          channelDescription: 'Daily reminders to log eggs',
          importance: NotificationImportance.Max, // Max importance for heads-up
          defaultColor: const Color(0xFFFFB74D), // Orange/egg color
          ledColor: const Color(0xFFFFB74D),
          playSound: true,
          enableVibration: true,
          criticalAlerts: true, // Bypass DND
        ),
      ],
      debug: true, // Enable debug logging
    );

    // Set up notification action listener
    AwesomeNotifications().setListeners(
      onActionReceivedMethod: _onActionReceived,
    );

    debugPrint('🔔 awesome_notifications initialized');
    _isInitialized = true;
  }

  /// Static callback for notification actions
  @pragma('vm:entry-point')
  static Future<void> _onActionReceived(ReceivedAction receivedAction) async {
    debugPrint('🔔 Notification action received: ${receivedAction.payload}');
    if (receivedAction.payload?['type'] == 'egg_reminder' && onEggReminderTapped != null) {
      onEggReminderTapped!();
    }
  }

  /// Request notification permissions.
  Future<bool> requestPermissions() async {
    final isAllowed = await AwesomeNotifications().isNotificationAllowed();
    if (!isAllowed) {
      // Request both alert and precise alarm permissions upfront
      final granted = await AwesomeNotifications().requestPermissionToSendNotifications(
        permissions: [
          NotificationPermission.Alert,
          NotificationPermission.Sound,
          NotificationPermission.Badge,
          NotificationPermission.Vibration,
          NotificationPermission.PreciseAlarms,
        ],
      );
      if (!granted) return false;
    }

    return true;
  }

  /// Check if notifications are permitted.
  Future<bool> areNotificationsEnabled() async {
    return await AwesomeNotifications().isNotificationAllowed();
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
      channelKey: _medicationChannelKey,
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
      channelKey: _withdrawalChannelKey,
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
      channelKey: _expenseChannelKey,
      title: 'Expense Reminder',
      body: 'Time to: $description',
      scheduledDate: scheduledDate,
    );
  }

  /// Cancel a medication notification.
  Future<void> cancelMedicationNotification(String medicationId) async {
    final notificationId =
        _medicationIdPrefix + medicationId.hashCode.abs() % 1000;
    await AwesomeNotifications().cancel(notificationId);
  }

  /// Cancel a withdrawal notification.
  Future<void> cancelWithdrawalNotification(String medicationId) async {
    final notificationId =
        _withdrawalIdPrefix + medicationId.hashCode.abs() % 1000;
    await AwesomeNotifications().cancel(notificationId);
  }

  /// Cancel an expense reminder notification.
  Future<void> cancelExpenseNotification(String expenseId) async {
    final notificationId = _expenseIdPrefix + expenseId.hashCode.abs() % 1000;
    await AwesomeNotifications().cancel(notificationId);
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
      channelKey: _eggReminderChannelKey,
      title: 'Time to check for eggs!',
      body: "You haven't logged any eggs today 🥚",
      scheduledDate: scheduledDate,
      payload: {'type': 'egg_reminder'},
    );

    debugPrint('🔔 Egg reminder scheduled successfully');
  }

  /// Cancel the egg reminder notification.
  Future<void> cancelEggReminder() async {
    await AwesomeNotifications().cancel(_eggReminderId);
  }

  /// Show an immediate test notification (for debugging)
  Future<void> showTestNotification() async {
    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: 9999,
        channelKey: _eggReminderChannelKey,
        title: 'Test Notification',
        body: 'This is a test notification from awesome_notifications',
        notificationLayout: NotificationLayout.Default,
      ),
    );
    debugPrint('🔔 Test notification shown');
  }

  /// Cancel all notifications.
  Future<void> cancelAllNotifications() async {
    await AwesomeNotifications().cancelAll();
  }

  /// Get all scheduled notification IDs.
  Future<List<NotificationModel>> getScheduledNotifications() async {
    return await AwesomeNotifications().listScheduledNotifications();
  }

  /// Internal method to schedule a notification.
  Future<void> _scheduleNotification({
    required int id,
    required String channelKey,
    required String title,
    required String body,
    required DateTime scheduledDate,
    Map<String, String>? payload,
    NotificationCategory? category,
  }) async {
    debugPrint('🔔 Scheduling notification id=$id for $scheduledDate');

    try {
      final success = await AwesomeNotifications().createNotification(
        content: NotificationContent(
          id: id,
          channelKey: channelKey,
          title: title,
          body: body,
          notificationLayout: NotificationLayout.Default,
          payload: payload,
          wakeUpScreen: true,
          category: category,
        ),
        schedule: NotificationCalendar.fromDate(
          date: scheduledDate,
          preciseAlarm: false,
          allowWhileIdle: false, // Try without - may not need exact alarm permission
        ),
      );

      debugPrint('🔔 Notification scheduled: $success');

      // List scheduled notifications for verification
      final scheduled = await AwesomeNotifications().listScheduledNotifications();
      debugPrint('🔔 Scheduled notifications count: ${scheduled.length}');
      for (final n in scheduled) {
        debugPrint('🔔   - id: ${n.content?.id}, title: ${n.content?.title}');
      }
    } catch (e) {
      debugPrint('🔔 ERROR scheduling notification: $e');
    }
  }

}
