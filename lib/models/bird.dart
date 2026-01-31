import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:uuid/uuid.dart';

import 'enums.dart';

part 'bird.freezed.dart';

@freezed
abstract class Bird with _$Bird {
  const Bird._();

  const factory Bird({
    required String id,
    required String flockId,
    required String name,
    String? breed,
    String? breedId,
    String? photoPrimary,
    DateTime? hatchDate,
    DateTime? acquiredDate,
    String? source,
    String? eggColor,
    @Default(BirdSex.female) BirdSex sex,
    @Default(BirdSpecies.chicken) BirdSpecies species,
    @Default(BirdStatus.active) BirdStatus status,
    DateTime? statusDate,
    String? statusNotes,
    String? notes,
    required DateTime createdAt,
  }) = _Bird;

  /// Create a new bird with generated ID and timestamp
  factory Bird.create({
    required String flockId,
    required String name,
    String? breed,
    String? breedId,
    String? photoPrimary,
    DateTime? hatchDate,
    DateTime? acquiredDate,
    String? source,
    String? eggColor,
    BirdSex sex = BirdSex.female,
    BirdSpecies species = BirdSpecies.chicken,
    String? notes,
  }) {
    return Bird(
      id: const Uuid().v4(),
      flockId: flockId,
      name: name,
      breed: breed,
      breedId: breedId,
      photoPrimary: photoPrimary,
      hatchDate: hatchDate,
      acquiredDate: acquiredDate,
      source: source,
      eggColor: eggColor,
      sex: sex,
      species: species,
      notes: notes,
      createdAt: DateTime.now(),
    );
  }

  /// Create from SQLite map
  factory Bird.fromMap(Map<String, dynamic> map) {
    return Bird(
      id: map['id'] as String,
      flockId: map['flock_id'] as String,
      name: map['name'] as String,
      breed: map['breed'] as String?,
      breedId: map['breed_id'] as String?,
      photoPrimary: map['photo_primary'] as String?,
      hatchDate: map['hatch_date'] != null
          ? DateTime.parse(map['hatch_date'] as String)
          : null,
      acquiredDate: map['acquired_date'] != null
          ? DateTime.parse(map['acquired_date'] as String)
          : null,
      source: map['source'] as String?,
      eggColor: map['egg_color'] as String?,
      sex: BirdSex.values.firstWhere(
        (e) => e.name == (map['sex'] as String? ?? 'female'),
        orElse: () => BirdSex.female,
      ),
      species: BirdSpecies.values.firstWhere(
        (e) => e.name == (map['species'] as String? ?? 'chicken'),
        orElse: () => BirdSpecies.chicken,
      ),
      status: BirdStatus.values.firstWhere(
        (e) => e.name == (map['status'] as String? ?? 'active'),
        orElse: () => BirdStatus.active,
      ),
      statusDate: map['status_date'] != null
          ? DateTime.parse(map['status_date'] as String)
          : null,
      statusNotes: map['status_notes'] as String?,
      notes: map['notes'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  /// Convert to SQLite map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'flock_id': flockId,
      'name': name,
      'breed': breed,
      'breed_id': breedId,
      'photo_primary': photoPrimary,
      'hatch_date': hatchDate?.toIso8601String(),
      'acquired_date': acquiredDate?.toIso8601String(),
      'source': source,
      'egg_color': eggColor,
      'sex': sex.name,
      'species': species.name,
      'status': status.name,
      'status_date': statusDate?.toIso8601String(),
      'status_notes': statusNotes,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
    };
  }

  /// Calculate age in days from hatch date
  int? get ageInDays {
    if (hatchDate == null) return null;
    return DateTime.now().difference(hatchDate!).inDays;
  }

  /// Calculate age in weeks from hatch date
  int? get ageInWeeks {
    final days = ageInDays;
    if (days == null) return null;
    return days ~/ 7;
  }

  /// Check if this bird is a hen
  bool get isHen => sex == BirdSex.female;

  /// Check if this bird is a rooster
  bool get isRooster => sex == BirdSex.male;

  /// Check if this bird is a chicken
  bool get isChicken => species == BirdSpecies.chicken;
}
