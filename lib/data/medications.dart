// Static medication data for common poultry treatments.
// This is reference data bundled with the app, not persisted to the database.
//
// DISCLAIMER: This information is for reference only. Always consult a
// veterinarian and follow product label instructions. Withdrawal times
// can vary based on dosage, administration method, and local regulations.
//
// LEGAL NOTE: Some medications listed here are NOT approved for use in
// poultry or food-producing animals in the United States. These are included
// for educational reference only. Always verify legality in your jurisdiction.

enum MedicationCategory {
  antibiotic,
  antiparasitic,
  coccidiostat,
  antifungal,
  vitamin,
  electrolyte,
  naturalRemedy,
  other,
}

enum AdministrationRoute {
  water,
  oral,
  injection,
  topical,
  feed,
}

/// Legal status for use in poultry in the United States
enum LegalStatus {
  /// FDA approved for use in poultry
  fdaApproved,

  /// Not FDA approved but commonly used off-label under veterinary guidance
  offLabel,

  /// Requires veterinary prescription (VFD or Rx)
  prescriptionRequired,

  /// BANNED for use in poultry in the United States
  bannedInUs,

  /// Not permitted in food-producing animals
  notForFoodAnimals,
}

class Medication {
  final String id;
  final String name;
  final String genericName;
  final List<String> brandNames;
  final MedicationCategory category;

  /// Egg withdrawal in days. Null means no established withdrawal period.
  final int? withdrawalDaysEgg;

  /// Meat withdrawal in days. Null means no established withdrawal period.
  final int? withdrawalDaysMeat;

  /// Additional context about withdrawal (e.g., "varies by source", "do not use in layers")
  final String? withdrawalNote;

  final List<AdministrationRoute> routes;
  final List<String> treatsConditions;
  final String dosageNotes;
  final String description;

  /// Legal status in the United States
  final LegalStatus legalStatus;

  /// Additional warning text for serious legal/safety concerns
  final String? legalWarning;

  const Medication({
    required this.id,
    required this.name,
    required this.genericName,
    this.brandNames = const [],
    required this.category,
    this.withdrawalDaysEgg,
    this.withdrawalDaysMeat,
    this.withdrawalNote,
    required this.routes,
    this.treatsConditions = const [],
    required this.dosageNotes,
    required this.description,
    required this.legalStatus,
    this.legalWarning,
  });

  /// Display-friendly category name
  String get categoryDisplay {
    switch (category) {
      case MedicationCategory.antibiotic:
        return 'Antibiotic';
      case MedicationCategory.antiparasitic:
        return 'Antiparasitic';
      case MedicationCategory.coccidiostat:
        return 'Coccidiostat';
      case MedicationCategory.antifungal:
        return 'Antifungal';
      case MedicationCategory.vitamin:
        return 'Vitamin/Supplement';
      case MedicationCategory.electrolyte:
        return 'Electrolyte';
      case MedicationCategory.naturalRemedy:
        return 'Natural Remedy';
      case MedicationCategory.other:
        return 'Other';
    }
  }

  /// Display-friendly legal status
  String get legalStatusDisplay {
    switch (legalStatus) {
      case LegalStatus.fdaApproved:
        return 'FDA Approved';
      case LegalStatus.offLabel:
        return 'Off-Label Use';
      case LegalStatus.prescriptionRequired:
        return 'Prescription Required';
      case LegalStatus.bannedInUs:
        return 'BANNED IN U.S.';
      case LegalStatus.notForFoodAnimals:
        return 'NOT FOR FOOD ANIMALS';
    }
  }

  /// Whether this medication has a known withdrawal period
  bool get hasWithdrawal =>
      (withdrawalDaysEgg != null && withdrawalDaysEgg! > 0) ||
          (withdrawalDaysMeat != null && withdrawalDaysMeat! > 0);

  /// Whether withdrawal period is unknown/not established
  bool get hasUnknownWithdrawal =>
      withdrawalDaysEgg == null || withdrawalDaysMeat == null;

  /// The longer of the two withdrawal periods (0 if both null)
  int get maxWithdrawalDays {
    final egg = withdrawalDaysEgg ?? 0;
    final meat = withdrawalDaysMeat ?? 0;
    return egg > meat ? egg : meat;
  }

  /// Whether this medication is banned or not for food animals
  bool get isBannedOrRestricted =>
      legalStatus == LegalStatus.bannedInUs ||
          legalStatus == LegalStatus.notForFoodAnimals;

  /// Whether to show a prominent warning in the UI
  bool get showLegalWarning =>
      isBannedOrRestricted || legalWarning != null;

  /// Get withdrawal display text for eggs
  String get withdrawalEggDisplay {
    if (legalStatus == LegalStatus.bannedInUs ||
        legalStatus == LegalStatus.notForFoodAnimals) {
      return 'N/A';
    }
    if (withdrawalDaysEgg == null) {
      return 'Unknown';
    }
    return '${withdrawalDaysEgg}d';
  }

  /// Get withdrawal display text for meat
  String get withdrawalMeatDisplay {
    if (legalStatus == LegalStatus.bannedInUs ||
        legalStatus == LegalStatus.notForFoodAnimals) {
      return 'N/A';
    }
    if (withdrawalDaysMeat == null) {
      return 'Unknown';
    }
    return '${withdrawalDaysMeat}d';
  }
}

/// All medications bundled with the app
const List<Medication> medications = [
  // === COCCIDIOSTATS ===

  Medication(
    id: 'amprolium',
    name: 'Corid',
    genericName: 'Amprolium',
    brandNames: ['Corid', 'Amprol', 'Amprovine'],
    category: MedicationCategory.coccidiostat,
    withdrawalDaysEgg: 0,
    withdrawalDaysMeat: 0,
    routes: [AdministrationRoute.water],
    treatsConditions: ['Coccidiosis'],
    dosageNotes:
    'Treatment: 2 tsp per gallon for 5-7 days. Prevention: 1/3 tsp per gallon for 1-2 weeks. Use 20% soluble powder or 9.6% liquid.',
    description:
    'The most common treatment for coccidiosis in backyard flocks. Amprolium is a thiamine blocker that stops coccidia reproduction. Not an antibiotic. It has no withdrawal period as it\'s not absorbed systemically. Note: Can interfere with vitamin B1 (thiamine) absorption.',
    legalStatus: LegalStatus.fdaApproved,
  ),

  // === DEWORMERS / ANTIPARASITICS ===

  Medication(
    id: 'fenbendazole',
    name: 'SafeGuard',
    genericName: 'Fenbendazole',
    brandNames: ['SafeGuard', 'Panacur'],
    category: MedicationCategory.antiparasitic,
    withdrawalDaysEgg: 14,
    withdrawalDaysMeat: 14,
    withdrawalNote: 'Off-label; 14 days commonly recommended but not FDA-established.',
    routes: [AdministrationRoute.oral, AdministrationRoute.feed],
    treatsConditions: [
      'Roundworms',
      'Capillary worms',
      'Cecal worms',
      'Gapeworms',
    ],
    dosageNotes:
    'Goat formulation: 1ml per 10 lbs body weight orally for 3-5 consecutive days. Can mix with feed at 1oz per 15-20 lbs feed.',
    description:
    'A broad-spectrum dewormer effective against most common chicken parasites except tapeworms. Generally considered safe with a wide margin of error. Not FDA-approved for poultry but commonly used off-label.',
    legalStatus: LegalStatus.offLabel,
  ),

  Medication(
    id: 'ivermectin',
    name: 'Ivermectin',
    genericName: 'Ivermectin',
    brandNames: ['Ivomec', 'Eprinex'],
    category: MedicationCategory.antiparasitic,
    withdrawalDaysEgg: null,
    withdrawalDaysMeat: null,
    withdrawalNote: 'NO ESTABLISHED WITHDRAWAL. Recommendations range from 7-14 days to discarding eggs indefinitely. Consult a veterinarian.',
    routes: [AdministrationRoute.oral, AdministrationRoute.topical],
    treatsConditions: [
      'Roundworms',
      'Capillary worms',
      'Gapeworms',
      'Mites',
      'Lice',
    ],
    dosageNotes:
    'Pour-on (Eprinex): 0.5ml for large fowl, applied to skin on back of neck. Injectable (given orally): 0.25ml per large fowl. Do NOT inject chickens.',
    description:
    'The most common mite/lice treatment in backyard flocks. Also effective against internal parasites. Not FDA-approved for poultry—use with veterinary guidance.',
    legalStatus: LegalStatus.offLabel,
  ),

  Medication(
    id: 'piperazine',
    name: 'Wazine',
    genericName: 'Piperazine',
    brandNames: ['Wazine', 'Wazine-17'],
    category: MedicationCategory.antiparasitic,
    withdrawalDaysEgg: 14,
    withdrawalDaysMeat: 14,
    routes: [AdministrationRoute.water],
    treatsConditions: ['Large roundworms'],
    dosageNotes:
    '1 oz per gallon of drinking water for one day. Repeat in 10-14 days.',
    description:
    'One of the few FDA-approved dewormers for poultry, but only effective against large roundworms (Ascaridia galli). Often used as a first dewormer due to legal status, but has limited spectrum.',
    legalStatus: LegalStatus.fdaApproved,
  ),

  Medication(
    id: 'levamisole',
    name: 'Prohibit',
    genericName: 'Levamisole',
    brandNames: ['Prohibit', 'Levasol', 'Tramisol'],
    category: MedicationCategory.antiparasitic,
    withdrawalDaysEgg: null,
    withdrawalDaysMeat: null,
    withdrawalNote: 'No FDA-established withdrawal for poultry. Common recommendations: 7-14 days.',
    routes: [AdministrationRoute.water],
    treatsConditions: [
      'Roundworms',
      'Capillary worms',
      'Cecal worms',
      'Gapeworms',
    ],
    dosageNotes:
    'Dissolve packet in water as directed. Provide as only water source for one day. Narrow margin of safety—do not overdose.',
    description:
    'A fast-acting dewormer with immune-stimulating properties. Has a narrower safety margin than fenbendazole, so accurate dosing is important. Not FDA-approved for poultry.',
    legalStatus: LegalStatus.offLabel,
  ),

  // === TOPICAL/EXTERNAL ===

  Medication(
    id: 'permethrin',
    name: 'Permethrin',
    genericName: 'Permethrin',
    brandNames: ['Poultry Dust', 'Gordon\'s Permethrin-10', 'Prozap'],
    category: MedicationCategory.antiparasitic,
    withdrawalDaysEgg: 0,
    withdrawalDaysMeat: 0,
    routes: [AdministrationRoute.topical],
    treatsConditions: ['Mites', 'Lice', 'Fleas', 'Flies'],
    dosageNotes:
    'Dust: Apply directly to birds and nesting areas. Spray: Dilute 10% concentrate to 0.5% and spray coop thoroughly. Repeat in 10-14 days.',
    description:
    'A synthetic pyrethroid insecticide highly effective against external parasites. Safe when used as directed. Also used to treat coops and nesting boxes.',
    legalStatus: LegalStatus.fdaApproved,
  ),

  Medication(
    id: 'sevin',
    name: 'Sevin Dust',
    genericName: 'Carbaryl',
    brandNames: ['Sevin', 'Garden Tech'],
    category: MedicationCategory.antiparasitic,
    withdrawalDaysEgg: 7,
    withdrawalDaysMeat: 7,
    routes: [AdministrationRoute.topical],
    treatsConditions: ['Mites', 'Lice'],
    dosageNotes:
    'Dust birds lightly under wings and around vent. Apply to bedding and coop. Repeat in 10-14 days.',
    description:
    'A traditional garden insecticide sometimes used for poultry parasites. Being phased out in favor of permethrin in many areas. Use 5% garden dust formula only.',
    legalStatus: LegalStatus.offLabel,
  ),

  // === NATURAL REMEDIES ===

  Medication(
    id: 'vetrx',
    name: 'VetRx',
    genericName: 'VetRx Poultry Remedy',
    brandNames: ['VetRx'],
    category: MedicationCategory.naturalRemedy,
    withdrawalDaysEgg: 0,
    withdrawalDaysMeat: 0,
    routes: [AdministrationRoute.oral, AdministrationRoute.topical],
    treatsConditions: [
      'Respiratory congestion',
      'Scaly leg mites',
      'Colds',
    ],
    dosageNotes:
    'Internal: Add to water or apply drops to beak. External: Warm and apply to legs for scaly leg mites, or under wings for respiratory issues.',
    description:
    'A traditional remedy made from camphor, oil of origanum, and other natural ingredients. Helps with respiratory symptoms and scaly leg mites. Not a cure for infections but provides supportive care.',
    legalStatus: LegalStatus.fdaApproved,
  ),

  Medication(
    id: 'acv',
    name: 'Apple Cider Vinegar',
    genericName: 'Apple Cider Vinegar',
    brandNames: ['Bragg\'s', 'Various'],
    category: MedicationCategory.naturalRemedy,
    withdrawalDaysEgg: 0,
    withdrawalDaysMeat: 0,
    routes: [AdministrationRoute.water],
    treatsConditions: [
      'General health maintenance',
      'Digestive support',
    ],
    dosageNotes:
    '1-2 tablespoons per gallon of water, 2-3 times per week. Use raw, unfiltered ACV with "mother." Do not use in metal waterers.',
    description:
    'A popular natural supplement believed to support digestive health and boost immunity. Limited scientific evidence but widely used by backyard keepers. Use plastic or ceramic waterers only.',
    legalStatus: LegalStatus.fdaApproved,
  ),

  Medication(
    id: 'garlic',
    name: 'Garlic',
    genericName: 'Allium sativum',
    brandNames: [],
    category: MedicationCategory.naturalRemedy,
    withdrawalDaysEgg: 0,
    withdrawalDaysMeat: 0,
    routes: [AdministrationRoute.water, AdministrationRoute.feed],
    treatsConditions: [
      'General health maintenance',
      'Immune support',
      'Mild parasite prevention',
    ],
    dosageNotes:
    'Crushed: 1 clove per quart of water or mixed into feed. Some keepers add to water weekly as a preventive.',
    description:
    'A natural supplement with mild antimicrobial properties. Some keepers use it as part of a natural parasite prevention program. May affect egg flavor if used excessively.',
    legalStatus: LegalStatus.fdaApproved,
  ),

  Medication(
    id: 'oregano',
    name: 'Oregano Oil',
    genericName: 'Oregano Essential Oil',
    brandNames: ['Various'],
    category: MedicationCategory.naturalRemedy,
    withdrawalDaysEgg: 0,
    withdrawalDaysMeat: 0,
    routes: [AdministrationRoute.water, AdministrationRoute.feed],
    treatsConditions: [
      'Respiratory support',
      'Immune support',
      'Coccidiosis prevention',
    ],
    dosageNotes:
    'Commercial products: follow label directions. DIY: 1-2 drops food-grade oil per gallon water, or dried oregano in feed.',
    description:
    'Contains carvacrol and thymol with natural antimicrobial properties. Commercial poultry farms use oregano products as antibiotic alternatives. Some evidence for coccidia prevention.',
    legalStatus: LegalStatus.fdaApproved,
  ),

  Medication(
    id: 'diatomaceous_earth',
    name: 'Diatomaceous Earth',
    genericName: 'Diatomaceous Earth (Food Grade)',
    brandNames: ['Harris', 'Safer Brand', 'Various'],
    category: MedicationCategory.naturalRemedy,
    withdrawalDaysEgg: 0,
    withdrawalDaysMeat: 0,
    routes: [AdministrationRoute.topical, AdministrationRoute.feed],
    treatsConditions: [
      'External parasites (prevention)',
      'Internal parasites (claimed)',
    ],
    dosageNotes:
    'Dust bath: Mix into dust bath area. Coop: Sprinkle in bedding and crevices. Feed: 2% of feed ration (controversial effectiveness).',
    description:
    'Fossilized algae that damages insect exoskeletons. Effective for external parasite prevention in dust baths and coop treatment. Internal use for worms is not scientifically supported. Use FOOD GRADE only.',
    legalStatus: LegalStatus.fdaApproved,
  ),

  // === VITAMINS & ELECTROLYTES ===

  Medication(
    id: 'vitamins_electrolytes',
    name: 'Poultry Vitamins & Electrolytes',
    genericName: 'Vitamin/Electrolyte Supplement',
    brandNames: ['Sav-A-Chick', 'Durvet', 'Rooster Booster'],
    category: MedicationCategory.electrolyte,
    withdrawalDaysEgg: 0,
    withdrawalDaysMeat: 0,
    routes: [AdministrationRoute.water],
    treatsConditions: [
      'Heat stress',
      'Dehydration',
      'Illness recovery',
      'Shipping stress',
    ],
    dosageNotes:
    'Follow package directions. Typically one packet per gallon. Use for 3-5 days during stress or illness.',
    description:
    'A supportive supplement for stressed or recovering birds. Replaces electrolytes lost during heat stress or illness. Good to keep on hand for emergencies.',
    legalStatus: LegalStatus.fdaApproved,
  ),

  Medication(
    id: 'vitamin_e_selenium',
    name: 'Vitamin E with Selenium',
    genericName: 'Vitamin E / Selenium',
    brandNames: ['Poultry Cell', 'Nutri-Drench'],
    category: MedicationCategory.vitamin,
    withdrawalDaysEgg: 0,
    withdrawalDaysMeat: 0,
    routes: [AdministrationRoute.oral],
    treatsConditions: [
      'Wry neck (torticollis)',
      'Vitamin E deficiency',
      'Neurological symptoms',
    ],
    dosageNotes:
    'For wry neck: 400 IU vitamin E daily + selenium supplement, with B-complex. Continue for 1-2 weeks or until symptoms resolve.',
    description:
    'Essential for treating wry neck (torticollis) and other neurological issues related to vitamin E deficiency. Often combined with B vitamins and selenium for best results.',
    legalStatus: LegalStatus.fdaApproved,
  ),

  Medication(
    id: 'calcium',
    name: 'Calcium Supplement',
    genericName: 'Calcium',
    brandNames: ['Oyster Shell', 'Limestone', 'Calcium Gluconate'],
    category: MedicationCategory.vitamin,
    withdrawalDaysEgg: 0,
    withdrawalDaysMeat: 0,
    routes: [AdministrationRoute.feed, AdministrationRoute.oral],
    treatsConditions: [
      'Soft shelled eggs',
      'Egg binding (emergency)',
      'Calcium deficiency',
    ],
    dosageNotes:
    'Prevention: Offer oyster shell free-choice in separate container. Emergency (egg binding): Liquid calcium given orally, seek vet care.',
    description:
    'Essential for laying hens to produce strong eggshells. Should always be available free-choice. Liquid calcium can help in egg-binding emergencies but is not a substitute for veterinary care.',
    legalStatus: LegalStatus.fdaApproved,
  ),

  Medication(
    id: 'probiotics',
    name: 'Poultry Probiotics',
    genericName: 'Probiotic Supplement',
    brandNames: ['Big Ole Bird', 'Gro-2-Max', 'Various'],
    category: MedicationCategory.vitamin,
    withdrawalDaysEgg: 0,
    withdrawalDaysMeat: 0,
    routes: [AdministrationRoute.water, AdministrationRoute.feed],
    treatsConditions: [
      'Post-antibiotic recovery',
      'Digestive upset',
      'Chick health',
    ],
    dosageNotes:
    'Follow package directions. Typically added to water or sprinkled on feed. Use after antibiotic treatment to restore gut flora.',
    description:
    'Beneficial bacteria that support digestive health. Particularly useful after antibiotic treatment to repopulate healthy gut bacteria. Also good for chicks and stressed birds.',
    legalStatus: LegalStatus.fdaApproved,
  ),

  // === WOUND CARE ===

  Medication(
    id: 'blu_kote',
    name: 'Blu-Kote',
    genericName: 'Gentian Violet Antiseptic',
    brandNames: ['Blu-Kote', 'Dr. Naylor Blu-Kote'],
    category: MedicationCategory.other,
    withdrawalDaysEgg: 0,
    withdrawalDaysMeat: 0,
    routes: [AdministrationRoute.topical],
    treatsConditions: [
      'Wounds',
      'Pecking injuries',
      'Fungal infections',
      'Bumblefoot',
    ],
    dosageNotes:
    'Spray or dab onto clean wounds. The blue/purple color helps hide wounds from other birds who may peck at red areas.',
    description:
    'An antiseptic wound spray that colors the wound blue/purple, helping to hide it from flock mates. Chickens are attracted to red and will peck at wounds; the blue color deters this.',
    legalStatus: LegalStatus.fdaApproved,
  ),

  Medication(
    id: 'vetericyn',
    name: 'Vetericyn',
    genericName: 'Hypochlorous Acid',
    brandNames: ['Vetericyn Plus', 'Vetericyn Poultry Care'],
    category: MedicationCategory.other,
    withdrawalDaysEgg: 0,
    withdrawalDaysMeat: 0,
    routes: [AdministrationRoute.topical],
    treatsConditions: [
      'Wounds',
      'Eye infections',
      'Bumblefoot',
      'Vent prolapse',
    ],
    dosageNotes:
    'Clean wound and spray liberally. Can be used around eyes and sensitive areas. Repeat 2-3 times daily until healed.',
    description:
    'A non-toxic wound care spray safe for use around eyes, mouth, and sensitive tissue. Does not sting. Excellent for cleaning and promoting healing of various injuries.',
    legalStatus: LegalStatus.fdaApproved,
  ),
];

// === HELPER FUNCTIONS ===

/// Get a medication by its ID, or null if not found
Medication? getMedicationById(String id) {
  try {
    return medications.firstWhere((m) => m.id == id);
  } catch (_) {
    return null;
  }
}

/// Search medications by name, generic name, brand names, conditions, or description
List<Medication> searchMedications(String query) {
  final q = query.toLowerCase().trim();
  if (q.isEmpty) return medications;

  return medications.where((m) {
    if (m.name.toLowerCase().contains(q)) return true;
    if (m.genericName.toLowerCase().contains(q)) return true;
    if (m.brandNames.any((b) => b.toLowerCase().contains(q))) return true;
    if (m.treatsConditions.any((c) => c.toLowerCase().contains(q))) return true;
    if (m.description.toLowerCase().contains(q)) return true;
    return false;
  }).toList();
}

/// Filter medications by category
List<Medication> getMedicationsByCategory(MedicationCategory category) {
  return medications.where((m) => m.category == category).toList();
}

/// Get medications that treat a specific condition
List<Medication> getMedicationsForCondition(String condition) {
  final c = condition.toLowerCase();
  return medications.where((m) {
    return m.treatsConditions.any((t) => t.toLowerCase().contains(c));
  }).toList();
}

/// Get medications with no withdrawal period
List<Medication> getNoWithdrawalMedications() {
  return medications.where((m) => !m.hasWithdrawal && !m.isBannedOrRestricted).toList();
}

/// Get medications safe for laying hens (FDA approved, no withdrawal concerns)
List<Medication> getLayerSafeMedications() {
  return medications.where((m) {
    if (m.isBannedOrRestricted) return false;
    if (m.withdrawalNote?.toLowerCase().contains('laying hen') == true) return false;
    if (m.legalWarning?.toLowerCase().contains('laying') == true) return false;
    return true;
  }).toList();
}

/// Get medications that are FDA approved
List<Medication> getFdaApprovedMedications() {
  return medications.where((m) => m.legalStatus == LegalStatus.fdaApproved).toList();
}

/// Get medications that require a prescription
List<Medication> getPrescriptionMedications() {
  return medications.where((m) => m.legalStatus == LegalStatus.prescriptionRequired).toList();
}

/// Get over-the-counter medications (FDA approved, no prescription)
List<Medication> getOtcMedications() {
  return medications.where((m) => m.legalStatus == LegalStatus.fdaApproved).toList();
}

/// Get natural remedies only
List<Medication> getNaturalRemedies() {
  return medications
      .where((m) => m.category == MedicationCategory.naturalRemedy)
      .toList();
}

/// Get medications sorted by withdrawal period (longest first)
List<Medication> getMedicationsByWithdrawal() {
  final sorted = List<Medication>.from(medications);
  sorted.sort((a, b) => b.maxWithdrawalDays.compareTo(a.maxWithdrawalDays));
  return sorted;
}

/// Get banned or restricted medications (for reference/education only)
List<Medication> getBannedMedications() {
  return medications.where((m) => m.isBannedOrRestricted).toList();
}

/// Calculate withdrawal end date from start date
DateTime calculateWithdrawalEnd(DateTime treatmentEnd, int withdrawalDays) {
  return treatmentEnd.add(Duration(days: withdrawalDays));
}

/// Check if a withdrawal period is still active
bool isWithdrawalActive(DateTime treatmentEnd, int withdrawalDays) {
  final withdrawalEnd = calculateWithdrawalEnd(treatmentEnd, withdrawalDays);
  return DateTime.now().isBefore(withdrawalEnd);
}

/// Get days remaining in withdrawal period
int getWithdrawalDaysRemaining(DateTime treatmentEnd, int withdrawalDays) {
  final withdrawalEnd = calculateWithdrawalEnd(treatmentEnd, withdrawalDays);
  final remaining = withdrawalEnd.difference(DateTime.now()).inDays;
  return remaining > 0 ? remaining : 0;
}
