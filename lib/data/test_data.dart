/// Test data for Flock Manager app development and testing.
///
/// This file provides realistic sample data optimized for screenshots:
/// - 2 flocks (backyard layers with 5 hens, bantams with 2)
/// - 7 birds with varied breeds for colorful egg basket
/// - 365 days of egg production logs with seasonal patterns
/// - Bird status events for flock size tracking
/// - Expenses and income with clean numbers
/// - Some medication logs and health notes
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

/// Helper to generate dates relative to today (midnight timestamp for proper comparison)
String _daysAgo(int days) {
  final now = DateTime.now();
  final date = DateTime(now.year, now.month, now.day).subtract(Duration(days: days));
  return date.toIso8601String();
}

String _daysAgoFull(int days) {
  return DateTime.now().subtract(Duration(days: days)).toIso8601String();
}

/// Static IDs for referential integrity in test data
class TestIds {
  // Flocks
  static const flockBackyard = 'flock-backyard-001';
  static const flockBantams = 'flock-bantams-002';

  // Birds - Backyard flock (5 hens for nice distribution demo)
  static const birdHenrietta = 'bird-henrietta-001';
  static const birdGinger = 'bird-ginger-002';
  static const birdPepper = 'bird-pepper-003';
  static const birdOlive = 'bird-olive-004';
  static const birdHazel = 'bird-hazel-005';

  // Birds - Bantam flock
  static const birdPebbles = 'bird-pebbles-006';
  static const birdCookie = 'bird-cookie-007';
}


/// Calculate seasonal egg production multiplier based on day of year.
/// Simulates natural daylight-driven production cycle.
/// Summer (June): peak production (1.0)
/// Winter (December): low production (0.4)
double _seasonalMultiplier(int dayOfYear) {
  // Sine wave centered on June 21 (day 172)
  // Ranges from ~0.4 in winter to ~1.0 in summer
  final angle = 2 * pi * (dayOfYear - 172) / 365;
  return 0.7 + 0.3 * -cos(angle); // cos because we want peak at day 172
}

/// Generate 365 days of egg production data with seasonal variation
/// - Realistic seasonal patterns tied to daylight hours
/// - Some distributed egg entries (one per bird)
/// - Backyard: 5 hens -> varies 2-5 eggs/day based on season
/// - Bantams: 2 hens -> varies 0-2 eggs/day based on season
List<Map<String, dynamic>> generateEggLogs() {
  final logs = <Map<String, dynamic>>[];

  // Bird IDs for distributed logging
  final backyardBirds = [
    TestIds.birdHenrietta,
    TestIds.birdGinger,
    TestIds.birdPepper,
    TestIds.birdOlive,
    TestIds.birdHazel,
  ];

  final now = DateTime.now();

  for (int day = 0; day < 365; day++) {
    final date = _daysAgo(day);
    final timestamp = now.subtract(Duration(days: day, hours: 10));
    final timestampStr = timestamp.toIso8601String();

    // Calculate day of year for seasonal adjustment
    final logDate = now.subtract(Duration(days: day));
    final startOfYear = DateTime(logDate.year, 1, 1);
    final dayOfYear = logDate.difference(startOfYear).inDays + 1;

    // Seasonal multiplier (0.4 in winter, 1.0 in summer)
    final seasonal = _seasonalMultiplier(dayOfYear);

    // Backyard flock - base 5 eggs/day with seasonal and daily variation
    // Pattern: 5, 4, 5, 4, 5, 3, 4 repeating (avg ~4.3) scaled by season
    final dailyPattern = [5, 4, 5, 4, 5, 3, 4];
    int baseCount = dailyPattern[day % 7];
    int backyardCount = (baseCount * seasonal).round();

    // Add some random variation
    if (_random.nextDouble() < 0.1) {
      backyardCount = (backyardCount - 1).clamp(0, 5);
    }
    if (_random.nextDouble() < 0.05) {
      backyardCount = (backyardCount + 1).clamp(0, 5);
    }

    // Every 14 days, log as distributed (one egg per bird) for demo
    if (day % 14 == 0 && backyardCount == 5) {
      // Create distributed entries - same timestamp, different birds
      for (final birdId in backyardBirds) {
        logs.add({
          'id': _generateId(),
          'date': date,
          'flock_id': TestIds.flockBackyard,
          'bird_id': birdId,
          'count': 1,
          'size': 'large',
          'quality': 'normal',
          'notes': null,
          'created_at': timestampStr,
        });
      }
    } else if (backyardCount > 0) {
      // Regular flock-level log
      String? notes;
      String quality = 'normal';
      String size = 'large';

      if (day == 5) {
        notes = 'Double yolker from Ginger!';
        quality = 'doubleYolk';
        size = 'jumbo';
      } else if (day == 12) {
        notes = 'Beautiful olive egg from Olive';
      } else if (day == 21) {
        notes = 'Blue egg extra vibrant today';
      } else if (day == 100) {
        notes = 'First egg after molt!';
      } else if (day == 180) {
        notes = 'Peak summer production';
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
        'created_at': timestampStr,
      });
    }

    // Bantam flock - 1-2 eggs, simpler pattern with seasonal adjustment
    int bantamBase = day % 3 == 0 ? 2 : 1;
    int bantamCount = (bantamBase * seasonal).round();
    // Skip more days in winter
    if (day % 5 == 0 || (seasonal < 0.6 && _random.nextDouble() < 0.3)) {
      bantamCount = 0;
    }

    if (bantamCount > 0) {
      logs.add({
        'id': _generateId(),
        'date': date,
        'flock_id': TestIds.flockBantams,
        'bird_id': null,
        'count': bantamCount,
        'size': 'small',
        'quality': 'normal',
        'notes': null,
        'created_at': timestampStr,
      });
    }
  }

  return logs;
}

/// Generate bird status events for flock size tracking
List<Map<String, dynamic>> generateBirdStatusEvents() {
  final events = <Map<String, dynamic>>[];

  // Henrietta and Ginger added first (365 days ago)
  for (final birdId in [TestIds.birdHenrietta, TestIds.birdGinger]) {
    events.add({
      'id': _generateId(),
      'bird_id': birdId,
      'flock_id': TestIds.flockBackyard,
      'status': 'active',
      'event_date': _daysAgo(365),
      'notes': 'Initial flock member',
      'created_at': _daysAgoFull(365),
    });
  }

  // Pepper added 300 days ago
  events.add({
    'id': _generateId(),
    'bird_id': TestIds.birdPepper,
    'flock_id': TestIds.flockBackyard,
    'status': 'active',
    'event_date': _daysAgo(300),
    'notes': 'Added from neighbor',
    'created_at': _daysAgoFull(300),
  });

  // Olive added 250 days ago
  events.add({
    'id': _generateId(),
    'bird_id': TestIds.birdOlive,
    'flock_id': TestIds.flockBackyard,
    'status': 'active',
    'event_date': _daysAgo(250),
    'notes': 'Added from hatchery',
    'created_at': _daysAgoFull(250),
  });

  // Hazel added 200 days ago
  events.add({
    'id': _generateId(),
    'bird_id': TestIds.birdHazel,
    'flock_id': TestIds.flockBackyard,
    'status': 'active',
    'event_date': _daysAgo(200),
    'notes': 'Added from breeder',
    'created_at': _daysAgoFull(200),
  });

  // Bantam flock
  events.add({
    'id': _generateId(),
    'bird_id': TestIds.birdPebbles,
    'flock_id': TestIds.flockBantams,
    'status': 'active',
    'event_date': _daysAgo(180),
    'notes': 'Initial bantam flock',
    'created_at': _daysAgoFull(180),
  });

  events.add({
    'id': _generateId(),
    'bird_id': TestIds.birdCookie,
    'flock_id': TestIds.flockBantams,
    'status': 'active',
    'event_date': _daysAgo(170),
    'notes': 'Added from poultry show',
    'created_at': _daysAgoFull(170),
  });

  return events;
}


/// All test data consolidated
class TestData {
  // Use getters to generate fresh data each time (dates relative to now)
  static List<Map<String, dynamic>> get flocks => _generateFlocks();
  static List<Map<String, dynamic>> get birds => _generateBirds();
  static List<Map<String, dynamic>> get eggLogs => generateEggLogs();
  static List<Map<String, dynamic>> get expenses => _generateExpenses();
  static List<Map<String, dynamic>> get income => _generateIncome();
  static List<Map<String, dynamic>> get medicationLogs => _generateMedicationLogs();
  static List<Map<String, dynamic>> get healthNotes => _generateHealthNotes();
  static List<Map<String, dynamic>> get birdStatusEvents =>
      generateBirdStatusEvents();

  // Generator functions for fresh data
  static List<Map<String, dynamic>> _generateFlocks() => [
    {
      'id': TestIds.flockBackyard,
      'name': 'Backyard Layers',
      'description': 'Mixed breeds for a colorful egg basket',
      'icon': 'egg',
      'color': '4CAF50',
      'is_archived': 0,
      'created_at': _daysAgoFull(365),
    },
    {
      'id': TestIds.flockBantams,
      'name': 'Bantam Buddies',
      'description': 'Small ornamental flock',
      'icon': 'pets',
      'color': 'FF9800',
      'is_archived': 0,
      'created_at': _daysAgoFull(180),
    },
  ];

  static List<Map<String, dynamic>> _generateBirds() => [
    {
      'id': TestIds.birdHenrietta,
      'flock_id': TestIds.flockBackyard,
      'name': 'Henrietta',
      'breed': 'Barred Plymouth Rock',
      'breed_id': 'plymouth_rock_barred',
      'photo_primary': null,
      'hatch_date': _daysAgo(540),
      'acquired_date': _daysAgo(500),
      'source': 'Local feed store',
      'egg_color': 'Brown',
      'sex': 'female',
      'status': 'active',
      'status_date': null,
      'status_notes': null,
      'notes': 'Flock leader, first to the treat bowl!',
      'created_at': _daysAgoFull(365),
    },
    {
      'id': TestIds.birdGinger,
      'flock_id': TestIds.flockBackyard,
      'name': 'Ginger',
      'breed': 'Buff Orpington',
      'breed_id': 'orpington_buff',
      'photo_primary': null,
      'hatch_date': _daysAgo(520),
      'acquired_date': _daysAgo(500),
      'source': 'Local feed store',
      'egg_color': 'Brown',
      'sex': 'female',
      'status': 'active',
      'status_date': null,
      'status_notes': null,
      'notes': 'Sweetest hen, loves cuddles',
      'created_at': _daysAgoFull(365),
    },
    {
      'id': TestIds.birdPepper,
      'flock_id': TestIds.flockBackyard,
      'name': 'Pepper',
      'breed': 'Silver Laced Wyandotte',
      'breed_id': 'wyandotte',
      'photo_primary': null,
      'hatch_date': _daysAgo(480),
      'acquired_date': _daysAgo(450),
      'source': 'Neighbor',
      'egg_color': 'Brown',
      'sex': 'female',
      'status': 'active',
      'status_date': null,
      'status_notes': null,
      'notes': 'Beautiful lacing, consistent layer',
      'created_at': _daysAgoFull(300),
    },
    {
      'id': TestIds.birdOlive,
      'flock_id': TestIds.flockBackyard,
      'name': 'Olive',
      'breed': 'Olive Egger',
      'breed_id': 'olive_egger',
      'photo_primary': null,
      'hatch_date': _daysAgo(400),
      'acquired_date': _daysAgo(380),
      'source': 'Online hatchery',
      'egg_color': 'Olive',
      'sex': 'female',
      'status': 'active',
      'status_date': null,
      'status_notes': null,
      'notes': 'Beautiful olive green eggs!',
      'created_at': _daysAgoFull(250),
    },
    {
      'id': TestIds.birdHazel,
      'flock_id': TestIds.flockBackyard,
      'name': 'Hazel',
      'breed': 'Easter Egger',
      'breed_id': 'easter_egger',
      'photo_primary': null,
      'hatch_date': _daysAgo(380),
      'acquired_date': _daysAgo(360),
      'source': 'Local breeder',
      'egg_color': 'Blue',
      'sex': 'female',
      'status': 'active',
      'status_date': null,
      'status_notes': null,
      'notes': 'Pretty blue eggs, cute beard',
      'created_at': _daysAgoFull(240),
    },
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
      'sex': 'female',
      'status': 'active',
      'status_date': null,
      'status_notes': null,
      'notes': 'White silkie, great broody mom',
      'created_at': _daysAgoFull(180),
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
      'sex': 'female',
      'status': 'active',
      'status_date': null,
      'status_notes': null,
      'notes': 'Golden Sebright, tiny but pretty eggs',
      'created_at': _daysAgoFull(170),
    },
  ];

  static List<Map<String, dynamic>> _generateExpenses() => [
    {
      'id': _generateId(),
      'date': _daysAgo(2),
      'amount': 35.00,
      'category': 'feed',
      'description': '50lb layer pellets',
      'flock_id': null,
      'is_recurring': 0,
      'recurring_interval': null,
      'created_at': _daysAgoFull(2),
    },
    {
      'id': _generateId(),
      'date': _daysAgo(7),
      'amount': 10.00,
      'category': 'feed',
      'description': 'Mealworm treats',
      'flock_id': null,
      'is_recurring': 0,
      'recurring_interval': null,
      'created_at': _daysAgoFull(7),
    },
    {
      'id': _generateId(),
      'date': _daysAgo(14),
      'amount': 15.00,
      'category': 'bedding',
      'description': 'Pine shavings',
      'flock_id': TestIds.flockBackyard,
      'is_recurring': 0,
      'recurring_interval': null,
      'created_at': _daysAgoFull(14),
    },
    {
      'id': _generateId(),
      'date': _daysAgo(21),
      'amount': 8.00,
      'category': 'supplies',
      'description': 'Oyster shell',
      'flock_id': null,
      'is_recurring': 0,
      'recurring_interval': null,
      'created_at': _daysAgoFull(21),
    },
    {
      'id': _generateId(),
      'date': _daysAgo(30),
      'amount': 35.00,
      'category': 'feed',
      'description': '50lb layer pellets',
      'flock_id': null,
      'is_recurring': 1,
      'recurring_interval': 'monthly',
      'created_at': _daysAgoFull(30),
    },
    {
      'id': _generateId(),
      'date': _daysAgo(45),
      'amount': 25.00,
      'category': 'supplies',
      'description': 'Heated waterer',
      'flock_id': null,
      'is_recurring': 0,
      'recurring_interval': null,
      'created_at': _daysAgoFull(45),
    },
  ];

  static List<Map<String, dynamic>> _generateIncome() => [
    {
      'id': _generateId(),
      'date': _daysAgo(3),
      'amount': 6.00,
      'description': 'Dozen to neighbor',
      'egg_count': 12,
      'created_at': _daysAgoFull(3),
    },
    {
      'id': _generateId(),
      'date': _daysAgo(10),
      'amount': 12.00,
      'description': '2 dozen - mixed colors',
      'egg_count': 24,
      'created_at': _daysAgoFull(10),
    },
    {
      'id': _generateId(),
      'date': _daysAgo(17),
      'amount': 18.00,
      'description': 'Farmers market',
      'egg_count': 36,
      'created_at': _daysAgoFull(17),
    },
    {
      'id': _generateId(),
      'date': _daysAgo(24),
      'amount': 6.00,
      'description': 'Coworker sale',
      'egg_count': 12,
      'created_at': _daysAgoFull(24),
    },
    {
      'id': _generateId(),
      'date': _daysAgo(31),
      'amount': 12.00,
      'description': 'Neighbor - weekly order',
      'egg_count': 24,
      'created_at': _daysAgoFull(31),
    },
  ];

  static List<Map<String, dynamic>> _generateMedicationLogs() => [
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
      'withdrawal_days': 0,
      'notes': 'Quarterly deworming',
      'created_at': _daysAgoFull(60),
    },
  ];

  static List<Map<String, dynamic>> _generateHealthNotes() => [
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
      'bird_id': TestIds.birdHenrietta,
      'date': _daysAgo(30),
      'type': 'observation',
      'description': 'Annual health check - good weight, clear eyes, healthy comb. Top condition.',
      'created_at': _daysAgoFull(30),
    },
    {
      'id': _generateId(),
      'bird_id': TestIds.birdOlive,
      'date': _daysAgo(7),
      'type': 'observation',
      'description': 'Beautiful deep olive eggs this week. Getting darker as she matures.',
      'created_at': _daysAgoFull(7),
    },
  ];
  
  /// Print summary statistics
  static void printSummary() {
    final eggs = eggLogs;
    final totalEggs = eggs.fold<int>(0, (sum, log) => sum + (log['count'] as int));

    // ignore: avoid_print
    print('=== TEST DATA SUMMARY ===');
    // ignore: avoid_print
    print('Flocks: ${flocks.length}');
    // ignore: avoid_print
    print('Birds: ${birds.length} (${birds.where((b) => b['status'] == 'active').length} active)');
    // ignore: avoid_print
    print('Egg logs: ${eggs.length} entries');
    // ignore: avoid_print
    print('Total eggs: $totalEggs over 365 days');
    // ignore: avoid_print
    print('Daily average: ${(totalEggs / 365).toStringAsFixed(1)} eggs');
    // ignore: avoid_print
    print('Bird status events: ${birdStatusEvents.length} entries');
    // ignore: avoid_print
    print('Expenses: ${expenses.length} entries');
    // ignore: avoid_print
    print('Income: ${income.length} entries');
    // ignore: avoid_print
    print('Medication logs: ${medicationLogs.length} entries');
    // ignore: avoid_print
    print('Health notes: ${healthNotes.length} entries');
    // ignore: avoid_print
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
    await db.delete('bird_status_events');
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

    // Insert bird status events
    for (final event in birdStatusEvents) {
      await db.insert('bird_status_events', event);
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
