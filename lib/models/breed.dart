import 'package:freezed_annotation/freezed_annotation.dart';

part 'breed.freezed.dart';

/// Breed information for reference (not stored in SQLite, static data)
@freezed
class Breed with _$Breed {
  const Breed._();

  const factory Breed({
    required String id,
    required String name,
    String? aka,
    String? category,
    String? eggColor,
    String? eggSize,
    int? eggsPerYear,
    String? temperament,
    bool? coldHardy,
    bool? heatTolerant,
    String? broodyTendency,
    String? weight,
    String? description,
  }) = _Breed;

  /// Display egg production as a range string
  String get eggProductionDisplay {
    if (eggsPerYear == null) return 'Unknown';
    if (eggsPerYear! >= 280) return 'Excellent ($eggsPerYear+/year)';
    if (eggsPerYear! >= 200) return 'Good ($eggsPerYear/year)';
    if (eggsPerYear! >= 150) return 'Moderate ($eggsPerYear/year)';
    return 'Low ($eggsPerYear/year)';
  }
}
