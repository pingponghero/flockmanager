import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:uuid/uuid.dart';

part 'medication_log.freezed.dart';

@freezed
abstract class MedicationLog with _$MedicationLog {
  const MedicationLog._();

  const factory MedicationLog({
    required String id,
    String? birdId,
    required String flockId,
    required String medicationName,
    String? dosage,
    required DateTime startDate,
    DateTime? endDate,
    int? withdrawalDays,
    String? notes,
    required DateTime createdAt,
  }) = _MedicationLog;

  /// Create a new medication log with generated ID and timestamp
  factory MedicationLog.create({
    String? birdId,
    required String flockId,
    required String medicationName,
    String? dosage,
    required DateTime startDate,
    DateTime? endDate,
    int? withdrawalDays,
    String? notes,
  }) {
    return MedicationLog(
      id: const Uuid().v4(),
      birdId: birdId,
      flockId: flockId,
      medicationName: medicationName,
      dosage: dosage,
      startDate: startDate,
      endDate: endDate,
      withdrawalDays: withdrawalDays,
      notes: notes,
      createdAt: DateTime.now(),
    );
  }

  /// Create from SQLite map
  factory MedicationLog.fromMap(Map<String, dynamic> map) {
    return MedicationLog(
      id: map['id'] as String,
      birdId: map['bird_id'] as String?,
      flockId: map['flock_id'] as String,
      medicationName: map['medication_name'] as String,
      dosage: map['dosage'] as String?,
      startDate: DateTime.parse(map['start_date'] as String),
      endDate: map['end_date'] != null
          ? DateTime.parse(map['end_date'] as String)
          : null,
      withdrawalDays: map['withdrawal_days'] as int?,
      notes: map['notes'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  /// Convert to SQLite map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'bird_id': birdId,
      'flock_id': flockId,
      'medication_name': medicationName,
      'dosage': dosage,
      'start_date': startDate.toIso8601String(),
      'end_date': endDate?.toIso8601String(),
      'withdrawal_days': withdrawalDays,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
    };
  }

  /// Check if medication is currently active
  bool get isActive {
    if (endDate == null) return true;
    return DateTime.now().isBefore(endDate!);
  }

  /// Calculate withdrawal end date
  DateTime? get withdrawalEndDate {
    if (withdrawalDays == null || withdrawalDays == 0) return null;
    final effectiveEndDate = endDate ?? DateTime.now();
    return effectiveEndDate.add(Duration(days: withdrawalDays!));
  }

  /// Check if withdrawal period is currently active
  bool get isWithdrawalActive {
    final endWithdrawal = withdrawalEndDate;
    if (endWithdrawal == null) return false;
    return DateTime.now().isBefore(endWithdrawal);
  }

  /// Days remaining in withdrawal period
  int? get withdrawalDaysRemaining {
    final endWithdrawal = withdrawalEndDate;
    if (endWithdrawal == null) return null;
    final remaining = endWithdrawal.difference(DateTime.now()).inDays;
    return remaining > 0 ? remaining : 0;
  }
}
