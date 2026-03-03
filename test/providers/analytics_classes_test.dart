import 'package:flutter_test/flutter_test.dart';
import 'package:flock_manager/models/bird.dart';
import 'package:flock_manager/models/enums.dart';
import 'package:flock_manager/providers/analytics_provider.dart';

void main() {
  group('AnalyticsPeriod', () {
    test('displayName returns correct values', () {
      expect(AnalyticsPeriod.week.displayName, 'Last 7 Days');
      expect(AnalyticsPeriod.month.displayName, 'This Month');
      expect(AnalyticsPeriod.year.displayName, 'This Year');
      expect(AnalyticsPeriod.allTime.displayName, 'All Time');
    });

    test('dateRange for week is last 7 days', () {
      final range = AnalyticsPeriod.week.dateRange;
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final expectedStart = today.subtract(const Duration(days: 6));
      // Last 7 days: start is 6 days ago, end is today
      expect(range.start, expectedStart);
      expect(range.end, today);
      expect(range.dayCount, 7);
    });

    test('dateRange for month starts from first day', () {
      final range = AnalyticsPeriod.month.dateRange;
      expect(range.start.day, 1);
      expect(range.start.month, DateTime.now().month);
    });

    test('dateRange for year starts from January 1', () {
      final range = AnalyticsPeriod.year.dateRange;
      expect(range.start.day, 1);
      expect(range.start.month, 1);
      expect(range.start.year, DateTime.now().year);
    });

    test('dateRange for allTime starts from 2020', () {
      final range = AnalyticsPeriod.allTime.dateRange;
      expect(range.start.year, 2020);
      expect(range.start.month, 1);
      expect(range.start.day, 1);
    });
  });

  group('DateRange', () {
    test('dayCount calculates correctly', () {
      final range = DateRange(
        DateTime(2024, 1, 1),
        DateTime(2024, 1, 7),
      );
      expect(range.dayCount, 7);
    });

    test('dayCount for single day is 1', () {
      final range = DateRange(
        DateTime(2024, 1, 1),
        DateTime(2024, 1, 1),
      );
      expect(range.dayCount, 1);
    });

    test('equality works correctly', () {
      final range1 = DateRange(
        DateTime(2024, 1, 1),
        DateTime(2024, 1, 7),
      );
      final range2 = DateRange(
        DateTime(2024, 1, 1),
        DateTime(2024, 1, 7),
      );
      final range3 = DateRange(
        DateTime(2024, 1, 1),
        DateTime(2024, 1, 8),
      );

      expect(range1, equals(range2));
      expect(range1, isNot(equals(range3)));
    });

    test('hashCode is consistent with equality', () {
      final range1 = DateRange(
        DateTime(2024, 1, 1),
        DateTime(2024, 1, 7),
      );
      final range2 = DateRange(
        DateTime(2024, 1, 1),
        DateTime(2024, 1, 7),
      );

      expect(range1.hashCode, equals(range2.hashCode));
    });
  });

  group('BirdEggStats', () {
    late Bird testBird;

    setUp(() {
      testBird = Bird(
        id: 'bird-1',
        flockId: 'flock-1',
        name: 'Henrietta',
        status: BirdStatus.active,
        createdAt: DateTime.now(),
      );
    });

    test('isFreeloader returns true when eggCount is 0', () {
      final stats = BirdEggStats(
        bird: testBird,
        eggCount: 0,
        percentage: 0,
        activeDays: 7,
      );

      expect(stats.isFreeloader, isTrue);
    });

    test('isFreeloader returns false when eggCount > 0', () {
      final stats = BirdEggStats(
        bird: testBird,
        eggCount: 5,
        percentage: 25,
        activeDays: 10,
      );

      expect(stats.isFreeloader, isFalse);
    });

    test('isTopLayer returns true when layingRate >= 5', () {
      // 5 eggs / 7 days = 5.0 eggs/week
      final stats = BirdEggStats(
        bird: testBird,
        eggCount: 5,
        percentage: 50,
        activeDays: 7,
      );

      expect(stats.isTopLayer, isTrue);
    });

    test('isTopLayer returns true when layingRate > 5', () {
      // 14 eggs / 14 days = 7.0 eggs/week
      final stats = BirdEggStats(
        bird: testBird,
        eggCount: 14,
        percentage: 70,
        activeDays: 14,
      );

      expect(stats.isTopLayer, isTrue);
    });

    test('isTopLayer returns false when layingRate < 5', () {
      // 6 eggs / 14 days = 3.0 eggs/week
      final stats = BirdEggStats(
        bird: testBird,
        eggCount: 6,
        percentage: 30,
        activeDays: 14,
      );

      expect(stats.isTopLayer, isFalse);
    });
  });

  group('DailyEggCount', () {
    test('stores date and count correctly', () {
      final date = DateTime(2024, 6, 15);
      final dailyCount = DailyEggCount(date: date, count: 5);

      expect(dailyCount.date, date);
      expect(dailyCount.count, 5);
    });
  });

  group('AnalyticsSummary', () {
    late Bird topBird;
    late Bird averageBird;
    late Bird freeloaderBird;
    late List<BirdEggStats> birdStats;

    setUp(() {
      topBird = Bird(
        id: 'top-bird',
        flockId: 'flock-1',
        name: 'Top Layer',
        status: BirdStatus.active,
        createdAt: DateTime.now(),
      );

      averageBird = Bird(
        id: 'avg-bird',
        flockId: 'flock-1',
        name: 'Average Layer',
        status: BirdStatus.active,
        createdAt: DateTime.now(),
      );

      freeloaderBird = Bird(
        id: 'freeloader-bird',
        flockId: 'flock-1',
        name: 'Freeloader',
        status: BirdStatus.active,
        createdAt: DateTime.now(),
      );

      birdStats = [
        BirdEggStats(
          bird: topBird,
          eggCount: 14,
          percentage: 70,
          activeDays: 14,
        ),
        BirdEggStats(
          bird: averageBird,
          eggCount: 6,
          percentage: 30,
          activeDays: 14,
        ),
        BirdEggStats(
          bird: freeloaderBird,
          eggCount: 0,
          percentage: 0,
          activeDays: 14,
        ),
      ];
    });

    test('topLayers returns birds with layingRate >= 5', () {
      final summary = AnalyticsSummary(
        totalEggs: 20,
        dailyAverage: 2.86,
        bestDayCount: 5,
        bestDayDate: DateTime(2024, 6, 15),
        worstDayCount: 1,
        worstDayDate: DateTime(2024, 6, 10),
        daysWithData: 7,
        daysWithoutData: 0,
        periodChange: 10.0,
        hasPreviousPeriodData: true,
        birdStats: birdStats,
        dailyCounts: [],
        chartData: [],
        chartGranularity: ChartGranularity.daily,
      );

      expect(summary.topLayers.length, 1);
      expect(summary.topLayers.first.bird.name, 'Top Layer');
    });

    test('freeloaders returns birds with 0 eggs', () {
      final summary = AnalyticsSummary(
        totalEggs: 20,
        dailyAverage: 2.86,
        bestDayCount: 5,
        worstDayCount: 1,
        daysWithData: 7,
        daysWithoutData: 0,
        periodChange: 10.0,
        hasPreviousPeriodData: true,
        birdStats: birdStats,
        dailyCounts: [],
        chartData: [],
        chartGranularity: ChartGranularity.daily,
      );

      expect(summary.freeloaders.length, 1);
      expect(summary.freeloaders.first.bird.name, 'Freeloader');
    });

    test('activeBirdCount returns total number of birds', () {
      final summary = AnalyticsSummary(
        totalEggs: 20,
        dailyAverage: 2.86,
        bestDayCount: 5,
        worstDayCount: 1,
        daysWithData: 7,
        daysWithoutData: 0,
        periodChange: 10.0,
        hasPreviousPeriodData: true,
        birdStats: birdStats,
        dailyCounts: [],
        chartData: [],
        chartGranularity: ChartGranularity.daily,
      );

      expect(summary.activeBirdCount, 3);
    });

    test('topLayers are sorted by egg count descending', () {
      final bird1 = Bird(
        id: 'bird-1',
        flockId: 'flock-1',
        name: 'Bird 1',
        status: BirdStatus.active,
        createdAt: DateTime.now(),
      );
      final bird2 = Bird(
        id: 'bird-2',
        flockId: 'flock-1',
        name: 'Bird 2',
        status: BirdStatus.active,
        createdAt: DateTime.now(),
      );

      final multipleTopLayers = [
        BirdEggStats(bird: bird1, eggCount: 10, percentage: 40, activeDays: 14),
        BirdEggStats(bird: bird2, eggCount: 15, percentage: 60, activeDays: 14),
      ];

      final summary = AnalyticsSummary(
        totalEggs: 25,
        dailyAverage: 3.57,
        bestDayCount: 5,
        worstDayCount: 2,
        daysWithData: 7,
        daysWithoutData: 0,
        periodChange: 0,
        hasPreviousPeriodData: true,
        birdStats: multipleTopLayers,
        dailyCounts: [],
        chartData: [],
        chartGranularity: ChartGranularity.daily,
      );

      final topLayers = summary.topLayers;
      expect(topLayers.length, 2);
      expect(topLayers[0].eggCount, 15); // Higher count first
      expect(topLayers[1].eggCount, 10);
    });
  });
}
