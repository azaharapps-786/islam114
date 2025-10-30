// lib/data/models/islamic_event_model.dart
import 'package:hijri/hijri_calendar.dart';

class IslamicEvent {
  final String id;
  final String title;
  final String description;
  final DateTime gregorianDate;
  final HijriDate hijriDate;
  final EventType type;
  final bool isImportant;
  final String? prayerTimeAdjustment;

  IslamicEvent({
    required this.id,
    required this.title,
    required this.description,
    required this.gregorianDate,
    required this.hijriDate,
    required this.type,
    this.isImportant = false,
    this.prayerTimeAdjustment,
  });

  // Create normalized DateTime (midnight UTC) for accurate date comparisons
  DateTime get normalizedDate {
    return DateTime.utc(
      gregorianDate.year,
      gregorianDate.month,
      gregorianDate.day,
    );
  }

  // Check if event is today
  bool get isToday {
    final now = DateTime.now();
    final today = DateTime.utc(now.year, now.month, now.day);
    return normalizedDate.isAtSameMomentAs(today);
  }

  // Check if event is in the future
  bool get isFuture {
    final now = DateTime.now();
    final today = DateTime.utc(now.year, now.month, now.day);
    return normalizedDate.isAfter(today);
  }

  // Get days until event
  int get daysUntil {
    final now = DateTime.now();
    final today = DateTime.utc(now.year, now.month, now.day);
    return normalizedDate.difference(today).inDays;
  }

  factory IslamicEvent.fromJson(Map<String, dynamic> json) {
    return IslamicEvent(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      gregorianDate: DateTime.parse(json['gregorianDate']),
      hijriDate: HijriDate.fromJson(json['hijriDate']),
      type: EventType.values.firstWhere(
            (e) => e.toString() == json['type'],
        orElse: () => EventType.other,
      ),
      isImportant: json['isImportant'] ?? false,
      prayerTimeAdjustment: json['prayerTimeAdjustment'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'gregorianDate': gregorianDate.toIso8601String(),
      'hijriDate': hijriDate.toJson(),
      'type': type.toString(),
      'isImportant': isImportant,
      'prayerTimeAdjustment': prayerTimeAdjustment,
    };
  }
}

class HijriDate {
  final int day;
  final int month;
  final int year;
  final String monthName;

  HijriDate({
    required this.day,
    required this.month,
    required this.year,
    required this.monthName,
  });

  factory HijriDate.fromJson(Map<String, dynamic> json) {
    return HijriDate(
      day: json['day'],
      month: json['month'],
      year: json['year'],
      monthName: json['monthName'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'day': day,
      'month': month,
      'year': year,
      'monthName': monthName,
    };
  }

  String get formattedDate => '$day $monthName $year AH';
  String get shortFormattedDate => '$day $monthName';
}

enum EventType {
  eid,
  ramadan,
  hajj,
  fasting,
  nightOfPower,
  islamicNewYear,
  ashura,
  other,
}

// Extension for EventType to get display properties
extension EventTypeExtension on EventType {
  String get displayName {
    switch (this) {
      case EventType.eid:
        return 'Eid';
      case EventType.ramadan:
        return 'Ramadan';
      case EventType.hajj:
        return 'Hajj';
      case EventType.fasting:
        return 'Fasting';
      case EventType.nightOfPower:
        return 'Night of Power';
      case EventType.islamicNewYear:
        return 'Islamic New Year';
      case EventType.ashura:
        return 'Ashura';
      case EventType.other:
        return 'Other';
    }
  }
}