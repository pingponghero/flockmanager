import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter/material.dart' show TimeOfDay;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
        debugPrint('🔔 Notifications not enabled, requesting permission');
        final granted = await requestPermission();
        if (!granted) {
          debugPrint('🔔 Notification permission denied, not enabling egg reminders');
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

  /// Called when eggs are logged - reschedules reminder for tomorrow
  Future<void> onEggsLogged() async {
    if (!state.eggReminders || state.eggReminderTime == null) return;

    final service = NotificationService();
    await service.scheduleEggReminder(state.eggReminderTime!, tomorrow: true);
  }

  /// Evaluates and schedules egg reminder based on current state
  Future<void> evaluateEggReminder() async {
    debugPrint('🔔 evaluateEggReminder called - eggReminders: ${state.eggReminders}, time: ${state.eggReminderTime}');
    if (!state.eggReminders || state.eggReminderTime == null) return;

    await _scheduleEggReminderIfNeeded();
  }

  Future<void> _scheduleEggReminderIfNeeded() async {
    debugPrint('🔔 _scheduleEggReminderIfNeeded called');
    if (!state.eggReminders || state.eggReminderTime == null) return;

    final eggRepo = EggRepository();
    final hasEggsToday = await eggRepo.hasEggsLoggedToday();
    final service = NotificationService();

    debugPrint('🔔 hasEggsToday: $hasEggsToday, time: ${state.eggReminderTime}');

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

/// Provider to schedule notifications for a medication
/// Call this when a medication is added or updated
final scheduleMedicationNotificationsProvider =
    FutureProvider.family<void, String>((ref, medicationId) async {
  final settings = ref.watch(notificationSettingsProvider);
  if (!settings.permissionGranted) return;

  final medication = await ref.watch(medicationByIdProvider(medicationId).future);
  if (medication == null) return;

  final service = NotificationService();

  // Schedule medication end notification
  if (settings.medicationReminders && medication.endDate != null) {
    await service.scheduleMedicationEnd(medication);
  }

  // Schedule withdrawal end notification
  if (settings.withdrawalAlerts && medication.isWithdrawalActive) {
    await service.scheduleWithdrawalEnd(medication);
  }
});

/// Provider to cancel notifications for a medication
/// Call this when a medication is deleted
final cancelMedicationNotificationsProvider =
    FutureProvider.family<void, String>((ref, medicationId) async {
  final service = NotificationService();
  await service.cancelMedicationNotification(medicationId);
  await service.cancelWithdrawalNotification(medicationId);
});
