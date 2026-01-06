import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hijri/hijri_calendar.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../core/services/settings_service.dart';
import '../../data/models/islamic_event_model.dart';
import '../../data/services/islamic_event_provider.dart';
import '../../core/enums/calculation_method.dart';

class IslamicCalendarPage extends StatefulWidget {
  const IslamicCalendarPage({super.key});

  @override
  State<IslamicCalendarPage> createState() => _IslamicCalendarPageState();
}

class _IslamicCalendarPageState extends State<IslamicCalendarPage> with TickerProviderStateMixin {
  DateTime _focused = DateTime.now();
  DateTime _selected = DateTime.now();
  final HijriCalendar _hijriToday = HijriCalendar.now();
  late HijriCalendar _hijriFocused;
  late HijriCalendar _hijriSelected;

  bool _isHijriView = false;
  Map<DateTime, List<IslamicEvent>> _events = {};
  List<IslamicEvent> _selectedEvents = [];
  List<IslamicEvent> _upcoming = [];
  bool _loading = true;

  final List<String> _hijriMonths = [
    'Muharram', 'Safar', "Rabi' al-Awwal", "Rabi' al-Thani",
    'Jumada al-Awwal', 'Jumada al-Thani', 'Rajab', "Sha'ban",
    'Ramadan', 'Shawwal', "Dhul-Qa'dah", 'Dhul-Hijjah'
  ];

  @override
  void initState() {
    super.initState();
    _hijriFocused = HijriCalendar.now();
    _hijriSelected = HijriCalendar.now();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    final settings = Provider.of<SettingsService>(context, listen: false);
    final method = settings.getCalculationMethod();

    try {
      final now = DateTime.now();
      final List<IslamicEvent> allEvents = [];

      for (int year = now.year - 1; year <= now.year + 1; year++) {
        final events = await IslamicEventProvider.getEventsForGregorianYear(year, method);
        allEvents.addAll(events);
      }

      final eventMap = <DateTime, List<IslamicEvent>>{};
      for (final e in allEvents) {
        final d = DateTime.utc(e.gregorianDate.year, e.gregorianDate.month, e.gregorianDate.day);
        eventMap[d] ??= [];
        eventMap[d]!.add(e);
      }

      if (mounted) {
        setState(() {
          _events = eventMap;
          _upcoming = allEvents.where((e) => e.gregorianDate.isAfter(now)).toList().take(8).toList();
          _selectedEvents = eventMap[DateTime.utc(_selected.year, _selected.month, _selected.day)] ?? [];
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _onDaySelected(DateTime selected, DateTime focused) {
    setState(() {
      _selected = selected;
      _focused = focused;
      _hijriSelected = HijriCalendar.fromDate(selected);
      _selectedEvents = _events[DateTime.utc(selected.year, selected.month, selected.day)] ?? [];
    });
  }

  void _toggleCalendarView() {
    setState(() => _isHijriView = !_isHijriView);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fontScale = Provider.of<SettingsService>(context).fontScale;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Islamic Calendar'),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(_isHijriView ? Icons.calendar_month : Icons.mosque),
            onPressed: _toggleCalendarView,
            tooltip: _isHijriView ? 'Switch to Gregorian' : 'Switch to Hijri',
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // 1. DATE CARDS (Header) - Now tappable
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _isHijriView = false),
                      child: _buildDateCard(
                        "Gregorian",
                        DateFormat('dd MMM yyyy').format(_selected),
                        theme.colorScheme.primary,
                        !_isHijriView,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _isHijriView = true),
                      child: _buildDateCard(
                        "Hijri",
                        "${_hijriSelected.hDay} ${_hijriMonths[_hijriSelected.hMonth - 1]} ${_hijriSelected.hYear}",
                        theme.colorScheme.secondary,
                        _isHijriView,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 2. THE CALENDAR
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20)],
              ),
              child: _isHijriView ? _buildHijriGrid(theme, fontScale) : _buildGregorianTable(theme, fontScale),
            ),
          ),

          // 3. UPCOMING EVENTS
          if (_upcoming.isNotEmpty) ...[
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
                child: Text('Upcoming Events', style: TextStyle(fontSize: 18 * fontScale, fontWeight: FontWeight.bold)),
              ),
            ),
            SliverToBoxAdapter(
              child: SizedBox(
                height: 110,
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  scrollDirection: Axis.horizontal,
                  itemCount: _upcoming.length,
                  itemBuilder: (context, i) => _buildUpcomingItem(_upcoming[i], theme, fontScale),
                ),
              ),
            ),
          ],

          // 4. SELECTED DAY EVENTS
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
              child: Text(
                'Events on ${_isHijriView ? '${_hijriSelected.hDay} ${_hijriMonths[_hijriSelected.hMonth - 1]}' : DateFormat('dd MMM yyyy').format(_selected)}',
                style: TextStyle(fontSize: 18 * fontScale, fontWeight: FontWeight.bold),
              ),
            ),
          ),

          _selectedEvents.isEmpty
              ? const SliverToBoxAdapter(
            child: Center(
              child: Padding(
                padding: EdgeInsets.all(32.0),
                child: Text('No special events on this day'),
              ),
            ),
          )
              : SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                    (context, i) => _buildEventTile(_selectedEvents[i], theme, fontScale),
                childCount: _selectedEvents.length,
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 40)),
        ],
      ),
    );
  }

  // --- SUB-WIDGETS ---

  Widget _buildDateCard(String label, String value, Color color, bool active) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: active ? color : color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        boxShadow: active
            ? [BoxShadow(color: color.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))]
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: active ? Colors.white70 : color,
              fontSize: 13 * Provider.of<SettingsService>(context).fontScale,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              color: active ? Colors.white : Colors.black87,
              fontWeight: FontWeight.bold,
              fontSize: 16 * Provider.of<SettingsService>(context).fontScale,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGregorianTable(ThemeData theme, double fontScale) {
    return TableCalendar(
      firstDay: DateTime.utc(2024, 1, 1),
      lastDay: DateTime.utc(2030, 12, 31),
      focusedDay: _focused,
      selectedDayPredicate: (day) => isSameDay(_selected, day),
      onDaySelected: _onDaySelected,
      calendarFormat: CalendarFormat.month,
      headerStyle: const HeaderStyle(formatButtonVisible: false, titleCentered: true),
      eventLoader: (day) => _events[DateTime.utc(day.year, day.month, day.day)] ?? [],
      calendarStyle: CalendarStyle(
        selectedDecoration: BoxDecoration(color: theme.colorScheme.primary, shape: BoxShape.circle),
        todayDecoration: BoxDecoration(color: theme.colorScheme.primary.withOpacity(0.2), shape: BoxShape.circle, border: Border.all(color: theme.colorScheme.primary)),
        markerDecoration: BoxDecoration(color: theme.colorScheme.secondary, shape: BoxShape.circle),
      ),
    );
  }

  Widget _buildHijriGrid(ThemeData theme, double fontScale) {
    final daysInMonth = _hijriFocused.getDaysInMonth(_hijriFocused.hYear, _hijriFocused.hMonth);
    final firstDayGreg = _hijriFocused.hijriToGregorian(_hijriFocused.hYear, _hijriFocused.hMonth, 1);
    final firstWeekday = firstDayGreg.weekday % 7; // Sunday = 0

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              icon: const Icon(Icons.chevron_left),
              onPressed: () {
                setState(() {
                  _hijriFocused.hMonth--;
                  if (_hijriFocused.hMonth < 1) {
                    _hijriFocused.hMonth = 12;
                    _hijriFocused.hYear--;
                  }
                });
              },
            ),
            Text(
              '${_hijriMonths[_hijriFocused.hMonth - 1]} ${_hijriFocused.hYear}',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            IconButton(
              icon: const Icon(Icons.chevron_right),
              onPressed: () {
                setState(() {
                  _hijriFocused.hMonth++;
                  if (_hijriFocused.hMonth > 12) {
                    _hijriFocused.hMonth = 1;
                    _hijriFocused.hYear++;
                  }
                });
              },
            ),
          ],
        ),
        const SizedBox(height: 8),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 7),
          itemCount: daysInMonth + firstWeekday,
          itemBuilder: (context, i) {
            if (i < firstWeekday) return const SizedBox.shrink();

            final day = i - firstWeekday + 1;
            final isSelected = _hijriSelected.hDay == day &&
                _hijriSelected.hMonth == _hijriFocused.hMonth &&
                _hijriSelected.hYear == _hijriFocused.hYear;
            final isToday = _hijriToday.hDay == day &&
                _hijriToday.hMonth == _hijriFocused.hMonth &&
                _hijriToday.hYear == _hijriFocused.hYear;

            final gregDate = _hijriFocused.hijriToGregorian(_hijriFocused.hYear, _hijriFocused.hMonth, day);
            final hasEvent = _events[DateTime.utc(gregDate.year, gregDate.month, gregDate.day)]?.isNotEmpty ?? false;

            return GestureDetector(
              onTap: () => _onDaySelected(gregDate, gregDate),
              child: Container(
                margin: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: isSelected
                      ? theme.colorScheme.secondary
                      : isToday
                      ? theme.colorScheme.secondary.withOpacity(0.2)
                      : Colors.transparent,
                  shape: BoxShape.circle,
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Text(
                      '$day',
                      style: TextStyle(
                        color: isSelected ? Colors.white : null,
                        fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                        fontSize: 14 * fontScale,
                      ),
                    ),
                    if (hasEvent)
                      Positioned(
                        bottom: 6,
                        child: Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: isSelected ? Colors.white70 : theme.colorScheme.secondary,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildUpcomingItem(IslamicEvent event, ThemeData theme, double fontScale) {
    return Container(
      width: 150,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            event.title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const Spacer(),
          Text(
            DateFormat('MMM dd').format(event.gregorianDate),
            style: TextStyle(color: theme.colorScheme.primary, fontSize: 12, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _buildEventTile(IslamicEvent event, ThemeData theme, double fontScale) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: const BorderSide(color: Colors.black12)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
          child: Icon(Icons.event_available, color: theme.colorScheme.primary, size: 20),
        ),
        title: Text(event.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        subtitle: Text(event.hijriDate.formattedDate, style: const TextStyle(fontSize: 12)),
        trailing: event.isImportant ? const Icon(Icons.star, color: Colors.amber, size: 20) : null,
      ),
    );
  }
}