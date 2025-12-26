/// Bird status indicating current state
enum BirdStatus {
  active,
  deceased,
  sold,
  givenAway;

  String get displayName {
    switch (this) {
      case BirdStatus.active:
        return 'Active';
      case BirdStatus.deceased:
        return 'Deceased';
      case BirdStatus.sold:
        return 'Sold';
      case BirdStatus.givenAway:
        return 'Given Away';
    }
  }
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
  abnormal;

  String get displayName {
    switch (this) {
      case EggQuality.normal:
        return 'Normal';
      case EggQuality.softShell:
        return 'Soft Shell';
      case EggQuality.doubleYolk:
        return 'Double Yolk';
      case EggQuality.abnormal:
        return 'Abnormal';
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
