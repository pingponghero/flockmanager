import 'dart:math' as math;

/// Utility class for calculating daylight hours based on latitude and day of year.
/// Uses precalculated fixtures for common latitudes to avoid runtime computation.
/// Supports Northern Hemisphere, Southern Hemisphere, and Equator.
class DaylightCalculator {
  DaylightCalculator._();

  // ==================== Precalculated Monthly Averages ====================
  // Monthly daylight hours (index 0 = January, 11 = December) for Northern latitudes.
  // Precalculated using the solar declination formula for mid-month dates.
  // Southern Hemisphere uses the same values but shifted by 6 months.

  /// Equator (0°) - constant ~12 hours year-round
  static const _lat0 = [12.1, 12.1, 12.0, 12.0, 12.0, 12.0, 12.0, 12.0, 12.0, 12.1, 12.1, 12.1];

  /// 25°N (Miami, FL area) - nearly round egg shape
  static const _lat25 = [10.8, 11.3, 11.9, 12.6, 13.2, 13.5, 13.4, 12.9, 12.2, 11.5, 10.9, 10.6];

  /// 30°N (Houston, TX area)
  static const _lat30 = [10.4, 11.0, 11.8, 12.7, 13.5, 13.9, 13.7, 13.1, 12.2, 11.3, 10.5, 10.1];

  /// 35°N (Raleigh, NC area)
  static const _lat35 = [10.0, 10.7, 11.7, 12.8, 13.8, 14.3, 14.1, 13.3, 12.3, 11.2, 10.2, 9.7];

  /// 39°N (Kansas City, MO area) - DEFAULT - classic egg shape
  static const _lat39 = [9.6, 10.5, 11.6, 12.9, 14.0, 14.7, 14.4, 13.5, 12.3, 11.1, 9.9, 9.3];

  /// 42°N (Boston, MA area)
  static const _lat42 = [9.3, 10.3, 11.6, 13.0, 14.3, 15.0, 14.7, 13.7, 12.4, 11.0, 9.6, 9.0];

  /// 45°N (Minneapolis, MN area) - elongated egg
  static const _lat45 = [9.0, 10.0, 11.5, 13.1, 14.5, 15.4, 15.0, 13.9, 12.5, 10.9, 9.3, 8.6];

  /// 50°N (Vancouver, BC area) - tall oval
  static const _lat50 = [8.4, 9.6, 11.3, 13.3, 15.0, 16.1, 15.7, 14.3, 12.6, 10.6, 8.8, 8.0];

  /// 55°N (Edmonton, AB area) - very elongated
  static const _lat55 = [7.6, 9.1, 11.2, 13.5, 15.6, 17.0, 16.5, 14.8, 12.7, 10.4, 8.2, 7.2];

  /// Map of precalculated monthly averages by absolute latitude.
  static const Map<int, List<double>> _monthlyByLatitude = {
    0: _lat0,
    25: _lat25,
    30: _lat30,
    35: _lat35,
    39: _lat39,
    42: _lat42,
    45: _lat45,
    50: _lat50,
    55: _lat55,
  };

  /// Get monthly daylight averages for a latitude.
  /// Uses precalculated fixtures when available, interpolates for in-between values.
  /// For Southern Hemisphere (negative latitudes), shifts the curve by 6 months.
  static List<double> getMonthlyDaylightCurve(int latitude) {
    final isSouthern = latitude < 0;
    final absLat = latitude.abs().clamp(0, 60);

    // Get the curve for the absolute latitude
    final curve = _getCurveForAbsoluteLatitude(absLat);

    // For Southern Hemisphere, shift by 6 months (swap summer/winter)
    if (isSouthern && absLat > 0) {
      return List.generate(12, (i) => curve[(i + 6) % 12]);
    }

    return curve;
  }

  /// Get curve for absolute latitude value (Northern Hemisphere perspective).
  static List<double> _getCurveForAbsoluteLatitude(int absLat) {
    // Direct lookup if we have precalculated data
    if (_monthlyByLatitude.containsKey(absLat)) {
      return _monthlyByLatitude[absLat]!;
    }

    // Find bracketing latitudes and interpolate
    final latitudes = _monthlyByLatitude.keys.toList()..sort();
    int? lowerLat;
    int? upperLat;

    for (final l in latitudes) {
      if (l <= absLat) lowerLat = l;
      if (l >= absLat && upperLat == null) upperLat = l;
    }

    // Edge cases
    if (lowerLat == null) return _monthlyByLatitude[latitudes.first]!;
    if (upperLat == null) return _monthlyByLatitude[latitudes.last]!;
    if (lowerLat == upperLat) return _monthlyByLatitude[lowerLat]!;

    // Interpolate between the two
    final lowerCurve = _monthlyByLatitude[lowerLat]!;
    final upperCurve = _monthlyByLatitude[upperLat]!;
    final t = (absLat - lowerLat) / (upperLat - lowerLat);

    return List.generate(12, (i) {
      return lowerCurve[i] + (upperCurve[i] - lowerCurve[i]) * t;
    });
  }

  /// Get average daylight hours for a specific month (1-12) at given latitude.
  static double getMonthAverageDaylight(int month, int latitude) {
    final curve = getMonthlyDaylightCurve(latitude);
    return curve[(month - 1).clamp(0, 11)];
  }

  /// Get daylight hours for a specific date and latitude.
  /// Uses monthly average (sufficient accuracy for egg chart).
  static double getDaylightHoursForDate(DateTime date, int latitude) {
    return getMonthAverageDaylight(date.month, latitude);
  }

  /// Get the day of year (1-365) for a given DateTime.
  static int getDayOfYear(DateTime date) {
    final startOfYear = DateTime(date.year, 1, 1);
    return date.difference(startOfYear).inDays + 1;
  }

  /// Get the maximum daylight hours for a latitude.
  /// June for Northern Hemisphere, December for Southern.
  static double getMaxDaylight(int latitude) {
    final month = latitude >= 0 ? 6 : 12;
    return getMonthAverageDaylight(month, latitude);
  }

  /// Get the minimum daylight hours for a latitude.
  /// December for Northern Hemisphere, June for Southern.
  static double getMinDaylight(int latitude) {
    final month = latitude >= 0 ? 12 : 6;
    return getMonthAverageDaylight(month, latitude);
  }

  // ==================== Runtime Calculation (for edge cases) ====================

  /// Calculate exact daylight hours for a given day of year (1-365) and latitude.
  /// Use this only when precise daily values are needed (rarely).
  static double calculateDaylightHours(int dayOfYear, int latitude) {
    final day = dayOfYear.clamp(1, 365);
    final lat = latitude.clamp(-90, 90);

    final latRad = lat * math.pi / 180;
    final declination = 23.45 * math.sin(2 * math.pi / 365 * (day - 81)) * math.pi / 180;
    final cosHourAngle = -math.tan(latRad) * math.tan(declination);

    if (cosHourAngle < -1) return 24.0;
    if (cosHourAngle > 1) return 0.0;

    final hourAngle = math.acos(cosHourAngle);
    return hourAngle * 24 / math.pi;
  }
}
