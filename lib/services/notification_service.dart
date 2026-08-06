import 'dart:io' show Platform;

import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/material.dart' show Color, Colors, TimeOfDay;
import 'package:flutter/services.dart' show MethodChannel;
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
    );

    // Set up notification action listener
    AwesomeNotifications().setListeners(
      onActionReceivedMethod: _onActionReceived,
    );

    _isInitialized = true;
  }

  /// Static callback for notification actions
  @pragma('vm:entry-point')
  static Future<void> _onActionReceived(ReceivedAction receivedAction) async {
    if (receivedAction.payload?['type'] == 'egg_reminder' && onEggReminderTapped != null) {
      onEggReminderTapped!();
    }
  }

  /// Request notification permissions.
  Future<bool> requestPermissions() async {
    final isAllowed = await AwesomeNotifications().isNotificationAllowed();
    if (!isAllowed) {
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

    // Exact alarms are a separate special permission on Android 12+ and can
    // be missing even when notifications are allowed (the old code never
    // asked in that case, so reminders were scheduled inexactly and OEM
    // battery managers deferred them indefinitely).
    if (!await hasExactAlarmPermission()) {
      await AwesomeNotifications().requestPermissionToSendNotifications(
        permissions: [NotificationPermission.PreciseAlarms],
      );
    }

    return true;
  }

  /// Check if notifications are permitted.
  Future<bool> areNotificationsEnabled() async {
    return await AwesomeNotifications().isNotificationAllowed();
  }

  /// Whether the exact-alarm special permission is granted (Android 12+).
  /// Reminders still work without it but fire at imprecise times — or not
  /// at all under aggressive OEM battery management.
  Future<bool> hasExactAlarmPermission() async {
    // Ask the OS directly (AlarmManager.canScheduleExactAlarms). The
    // awesome_notifications PreciseAlarms check does not reliably reflect a
    // permission the user just granted on the system settings page.
    if (Platform.isAndroid) {
      try {
        final canSchedule =
            await _exactAlarmChannel.invokeMethod<bool>('canScheduleExactAlarms');
        if (canSchedule != null) return canSchedule;
      } catch (_) {
        // Fall through to the plugin check below.
      }
    }
    final allowed = await AwesomeNotifications().checkPermissionList(
      permissions: [NotificationPermission.PreciseAlarms],
    );
    return allowed.contains(NotificationPermission.PreciseAlarms);
  }

  static const MethodChannel _exactAlarmChannel =
      MethodChannel('com.tyndallstudios.flockmanager/exact_alarm');

  /// Open the system "Alarms & reminders" page to grant exact alarms.
  ///
  /// On Android 12+ `SCHEDULE_EXACT_ALARM` is a special-access permission that
  /// cannot be granted from the notification-permission dialog; when
  /// notifications are already allowed, the awesome_notifications request is a
  /// no-op. We launch the settings intent directly via a platform channel and
  /// only fall back to the plugin request if that fails.
  Future<void> requestExactAlarmPermission() async {
    if (Platform.isAndroid) {
      try {
        final opened =
            await _exactAlarmChannel.invokeMethod<bool>('openExactAlarmSettings');
        if (opened == true) return;
      } catch (_) {
        // Fall through to the plugin request below.
      }
    }
    await AwesomeNotifications().requestPermissionToSendNotifications(
      permissions: [NotificationPermission.PreciseAlarms],
    );
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

  /// Schedule the daily egg reminder notification.
  ///
  /// The base schedule is a *repeating* daily alarm, so the reminder keeps
  /// firing even when the app isn't opened for days (the previous one-shot
  /// chain died the first day the app wasn't launched to re-arm it).
  ///
  /// If [tomorrow] is true (eggs already logged today), the repeating alarm
  /// is replaced with a one-shot for tomorrow so today's reminder is
  /// suppressed; the repeating schedule is re-established on the next app
  /// launch via evaluateEggReminder.
  Future<void> scheduleEggReminder(TimeOfDay time, {bool tomorrow = false}) async {
    // Cancel any existing egg reminder first
    await cancelEggReminder();

    if (tomorrow) {
      final now = DateTime.now();
      final scheduledDate = DateTime(
        now.year,
        now.month,
        now.day,
        time.hour,
        time.minute,
      ).add(const Duration(days: 1));

      await _scheduleNotification(
        id: _eggReminderId,
        channelKey: _eggReminderChannelKey,
        title: 'Time to check for eggs!',
        body: "You haven't logged any eggs today 🥚",
        scheduledDate: scheduledDate,
        payload: {'type': 'egg_reminder'},
      );
      return;
    }

    final content = NotificationContent(
      id: _eggReminderId,
      channelKey: _eggReminderChannelKey,
      title: 'Time to check for eggs!',
      body: "You haven't logged any eggs today 🥚",
      notificationLayout: NotificationLayout.Default,
      payload: {'type': 'egg_reminder'},
      wakeUpScreen: true,
    );

    try {
      await AwesomeNotifications().createNotification(
        content: content,
        schedule: NotificationCalendar(
          hour: time.hour,
          minute: time.minute,
          second: 0,
          repeats: true,
          preciseAlarm: true,
          allowWhileIdle: true,
        ),
      );
    } catch (_) {
      await AwesomeNotifications().createNotification(
        content: content,
        schedule: NotificationCalendar(
          hour: time.hour,
          minute: time.minute,
          second: 0,
          repeats: true,
          preciseAlarm: false,
          allowWhileIdle: true,
        ),
      );
    }
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
        title: 'Flock Manager',
        body: 'Notifications are working — this is what your reminders will look like.',
        notificationLayout: NotificationLayout.Default,
      ),
    );
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
  ///
  /// Uses precise, Doze-proof alarms: with `preciseAlarm: false` +
  /// `allowWhileIdle: false` (the old behavior) alarms are deferred by
  /// Doze/OEM battery management and on some devices never fire at all.
  /// Falls back to an inexact idle-allowed alarm if the exact-alarm
  /// permission is missing.
  Future<void> _scheduleNotification({
    required int id,
    required String channelKey,
    required String title,
    required String body,
    required DateTime scheduledDate,
    Map<String, String>? payload,
    NotificationCategory? category,
  }) async {
    final content = NotificationContent(
      id: id,
      channelKey: channelKey,
      title: title,
      body: body,
      notificationLayout: NotificationLayout.Default,
      payload: payload,
      wakeUpScreen: true,
      category: category,
    );

    try {
      await AwesomeNotifications().createNotification(
        content: content,
        schedule: NotificationCalendar.fromDate(
          date: scheduledDate,
          preciseAlarm: true,
          allowWhileIdle: true,
        ),
      );
    } catch (_) {
      // Exact-alarm permission not granted — schedule inexactly rather
      // than not at all.
      await AwesomeNotifications().createNotification(
        content: content,
        schedule: NotificationCalendar.fromDate(
          date: scheduledDate,
          preciseAlarm: false,
          allowWhileIdle: true,
        ),
      );
    }
  }
}
