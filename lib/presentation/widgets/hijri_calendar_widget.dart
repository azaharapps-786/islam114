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

class _HijriCalendarWidgetState extends State<HijriCalendarWidget>
    with TickerProviderStateMixin {
  late HijriCalendar _currentMonth;
  late HijriCalendar _selectedDate;
  late CalendarFormat _calendarFormat;
  late DateTime _focusedDay;

  // Define safe date ranges for the calendar
  late DateTime _firstDay;
  late DateTime _lastDay;
  late DateTime _currentMonthStart;
  late DateTime _currentMonthEnd;

  // Animation controller for format changes
  late AnimationController _formatController;

  // Hijri month names
  final List<String> _hijriMonthNames = [
    "Muharram", "Safar", "Rabi' al-Awwal", "Rabi' al-Thani",
    "Jumada al-Awwal", "Jumada al-Thani", "Rajab", "Sha'ban",
    "Ramadan", "Shawwal", "Dul-Qadah", "Dhul-Hijjah"
  ];

  @override
  void initState() {
    super.initState();
    _calendarFormat = widget.calendarFormat;
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

    // Initialize animation controller
    _formatController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _formatController.dispose();
    super.dispose();
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
    if (oldWidget.calendarFormat != widget.calendarFormat) {
      setState(() => _calendarFormat = widget.calendarFormat);
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

  // New: Handle format changes
  void _onFormatChanged(CalendarFormat format) {
    setState(() => _calendarFormat = format);
    widget.onFormatChanged(format);
    _formatController.forward().then((_) => _formatController.reverse());
  }

  // New: Get format-specific row count
  int _getRowsForFormat() {
    final daysInMonth = _getDaysInHijriMonth(_currentMonth.hYear, _currentMonth.hMonth);
    final tempHijri = HijriCalendar();
    tempHijri.hYear = _currentMonth.hYear;
    tempHijri.hMonth = _currentMonth.hMonth;
    tempHijri.hDay = 1;
    final firstDayGreg = _hijriToGregorian(tempHijri);
    final firstDayOfWeek = firstDayGreg.weekday % 7;
    final totalCells = firstDayOfWeek + daysInMonth;
    switch (_calendarFormat) {
      case CalendarFormat.month:
        return (totalCells / 7).ceil();
      case CalendarFormat.twoWeeks:
        return 2;
      case CalendarFormat.week:
        return 1;
      default:
        return (totalCells / 7).ceil();
    }
  }

  double _getCalendarHeight() {
    final rows = _getRowsForFormat();
    return rows * 50.0; // Consistent cell height
  }

  // New: Navigate months (used for chevrons and swipes)
  void _navigateMonth(int direction) {
    setState(() {
      if (direction > 0) {
        if (_currentMonth.hMonth == 12) {
          _currentMonth.hMonth = 1;
          _currentMonth.hYear += 1;
        } else {
          _currentMonth.hMonth += 1;
        }
      } else {
        if (_currentMonth.hMonth == 1) {
          _currentMonth.hMonth = 12;
          _currentMonth.hYear -= 1;
        } else {
          _currentMonth.hMonth -= 1;
        }
      }
      _focusedDay = _hijriToGregorian(_currentMonth);
      _updateDateRanges();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        // Month navigation header with format toggle
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            children: [
              IconButton(
                onPressed: () => _navigateMonth(-1),
                icon: Icon(
                  Icons.chevron_left,
                  color: theme.colorScheme.primary,
                ),
                tooltip: 'Previous month',
              ),
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    InkWell(
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
                    IconButton(
                      onPressed: () {
                        final newFormat = _calendarFormat == CalendarFormat.month
                            ? CalendarFormat.twoWeeks
                            : CalendarFormat.month;
                        _onFormatChanged(newFormat);
                      },
                      icon: Icon(
                        _calendarFormat == CalendarFormat.month ? Icons.view_week : Icons.calendar_month,
                        color: theme.colorScheme.primary,
                      ),
                      tooltip: 'Toggle Format',
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => _navigateMonth(1),
                icon: Icon(
                  Icons.chevron_right,
                  color: theme.colorScheme.primary,
                ),
                tooltip: 'Next month',
              ),
            ],
          ),
        ),

        // Day names header with weekend styling
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat']
                .asMap()
                .entries
                .map((entry) {
              final isWeekend = entry.key == 0 || entry.key == 6; // Sun=0, Sat=6
              return Expanded(
                child: Center(
                  child: Text(
                    entry.value,
                    style: TextStyle(
                      fontSize: 12 * widget.fontScale,
                      fontWeight: FontWeight.w600,
                      color: isWeekend
                          ? theme.colorScheme.error
                          : theme.colorScheme.onSurface.withOpacity(0.6),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            }).toList(),
          ),
        ),

        // Calendar grid with swipe and format support
        Expanded(
          child: GestureDetector(
            onHorizontalDragEnd: (details) {
              if (details.primaryVelocity! > 500) {
                _navigateMonth(-1); // Swipe left -> previous
              } else if (details.primaryVelocity! < -500) {
                _navigateMonth(1); // Swipe right -> next
              }
            },
            child: AnimatedBuilder(
              animation: _formatController,
              builder: (context, child) {
                return Container(
                  height: _getCalendarHeight(),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _buildCalendarGridForFormat(theme),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  // New: Build grid based on format
  Widget _buildCalendarGridForFormat(ThemeData theme) {
    final daysInMonth = _getDaysInHijriMonth(_currentMonth.hYear, _currentMonth.hMonth);
    final firstDay = HijriCalendar();
    firstDay.hYear = _currentMonth.hYear;
    firstDay.hMonth = _currentMonth.hMonth;
    firstDay.hDay = 1;
    final firstDayGregorian = _hijriToGregorian(firstDay);
    final firstDayOfWeek = firstDayGregorian.weekday % 7; // 0=Sunday

    List<Widget> dayWidgets = [];

    switch (_calendarFormat) {
      case CalendarFormat.month:
      // Full month view
        for (int i = 0; i < firstDayOfWeek; i++) {
          dayWidgets.add(const SizedBox.shrink());
        }
        for (int day = 1; day <= daysInMonth; day++) {
          final weekdayIndex = (firstDayOfWeek + day - 1) % 7;
          final isWeekend = weekdayIndex == 0 || weekdayIndex == 6;
          dayWidgets.add(
            _DayCell(
              day: day,
              isToday: _isToday(day),
              isSelected: _isSelected(day),
              hasEvents: _hasEvents(day),
              isWeekend: isWeekend,
              onTap: () => _selectDate(day),
              theme: theme,
              fontScale: widget.fontScale,
            ),
          );
        }
        break;
      case CalendarFormat.twoWeeks:
      case CalendarFormat.week:
      // Week or two-week view (show current week(s) starting from month start)
        final cellsPerView = _calendarFormat == CalendarFormat.week ? 7 : 14;
        for (int i = 0; i < cellsPerView; i++) {
          final day = i - firstDayOfWeek + 1;
          final weekdayIndex = i % 7;
          final isWeekend = weekdayIndex == 0 || weekdayIndex == 6;
          if (day >= 1 && day <= daysInMonth) {
            dayWidgets.add(
              _DayCell(
                day: day,
                isToday: _isToday(day),
                isSelected: _isSelected(day),
                hasEvents: _hasEvents(day),
                isWeekend: isWeekend,
                onTap: () => _selectDate(day),
                theme: theme,
                fontScale: widget.fontScale,
              ),
            );
          } else {
            dayWidgets.add(const SizedBox.shrink());
          }
        }
        break;
    }

    return GridView.count(
      crossAxisCount: 7,
      children: dayWidgets,
      childAspectRatio: 1.0,
      mainAxisSpacing: 4,
      crossAxisSpacing: 4,
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
  final bool isWeekend; // New: For weekend styling
  final VoidCallback onTap;
  final ThemeData theme;
  final double fontScale;

  const _DayCell({
    required this.day,
    required this.isToday,
    required this.isSelected,
    required this.hasEvents,
    required this.isWeekend,
    required this.onTap,
    required this.theme,
    required this.fontScale,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = isSelected
        ? Colors.white
        : isToday
        ? theme.colorScheme.primary
        : isWeekend
        ? theme.colorScheme.error
        : theme.colorScheme.onSurface;

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
          // New: Shadow for selected days
          boxShadow: isSelected
              ? [
            BoxShadow(
              color: theme.colorScheme.primary.withOpacity(0.4),
              blurRadius: 8,
              offset: const Offset(0, 2),
            )
          ]
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
                  color: textColor,
                ),
              ),
            ),
            // New: Cap at 3 markers if multiple events (simple dot for now)
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