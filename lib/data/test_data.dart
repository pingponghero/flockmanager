/// Test data for Flock Manager app development and testing.
///
/// This file provides realistic sample data for:
/// - 3 flocks (backyard layers, bantams, breeding project)
/// - 12 birds with varied breeds, ages, and statuses
/// - 35 days of egg production logs with realistic patterns
/// - Expenses across all categories
/// - Medication logs with withdrawal tracking
/// - Health notes
///
/// Usage:
/// ```dart
/// import 'package:flock_manager/data/test_data.dart';
/// await TestData.seedDatabase();
/// ```

import 'dart:math';
import '../database/database_helper.dart';

final _random = Random();
String _generateId() =>
    '${DateTime.now().microsecondsSinceEpoch.toRadixString(36)}-${_random.nextInt(999999).toRadixString(36)}';

/// Helper to generate dates relative to today
String _daysAgo(int days) {
  final date = DateTime.now().subtract(Duration(days: days));
  return date.toIso8601String().split('T')[0];
}

String _daysAgoFull(int days) {
  return DateTime.now().subtract(Duration(days: days)).toIso8601String();
}

/// Static IDs for referential integrity in test data
class TestIds {
  // Flocks
  static const flockBackyard = 'flock-backyard-001';
  static const flockBantams = 'flock-bantams-002';
  static const flockBreeding = 'flock-breeding-003';
  
  // Birds - Backyard flock
  static const birdHenrietta = 'bird-henrietta-001';
  static const birdGinger = 'bird-ginger-002';
  static const birdPepper = 'bird-pepper-003';
  static const birdDottie = 'bird-dottie-004';
  static const birdOlive = 'bird-olive-005';
  static const birdHazel = 'bird-hazel-006';
  static const birdMaple = 'bird-maple-007';
  
  // Birds - Bantam flock
  static const birdPebbles = 'bird-pebbles-008';
  static const birdCookie = 'bird-cookie-009';
  
  // Birds - Breeding flock
  static const birdMidnight = 'bird-midnight-010';
  static const birdCopper = 'bird-copper-011';
  static const birdShadow = 'bird-shadow-012';
}

/// Test flock data
final List<Map<String, dynamic>> testFlocks = [
  {
    'id': TestIds.flockBackyard,
    'name': 'Backyard Layers',
    'description': 'Main egg production flock - mixed breeds for colorful egg basket',
    'icon': 'egg',
    'color': '4CAF50', // Green
    'is_archived': 0,
    'created_at': _daysAgoFull(180),
  },
  {
    'id': TestIds.flockBantams,
    'name': 'Bantam Buddies',
    'description': 'Small ornamental flock - mostly pets',
    'icon': 'pets',
    'color': 'FF9800', // Orange
    'is_archived': 0,
    'created_at': _daysAgoFull(90),
  },
  {
    'id': TestIds.flockBreeding,
    'name': 'Marans Project',
    'description': 'Black Copper Marans breeding for dark eggs',
    'icon': 'nature',
    'color': '795548', // Brown
    'is_archived': 0,
    'created_at': _daysAgoFull(60),
  },
];

/// Test bird data
final List<Map<String, dynamic>> testBirds = [
  // === BACKYARD LAYERS FLOCK ===
  {
    'id': TestIds.birdHenrietta,
    'flock_id': TestIds.flockBackyard,
    'name': 'Henrietta',
    'breed': 'Barred Plymouth Rock',
    'breed_id': 'plymouth_rock_barred',
    'photo_primary': null,
    'hatch_date': _daysAgo(540), // ~1.5 years old
    'acquired_date': _daysAgo(480),
    'source': 'Local feed store',
    'egg_color': 'Brown',
    'status': 'active',
    'status_date': null,
    'status_notes': null,
    'notes': 'Flock leader. First to the treat bowl, keeps everyone in line.',
    'created_at': _daysAgoFull(180),
  },
  {
    'id': TestIds.birdGinger,
    'flock_id': TestIds.flockBackyard,
    'name': 'Ginger',
    'breed': 'Buff Orpington',
    'breed_id': 'orpington_buff',
    'photo_primary': null,
    'hatch_date': _daysAgo(510),
    'acquired_date': _daysAgo(480),
    'source': 'Local feed store',
    'egg_color': 'Brown',
    'status': 'active',
    'status_date': null,
    'status_notes': null,
    'notes': 'Sweetest bird in the flock. Goes broody every spring.',
    'created_at': _daysAgoFull(180),
  },
  {
    'id': TestIds.birdPepper,
    'flock_id': TestIds.flockBackyard,
    'name': 'Pepper',
    'breed': 'Silver Laced Wyandotte',
    'breed_id': 'wyandotte',
    'photo_primary': null,
    'hatch_date': _daysAgo(400),
    'acquired_date': _daysAgo(380),
    'source': 'Neighbor hatched',
    'egg_color': 'Brown',
    'status': 'active',
    'status_date': null,
    'status_notes': null,
    'notes': 'Beautiful lacing. Consistent layer even in winter.',
    'created_at': _daysAgoFull(150),
  },
  {
    'id': TestIds.birdDottie,
    'flock_id': TestIds.flockBackyard,
    'name': 'Dottie',
    'breed': 'Speckled Sussex',
    'breed_id': 'sussex_speckled',
    'photo_primary': null,
    'hatch_date': _daysAgo(380),
    'acquired_date': _daysAgo(360),
    'source': 'Tractor Supply',
    'egg_color': 'Brown',
    'status': 'active',
    'status_date': null,
    'status_notes': null,
    'notes': 'Most curious bird - always investigating everything.',
    'created_at': _daysAgoFull(140),
  },
  {
    'id': TestIds.birdOlive,
    'flock_id': TestIds.flockBackyard,
    'name': 'Olive',
    'breed': 'Olive Egger',
    'breed_id': 'olive_egger',
    'photo_primary': null,
    'hatch_date': _daysAgo(320),
    'acquired_date': _daysAgo(300),
    'source': 'Online hatchery',
    'egg_color': 'Olive',
    'status': 'active',
    'status_date': null,
    'status_notes': null,
    'notes': 'Beautiful olive eggs! F1 cross from Marans x Ameraucana.',
    'created_at': _daysAgoFull(120),
  },
  {
    'id': TestIds.birdHazel,
    'flock_id': TestIds.flockBackyard,
    'name': 'Hazel',
    'breed': 'Easter Egger',
    'breed_id': 'easter_egger',
    'photo_primary': null,
    'hatch_date': _daysAgo(290),
    'acquired_date': _daysAgo(270),
    'source': 'Local breeder',
    'egg_color': 'Blue',
    'status': 'active',
    'status_date': null,
    'status_notes': null,
    'notes': 'Lays pretty blue eggs. Has a cute beard and muffs.',
    'created_at': _daysAgoFull(100),
  },
  {
    'id': TestIds.birdMaple,
    'flock_id': TestIds.flockBackyard,
    'name': 'Maple',
    'breed': 'Rhode Island Red',
    'breed_id': 'rhode_island_red',
    'photo_primary': null,
    'hatch_date': _daysAgo(600),
    'acquired_date': _daysAgo(560),
    'source': 'Friend\'s farm',
    'egg_color': 'Brown',
    'status': 'deceased',
    'status_date': _daysAgo(15),
    'status_notes': 'Found in coop, passed peacefully in sleep. Good layer for 2 years.',
    'notes': 'Was our best layer. RIP sweet girl.',
    'created_at': _daysAgoFull(180),
  },
  
  // === BANTAM FLOCK ===
  {
    'id': TestIds.birdPebbles,
    'flock_id': TestIds.flockBantams,
    'name': 'Pebbles',
    'breed': 'Silkie',
    'breed_id': 'silkie',
    'photo_primary': null,
    'hatch_date': _daysAgo(450),
    'acquired_date': _daysAgo(420),
    'source': 'Poultry show',
    'egg_color': 'Cream',
    'status': 'active',
    'status_date': null,
    'status_notes': null,
    'notes': 'White silkie. Goes broody constantly - great foster mom.',
    'created_at': _daysAgoFull(90),
  },
  {
    'id': TestIds.birdCookie,
    'flock_id': TestIds.flockBantams,
    'name': 'Cookie',
    'breed': 'Sebright',
    'breed_id': 'sebright',
    'photo_primary': null,
    'hatch_date': _daysAgo(380),
    'acquired_date': _daysAgo(350),
    'source': 'Poultry show',
    'egg_color': 'Cream',
    'status': 'active',
    'status_date': null,
    'status_notes': null,
    'notes': 'Golden Sebright. Tiny eggs but so pretty!',
    'created_at': _daysAgoFull(85),
  },
  
  // === BREEDING FLOCK ===
  {
    'id': TestIds.birdMidnight,
    'flock_id': TestIds.flockBreeding,
    'name': 'Midnight',
    'breed': 'Black Copper Marans',
    'breed_id': 'marans_black_copper',
    'photo_primary': null,
    'hatch_date': _daysAgo(300),
    'acquired_date': _daysAgo(280),
    'source': 'Marans breeder - show quality',
    'egg_color': 'Chocolate',
    'status': 'active',
    'status_date': null,
    'status_notes': null,
    'notes': 'Best egg color in the flock. Eggs consistently #6-7 on Marans scale.',
    'created_at': _daysAgoFull(60),
  },
  {
    'id': TestIds.birdCopper,
    'flock_id': TestIds.flockBreeding,
    'name': 'Copper',
    'breed': 'Black Copper Marans',
    'breed_id': 'marans_black_copper',
    'photo_primary': null,
    'hatch_date': _daysAgo(310),
    'acquired_date': _daysAgo(280),
    'source': 'Marans breeder - show quality',
    'egg_color': 'Chocolate',
    'status': 'active',
    'status_date': null,
    'status_notes': null,
    'notes': 'Beautiful copper hackles. Eggs lighter than Midnight (#5).',
    'created_at': _daysAgoFull(60),
  },
  {
    'id': TestIds.birdShadow,
    'flock_id': TestIds.flockBreeding,
    'name': 'Shadow',
    'breed': 'Black Copper Marans',
    'breed_id': 'marans_black_copper',
    'photo_primary': null,
    'hatch_date': _daysAgo(295),
    'acquired_date': _daysAgo(280),
    'source': 'Marans breeder - show quality',
    'egg_color': 'Chocolate',
    'status': 'active',
    'status_date': null,
    'status_notes': null,
    'notes': 'Rooster. Great temperament, protective but not aggressive.',
    'created_at': _daysAgoFull(60),
  },
];

/// Generate 35 days of realistic egg production data
/// Patterns simulated:
/// - Daily variation (not every hen lays every day)
/// - Slightly lower weekend collection (sometimes miss afternoon eggs)
/// - Weather dip (days 20-22 simulated cold snap)
/// - One bird deceased at day 15
List<Map<String, dynamic>> generateEggLogs() {
  final logs = <Map<String, dynamic>>[];
  
  // Baseline daily production by flock
  // Backyard: 6 active layers -> expect 4-6 eggs/day typically
  // Bantams: 2 layers -> expect 0-2 eggs/day
  // Breeding: 2 laying hens -> expect 1-2 eggs/day
  
  for (int day = 0; day < 35; day++) {
    final date = _daysAgo(day);
    final dayOfWeek = DateTime.now().subtract(Duration(days: day)).weekday;
    final isWeekend = dayOfWeek == 6 || dayOfWeek == 7;
    final isColdSnap = day >= 20 && day <= 22;
    final mapleAlive = day >= 15; // Maple died 15 days ago
    
    // Backyard flock eggs
    int backyardBase = mapleAlive ? 5 : 4; // One fewer after Maple passed
    if (isWeekend) backyardBase -= 1;
    if (isColdSnap) backyardBase -= 2;
    
    // Add natural daily variation (-1 to +1)
    final backyardVariation = (day % 3) - 1;
    int backyardCount = (backyardBase + backyardVariation).clamp(0, 7);
    
    // Occasionally attribute some eggs to specific birds
    if (day % 4 == 0 && backyardCount > 0) {
      // Log individually attributed eggs
      logs.add({
        'id': _generateId(),
        'date': date,
        'flock_id': TestIds.flockBackyard,
        'bird_id': TestIds.birdHenrietta,
        'count': 1,
        'size': 'large',
        'quality': 'normal',
        'notes': null,
        'created_at': _daysAgoFull(day),
      });
      backyardCount -= 1;
    }
    
    if (day % 5 == 0 && backyardCount > 0) {
      logs.add({
        'id': _generateId(),
        'date': date,
        'flock_id': TestIds.flockBackyard,
        'bird_id': TestIds.birdOlive,
        'count': 1,
        'size': 'medium',
        'quality': 'normal',
        'notes': 'Beautiful dark olive color today',
        'created_at': _daysAgoFull(day),
      });
      backyardCount -= 1;
    }
    
    // Log remaining as flock total
    if (backyardCount > 0) {
      String? notes;
      String quality = 'normal';
      String size = 'large';
      
      if (day == 8) {
        notes = 'Found one soft shell, might need more calcium';
        quality = 'softShell';
      } else if (day == 25) {
        notes = 'Double yolker from one of the Orpingtons!';
        quality = 'doubleYolk';
        size = 'jumbo';
      } else if (isColdSnap) {
        notes = 'Cold weather affecting production';
      }
      
      logs.add({
        'id': _generateId(),
        'date': date,
        'flock_id': TestIds.flockBackyard,
        'bird_id': null,
        'count': backyardCount,
        'size': size,
        'quality': quality,
        'notes': notes,
        'created_at': _daysAgoFull(day),
      });
    }
    
    // Bantam flock eggs (less consistent, often broody)
    int bantamCount = day % 3 == 0 ? 2 : (day % 2 == 0 ? 1 : 0);
    if (day >= 10 && day <= 20) bantamCount = 0; // Pebbles went broody
    
    if (bantamCount > 0) {
      logs.add({
        'id': _generateId(),
        'date': date,
        'flock_id': TestIds.flockBantams,
        'bird_id': null,
        'count': bantamCount,
        'size': 'small',
        'quality': 'normal',
        'notes': day == 9 ? 'Last eggs before Pebbles went broody' : null,
        'created_at': _daysAgoFull(day),
      });
    }
    
    // Breeding flock eggs
    int breedingCount = isColdSnap ? 1 : 2;
    if (day % 4 == 0) breedingCount = 1; // Natural variation
    
    if (breedingCount > 0) {
      logs.add({
        'id': _generateId(),
        'date': date,
        'flock_id': TestIds.flockBreeding,
        'bird_id': day % 2 == 0 ? TestIds.birdMidnight : null,
        'count': breedingCount,
        'size': 'large',
        'quality': 'normal',
        'notes': day == 3 ? 'Saved for incubator - great color' : null,
        'created_at': _daysAgoFull(day),
      });
    }
  }
  
  return logs;
}

/// Test expense data
final List<Map<String, dynamic>> testExpenses = [
  {
    'id': _generateId(),
    'date': _daysAgo(2),
    'amount': 32.99,
    'category': 'feed',
    'description': '50lb layer pellets - Purina',
    'flock_id': null, // Shared across flocks
    'is_recurring': 0,
    'recurring_interval': null,
    'created_at': _daysAgoFull(2),
  },
  {
    'id': _generateId(),
    'date': _daysAgo(5),
    'amount': 8.99,
    'category': 'feed',
    'description': 'Mealworm treats 5lb bag',
    'flock_id': null,
    'is_recurring': 0,
    'recurring_interval': null,
    'created_at': _daysAgoFull(5),
  },
  {
    'id': _generateId(),
    'date': _daysAgo(8),
    'amount': 15.49,
    'category': 'bedding',
    'description': 'Pine shavings - large bale',
    'flock_id': TestIds.flockBackyard,
    'is_recurring': 0,
    'recurring_interval': null,
    'created_at': _daysAgoFull(8),
  },
  {
    'id': _generateId(),
    'date': _daysAgo(12),
    'amount': 24.99,
    'category': 'supplies',
    'description': 'Heated waterer base for winter',
    'flock_id': null,
    'is_recurring': 0,
    'recurring_interval': null,
    'created_at': _daysAgoFull(12),
  },
  {
    'id': _generateId(),
    'date': _daysAgo(18),
    'amount': 12.95,
    'category': 'medical',
    'description': 'Poultry VetRx - respiratory support',
    'flock_id': TestIds.flockBackyard,
    'is_recurring': 0,
    'recurring_interval': null,
    'created_at': _daysAgoFull(18),
  },
  {
    'id': _generateId(),
    'date': _daysAgo(22),
    'amount': 89.00,
    'category': 'equipment',
    'description': 'New nest boxes (3 pack)',
    'flock_id': TestIds.flockBackyard,
    'is_recurring': 0,
    'recurring_interval': null,
    'created_at': _daysAgoFull(22),
  },
  {
    'id': _generateId(),
    'date': _daysAgo(25),
    'amount': 6.49,
    'category': 'supplies',
    'description': 'Oyster shell calcium supplement',
    'flock_id': null,
    'is_recurring': 0,
    'recurring_interval': null,
    'created_at': _daysAgoFull(25),
  },
  {
    'id': _generateId(),
    'date': _daysAgo(30),
    'amount': 32.99,
    'category': 'feed',
    'description': '50lb layer pellets - Purina',
    'flock_id': null,
    'is_recurring': 1,
    'recurring_interval': 'monthly',
    'created_at': _daysAgoFull(30),
  },
  {
    'id': _generateId(),
    'date': _daysAgo(32),
    'amount': 45.00,
    'category': 'other',
    'description': 'Fertile hatching eggs (Marans) - 6 pack',
    'flock_id': TestIds.flockBreeding,
    'is_recurring': 0,
    'recurring_interval': null,
    'created_at': _daysAgoFull(32),
  },
];

/// Test income data
final List<Map<String, dynamic>> testIncome = [
  {
    'id': _generateId(),
    'date': _daysAgo(3),
    'amount': 6.00,
    'description': 'Egg sale to neighbor - 1 dozen',
    'egg_count': 12,
    'created_at': _daysAgoFull(3),
  },
  {
    'id': _generateId(),
    'date': _daysAgo(10),
    'amount': 12.00,
    'description': 'Egg sale - 2 dozen mixed colors',
    'egg_count': 24,
    'created_at': _daysAgoFull(10),
  },
  {
    'id': _generateId(),
    'date': _daysAgo(17),
    'amount': 18.00,
    'description': 'Egg sale at farmers market',
    'egg_count': 36,
    'created_at': _daysAgoFull(17),
  },
  {
    'id': _generateId(),
    'date': _daysAgo(24),
    'amount': 6.00,
    'description': 'Coworker egg sale',
    'egg_count': 12,
    'created_at': _daysAgoFull(24),
  },
];

/// Test medication logs
final List<Map<String, dynamic>> testMedicationLogs = [
  {
    'id': _generateId(),
    'bird_id': null,
    'flock_id': TestIds.flockBackyard,
    'medication_name': 'Corid (Amprolium)',
    'dosage': '9.5ml per gallon water',
    'start_date': _daysAgo(45),
    'end_date': _daysAgo(40),
    'withdrawal_days': 0,
    'notes': 'Preventive treatment - new birds introduced',
    'created_at': _daysAgoFull(45),
  },
  {
    'id': _generateId(),
    'bird_id': TestIds.birdGinger,
    'flock_id': TestIds.flockBackyard,
    'medication_name': 'VetRx',
    'dosage': '2 drops under wing, 2 drops in water',
    'start_date': _daysAgo(18),
    'end_date': _daysAgo(14),
    'withdrawal_days': 0,
    'notes': 'Minor respiratory wheeze, cleared up quickly',
    'created_at': _daysAgoFull(18),
  },
  {
    'id': _generateId(),
    'bird_id': null,
    'flock_id': TestIds.flockBackyard,
    'medication_name': 'SafeGuard (Fenbendazole)',
    'dosage': '0.5ml per bird orally',
    'start_date': _daysAgo(60),
    'end_date': _daysAgo(55),
    'withdrawal_days': 14,
    'notes': 'Quarterly deworming',
    'created_at': _daysAgoFull(60),
  },
  // Active medication for testing withdrawal banner
  {
    'id': _generateId(),
    'bird_id': null,
    'flock_id': TestIds.flockBreeding,
    'medication_name': 'Valbazen',
    'dosage': '0.5ml per bird',
    'start_date': _daysAgo(5),
    'end_date': _daysAgo(3),
    'withdrawal_days': 14,
    'notes': 'Pre-breeding deworming. Withdrawal ends ${_daysAgo(-11)}',
    'created_at': _daysAgoFull(5),
  },
];

/// Test health notes
final List<Map<String, dynamic>> testHealthNotes = [
  {
    'id': _generateId(),
    'bird_id': TestIds.birdGinger,
    'date': _daysAgo(18),
    'type': 'symptom',
    'description': 'Slight wheeze noticed, no discharge. Eating and drinking normally.',
    'created_at': _daysAgoFull(18),
  },
  {
    'id': _generateId(),
    'bird_id': TestIds.birdGinger,
    'date': _daysAgo(16),
    'type': 'treatment',
    'description': 'Started VetRx treatment. Applied under wings and added to water.',
    'created_at': _daysAgoFull(16),
  },
  {
    'id': _generateId(),
    'bird_id': TestIds.birdGinger,
    'date': _daysAgo(14),
    'type': 'observation',
    'description': 'Wheeze completely cleared. Back to normal.',
    'created_at': _daysAgoFull(14),
  },
  {
    'id': _generateId(),
    'bird_id': TestIds.birdPebbles,
    'date': _daysAgo(10),
    'type': 'observation',
    'description': 'Going broody - puffed up, refusing to leave nest box. Moved to broody breaker.',
    'created_at': _daysAgoFull(10),
  },
  {
    'id': _generateId(),
    'bird_id': TestIds.birdPebbles,
    'date': _daysAgo(5),
    'type': 'observation',
    'description': 'Still broody after 5 days in wire cage. Trying frozen water bottle method.',
    'created_at': _daysAgoFull(5),
  },
  {
    'id': _generateId(),
    'bird_id': TestIds.birdMaple,
    'date': _daysAgo(16),
    'type': 'symptom',
    'description': 'Slower than usual, staying on roost more. Eating less. Age catching up?',
    'created_at': _daysAgoFull(16),
  },
  {
    'id': _generateId(),
    'bird_id': TestIds.birdMaple,
    'date': _daysAgo(15),
    'type': 'other',
    'description': 'Found passed away on roost this morning. Peaceful. She was a good girl.',
    'created_at': _daysAgoFull(15),
  },
  {
    'id': _generateId(),
    'bird_id': TestIds.birdHenrietta,
    'date': _daysAgo(30),
    'type': 'observation',
    'description': 'Annual health check - good weight, clear eyes, healthy comb. Top condition.',
    'created_at': _daysAgoFull(30),
  },
  {
    'id': _generateId(),
    'bird_id': TestIds.birdMidnight,
    'date': _daysAgo(7),
    'type': 'observation',
    'description': 'Eggs consistently #6-7 on Marans color scale. Great breeding candidate.',
    'created_at': _daysAgoFull(7),
  },
];

/// All test data consolidated
class TestData {
  static final flocks = testFlocks;
  static final birds = testBirds;
  static final eggLogs = generateEggLogs();
  static final expenses = testExpenses;
  static final income = testIncome;
  static final medicationLogs = testMedicationLogs;
  static final healthNotes = testHealthNotes;
  
  /// Print summary statistics
  static void printSummary() {
    final eggs = eggLogs;
    final totalEggs = eggs.fold<int>(0, (sum, log) => sum + (log['count'] as int));
    
    print('=== TEST DATA SUMMARY ===');
    print('Flocks: ${flocks.length}');
    print('Birds: ${birds.length} (${birds.where((b) => b['status'] == 'active').length} active)');
    print('Egg logs: ${eggs.length} entries');
    print('Total eggs: $totalEggs over 35 days');
    print('Daily average: ${(totalEggs / 35).toStringAsFixed(1)} eggs');
    print('Expenses: ${expenses.length} entries');
    print('Income: ${income.length} entries');
    print('Medication logs: ${medicationLogs.length} entries');
    print('Health notes: ${healthNotes.length} entries');
    print('========================');
  }
  
  /// Seed the database with test data.
  /// WARNING: This clears all existing data!
  ///
  /// ```dart
  /// await TestData.seedDatabase();
  /// ```
  static Future<void> seedDatabase() async {
    final db = await DatabaseHelper.instance.database;

    // Clear existing data (order matters due to foreign keys)
    await db.delete('health_notes');
    await db.delete('medication_logs');
    await db.delete('income');
    await db.delete('expenses');
    await db.delete('egg_logs');
    await db.delete('bird_photos');
    await db.delete('birds');
    await db.delete('flocks');

    // Insert flocks
    for (final flock in flocks) {
      await db.insert('flocks', flock);
    }

    // Insert birds
    for (final bird in birds) {
      await db.insert('birds', bird);
    }

    // Insert egg logs
    for (final log in eggLogs) {
      await db.insert('egg_logs', log);
    }

    // Insert expenses
    for (final expense in expenses) {
      await db.insert('expenses', expense);
    }

    // Insert income
    for (final inc in income) {
      await db.insert('income', inc);
    }

    // Insert medication logs
    for (final med in medicationLogs) {
      await db.insert('medication_logs', med);
    }

    // Insert health notes
    for (final note in healthNotes) {
      await db.insert('health_notes', note);
    }

    // ignore: avoid_print
    print('Test data seeded successfully!');
    printSummary();
  }

  /// Check if test data exists in the database
  static Future<bool> hasTestData() async {
    final db = await DatabaseHelper.instance.database;
    final result = await db.query('flocks',
        where: 'id = ?', whereArgs: [TestIds.flockBackyard]);
    return result.isNotEmpty;
  }
}

// Run this to see the test data summary
void main() {
  TestData.printSummary();
  
  // Print first few egg logs as sample
  print('\n=== SAMPLE EGG LOGS (first 10) ===');
  for (final log in TestData.eggLogs.take(10)) {
    print('${log['date']}: ${log['count']} eggs (${log['flock_id']?.toString().split('-')[1] ?? 'unknown'})');
  }
}
