import 'package:flutter/material.dart';

/// Bird status indicating current state
enum BirdStatus {
  active,
  inactive,
  deceased,
  sold,
  givenAway;

  String get displayName {
    switch (this) {
      case BirdStatus.active:
        return 'Active';
      case BirdStatus.inactive:
        return 'Inactive';
      case BirdStatus.deceased:
        return 'Deceased';
      case BirdStatus.sold:
        return 'Sold';
      case BirdStatus.givenAway:
        return 'Given Away';
    }
  }

  IconData get icon => switch (this) {
        BirdStatus.active => Icons.check_circle,
        BirdStatus.inactive => Icons.bedtime,
        BirdStatus.deceased => Icons.block,
        BirdStatus.sold => Icons.sell,
        BirdStatus.givenAway => Icons.volunteer_activism,
      };

  Color get iconColor => switch (this) {
        BirdStatus.active => Colors.green,
        BirdStatus.inactive => Colors.amber,
        BirdStatus.deceased => Colors.grey,
        BirdStatus.sold => Colors.blue,
        BirdStatus.givenAway => Colors.orange,
      };
}

/// Egg size classification
enum EggSize {
  small,
  medium,
  large,
  jumbo;

  String get displayName {
    switch (this) {
      case EggSize.small:
        return 'Small';
      case EggSize.medium:
        return 'Medium';
      case EggSize.large:
        return 'Large';
      case EggSize.jumbo:
        return 'Jumbo';
    }
  }
}

/// Egg quality classification
enum EggQuality {
  normal,
  softShell,
  doubleYolk,
  fairy,
  abnormal;

  String get displayName {
    switch (this) {
      case EggQuality.normal:
        return 'Normal';
      case EggQuality.softShell:
        return 'Soft Shell';
      case EggQuality.doubleYolk:
        return 'Double Yolk';
      case EggQuality.fairy:
        return 'Fairy';
      case EggQuality.abnormal:
        return 'Abnormal';
    }
  }
}

/// Bird sex
enum BirdSex {
  female,
  male,
  unknown;

  String get displayName {
    switch (this) {
      case BirdSex.female:
        return 'Female';
      case BirdSex.male:
        return 'Male';
      case BirdSex.unknown:
        return 'Unknown';
    }
  }
}

/// Bird species
enum BirdSpecies {
  chicken,
  duck,
  turkey,
  other;

  String get displayName {
    switch (this) {
      case BirdSpecies.chicken:
        return 'Chicken';
      case BirdSpecies.duck:
        return 'Duck';
      case BirdSpecies.turkey:
        return 'Turkey';
      case BirdSpecies.other:
        return 'Other';
    }
  }
}

/// Expense category for tracking costs
enum ExpenseCategory {
  feed,
  bedding,
  supplies,
  medical,
  equipment,
  other;

  String get displayName {
    switch (this) {
      case ExpenseCategory.feed:
        return 'Feed';
      case ExpenseCategory.bedding:
        return 'Bedding';
      case ExpenseCategory.supplies:
        return 'Supplies';
      case ExpenseCategory.medical:
        return 'Medical';
      case ExpenseCategory.equipment:
        return 'Equipment';
      case ExpenseCategory.other:
        return 'Other';
    }
  }
}

/// Health note type for categorizing observations
enum HealthNoteType {
  observation,
  symptom,
  treatment,
  vetVisit,
  other;

  String get displayName {
    switch (this) {
      case HealthNoteType.observation:
        return 'Observation';
      case HealthNoteType.symptom:
        return 'Symptom';
      case HealthNoteType.treatment:
        return 'Treatment';
      case HealthNoteType.vetVisit:
        return 'Vet Visit';
      case HealthNoteType.other:
        return 'Other';
    }
  }
}

/// Type of an income record: eggs sold for money, or gifted for free.
/// Gifts always have amount 0 and are excluded from sale statistics.
enum IncomeType {
  sale,
  gift;

  String get displayName {
    switch (this) {
      case IncomeType.sale:
        return 'Sale';
      case IncomeType.gift:
        return 'Gift';
    }
  }
}

/// Recurring interval for expenses
enum RecurringInterval {
  weekly,
  monthly;

  String get displayName {
    switch (this) {
      case RecurringInterval.weekly:
        return 'Weekly';
      case RecurringInterval.monthly:
        return 'Monthly';
    }
  }
}
