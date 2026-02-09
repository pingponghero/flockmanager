import 'package:flutter_test/flutter_test.dart';
import 'package:flock_manager/models/enums.dart';

void main() {
  group('BirdStatus', () {
    test('displayName returns correct values', () {
      expect(BirdStatus.active.displayName, 'Active');
      expect(BirdStatus.inactive.displayName, 'Inactive');
      expect(BirdStatus.deceased.displayName, 'Deceased');
      expect(BirdStatus.sold.displayName, 'Sold');
      expect(BirdStatus.givenAway.displayName, 'Given Away');
    });

    test('all values are defined', () {
      expect(BirdStatus.values.length, 5);
    });
  });

  group('EggSize', () {
    test('displayName returns correct values', () {
      expect(EggSize.small.displayName, 'Small');
      expect(EggSize.medium.displayName, 'Medium');
      expect(EggSize.large.displayName, 'Large');
      expect(EggSize.jumbo.displayName, 'Jumbo');
    });

    test('all values are defined', () {
      expect(EggSize.values.length, 4);
    });
  });

  group('EggQuality', () {
    test('displayName returns correct values', () {
      expect(EggQuality.normal.displayName, 'Normal');
      expect(EggQuality.softShell.displayName, 'Soft Shell');
      expect(EggQuality.doubleYolk.displayName, 'Double Yolk');
      expect(EggQuality.fairy.displayName, 'Fairy');
      expect(EggQuality.abnormal.displayName, 'Abnormal');
    });

    test('all values are defined', () {
      expect(EggQuality.values.length, 5);
    });
  });

  group('ExpenseCategory', () {
    test('displayName returns correct values', () {
      expect(ExpenseCategory.feed.displayName, 'Feed');
      expect(ExpenseCategory.bedding.displayName, 'Bedding');
      expect(ExpenseCategory.supplies.displayName, 'Supplies');
      expect(ExpenseCategory.medical.displayName, 'Medical');
      expect(ExpenseCategory.equipment.displayName, 'Equipment');
      expect(ExpenseCategory.other.displayName, 'Other');
    });

    test('all values are defined', () {
      expect(ExpenseCategory.values.length, 6);
    });
  });

  group('HealthNoteType', () {
    test('displayName returns correct values', () {
      expect(HealthNoteType.observation.displayName, 'Observation');
      expect(HealthNoteType.symptom.displayName, 'Symptom');
      expect(HealthNoteType.treatment.displayName, 'Treatment');
      expect(HealthNoteType.vetVisit.displayName, 'Vet Visit');
      expect(HealthNoteType.other.displayName, 'Other');
    });

    test('all values are defined', () {
      expect(HealthNoteType.values.length, 5);
    });
  });

  group('RecurringInterval', () {
    test('displayName returns correct values', () {
      expect(RecurringInterval.weekly.displayName, 'Weekly');
      expect(RecurringInterval.monthly.displayName, 'Monthly');
    });

    test('all values are defined', () {
      expect(RecurringInterval.values.length, 2);
    });
  });
}
