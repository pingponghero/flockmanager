import 'package:flutter/material.dart' show TimeOfDay;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/medication_log.dart';
import '../repositories/egg_repository.dart';
import '../services/notification_service.dart';
import 'medication_provider.dart';

/// Notification settings state
class NotificationSettings {
  final bool medicationReminders;
  final bool withdrawalAlerts;
  final bool expenseReminders;
  final bool permissionGranted;
  final bool eggReminders;
  final TimeOfDay? eggReminderTime;

  const NotificationSettings({
    this.medicationReminders = true,
    this.withdrawalAlerts = true,
    this.expenseReminders = true,
    this.permissionGranted = false,
    this.eggReminders = false,
    this.eggReminderTime,
  });

  NotificationSettings copyWith({
    bool? medicationReminders,
    bool? withdrawalAlerts,
    bool? expenseReminders,
    bool? permissionGranted,
    bool? eggReminders,
    TimeOfDay? eggReminderTime,
    bool clearEggReminderTime = false,
  }) {
    return NotificationSettings(
      medicationReminders: medicationReminders ?? this.medicationReminders,
      withdrawalAlerts: withdrawalAlerts ?? this.withdrawalAlerts,
      expenseReminders: expenseReminders ?? this.expenseReminders,
      permissionGranted: permissionGranted ?? this.permissionGranted,
      eggReminders: eggReminders ?? this.eggReminders,
      eggReminderTime: clearEggReminderTime
          ? null
          : (eggReminderTime ?? this.eggReminderTime),
    );
  }
}

/// Notifier for notification settings
class NotificationSettingsNotifier extends Notifier<NotificationSettings> {
  static const _keyMedicationReminders = 'notification_medication_reminders';
  static const _keyWithdrawalAlerts = 'notification_withdrawal_alerts';
  static const _keyExpenseReminders = 'notification_expense_reminders';
  static const _keyPermissionGranted = 'notification_permission_granted';
  static const _keyEggReminders = 'notification_egg_reminders';
  static const _keyEggReminderHour = 'notification_egg_reminder_hour';
  static const _keyEggReminderMinute = 'notification_egg_reminder_minute';

  @override
  NotificationSettings build() {
    _loadSettings();
    return const NotificationSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();

    // Load egg reminder time if set
    final eggHour = prefs.getInt(_keyEggReminderHour);
    final eggMinute = prefs.getInt(_keyEggReminderMinute);
    final eggReminderTime = (eggHour != null && eggMinute != null)
        ? TimeOfDay(hour: eggHour, minute: eggMinute)
        : null;

    state = NotificationSettings(
      medicationReminders: prefs.getBool(_keyMedicationReminders) ?? true,
      withdrawalAlerts: prefs.getBool(_keyWithdrawalAlerts) ?? true,
      expenseReminders: prefs.getBool(_keyExpenseReminders) ?? true,
      permissionGranted: prefs.getBool(_keyPermissionGranted) ?? false,
      eggReminders: prefs.getBool(_keyEggReminders) ?? false,
      eggReminderTime: eggReminderTime,
    );
  }

  Future<void> setMedicationReminders(bool enabled) async {
    state = state.copyWith(medicationReminders: enabled);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyMedicationReminders, enabled);

    if (enabled) {
      await _scheduleAllMedicationNotifications();
    } else {
      // Cancel all medication notifications
      final service = NotificationService();
      final medications = await ref.read(medicationsProvider.future);
      for (final med in medications) {
        await service.cancelMedicationNotification(med.id);
      }
    }
  }

  Future<void> setWithdrawalAlerts(bool enabled) async {
    state = state.copyWith(withdrawalAlerts: enabled);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyWithdrawalAlerts, enabled);

    if (enabled) {
      await _scheduleAllWithdrawalNotifications();
    } else {
      // Cancel all withdrawal notifications
      final service = NotificationService();
      final medications = await ref.read(medicationsProvider.future);
      for (final med in medications) {
        await service.cancelWithdrawalNotification(med.id);
      }
    }
  }

  Future<void> setExpenseReminders(bool enabled) async {
    state = state.copyWith(expenseReminders: enabled);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyExpenseReminders, enabled);
    // Note: expense reminders would be scheduled when expenses are created
  }

  /// Enable or disable egg reminders.
  Future<void> setEggReminders(bool enabled) async {
    final service = NotificationService();

    if (enabled) {
      // Ensure notification permission is granted
      final hasPermission = await service.areNotificationsEnabled();
      if (!hasPermission) {
        final granted = await requestPermission();
        if (!granted) {
          return;
        }
      }
    }

    state = state.copyWith(eggReminders: enabled);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyEggReminders, enabled);

    if (enabled) {
      // Set default time (6:00 PM) if not already set
      if (state.eggReminderTime == null) {
        await setEggReminderTime(const TimeOfDay(hour: 18, minute: 0));
      } else {
        await _scheduleEggReminderIfNeeded();
      }
    } else {
      await service.cancelEggReminder();
    }
  }

  Future<void> setEggReminderTime(TimeOfDay time) async {
    state = state.copyWith(eggReminderTime: time);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyEggReminderHour, time.hour);
    await prefs.setInt(_keyEggReminderMinute, time.minute);

    if (state.eggReminders) {
      await _scheduleEggReminderIfNeeded();
    }
  }

  /// Called when a medication is added or edited — (re)schedules its
  /// end-of-treatment and withdrawal notifications.
  Future<void> onMedicationSaved(MedicationLog medication) async {
    final service = NotificationService();

    // Clear any previously scheduled notifications for this medication so
    // an edit (e.g. end date removed) doesn't leave stale alarms behind.
    await service.cancelMedicationNotification(medication.id);
    await service.cancelWithdrawalNotification(medication.id);

    if (!await service.areNotificationsEnabled()) return;

    if (state.medicationReminders && medication.endDate != null) {
      await service.scheduleMedicationEnd(medication);
    }
    if (state.withdrawalAlerts && medication.isWithdrawalActive) {
      await service.scheduleWithdrawalEnd(medication);
    }
  }

  /// Called when a medication is deleted — cancels its notifications.
  Future<void> onMedicationDeleted(String medicationId) async {
    final service = NotificationService();
    await service.cancelMedicationNotification(medicationId);
    await service.cancelWithdrawalNotification(medicationId);
  }

  /// Called when eggs are logged - reschedules reminder for tomorrow
  Future<void> onEggsLogged() async {
    if (!state.eggReminders || state.eggReminderTime == null) return;

    final service = NotificationService();
    await service.scheduleEggReminder(state.eggReminderTime!, tomorrow: true);
  }

  /// Evaluates and schedules egg reminder based on current state
  Future<void> evaluateEggReminder() async {
    if (!state.eggReminders || state.eggReminderTime == null) return;

    await _scheduleEggReminderIfNeeded();
  }

  Future<void> _scheduleEggReminderIfNeeded() async {
    if (!state.eggReminders || state.eggReminderTime == null) return;

    final eggRepo = EggRepository();
    final hasEggsToday = await eggRepo.hasEggsLoggedToday();
    final service = NotificationService();

    if (hasEggsToday) {
      // Already logged today - schedule for tomorrow
      await service.scheduleEggReminder(state.eggReminderTime!, tomorrow: true);
    } else {
      // No eggs today - schedule for today (or tomorrow if time passed)
      await service.scheduleEggReminder(state.eggReminderTime!);
    }
  }

  Future<bool> requestPermission() async {
    final service = NotificationService();
    final granted = await service.requestPermissions();
    state = state.copyWith(permissionGranted: granted);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyPermissionGranted, granted);

    if (granted) {
      // Schedule notifications if enabled
      await _scheduleAllNotifications();
    }

    return granted;
  }

  Future<void> checkPermissionStatus() async {
    final service = NotificationService();
    final granted = await service.areNotificationsEnabled();
    if (granted != state.permissionGranted) {
      state = state.copyWith(permissionGranted: granted);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keyPermissionGranted, granted);
    }
  }

  Future<void> _scheduleAllNotifications() async {
    await _scheduleAllMedicationNotifications();
    await _scheduleAllWithdrawalNotifications();
  }

  Future<void> _scheduleAllMedicationNotifications() async {
    if (!state.medicationReminders) return;

    final service = NotificationService();
    final medications = await ref.read(medicationsProvider.future);

    for (final med in medications) {
      if (med.endDate != null && med.endDate!.isAfter(DateTime.now())) {
        await service.scheduleMedicationEnd(med);
      }
    }
  }

  Future<void> _scheduleAllWithdrawalNotifications() async {
    if (!state.withdrawalAlerts) return;

    final service = NotificationService();
    final medications = await ref.read(medicationsProvider.future);

    for (final med in medications) {
      if (med.isWithdrawalActive) {
        await service.scheduleWithdrawalEnd(med);
      }
    }
  }
}

/// Provider for notification settings
final notificationSettingsProvider =
    NotifierProvider<NotificationSettingsNotifier, NotificationSettings>(() {
  return NotificationSettingsNotifier();
});

/// Provider to initialize notification service
final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService();
});

/// Whether the exact-alarm special permission is granted (Android 12+).
/// Invalidate after directing the user to the system settings page.
final exactAlarmAllowedProvider = FutureProvider<bool>((ref) async {
  return NotificationService().hasExactAlarmPermission();
});

// NOTE: medication notification scheduling/cancellation lives on
// NotificationSettingsNotifier (onMedicationSaved / onMedicationDeleted).
// The previous FutureProvider.family versions were never called from any
// save path — medications added after initial permission grant never got
// notifications scheduled at all (#26) — and family FutureProviders cache
// their result, making them unsafe for repeat side effects.
