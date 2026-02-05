import 'package:flutter_test/flutter_test.dart';
import 'package:flock_manager/providers/golden_egg_provider.dart';

void main() {
  group('ChartTimeScale', () {
    test('has daily and monthly values', () {
      expect(ChartTimeScale.values, contains(ChartTimeScale.daily));
      expect(ChartTimeScale.values, contains(ChartTimeScale.monthly));
    });
  });

  group('DailyEggData', () {
    test('creates with required fields', () {
      final data = DailyEggData(
        date: DateTime(2024, 6, 15),
        count: 5,
        dayIndex: 0,
      );

      expect(data.date, DateTime(2024, 6, 15));
      expect(data.count, 5);
      expect(data.dayIndex, 0);
    });

    test('allows zero count', () {
      final data = DailyEggData(
        date: DateTime(2024, 6, 15),
        count: 0,
        dayIndex: 3,
      );

      expect(data.count, 0);
    });
  });

  group('WeeklyEggData', () {
    test('creates with required fields', () {
      final data = WeeklyEggData(
        weekStart: DateTime(2024, 6, 10),
        totalCount: 35,
        dailyAverage: 5.0,
        daysWithData: 7,
      );

      expect(data.weekStart, DateTime(2024, 6, 10));
      expect(data.totalCount, 35);
      expect(data.dailyAverage, 5.0);
      expect(data.daysWithData, 7);
    });

    test('handles partial week', () {
      final data = WeeklyEggData(
        weekStart: DateTime(2024, 6, 10),
        totalCount: 15,
        dailyAverage: 3.0,
        daysWithData: 5,
      );

      expect(data.daysWithData, 5);
      expect(data.dailyAverage, 3.0);
    });
  });

  group('MonthlyEggData', () {
    test('creates with required fields', () {
      final data = MonthlyEggData(
        month: 6,
        year: 2024,
        totalCount: 150,
        daysRecorded: 30,
        dailyAverage: 5.0,
        isActual: true,
      );

      expect(data.month, 6);
      expect(data.year, 2024);
      expect(data.totalCount, 150);
      expect(data.daysRecorded, 30);
      expect(data.dailyAverage, 5.0);
      expect(data.isActual, true);
      expect(data.avgFlockSize, 0); // default value
    });

    test('includes avgFlockSize when provided', () {
      final data = MonthlyEggData(
        month: 6,
        year: 2024,
        totalCount: 150,
        daysRecorded: 30,
        dailyAverage: 5.0,
        isActual: true,
        avgFlockSize: 3.5,
      );

      expect(data.avgFlockSize, 3.5);
    });

    test('isComplete returns true for 15+ days', () {
      final complete = MonthlyEggData(
        month: 6,
        year: 2024,
        totalCount: 75,
        daysRecorded: 15,
        dailyAverage: 5.0,
        isActual: true,
      );

      expect(complete.isComplete, true);
    });

    test('isComplete returns false for less than 15 days', () {
      final incomplete = MonthlyEggData(
        month: 6,
        year: 2024,
        totalCount: 50,
        daysRecorded: 14,
        dailyAverage: 3.57,
        isActual: true,
      );

      expect(incomplete.isComplete, false);
    });

    test('isActual distinguishes real data from forecast', () {
      final actual = MonthlyEggData(
        month: 6,
        year: 2024,
        totalCount: 150,
        daysRecorded: 30,
        dailyAverage: 5.0,
        isActual: true,
      );

      final forecast = MonthlyEggData(
        month: 7,
        year: 2024,
        totalCount: 155,
        daysRecorded: 0,
        dailyAverage: 5.0,
        isActual: false,
      );

      expect(actual.isActual, true);
      expect(forecast.isActual, false);
    });
  });

  group('GoldenEggChartData', () {
    test('creates with required fields', () {
      final data = GoldenEggChartData(
        timeScale: ChartTimeScale.monthly,
        totalEggs: 500,
        dailyAverage: 4.5,
        daysOfData: 111,
        maxDailyCount: 8,
      );

      expect(data.timeScale, ChartTimeScale.monthly);
      expect(data.totalEggs, 500);
      expect(data.dailyAverage, 4.5);
      expect(data.daysOfData, 111);
      expect(data.maxDailyCount, 8);
      expect(data.dailyCounts, isEmpty);
      expect(data.weeklyCounts, isEmpty);
      expect(data.monthlyCounts, isEmpty);
      expect(data.prevYearMonthlyCounts, isEmpty);
    });

    test('includes optional fields when provided', () {
      final daily = DailyEggData(
        date: DateTime(2024, 6, 15),
        count: 5,
        dayIndex: 0,
      );
      final monthly = MonthlyEggData(
        month: 6,
        year: 2024,
        totalCount: 150,
        daysRecorded: 30,
        dailyAverage: 5.0,
        isActual: true,
      );

      final data = GoldenEggChartData(
        timeScale: ChartTimeScale.daily,
        dailyCounts: [daily],
        monthlyCounts: [monthly],
        totalEggs: 150,
        dailyAverage: 5.0,
        daysOfData: 30,
        maxDailyCount: 7,
        allTimeDailyAverage: 4.8,
        activeFlockSize: 4,
      );

      expect(data.dailyCounts.length, 1);
      expect(data.monthlyCounts.length, 1);
      expect(data.allTimeDailyAverage, 4.8);
      expect(data.activeFlockSize, 4);
    });

    test('empty constant has default values', () {
      expect(GoldenEggChartData.empty.timeScale, ChartTimeScale.daily);
      expect(GoldenEggChartData.empty.totalEggs, 0);
      expect(GoldenEggChartData.empty.dailyAverage, 0);
      expect(GoldenEggChartData.empty.daysOfData, 0);
      expect(GoldenEggChartData.empty.maxDailyCount, 0);
      expect(GoldenEggChartData.empty.dailyCounts, isEmpty);
      expect(GoldenEggChartData.empty.weeklyCounts, isEmpty);
      expect(GoldenEggChartData.empty.monthlyCounts, isEmpty);
      expect(GoldenEggChartData.empty.prevYearMonthlyCounts, isEmpty);
      expect(GoldenEggChartData.empty.allTimeDailyAverage, 0);
      expect(GoldenEggChartData.empty.activeFlockSize, 0);
      expect(GoldenEggChartData.empty.prevPeriodTotal, 0);
    });

    test('prevPeriodTotal for week/month comparison', () {
      final data = GoldenEggChartData(
        timeScale: ChartTimeScale.daily,
        totalEggs: 35,
        dailyAverage: 5.0,
        daysOfData: 7,
        maxDailyCount: 8,
        prevPeriodTotal: 28,
      );

      expect(data.prevPeriodTotal, 28);
    });

    test('prevYearMonthlyCounts for year-over-year comparison', () {
      final thisYear = MonthlyEggData(
        month: 6,
        year: 2024,
        totalCount: 150,
        daysRecorded: 30,
        dailyAverage: 5.0,
        isActual: true,
      );

      final lastYear = MonthlyEggData(
        month: 6,
        year: 2023,
        totalCount: 140,
        daysRecorded: 30,
        dailyAverage: 4.67,
        isActual: true,
      );

      final data = GoldenEggChartData(
        timeScale: ChartTimeScale.monthly,
        monthlyCounts: [thisYear],
        prevYearMonthlyCounts: [lastYear],
        totalEggs: 150,
        dailyAverage: 5.0,
        daysOfData: 30,
        maxDailyCount: 7,
      );

      expect(data.monthlyCounts.first.year, 2024);
      expect(data.prevYearMonthlyCounts.first.year, 2023);
    });
  });

  group('data validation', () {
    test('MonthlyEggData month is 1-12', () {
      for (var month = 1; month <= 12; month++) {
        final data = MonthlyEggData(
          month: month,
          year: 2024,
          totalCount: 100,
          daysRecorded: 28,
          dailyAverage: 3.57,
          isActual: true,
        );
        expect(data.month, month);
      }
    });

    test('DailyEggData can have different day indices', () {
      final days = List.generate(7, (i) => DailyEggData(
        date: DateTime(2024, 6, 10 + i),
        count: 5 + i,
        dayIndex: i,
      ));

      expect(days.length, 7);
      expect(days[0].dayIndex, 0);
      expect(days[6].dayIndex, 6);
      expect(days[0].count, 5);
      expect(days[6].count, 11);
    });
  });
}
