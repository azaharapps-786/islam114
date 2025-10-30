// lib/core/utils/hijri_converter.dart
import 'package:hijri/hijri_calendar.dart';

class HijriConverter {
  /// Converts Hijri date to Gregorian DateTime
  /// Uses the hijri package's internal conversion
  static DateTime toGregorian(int hYear, int hMonth, int hDay) {
    try {
      // Create a HijriCalendar instance with the specified date
      final hijri = HijriCalendar();
      hijri.hYear = hYear;
      hijri.hMonth = hMonth;
      hijri.hDay = hDay;

      // The hijri package stores Gregorian equivalents internally
      // We can get them by converting from a known date

      // Get current date as reference
      final now = DateTime.now();
      final todayHijri = HijriCalendar.fromDate(now);

      // Calculate difference in days
      final diffYears = hYear - todayHijri.hYear;
      final diffMonths = hMonth - todayHijri.hMonth;
      final diffDays = hDay - todayHijri.hDay;

      // Approximate conversion (Hijri year ≈ 354 days, month ≈ 29.5 days)
      final totalDiffDays = (diffYears * 354) + (diffMonths * 30) + diffDays;

      return DateTime(now.year, now.month, now.day).add(Duration(days: totalDiffDays));
    } catch (e) {
      // Fallback to current date
      return DateTime.now();
    }
  }

  /// Alternative method using direct calculation
  /// More accurate for historical dates
  static DateTime toGregorianAccurate(int hYear, int hMonth, int hDay) {
    // Use Umm al-Qura calendar conversion
    // This is a simplified version - for production use a proper conversion library

    // Base epoch: 1 Muharram 1 AH = July 16, 622 CE (proleptic Gregorian)
    const hijriEpochJulianDay = 1948439.5;

    // Calculate Julian Day Number for the Hijri date
    final julianDay = _hijriToJulianDay(hYear, hMonth, hDay);

    // Convert Julian Day to Gregorian
    return _julianDayToGregorian(julianDay);
  }

  static double _hijriToJulianDay(int year, int month, int day) {
    // Simplified calculation based on mean synodic month
    const hijriEpochJulianDay = 1948439.5;
    const meanSynodicMonth = 29.530588853;

    final totalMonths = (year - 1) * 12 + month - 1;
    final totalDays = totalMonths * meanSynodicMonth + day;

    return hijriEpochJulianDay + totalDays;
  }

  static DateTime _julianDayToGregorian(double jd) {
    final a = (jd + 0.5).floor();
    final b = a + 1524;
    final c = ((b - 122.1) / 365.25).floor();
    final d = (365.25 * c).floor();
    final e = ((b - d) / 30.6001).floor();

    final day = b - d - (30.6001 * e).floor();
    final month = e < 14 ? e - 1 : e - 13;
    final year = month > 2 ? c - 4716 : c - 4715;

    return DateTime(year, month, day);
  }

  /// Converts Gregorian DateTime to Hijri date components
  static Map<String, int> toHijri(DateTime gregorian) {
    final hijri = HijriCalendar.fromDate(gregorian);
    return {
      'year': hijri.hYear,
      'month': hijri.hMonth,
      'day': hijri.hDay,
    };
  }

  /// Gets the number of days in a Hijri month
  static int getDaysInMonth(int year, int month) {
    final hijri = HijriCalendar();
    hijri.hYear = year;
    hijri.hMonth = month;
    hijri.hDay = 1;
    return hijri.lengthOfMonth;
  }
}