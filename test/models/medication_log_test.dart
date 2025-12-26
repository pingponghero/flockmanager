import 'package:flutter_test/flutter_test.dart';
import 'package:flock_manager/models/medication_log.dart';

void main() {
  group('MedicationLog', () {
    test('create() generates unique ID and timestamp', () {
      final log = MedicationLog.create(
        flockId: 'flock-123',
        medicationName: 'Corid',
        startDate: DateTime(2024, 1, 15),
      );

      expect(log.id, isNotEmpty);
      expect(log.medicationName, 'Corid');
      expect(log.createdAt, isNotNull);
    });

    test('create() with all fields', () {
      final log = MedicationLog.create(
        birdId: 'bird-456',
        flockId: 'flock-123',
        medicationName: 'SafeGuard',
        dosage: '1ml per bird',
        startDate: DateTime(2024, 1, 15),
        endDate: DateTime(2024, 1, 20),
        withdrawalDays: 14,
        notes: 'Treating for worms',
      );

      expect(log.birdId, 'bird-456');
      expect(log.dosage, '1ml per bird');
      expect(log.withdrawalDays, 14);
    });

    test('toMap() converts to SQLite-compatible map', () {
      final startDate = DateTime(2024, 1, 15);
      final endDate = DateTime(2024, 1, 20);
      final createdAt = DateTime(2024, 1, 15, 8, 0);

      final log = MedicationLog(
        id: 'med-123',
        birdId: 'bird-456',
        flockId: 'flock-789',
        medicationName: 'Tylan',
        dosage: '2ml',
        startDate: startDate,
        endDate: endDate,
        withdrawalDays: 1,
        notes: 'Respiratory treatment',
        createdAt: createdAt,
      );

      final map = log.toMap();

      expect(map['id'], 'med-123');
      expect(map['bird_id'], 'bird-456');
      expect(map['flock_id'], 'flock-789');
      expect(map['medication_name'], 'Tylan');
      expect(map['withdrawal_days'], 1);
    });

    test('fromMap() creates MedicationLog from SQLite map', () {
      final map = {
        'id': 'med-456',
        'bird_id': null,
        'flock_id': 'flock-123',
        'medication_name': 'VetRx',
        'dosage': 'As directed',
        'start_date': '2024-06-20T00:00:00.000',
        'end_date': null,
        'withdrawal_days': 0,
        'notes': null,
        'created_at': '2024-06-20T00:00:00.000',
      };

      final log = MedicationLog.fromMap(map);

      expect(log.id, 'med-456');
      expect(log.medicationName, 'VetRx');
      expect(log.birdId, isNull);
      expect(log.endDate, isNull);
    });

    test('isActive returns true when endDate is null', () {
      final log = MedicationLog(
        id: 'med-active',
        flockId: 'flock-123',
        medicationName: 'Ongoing Treatment',
        startDate: DateTime.now().subtract(const Duration(days: 5)),
        createdAt: DateTime.now(),
      );

      expect(log.isActive, true);
    });

    test('isActive returns true when endDate is in future', () {
      final log = MedicationLog(
        id: 'med-active',
        flockId: 'flock-123',
        medicationName: 'Current Treatment',
        startDate: DateTime.now().subtract(const Duration(days: 2)),
        endDate: DateTime.now().add(const Duration(days: 3)),
        createdAt: DateTime.now(),
      );

      expect(log.isActive, true);
    });

    test('isActive returns false when endDate is in past', () {
      final log = MedicationLog(
        id: 'med-inactive',
        flockId: 'flock-123',
        medicationName: 'Past Treatment',
        startDate: DateTime.now().subtract(const Duration(days: 10)),
        endDate: DateTime.now().subtract(const Duration(days: 5)),
        createdAt: DateTime.now(),
      );

      expect(log.isActive, false);
    });

    test('withdrawalEndDate calculates correctly', () {
      final endDate = DateTime(2024, 1, 20);

      final log = MedicationLog(
        id: 'med-withdrawal',
        flockId: 'flock-123',
        medicationName: 'SafeGuard',
        startDate: DateTime(2024, 1, 15),
        endDate: endDate,
        withdrawalDays: 14,
        createdAt: DateTime.now(),
      );

      expect(log.withdrawalEndDate, DateTime(2024, 2, 3));
    });

    test('withdrawalEndDate returns null when withdrawalDays is null', () {
      final log = MedicationLog(
        id: 'med-no-withdrawal',
        flockId: 'flock-123',
        medicationName: 'VetRx',
        startDate: DateTime.now(),
        createdAt: DateTime.now(),
      );

      expect(log.withdrawalEndDate, isNull);
    });

    test('withdrawalEndDate returns null when withdrawalDays is 0', () {
      final log = MedicationLog(
        id: 'med-zero-withdrawal',
        flockId: 'flock-123',
        medicationName: 'Corid',
        startDate: DateTime.now(),
        withdrawalDays: 0,
        createdAt: DateTime.now(),
      );

      expect(log.withdrawalEndDate, isNull);
    });

    test('isWithdrawalActive returns true during withdrawal period', () {
      final log = MedicationLog(
        id: 'med-in-withdrawal',
        flockId: 'flock-123',
        medicationName: 'SafeGuard',
        startDate: DateTime.now().subtract(const Duration(days: 10)),
        endDate: DateTime.now().subtract(const Duration(days: 5)),
        withdrawalDays: 14,
        createdAt: DateTime.now(),
      );

      expect(log.isWithdrawalActive, true);
    });

    test('roundtrip: toMap -> fromMap preserves data', () {
      final original = MedicationLog.create(
        birdId: 'bird-123',
        flockId: 'flock-456',
        medicationName: 'Ivermectin',
        dosage: '0.5ml',
        startDate: DateTime(2024, 3, 1),
        endDate: DateTime(2024, 3, 3),
        withdrawalDays: 14,
        notes: 'Parasite treatment',
      );

      final map = original.toMap();
      final restored = MedicationLog.fromMap(map);

      expect(restored.id, original.id);
      expect(restored.medicationName, original.medicationName);
      expect(restored.withdrawalDays, original.withdrawalDays);
    });
  });
}
