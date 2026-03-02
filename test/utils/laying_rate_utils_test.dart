import 'package:flutter_test/flutter_test.dart';
import 'package:flock_manager/models/bird_status_event.dart';
import 'package:flock_manager/utils/laying_rate_utils.dart';

BirdStatusEvent _event(String status, DateTime date) {
  return BirdStatusEvent(
    id: 'e-${date.millisecondsSinceEpoch}',
    birdId: 'bird-1',
    flockId: 'flock-1',
    status: status,
    eventDate: date,
    createdAt: date,
  );
}

void main() {
  group('calculateActiveDays', () {
    test('bird active for entire range', () {
      final events = [
        _event('active', DateTime(2024, 1, 1)),
      ];
      final result = calculateActiveDays(
        events,
        DateTime(2024, 1, 1),
        DateTime(2024, 1, 31),
      );
      expect(result, 30);
    });

    test('bird active for partial range (departed mid-range)', () {
      final events = [
        _event('active', DateTime(2024, 1, 1)),
        _event('deceased', DateTime(2024, 1, 16)),
      ];
      final result = calculateActiveDays(
        events,
        DateTime(2024, 1, 1),
        DateTime(2024, 1, 31),
      );
      expect(result, 15);
    });

    test('bird added mid-range', () {
      final events = [
        _event('active', DateTime(2024, 1, 11)),
      ];
      final result = calculateActiveDays(
        events,
        DateTime(2024, 1, 1),
        DateTime(2024, 1, 31),
      );
      expect(result, 20);
    });

    test('multiple active/inactive cycles', () {
      final events = [
        _event('active', DateTime(2024, 1, 1)),
        _event('sold', DateTime(2024, 1, 11)),
        _event('active', DateTime(2024, 1, 21)),
      ];
      final result = calculateActiveDays(
        events,
        DateTime(2024, 1, 1),
        DateTime(2024, 1, 31),
      );
      // 10 days (Jan 1-11) + 10 days (Jan 21-31) = 20
      expect(result, 20);
    });

    test('no events returns 1 (minimum)', () {
      final result = calculateActiveDays(
        [],
        DateTime(2024, 1, 1),
        DateTime(2024, 1, 31),
      );
      expect(result, 1);
    });

    test('range before bird was added returns 1 (minimum)', () {
      final events = [
        _event('active', DateTime(2024, 2, 1)),
      ];
      final result = calculateActiveDays(
        events,
        DateTime(2024, 1, 1),
        DateTime(2024, 1, 31),
      );
      expect(result, 1);
    });

    test('range after bird departed returns 1 (minimum)', () {
      final events = [
        _event('active', DateTime(2024, 1, 1)),
        _event('deceased', DateTime(2024, 1, 15)),
      ];
      final result = calculateActiveDays(
        events,
        DateTime(2024, 2, 1),
        DateTime(2024, 2, 28),
      );
      expect(result, 1);
    });

    test('bird active before and through range', () {
      final events = [
        _event('active', DateTime(2023, 12, 1)),
      ];
      final result = calculateActiveDays(
        events,
        DateTime(2024, 1, 1),
        DateTime(2024, 1, 31),
      );
      expect(result, 30);
    });

    test('events out of order are sorted correctly', () {
      final events = [
        _event('deceased', DateTime(2024, 1, 16)),
        _event('active', DateTime(2024, 1, 1)),
      ];
      final result = calculateActiveDays(
        events,
        DateTime(2024, 1, 1),
        DateTime(2024, 1, 31),
      );
      expect(result, 15);
    });

    test('bird sold then re-added with gap spanning range boundary', () {
      final events = [
        _event('active', DateTime(2024, 1, 1)),
        _event('sold', DateTime(2024, 1, 20)),
        _event('active', DateTime(2024, 2, 10)),
      ];
      // Range is Feb 1-28, bird was sold Jan 20, re-added Feb 10
      // Active from Feb 10 to Feb 28 = 18 days
      final result = calculateActiveDays(
        events,
        DateTime(2024, 2, 1),
        DateTime(2024, 2, 28),
      );
      expect(result, 18);
    });
  });
}
