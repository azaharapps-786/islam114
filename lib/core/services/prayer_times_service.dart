// lib/core/services/prayer_times_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/models/prayer_times_model.dart';

class PrayerTimesService {
  static final PrayerTimesService _instance = PrayerTimesService._internal();
  factory PrayerTimesService() => _instance;
  PrayerTimesService._internal();

  static const String _baseUrl = 'http://api.aladhan.com/v1/timings';
  static const String _cacheKey = 'prayer_times_cache';
  static const String _locationKey = 'prayer_times_location';
  static const String _timestampKey = 'prayer_times_timestamp';

  Future<PrayerTimesResponse?> getPrayerTimesByCoordinates(
      double latitude,
      double longitude, {
        DateTime? date,
      }) async {
    try {
      final targetDate = date ?? DateTime.now();
      final formattedDate = DateFormat('dd-MM-yyyy').format(targetDate);

      final url = '$_baseUrl/$formattedDate?latitude=$latitude&longitude=$longitude&method=8';

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final prayerTimes = PrayerTimesResponse.fromJson(data);

        // Cache the response if it's for today
        if (date == null || _isSameDay(date, DateTime.now())) {
          await _cachePrayerTimes(prayerTimes, latitude, longitude);
        }

        return prayerTimes;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<PrayerTimesResponse?> getCachedPrayerTimes() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedJson = prefs.getString(_cacheKey);

      if (cachedJson != null) {
        final data = json.decode(cachedJson);
        return PrayerTimesResponse.fromJson(data);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<bool> isCacheValid() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final timestamp = prefs.getInt(_timestampKey);

      // Fix 1: Check if timestamp is not null and greater than 0
      if (timestamp != null && timestamp > 0) {
        final cacheDate = DateTime.fromMillisecondsSinceEpoch(timestamp);
        return _isSameDay(cacheDate, DateTime.now());
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<void> _cachePrayerTimes(
      PrayerTimesResponse prayerTimes,
      double latitude,
      double longitude,
      ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final json = jsonEncode(prayerTimes.toJson());

      await prefs.setString(_cacheKey, json);
      await prefs.setDouble('${_locationKey}_lat', latitude);
      await prefs.setDouble('${_locationKey}_lng', longitude);
      await prefs.setInt(_timestampKey, DateTime.now().millisecondsSinceEpoch);
    } catch (e) {
      // Handle error silently
    }
  }

  Future<LocationData?> getCachedLocation() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final latitude = prefs.getDouble('${_locationKey}_lat');
      final longitude = prefs.getDouble('${_locationKey}_lng');

      if (latitude != null && longitude != null) {
        return LocationData(latitude: latitude, longitude: longitude);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }
}

// Extension to make the model serializable
extension PrayerTimesResponseExtension on PrayerTimesResponse {
  Map<String, dynamic> toJson() {
    return {
      'code': code,
      'status': status,
      'data': {
        'timings': {
          'Fajr': data.timings.fajr,
          'Sunrise': data.timings.sunrise,
          'Dhuhr': data.timings.dhuhr,
          'Asr': data.timings.asr,
          'Maghrib': data.timings.maghrib,
          'Isha': data.timings.isha,
        },
        'date': {
          'readable': data.date.readable,
          'hijri': {
            'date': data.date.hijri.date,
            'day': data.date.hijri.day,
            'month': {
              'number': data.date.hijri.month.number,
              'en': data.date.hijri.month.en,
            },
            'year': data.date.hijri.year,
          },
          'gregorian': {
            'date': data.date.gregorian.date,
            'day': data.date.gregorian.day,
            'month': {
              'number': data.date.gregorian.month.number,
              'en': data.date.gregorian.month.en,
            },
            'year': data.date.gregorian.year,
          },
        },
        'meta': {
          'latitude': data.meta.latitude,
          'longitude': data.meta.longitude,
          'timezone': data.meta.timezone,
        },
      },
    };
  }
}