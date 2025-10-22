// lib/data/models/prayer_times_model.dart
class PrayerTimesResponse {
  final int code;
  final String status;
  final TimingsData data;

  PrayerTimesResponse({
    required this.code,
    required this.status,
    required this.data,
  });

  factory PrayerTimesResponse.fromJson(Map<String, dynamic> json) {
    return PrayerTimesResponse(
      code: json['code'],
      status: json['status'],
      data: TimingsData.fromJson(json['data']),
    );
  }
}

class TimingsData {
  final Timings timings;
  final DateData date;
  final MetaData meta;

  TimingsData({
    required this.timings,
    required this.date,
    required this.meta,
  });

  factory TimingsData.fromJson(Map<String, dynamic> json) {
    return TimingsData(
      timings: Timings.fromJson(json['timings']),
      date: DateData.fromJson(json['date']),
      meta: MetaData.fromJson(json['meta']),
    );
  }
}

class Timings {
  final String fajr;
  final String sunrise;
  final String dhuhr;
  final String asr;
  final String maghrib;
  final String isha;

  Timings({
    required this.fajr,
    required this.sunrise,
    required this.dhuhr,
    required this.asr,
    required this.maghrib,
    required this.isha,
  });

  factory Timings.fromJson(Map<String, dynamic> json) {
    return Timings(
      fajr: json['Fajr'],
      sunrise: json['Sunrise'],
      dhuhr: json['Dhuhr'],
      asr: json['Asr'],
      maghrib: json['Maghrib'],
      isha: json['Isha'],
    );
  }
}

class DateData {
  final String readable;
  final HijriDate hijri;
  final GregorianDate gregorian;

  DateData({
    required this.readable,
    required this.hijri,
    required this.gregorian,
  });

  factory DateData.fromJson(Map<String, dynamic> json) {
    return DateData(
      readable: json['readable'],
      hijri: HijriDate.fromJson(json['hijri']),
      gregorian: GregorianDate.fromJson(json['gregorian']),
    );
  }
}

class HijriDate {
  final String date;
  final String day;
  final Month month;
  final String year;

  HijriDate({
    required this.date,
    required this.day,
    required this.month,
    required this.year,
  });

  factory HijriDate.fromJson(Map<String, dynamic> json) {
    return HijriDate(
      date: json['date'],
      day: json['day'],
      month: Month.fromJson(json['month']),
      year: json['year'],
    );
  }
}

class GregorianDate {
  final String date;
  final String day;
  final Month month;
  final String year;

  GregorianDate({
    required this.date,
    required this.day,
    required this.month,
    required this.year,
  });

  factory GregorianDate.fromJson(Map<String, dynamic> json) {
    return GregorianDate(
      date: json['date'],
      day: json['day'],
      month: Month.fromJson(json['month']),
      year: json['year'],
    );
  }
}

class Month {
  final int number;
  final String en;

  Month({
    required this.number,
    required this.en,
  });

  factory Month.fromJson(Map<String, dynamic> json) {
    return Month(
      number: json['number'],
      en: json['en'],
    );
  }
}

class MetaData {
  final double latitude;
  final double longitude;
  final String timezone;

  MetaData({
    required this.latitude,
    required this.longitude,
    required this.timezone,
  });

  factory MetaData.fromJson(Map<String, dynamic> json) {
    return MetaData(
      latitude: json['latitude'].toDouble(),
      longitude: json['longitude'].toDouble(),
      timezone: json['timezone'],
    );
  }
}

// Simplified model for UI
class PrayerTime {
  final String name;
  final String time;
  final bool isNext;

  PrayerTime({
    required this.name,
    required this.time,
    this.isNext = false,
  });
}

class LocationData {
  final double latitude;
  final double longitude;

  LocationData({
    required this.latitude,
    required this.longitude,
  });
}