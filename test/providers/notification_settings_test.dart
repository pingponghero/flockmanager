import 'package:flutter/material.dart' show TimeOfDay;
import 'package:flutter_test/flutter_test.dart';
import 'package:flock_manager/providers/notification_provider.dart';

void main() {
  group('NotificationSettings', () {
    test('default values are correct', () {
      const settings = NotificationSettings();

      expect(settings.medicationReminders, isTrue);
      expect(settings.withdrawalAlerts, isTrue);
      expect(settings.expenseReminders, isTrue);
      expect(settings.permissionGranted, isFalse);
      expect(settings.eggReminders, isFalse);
      expect(settings.eggReminderTime, isNull);
    });

    test('copyWith preserves unchanged values', () {
      const original = NotificationSettings(
        medicationReminders: true,
        withdrawalAlerts: true,
        expenseReminders: true,
        permissionGranted: true,
        eggReminders: true,
        eggReminderTime: TimeOfDay(hour: 18, minute: 0),
      );

      final copied = original.copyWith();

      expect(copied.medicationReminders, original.medicationReminders);
      expect(copied.withdrawalAlerts, original.withdrawalAlerts);
      expect(copied.expenseReminders, original.expenseReminders);
      expect(copied.permissionGranted, original.permissionGranted);
      expect(copied.eggReminders, original.eggReminders);
      expect(copied.eggReminderTime, original.eggReminderTime);
    });

    test('copyWith updates specified values', () {
      const original = NotificationSettings();

      final updated = original.copyWith(
        medicationReminders: false,
        withdrawalAlerts: false,
        expenseReminders: false,
        permissionGranted: true,
        eggReminders: true,
        eggReminderTime: const TimeOfDay(hour: 19, minute: 30),
      );

      expect(updated.medicationReminders, isFalse);
      expect(updated.withdrawalAlerts, isFalse);
      expect(updated.expenseReminders, isFalse);
      expect(updated.permissionGranted, isTrue);
      expect(updated.eggReminders, isTrue);
      expect(updated.eggReminderTime?.hour, 19);
      expect(updated.eggReminderTime?.minute, 30);
    });

    test('copyWith can clear eggReminderTime', () {
      const original = NotificationSettings(
        eggReminderTime: TimeOfDay(hour: 18, minute: 0),
      );

      final cleared = original.copyWith(clearEggReminderTime: true);

      expect(cleared.eggReminderTime, isNull);
    });

    test('copyWith with clearEggReminderTime ignores new eggReminderTime', () {
      const original = NotificationSettings(
        eggReminderTime: TimeOfDay(hour: 18, minute: 0),
      );

      final result = original.copyWith(
        clearEggReminderTime: true,
        eggReminderTime: const TimeOfDay(hour: 20, minute: 0),
      );

      expect(result.eggReminderTime, isNull);
    });

    test('copyWith updates only one value', () {
      const original = NotificationSettings(
        medicationReminders: true,
        withdrawalAlerts: true,
        eggReminders: false,
      );

      final updated = original.copyWith(eggReminders: true);

      expect(updated.medicationReminders, isTrue);
      expect(updated.withdrawalAlerts, isTrue);
      expect(updated.eggReminders, isTrue);
    });
  });
}
