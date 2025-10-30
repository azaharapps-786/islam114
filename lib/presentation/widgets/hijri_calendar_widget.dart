// lib/presentation/widgets/hijri_calendar_widget.dart
import 'package:flutter/material.dart';
import 'package:hijri/hijri_calendar.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../data/models/islamic_event_model.dart';
import '../../core/enums/calculation_method.dart';

class HijriCalendarWidget extends StatefulWidget {
  final HijriCalendar initialDate;
  final Function(HijriCalendar) onDateSelected;
  final Map<DateTime, List<IslamicEvent>> events;
  final CalculationMethod calculationMethod;
  final double fontScale;
  final CalendarFormat calendarFormat;
  final Function(CalendarFormat) onFormatChanged;

  const HijriCalendarWidget({
    super.key,
    required this.initialDate,
    required this.onDateSelected,
    required this.events,
    required this.calculationMethod,
    this.fontScale = 1.0,
    required this.calendarFormat,
    required this.onFormatChanged,
  });

  @override
  State<HijriCalendarWidget> createState() => _HijriCalendarWidgetState();
}

class _HijriCalendarWidgetState extends State<HijriCalendarWidget> {
  late HijriCalendar _currentMonth;
  late HijriCalendar _selectedDate;
  late CalendarFormat _calendarFormat;
  late DateTime _focusedDay;

  // Define safe date ranges for the calendar
  late DateTime _firstDay;
  late DateTime _lastDay;
  late DateTime _currentMonthStart;
  late DateTime _currentMonthEnd;

  // Hijri month names
  final List<String> _hijriMonthNames = [
    "Muharram", "Safar", "Rabi' al-Awwal", "Rabi' al-Thani",
    "Jumada al-Awwal", "Jumada al-Thani", "Rajab", "Sha'ban",
    "Ramadan", "Shawwal", "Dul-Qadah", "Dhul-Hijjah"
  ];

  @override
  void initState() {
    super.initState();
    _calendarFormat = CalendarFormat.month; // Always use month format
    _currentMonth = HijriCalendar();
    _currentMonth.hYear = widget.initialDate.hYear;
    _currentMonth.hMonth = widget.initialDate.hMonth;
    _currentMonth.hDay = 1;

    _selectedDate = HijriCalendar();
    _selectedDate.hYear = widget.initialDate.hYear;
    _selectedDate.hMonth = widget.initialDate.hMonth;
    _selectedDate.hDay = widget.initialDate.hDay;

    _focusedDay = _hijriToGregorian(_selectedDate);

    // Set safe date ranges for the calendar
    _updateDateRanges();
  }

  void _updateDateRanges() {
    // Calculate the current month's start and end dates
    final firstDayOfMonth = HijriCalendar();
    firstDayOfMonth.hYear = _currentMonth.hYear;
    firstDayOfMonth.hMonth = _currentMonth.hMonth;
    firstDayOfMonth.hDay = 1;

    final daysInMonth = _getDaysInHijriMonth(_currentMonth.hYear, _currentMonth.hMonth);

    final lastDayOfMonth = HijriCalendar();
    lastDayOfMonth.hYear = _currentMonth.hYear;
    lastDayOfMonth.hMonth = _currentMonth.hMonth;
    lastDayOfMonth.hDay = daysInMonth;

    _currentMonthStart = _hijriToGregorian(firstDayOfMonth);
    _currentMonthEnd = _hijriToGregorian(lastDayOfMonth);

    // Set the overall date range to include a few months before and after
    _firstDay = _currentMonthStart.subtract(const Duration(days: 90));
    _lastDay = _currentMonthEnd.add(const Duration(days: 90));

    // Ensure focused day is within range
    if (_focusedDay.isBefore(_firstDay)) {
      _focusedDay = _firstDay;
    } else if (_focusedDay.isAfter(_lastDay)) {
      _focusedDay = _lastDay;
    }
  }

  @override
  void didUpdateWidget(HijriCalendarWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialDate.hYear != widget.initialDate.hYear ||
        oldWidget.initialDate.hMonth != widget.initialDate.hMonth ||
        oldWidget.initialDate.hDay != widget.initialDate.hDay) {
      setState(() {
        _selectedDate.hYear = widget.initialDate.hYear;
        _selectedDate.hMonth = widget.initialDate.hMonth;
        _selectedDate.hDay = widget.initialDate.hDay;
        _focusedDay = _hijriToGregorian(_selectedDate);

        _currentMonth.hYear = widget.initialDate.hYear;
        _currentMonth.hMonth = widget.initialDate.hMonth;
        _currentMonth.hDay = 1;

        _updateDateRanges();
      });
    }
  }

  void _goToToday() {
    final today = HijriCalendar.now();
    setState(() {
      _currentMonth.hYear = today.hYear;
      _currentMonth.hMonth = today.hMonth;
      _currentMonth.hDay = 1;
      _selectedDate.hYear = today.hYear;
      _selectedDate.hMonth = today.hMonth;
      _selectedDate.hDay = today.hDay;
      _focusedDay = _hijriToGregorian(_selectedDate);
      _updateDateRanges();
    });
    widget.onDateSelected(_selectedDate);
  }

  void _selectDate(int day) {
    final newDate = HijriCalendar();
    newDate.hYear = _currentMonth.hYear;
    newDate.hMonth = _currentMonth.hMonth;
    newDate.hDay = day;

    setState(() {
      _selectedDate = newDate;
      _focusedDay = _hijriToGregorian(newDate);
    });
    widget.onDateSelected(newDate);
  }

  DateTime _hijriToGregorian(HijriCalendar hijri) {
    return HijriCalendar().hijriToGregorian(hijri.hYear, hijri.hMonth, hijri.hDay);
  }

  bool _isToday(int day) {
    final today = HijriCalendar.now();
    return day == today.hDay &&
        _currentMonth.hMonth == today.hMonth &&
        _currentMonth.hYear == today.hYear;
  }

  bool _isSelected(int day) {
    return day == _selectedDate.hDay &&
        _currentMonth.hMonth == _selectedDate.hMonth &&
        _currentMonth.hYear == _selectedDate.hYear;
  }

  bool _hasEvents(int day) {
    final hijri = HijriCalendar();
    hijri.hYear = _currentMonth.hYear;
    hijri.hMonth = _currentMonth.hMonth;
    hijri.hDay = day;

    final gregorian = _hijriToGregorian(hijri);
    final normalizedDate = DateTime.utc(
      gregorian.year,
      gregorian.month,
      gregorian.day,
    );

    return widget.events.containsKey(normalizedDate) &&
        widget.events[normalizedDate]!.isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        // Month navigation header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            children: [
              IconButton(
                onPressed: () {
                  if (_currentMonth.hMonth == 1) {
                    _currentMonth.hMonth = 12;
                    _currentMonth.hYear -= 1;
                  } else {
                    _currentMonth.hMonth -= 1;
                  }
                  _focusedDay = _hijriToGregorian(_currentMonth);
                  _updateDateRanges();
                  setState(() {});
                },
                icon: Icon(
                  Icons.chevron_left,
                  color: theme.colorScheme.primary,
                ),
                tooltip: 'Previous month',
              ),
              Expanded(
                child: InkWell(
                  onTap: _goToToday,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: Column(
                      children: [
                        Text(
                          _hijriMonthNames[_currentMonth.hMonth - 1],
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 16 * widget.fontScale,
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                        Text(
                          '${_currentMonth.hYear} AH',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 12 * widget.fontScale,
                            color: theme.colorScheme.onSurface.withOpacity(0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              IconButton(
                onPressed: () {
                  if (_currentMonth.hMonth == 12) {
                    _currentMonth.hMonth = 1;
                    _currentMonth.hYear += 1;
                  } else {
                    _currentMonth.hMonth += 1;
                  }
                  _focusedDay = _hijriToGregorian(_currentMonth);
                  _updateDateRanges();
                  setState(() {});
                },
                icon: Icon(
                  Icons.chevron_right,
                  color: theme.colorScheme.primary,
                ),
                tooltip: 'Next month',
              ),
            ],
          ),
        ),

        // Day names header - with proper padding
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'].map((name) {
              return Expanded(
                child: Center(
                  child: Text(
                    name,
                    style: TextStyle(
                      fontSize: 12 * widget.fontScale,
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurface.withOpacity(0.6),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            }).toList(),
          ),
        ),

        // Calendar grid with constrained height
        Expanded(
          child: _buildCalendarGrid(theme),
        ),
      ],
    );
  }

  Widget _buildCalendarGrid(ThemeData theme) {
    // Get days in month using the hijri package's built-in method
    final daysInMonth = _getDaysInHijriMonth(
      _currentMonth.hYear,
      _currentMonth.hMonth,
    );

    // Get the first day of the month
    final firstDay = HijriCalendar();
    firstDay.hYear = _currentMonth.hYear;
    firstDay.hMonth = _currentMonth.hMonth;
    firstDay.hDay = 1;

    final firstDayGregorian = _hijriToGregorian(firstDay);
    final firstDayOfWeek = firstDayGregorian.weekday % 7; // Convert to 0=Sunday

    final List<Widget> dayWidgets = [];

    // Add empty cells for days before the first day of the month
    for (int i = 0; i < firstDayOfWeek; i++) {
      dayWidgets.add(const SizedBox.shrink());
    }

    // Add cells for each day of the month
    for (int day = 1; day <= daysInMonth; day++) {
      dayWidgets.add(
        _DayCell(
          day: day,
          isToday: _isToday(day),
          isSelected: _isSelected(day),
          hasEvents: _hasEvents(day),
          onTap: () => _selectDate(day),
          theme: theme,
          fontScale: widget.fontScale,
        ),
      );
    }

    // Calculate the number of rows needed
    final totalCells = dayWidgets.length;
    final rows = (totalCells / 7).ceil();

    // Always use full month height since we removed format options
    final calendarHeight = rows * 50.0;

    return Container(
      height: calendarHeight,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GridView.count(
        crossAxisCount: 7,
        children: dayWidgets,
        childAspectRatio: 1.0,
        mainAxisSpacing: 4,
        crossAxisSpacing: 4,
      ),
    );
  }

  // Helper method to get days in a Hijri month
  int _getDaysInHijriMonth(int year, int month) {
    // Create a temporary HijriCalendar instance for the next month
    final nextMonth = HijriCalendar();
    nextMonth.hYear = month == 12 ? year + 1 : year;
    nextMonth.hMonth = month == 12 ? 1 : month + 1;
    nextMonth.hDay = 1;

    // Get the Gregorian date for the first day of next month
    final nextMonthGregorian = _hijriToGregorian(nextMonth);

    // Subtract one day to get the last day of current month
    final lastDayGregorian = nextMonthGregorian.subtract(const Duration(days: 1));

    // Convert back to Hijri to get the day number
    final lastDayHijri = HijriCalendar.fromDate(lastDayGregorian);

    return lastDayHijri.hDay;
  }
}

class _DayCell extends StatelessWidget {
  final int day;
  final bool isToday;
  final bool isSelected;
  final bool hasEvents;
  final VoidCallback onTap;
  final ThemeData theme;
  final double fontScale;

  const _DayCell({
    required this.day,
    required this.isToday,
    required this.isSelected,
    required this.hasEvents,
    required this.onTap,
    required this.theme,
    required this.fontScale,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: isSelected
              ? theme.colorScheme.primary
              : isToday
              ? theme.colorScheme.primary.withOpacity(0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: isToday && !isSelected
              ? Border.all(
            color: theme.colorScheme.primary,
            width: 2,
          )
              : null,
        ),
        child: Stack(
          children: [
            Center(
              child: Text(
                '$day',
                style: TextStyle(
                  fontSize: 14 * fontScale,
                  fontWeight: isToday || isSelected
                      ? FontWeight.bold
                      : FontWeight.normal,
                  color: isSelected
                      ? Colors.white
                      : isToday
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurface,
                ),
              ),
            ),
            if (hasEvents)
              Positioned(
                bottom: 4,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? Colors.white
                          : theme.colorScheme.secondary,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}