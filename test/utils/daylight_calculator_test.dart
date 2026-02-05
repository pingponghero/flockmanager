import 'package:flutter_test/flutter_test.dart';
import 'package:flock_manager/utils/daylight_calculator.dart';

void main() {
  group('DaylightCalculator', () {
    group('getMonthlyDaylightCurve', () {
      test('returns 12 monthly values', () {
        final curve = DaylightCalculator.getMonthlyDaylightCurve(39);
        expect(curve.length, 12);
      });

      test('equator has nearly constant daylight year-round', () {
        final curve = DaylightCalculator.getMonthlyDaylightCurve(0);

        for (final hours in curve) {
          expect(hours, closeTo(12.0, 0.2));
        }
      });

      test('northern hemisphere has longer days in summer (June)', () {
        final curve = DaylightCalculator.getMonthlyDaylightCurve(39);

        // June (index 5) should have longest days
        final juneDaylight = curve[5];
        final decDaylight = curve[11];

        expect(juneDaylight, greaterThan(decDaylight));
        expect(juneDaylight, greaterThan(14.0));
        expect(decDaylight, lessThan(10.0));
      });

      test('southern hemisphere has seasons reversed', () {
        final northCurve = DaylightCalculator.getMonthlyDaylightCurve(39);
        final southCurve = DaylightCalculator.getMonthlyDaylightCurve(-39);

        // June in south should equal December in north (within rounding)
        expect(southCurve[5], closeTo(northCurve[11], 0.5));
        // December in south should equal June in north
        expect(southCurve[11], closeTo(northCurve[5], 0.5));
      });

      test('higher latitudes have more extreme variation', () {
        final lat30 = DaylightCalculator.getMonthlyDaylightCurve(30);
        final lat50 = DaylightCalculator.getMonthlyDaylightCurve(50);

        final range30 = lat30.reduce((a, b) => a > b ? a : b) -
            lat30.reduce((a, b) => a < b ? a : b);
        final range50 = lat50.reduce((a, b) => a > b ? a : b) -
            lat50.reduce((a, b) => a < b ? a : b);

        expect(range50, greaterThan(range30));
      });

      test('interpolates between known latitudes', () {
        final lat30 = DaylightCalculator.getMonthlyDaylightCurve(30);
        final lat35 = DaylightCalculator.getMonthlyDaylightCurve(35);
        final lat32 = DaylightCalculator.getMonthlyDaylightCurve(32);

        // Lat 32 should be between lat 30 and lat 35
        for (var i = 0; i < 12; i++) {
          final minVal = lat30[i] < lat35[i] ? lat30[i] : lat35[i];
          final maxVal = lat30[i] > lat35[i] ? lat30[i] : lat35[i];
          expect(lat32[i], greaterThanOrEqualTo(minVal - 0.1));
          expect(lat32[i], lessThanOrEqualTo(maxVal + 0.1));
        }
      });

      test('clamps extreme latitudes', () {
        // Should not throw for extreme values
        final lat70 = DaylightCalculator.getMonthlyDaylightCurve(70);
        final latNeg70 = DaylightCalculator.getMonthlyDaylightCurve(-70);

        expect(lat70.length, 12);
        expect(latNeg70.length, 12);
      });
    });

    group('getMonthAverageDaylight', () {
      test('returns correct value for specific month', () {
        final juneDaylight = DaylightCalculator.getMonthAverageDaylight(6, 39);
        expect(juneDaylight, closeTo(14.7, 0.1));
      });

      test('handles month boundaries', () {
        // Month 1 (January)
        final jan = DaylightCalculator.getMonthAverageDaylight(1, 39);
        expect(jan, closeTo(9.6, 0.1));

        // Month 12 (December)
        final dec = DaylightCalculator.getMonthAverageDaylight(12, 39);
        expect(dec, closeTo(9.3, 0.1));
      });

      test('clamps out-of-range months', () {
        // Month 0 should clamp to January
        final month0 = DaylightCalculator.getMonthAverageDaylight(0, 39);
        final jan = DaylightCalculator.getMonthAverageDaylight(1, 39);
        expect(month0, jan);

        // Month 13 should clamp to December
        final month13 = DaylightCalculator.getMonthAverageDaylight(13, 39);
        final dec = DaylightCalculator.getMonthAverageDaylight(12, 39);
        expect(month13, dec);
      });
    });

    group('getDaylightHoursForDate', () {
      test('returns monthly average for given date', () {
        final summerSolstice = DateTime(2024, 6, 21);
        final hours = DaylightCalculator.getDaylightHoursForDate(summerSolstice, 39);

        expect(hours, closeTo(14.7, 0.1)); // June average at 39N
      });

      test('returns correct value for winter date', () {
        final winterDate = DateTime(2024, 12, 21);
        final hours = DaylightCalculator.getDaylightHoursForDate(winterDate, 39);

        expect(hours, closeTo(9.3, 0.1)); // December average at 39N
      });
    });

    group('getDayOfYear', () {
      test('returns 1 for January 1st', () {
        final dayOfYear = DaylightCalculator.getDayOfYear(DateTime(2024, 1, 1));
        expect(dayOfYear, 1);
      });

      test('returns 365 for December 31st in non-leap year', () {
        final dayOfYear = DaylightCalculator.getDayOfYear(DateTime(2023, 12, 31));
        expect(dayOfYear, 365);
      });

      test('returns 366 for December 31st in leap year', () {
        final dayOfYear = DaylightCalculator.getDayOfYear(DateTime(2024, 12, 31));
        expect(dayOfYear, 366);
      });

      test('returns correct value for mid-year date', () {
        // March 1st in non-leap year: 31 (Jan) + 28 (Feb) + 1 = 60
        final dayOfYear = DaylightCalculator.getDayOfYear(DateTime(2023, 3, 1));
        expect(dayOfYear, 60);
      });
    });

    group('getMaxDaylight', () {
      test('returns June value for Northern Hemisphere', () {
        final maxDaylight = DaylightCalculator.getMaxDaylight(39);
        final juneDaylight = DaylightCalculator.getMonthAverageDaylight(6, 39);

        expect(maxDaylight, juneDaylight);
      });

      test('returns December value for Southern Hemisphere', () {
        final maxDaylight = DaylightCalculator.getMaxDaylight(-39);
        final decDaylight = DaylightCalculator.getMonthAverageDaylight(12, -39);

        expect(maxDaylight, decDaylight);
      });
    });

    group('getMinDaylight', () {
      test('returns December value for Northern Hemisphere', () {
        final minDaylight = DaylightCalculator.getMinDaylight(39);
        final decDaylight = DaylightCalculator.getMonthAverageDaylight(12, 39);

        expect(minDaylight, decDaylight);
      });

      test('returns June value for Southern Hemisphere', () {
        final minDaylight = DaylightCalculator.getMinDaylight(-39);
        final juneDaylight = DaylightCalculator.getMonthAverageDaylight(6, -39);

        expect(minDaylight, juneDaylight);
      });
    });

    group('calculateDaylightHours', () {
      test('returns ~12 hours at equator year-round', () {
        for (var day = 1; day <= 365; day += 30) {
          final hours = DaylightCalculator.calculateDaylightHours(day, 0);
          expect(hours, closeTo(12.0, 0.5));
        }
      });

      test('returns longest day around summer solstice (day 172)', () {
        final summerSolstice = DaylightCalculator.calculateDaylightHours(172, 45);
        final winterSolstice = DaylightCalculator.calculateDaylightHours(355, 45);

        expect(summerSolstice, greaterThan(winterSolstice));
        expect(summerSolstice, greaterThan(15.0));
      });

      test('handles polar day (24 hours)', () {
        // High latitude during summer should approach 24 hours
        final arcticSummer = DaylightCalculator.calculateDaylightHours(172, 70);
        expect(arcticSummer, closeTo(24.0, 1.0));
      });

      test('handles polar night (0 hours)', () {
        // High latitude during winter should approach 0 hours
        final arcticWinter = DaylightCalculator.calculateDaylightHours(355, 70);
        expect(arcticWinter, lessThan(5.0));
      });

      test('clamps day of year to valid range', () {
        // Should not throw for out-of-range values
        final day0 = DaylightCalculator.calculateDaylightHours(0, 39);
        final day400 = DaylightCalculator.calculateDaylightHours(400, 39);

        expect(day0, isNotNull);
        expect(day400, isNotNull);
      });

      test('clamps latitude to valid range', () {
        // Should not throw for extreme latitudes
        final lat100 = DaylightCalculator.calculateDaylightHours(180, 100);
        final latNeg100 = DaylightCalculator.calculateDaylightHours(180, -100);

        expect(lat100, isNotNull);
        expect(latNeg100, isNotNull);
      });
    });

    group('seasonal patterns', () {
      test('summer solstice has more daylight than winter solstice', () {
        for (final lat in [25, 35, 45, 55]) {
          final summer = DaylightCalculator.calculateDaylightHours(172, lat);
          final winter = DaylightCalculator.calculateDaylightHours(355, lat);

          expect(summer, greaterThan(winter),
              reason: 'Summer should be longer than winter at latitude $lat');
        }
      });

      test('equinoxes have approximately equal day and night', () {
        // Spring equinox ~day 80, Fall equinox ~day 266
        for (final lat in [0, 25, 39, 45]) {
          final spring = DaylightCalculator.calculateDaylightHours(80, lat);
          final fall = DaylightCalculator.calculateDaylightHours(266, lat);

          expect(spring, closeTo(12.0, 1.0),
              reason: 'Spring equinox should be ~12h at latitude $lat');
          expect(fall, closeTo(12.0, 1.0),
              reason: 'Fall equinox should be ~12h at latitude $lat');
        }
      });
    });
  });
}
