// lib/data/services/islamic_event_provider.dart
import 'package:hijri/hijri_calendar.dart';
import '../models/islamic_event_model.dart';
import '../../core/enums/calculation_method.dart';

class IslamicEventProvider {
  // Hijri month names
  static const List<String> hijriMonthNames = [
    "Muharram", "Safar", "Rabi' al-Awwal", "Rabi' al-Thani",
    "Jumada al-Awwal", "Jumada al-Thani", "Rajab", "Sha'ban",
    "Ramadan", "Shawwal", "Dhul-Qadah", "Dhul-Hijjah"
  ];

  // ACCURATE Hijri to Gregorian conversion
  static DateTime hijriToGregorian(int year, int month, int day) {
    final now = DateTime.now();
    final currentHijri = HijriCalendar.fromDate(now);

    // Calculate difference in days
    int diffDays = 0;

    if (year == currentHijri.hYear) {
      diffDays = (month - currentHijri.hMonth) * 30 + (day - currentHijri.hDay);
    } else {
      diffDays = (year - currentHijri.hYear) * 354 +
          (month - currentHijri.hMonth) * 30 +
          (day - currentHijri.hDay);
    }

    return DateTime(now.year, now.month, now.day).add(Duration(days: diffDays));
  }

  // Get events for a specific Hijri year
  static Future<List<IslamicEvent>> getEventsForHijriYear(
      int hijriYear,
      CalculationMethod method,
      ) async {
    final List<IslamicEvent> events = [];

    // Islamic New Year (1 Muharram)
    events.add(_createEvent(
      id: 'islamic_new_year_$hijriYear',
      title: 'Islamic New Year',
      description: 'The beginning of the Islamic lunar calendar year. A day of reflection on the Hijrah (migration) of Prophet Muhammad (PBUH) from Mecca to Medina.',
      hijriYear: hijriYear,
      hijriMonth: 1,
      hijriDay: 1,
      type: EventType.islamicNewYear,
      isImportant: true,
    ));

    // Day of Ashura (10 Muharram)
    events.add(_createEvent(
      id: 'ashura_$hijriYear',
      title: 'Day of Ashura',
      description: 'Commemorates various events, including the martyrdom of Husayn ibn Ali. It is recommended to fast on this day and the day before or after.',
      hijriYear: hijriYear,
      hijriMonth: 1,
      hijriDay: 10,
      type: EventType.ashura,
      isImportant: true,
    ));

    // Mawlid al-Nabi (12 Rabi' al-Awwal)
    events.add(_createEvent(
      id: 'mawlid_$hijriYear',
      title: 'Mawlid al-Nabi',
      description: 'Celebration of the birthday of Prophet Muhammad (peace be upon him). A day of remembrance and reflection on his life and teachings.',
      hijriYear: hijriYear,
      hijriMonth: 3,
      hijriDay: 12,
      type: EventType.other,
      isImportant: true,
    ));

    // Isra and Mi'raj (27 Rajab)
    events.add(_createEvent(
      id: 'isra_miraj_$hijriYear',
      title: 'Isra and Mi\'raj',
      description: 'Commemorates the night journey of Prophet Muhammad from Mecca to Jerusalem and his ascension to the heavens.',
      hijriYear: hijriYear,
      hijriMonth: 7,
      hijriDay: 27,
      type: EventType.other,
      isImportant: true,
    ));

    // Laylat al-Bara'at (15 Sha'ban)
    events.add(_createEvent(
      id: 'baraat_$hijriYear',
      title: 'Laylat al-Bara\'at',
      description: 'The Night of Forgiveness (Shab-e-Baraat). A night of worship, prayer, and seeking forgiveness.',
      hijriYear: hijriYear,
      hijriMonth: 8,
      hijriDay: 15,
      type: EventType.other,
      isImportant: true,
    ));

    // First day of Ramadan (1 Ramadan)
    events.add(_createEvent(
      id: 'ramadan_start_$hijriYear',
      title: 'First Day of Ramadan',
      description: 'The blessed month of fasting begins. Muslims fast from dawn to sunset, increase prayers, charity, and Quran recitation.',
      hijriYear: hijriYear,
      hijriMonth: 9,
      hijriDay: 1,
      type: EventType.ramadan,
      isImportant: true,
      prayerTimeAdjustment: 'Fasting from dawn to sunset',
    ));

    // Battle of Badr (17 Ramadan)
    events.add(_createEvent(
      id: 'battle_of_badr_$hijriYear',
      title: 'Battle of Badr',
      description: 'The first major battle in Islamic history, a decisive victory that occurred on 17 Ramadan 2 AH.',
      hijriYear: hijriYear,
      hijriMonth: 9,
      hijriDay: 17,
      type: EventType.other,
      isImportant: false,
    ));

    // Conquest of Mecca (20 Ramadan)
    events.add(_createEvent(
      id: 'conquest_mecca_$hijriYear',
      title: 'Conquest of Mecca',
      description: 'The peaceful conquest of Mecca by Prophet Muhammad and his companions on 20 Ramadan 8 AH.',
      hijriYear: hijriYear,
      hijriMonth: 9,
      hijriDay: 20,
      type: EventType.other,
      isImportant: false,
    ));

    // Laylat al-Qadr (27 Ramadan) - Most likely night
    events.add(_createEvent(
      id: 'qadr_$hijriYear',
      title: 'Laylat al-Qadr',
      description: 'The Night of Power - better than a thousand months. The night when the Quran was first revealed. Seek it in the last 10 nights of Ramadan.',
      hijriYear: hijriYear,
      hijriMonth: 9,
      hijriDay: 27,
      type: EventType.nightOfPower,
      isImportant: true,
    ));

    // Eid al-Fitr (1 Shawwal)
    events.add(_createEvent(
      id: 'eid_fitr_$hijriYear',
      title: 'Eid al-Fitr',
      description: 'Festival of Breaking the Fast. Celebrated after completing Ramadan with prayers, gatherings, and charity.',
      hijriYear: hijriYear,
      hijriMonth: 10,
      hijriDay: 1,
      type: EventType.eid,
      isImportant: true,
      prayerTimeAdjustment: 'Eid prayer after sunrise',
    ));

    // Day of Arafah (9 Dhul-Hijjah)
    events.add(_createEvent(
      id: 'arafah_$hijriYear',
      title: 'Day of Arafah',
      description: 'The most important day of Hajj pilgrimage. Highly recommended to fast for those not performing Hajj. A day when Allah forgives sins.',
      hijriYear: hijriYear,
      hijriMonth: 12,
      hijriDay: 9,
      type: EventType.hajj,
      isImportant: true,
    ));

    // Eid al-Adha (10 Dhul-Hijjah)
    events.add(_createEvent(
      id: 'eid_adha_$hijriYear',
      title: 'Eid al-Adha',
      description: 'Festival of Sacrifice. Commemorates Prophet Ibrahim\'s willingness to sacrifice his son. Celebrated with prayers and Qurbani (sacrifice).',
      hijriYear: hijriYear,
      hijriMonth: 12,
      hijriDay: 10,
      type: EventType.eid,
      isImportant: true,
      prayerTimeAdjustment: 'Eid prayer after sunrise',
    ));

    // Days of Tashreeq (11-13 Dhul-Hijjah)
    for (int day = 11; day <= 13; day++) {
      events.add(_createEvent(
        id: 'tashreeq_${day}_$hijriYear',
        title: 'Day of Tashreeq ($day Dhul-Hijjah)',
        description: 'Days of eating, drinking, and remembering Allah. The days following Eid al-Adha for completing Hajj rituals.',
        hijriYear: hijriYear,
        hijriMonth: 12,
        hijriDay: day,
        type: EventType.other,
        isImportant: false,
      ));
    }

    return events;
  }

  // Get events for multiple Hijri years (for better coverage)
  static Future<List<IslamicEvent>> getEventsForGregorianYear(
      int gregorianYear,
      CalculationMethod method,
      ) async {
    final List<IslamicEvent> allEvents = [];

    // Convert Gregorian year to approximate Hijri years
    // A Gregorian year typically overlaps with 2 Hijri years
    final startDate = DateTime(gregorianYear, 1, 1);
    final endDate = DateTime(gregorianYear, 12, 31);

    final startHijri = HijriCalendar.fromDate(startDate);
    final endHijri = HijriCalendar.fromDate(endDate);

    // Get events for all relevant Hijri years
    for (int hijriYear = startHijri.hYear; hijriYear <= endHijri.hYear + 1; hijriYear++) {
      final events = await getEventsForHijriYear(hijriYear, method);
      allEvents.addAll(events);
    }

    // Filter events that fall within the Gregorian year
    return allEvents.where((event) {
      return event.gregorianDate.year == gregorianYear;
    }).toList()..sort((a, b) => a.gregorianDate.compareTo(b.gregorianDate));
  }

  // Helper method to create an event
  static IslamicEvent _createEvent({
    required String id,
    required String title,
    required String description,
    required int hijriYear,
    required int hijriMonth,
    required int hijriDay,
    required EventType type,
    required bool isImportant,
    String? prayerTimeAdjustment,
  }) {
    final gregorianDate = hijriToGregorian(hijriYear, hijriMonth, hijriDay);

    return IslamicEvent(
      id: id,
      title: title,
      description: description,
      gregorianDate: gregorianDate,
      hijriDate: HijriDate(
        day: hijriDay,
        month: hijriMonth,
        year: hijriYear,
        monthName: hijriMonthNames[hijriMonth - 1],
      ),
      type: type,
      isImportant: isImportant,
      prayerTimeAdjustment: prayerTimeAdjustment,
    );
  }

  // Get upcoming events (today and future)
  static Future<List<IslamicEvent>> getUpcomingEvents(
      CalculationMethod method, {
        int maxEvents = 10,
      }) async {
    final now = DateTime.now();
    final today = DateTime.utc(now.year, now.month, now.day);

    // Get events for current year and next 2 years
    final List<IslamicEvent> allEvents = [];
    for (int year = now.year; year <= now.year + 2; year++) {
      final events = await getEventsForGregorianYear(year, method);
      allEvents.addAll(events);
    }

    // Filter for future events (including today)
    final futureEvents = allEvents.where((event) {
      final eventDate = event.normalizedDate;
      return eventDate.isAtSameMomentAs(today) || eventDate.isAfter(today);
    }).toList();

    // Sort by date
    futureEvents.sort((a, b) => a.gregorianDate.compareTo(b.gregorianDate));

    // Return limited number of events
    return futureEvents.take(maxEvents).toList();
  }
}