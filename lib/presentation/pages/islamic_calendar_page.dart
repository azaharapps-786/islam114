import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:hijri/hijri_calendar.dart';
import 'package:intl/intl.dart' as intl;
import 'package:table_calendar/table_calendar.dart';

import 'package:islam114/main.dart'; // Import for global RouteObserver from main.dart
import '../../core/services/settings_service.dart';
import '../../data/models/islamic_event_model.dart';
import '../../data/services/islamic_event_provider.dart';
import '../../core/enums/calculation_method.dart';
import '../widgets/islamic_event_card.dart';
import '../widgets/hijri_calendar_widget.dart';

class IslamicCalendarPage extends StatefulWidget {
  const IslamicCalendarPage({super.key});

  @override
  State<IslamicCalendarPage> createState() => _IslamicCalendarPageState();
}

class _IslamicCalendarPageState extends State<IslamicCalendarPage>
    with TickerProviderStateMixin, RouteAware, WidgetsBindingObserver {
  late AnimationController _animationController;
  late AnimationController _cardAnimationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _gregorianCardAnimation;
  late Animation<double> _hijriCardAnimation;
  int _animationKey = 0; // Key to force recreation of animated elements

  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();
  HijriCalendar _hijriDate = HijriCalendar.now();
  CalendarFormat _calendarFormat = CalendarFormat.month;
  CalendarFormat _hijriCalendarFormat = CalendarFormat.month;
  CalculationMethod _calculationMethod = CalculationMethod.ummAlQura;

  final Map<DateTime, List<IslamicEvent>> _events = {};
  List<IslamicEvent> _selectedEvents = [];
  List<IslamicEvent> _upcomingEvents = [];
  bool _isLoading = true;

  // Track which calendar view is active
  bool _isHijriView = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 500), // Reduced from 800ms
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );

    _cardAnimationController = AnimationController(
      duration: const Duration(milliseconds: 200), // Reduced from 300ms
      vsync: this,
    );

    _gregorianCardAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(
        parent: _cardAnimationController,
        curve: Curves.easeInOut,
      ),
    );

    _hijriCardAnimation = Tween<double>(begin: 0.95, end: 1.0).animate(
      CurvedAnimation(
        parent: _cardAnimationController,
        curve: Curves.easeInOut,
      ),
    );

    _restartAnimation(); // Initialize animations

    _initialize();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Subscribe to the global RouteObserver instance.
    final modalRoute = ModalRoute.of(context);
    if (modalRoute is PageRoute) {
      routeObserver.subscribe(this, modalRoute as PageRoute<dynamic>);
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      // Trigger animation restart when app resumes from background.
      _restartAnimation();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _animationController.dispose();
    _cardAnimationController.dispose();
    // Unsubscribe from the global RouteObserver to prevent memory leaks.
    final modalRoute = ModalRoute.of(context);
    if (modalRoute is PageRoute) {
      routeObserver.unsubscribe(this);
    }
    super.dispose();
  }

  // Restart the page animations and trigger a rebuild for list items.
  void _restartAnimation() {
    _animationController.reset();
    _animationController.forward();
    _animationKey++;
    // Force a rebuild to replay list animations via key changes.
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void didPopNext() {
    // Triggered when returning to this route (e.g., popping back from another page).
    print('didPopNext called: Restarting IslamicCalendarPage animation'); // Debug log for verification.
    _restartAnimation();
  }

  Future<void> _initialize() async {
    await _loadSettings();
    await _loadIslamicEvents();
    await _loadUpcomingEvents();
  }

  Future<void> _loadSettings() async {
    final settings = Provider.of<SettingsService>(context, listen: false);
    final method = settings.getCalculationMethod();
    if (mounted) {
      setState(() {
        _calculationMethod = method;
      });
    }
  }

  Future<void> _loadIslamicEvents() async {
    setState(() => _isLoading = true);

    try {
      final now = DateTime.now();
      final List<IslamicEvent> allEvents = [];

      for (int year = now.year - 1; year <= now.year + 2; year++) {
        final events = await IslamicEventProvider.getEventsForGregorianYear(
          year,
          _calculationMethod,
        );
        allEvents.addAll(events);
      }

      final Map<DateTime, List<IslamicEvent>> eventMap = {};
      for (final event in allEvents) {
        final date = event.normalizedDate;
        eventMap[date] = eventMap[date] ?? [];
        eventMap[date]!.add(event);
      }

      final selectedNormalized = DateTime.utc(
        _selectedDay.year,
        _selectedDay.month,
        _selectedDay.day,
      );

      if (mounted) {
        setState(() {
          _events.clear();
          _events.addAll(eventMap);
          _selectedEvents = _events[selectedNormalized] ?? [];
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading events: $e')),
        );
      }
    }
  }

  Future<void> _loadUpcomingEvents() async {
    try {
      final events = await IslamicEventProvider.getUpcomingEvents(
        _calculationMethod,
        maxEvents: 10,
      );

      if (mounted) {
        setState(() {
          _upcomingEvents = events;
        });
      }
    } catch (e) {
      debugPrint('Error loading upcoming events: $e');
    }
  }

  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    final normalized = DateTime.utc(
      selectedDay.year,
      selectedDay.month,
      selectedDay.day,
    );

    if (mounted) {
      setState(() {
        _selectedDay = selectedDay;
        _focusedDay = focusedDay;
        _hijriDate = HijriCalendar.fromDate(selectedDay);
        _selectedEvents = _events[normalized] ?? [];
      });
    }
  }

  void _onHijriDaySelected(HijriCalendar hijriDate) {
    final now = DateTime.now();
    final currentHijri = HijriCalendar.fromDate(now);

    int diffDays = 0;
    if (hijriDate.hYear == currentHijri.hYear) {
      diffDays = (hijriDate.hMonth - currentHijri.hMonth) * 30 +
          (hijriDate.hDay - currentHijri.hDay);
    } else {
      diffDays = (hijriDate.hYear - currentHijri.hYear) * 354 +
          (hijriDate.hMonth - currentHijri.hMonth) * 30 +
          (hijriDate.hDay - currentHijri.hDay);
    }

    final gregorianDate = DateTime(now.year, now.month, now.day).add(Duration(days: diffDays));
    _onDaySelected(gregorianDate, gregorianDate);
  }

  Future<void> _changeCalculationMethod(CalculationMethod method) async {
    setState(() {
      _calculationMethod = method;
      _isLoading = true;
    });

    final settings = Provider.of<SettingsService>(context, listen: false);
    await settings.setCalculationMethod(method);

    await _loadIslamicEvents();
    await _loadUpcomingEvents();
  }

  void _switchToGregorianView() {
    if (_isHijriView) {
      _cardAnimationController.forward();
      Future.delayed(const Duration(milliseconds: 100), () { // Reduced from 150ms
        if (mounted) {
          setState(() {
            _isHijriView = false;
          });
          _cardAnimationController.reverse();
        }
      });
    }
  }

  void _switchToHijriView() {
    if (!_isHijriView) {
      _cardAnimationController.forward();
      Future.delayed(const Duration(milliseconds: 100), () { // Reduced from 150ms
        if (mounted) {
          setState(() {
            _isHijriView = true;
          });
          _cardAnimationController.reverse();
        }
      });
    }
  }

  void _onHijriFormatChanged(CalendarFormat format) {
    setState(() {
      _hijriCalendarFormat = format;
    });
  }

  @override
  Widget build(BuildContext context) {
    final double fontScale = Provider.of<SettingsService>(context).fontScale;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Islamic Calendar',
          style: TextStyle(fontSize: 18 * fontScale),
        ),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.today),
            tooltip: 'Go to today',
            onPressed: () {
              final today = DateTime.now();
              _onDaySelected(today, today);
            },
          ),
          PopupMenuButton<CalculationMethod>(
            icon: const Icon(Icons.settings),
            tooltip: 'Calculation Method',
            onSelected: _changeCalculationMethod,
            itemBuilder: (context) => [
              _buildCalculationMethodItem(
                CalculationMethod.ummAlQura,
                'Umm al-Qura',
                'Saudi Arabia',
              ),
              _buildCalculationMethodItem(
                CalculationMethod.northAmerica,
                'ISNA',
                'North America',
              ),
              _buildCalculationMethodItem(
                CalculationMethod.muslimWorldLeague,
                'MWL',
                'Muslim World League',
              ),
              _buildCalculationMethodItem(
                CalculationMethod.egyptian,
                'Egyptian',
                'Egypt',
              ),
              _buildCalculationMethodItem(
                CalculationMethod.karachi,
                'Karachi',
                'Pakistan',
              ),
            ],
          ),
        ],
      ),
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: _isHijriView
              ? _buildHijriCalendarView(fontScale, theme, _animationKey)
              : _buildGregorianCalendarView(fontScale, theme, _animationKey),
        ),
      ),
    );
  }

  PopupMenuItem<CalculationMethod> _buildCalculationMethodItem(
      CalculationMethod method,
      String title,
      String subtitle,
      ) {
    return PopupMenuItem(
      value: method,
      child: Row(
        children: [
          if (_calculationMethod == method)
            const Icon(Icons.check, color: Colors.green, size: 20)
          else
            const SizedBox(width: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGregorianCalendarView(double fontScale, ThemeData theme, int animationKey) {
    return TweenAnimationBuilder<double>(
      key: ValueKey('gregorian-view-$animationKey'),
      duration: const Duration(milliseconds: 400), // Reduced from 600ms
      tween: Tween(begin: 0.0, end: 1.0),
      curve: Curves.easeOut,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 20 * (1 - value)),
          child: Transform.scale(
            scale: value,
            child: Opacity(
              opacity: value,
              child: child,
            ),
          ),
        );
      },
      child: Column(
        children: [
          // Clickable Date display cards
          _buildDateCards(fontScale, theme, animationKey),

          // Calendar
          TweenAnimationBuilder<double>(
            key: ValueKey('gregorian-calendar-$animationKey'),
            duration: const Duration(milliseconds: 450), // Reduced from 700ms
            tween: Tween(begin: 0.0, end: 1.0),
            curve: Curves.easeOut,
            builder: (context, value, child) {
              return Transform.translate(
                offset: Offset(0, 20 * (1 - value)),
                child: Transform.scale(
                  scale: value,
                  child: Opacity(
                    opacity: value,
                    child: child,
                  ),
                ),
              );
            },
            child: _buildTableCalendar(fontScale, theme, animationKey),
          ),

          const SizedBox(height: 8),

          // Events list
          Expanded(
            child: _buildEventsList(fontScale, theme, animationKey),
          ),
        ],
      ),
    );
  }

  Widget _buildHijriCalendarView(double fontScale, ThemeData theme, int animationKey) {
    return TweenAnimationBuilder<double>(
      key: ValueKey('hijri-view-$animationKey'),
      duration: const Duration(milliseconds: 400), // Reduced from 600ms
      tween: Tween(begin: 0.0, end: 1.0),
      curve: Curves.easeOut,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 20 * (1 - value)),
          child: Transform.scale(
            scale: value,
            child: Opacity(
              opacity: value,
              child: child,
            ),
          ),
        );
      },
      child: Column(
        children: [
          // Clickable Date display cards
          _buildDateCards(fontScale, theme, animationKey),

          // Hijri Calendar
          Expanded(
            child: Column(
              children: [
                // Hijri Calendar Widget
                Expanded(
                  flex: 2,
                  child: TweenAnimationBuilder<double>(
                    key: ValueKey('hijri-calendar-$animationKey'),
                    duration: const Duration(milliseconds: 450), // Reduced from 700ms
                    tween: Tween(begin: 0.0, end: 1.0),
                    curve: Curves.easeOut,
                    builder: (context, value, child) {
                      return Transform.translate(
                        offset: Offset(0, 20 * (1 - value)),
                        child: Transform.scale(
                          scale: value,
                          child: Opacity(
                            opacity: value,
                            child: child,
                          ),
                        ),
                      );
                    },
                    child: Container(
                      margin: const EdgeInsets.all(16.0),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: HijriCalendarWidget(
                        initialDate: _hijriDate,
                        onDateSelected: _onHijriDaySelected,
                        events: _events,
                        calculationMethod: _calculationMethod,
                        fontScale: fontScale,
                        calendarFormat: _hijriCalendarFormat,
                        onFormatChanged: _onHijriFormatChanged,
                      ),
                    ),
                  ),
                ),

                // Selected day events
                Expanded(
                  flex: 1,
                  child: _buildEventsList(fontScale, theme, animationKey),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Updated: Unified date cards with adaptive text scaling
  Widget _buildDateCards(double fontScale, ThemeData theme, int animationKey) {
    return TweenAnimationBuilder<double>(
      key: ValueKey('date-cards-$animationKey'),
      duration: const Duration(milliseconds: 300), // Reduced from 500ms
      tween: Tween(begin: 0.0, end: 1.0),
      curve: Curves.easeOut,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 20 * (1 - value)),
          child: Transform.scale(
            scale: value,
            child: Opacity(
              opacity: value,
              child: child,
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            // Gregorian date card - Clickable
            Expanded(
              child: AnimatedBuilder(
                animation: _isHijriView ? _gregorianCardAnimation : _hijriCardAnimation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _isHijriView ? _gregorianCardAnimation.value : 1.0,
                    child: InkWell(
                      onTap: _switchToGregorianView,
                      borderRadius: BorderRadius.circular(16),
                      child: _buildDateCard(
                        title: 'Gregorian',
                        day: _selectedDay.day.toString(),
                        monthYear: intl.DateFormat('MMM yyyy').format(_selectedDay),
                        dayName: intl.DateFormat('EEEE').format(_selectedDay),
                        color: theme.colorScheme.primary,
                        fontScale: fontScale,
                        theme: theme,
                        isActive: !_isHijriView,
                        isHijri: false,
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(width: 12),
            // Hijri date card - Clickable
            Expanded(
              child: AnimatedBuilder(
                animation: _isHijriView ? _hijriCardAnimation : _gregorianCardAnimation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _isHijriView ? 1.0 : _gregorianCardAnimation.value,
                    child: InkWell(
                      onTap: _switchToHijriView,
                      borderRadius: BorderRadius.circular(16),
                      child: _buildDateCard(
                        title: 'Hijri',
                        day: _hijriDate.hDay.toString(),
                        monthYear: IslamicEventProvider.hijriMonthNames[_hijriDate.hMonth - 1],
                        dayName: '${_hijriDate.hYear} AH',
                        color: theme.colorScheme.secondary,
                        fontScale: fontScale,
                        theme: theme,
                        isActive: _isHijriView,
                        isHijri: true,
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Updated: _buildDateCard with unified sizing and adaptive scaling
  Widget _buildDateCard({
    required String title,
    required String day,
    required String monthYear,
    required String dayName,
    required Color color,
    required double fontScale,
    required ThemeData theme,
    required bool isActive,
    required bool isHijri,
  }) {
    // Unified sizing for both cards
    const cardPadding = EdgeInsets.all(16.0);
    const titleFontSize = 12.0;
    const dayFontSize = 32.0;
    const baseMonthYearFontSize = 14.0;
    const baseDayNameFontSize = 12.0;
    const spacing1 = 8.0;
    const spacing2 = 4.0;
    const checkIconSize = 12.0;
    const checkPadding = EdgeInsets.all(4.0);
    const bottomPadding = 4.0;

    // New: Adaptive font scaling function
    double _computeAdaptiveSize(String text, double baseSize, {int maxLines = 1, double maxWidthFraction = 0.9}) {
      final textPainter = TextPainter(
        text: TextSpan(text: text, style: TextStyle(fontSize: baseSize * fontScale)),
        maxLines: maxLines,
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      if (textPainter.didExceedMaxLines || textPainter.width > MediaQuery.of(context).size.width * 0.4 * maxWidthFraction) { // Estimate card width (~40% of screen)
        return baseSize * 0.8; // Reduce by 20%
      }
      return baseSize;
    }

    final adaptiveMonthSize = _computeAdaptiveSize(monthYear, baseMonthYearFontSize, maxLines: 2);
    final adaptiveDayNameSize = _computeAdaptiveSize(dayName, baseDayNameFontSize, maxLines: 1);

    return Card(
      elevation: isActive ? 6 : 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: isActive
            ? BorderSide(color: color, width: 2)
            : BorderSide.none,
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isActive
                ? [
              color.withOpacity(0.2),
              color.withOpacity(0.1),
            ]
                : [
              color.withOpacity(0.1),
              color.withOpacity(0.05),
            ],
          ),
        ),
        padding: cardPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: titleFontSize * fontScale,
                    color: color,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
                const Spacer(),
                if (isActive)
                  Container(
                    padding: checkPadding,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.check,
                      size: checkIconSize,
                      color: Colors.white,
                    ),
                  ),
              ],
            ),
            SizedBox(height: spacing1),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  day,
                  style: TextStyle(
                    fontSize: dayFontSize * fontScale,
                    fontWeight: FontWeight.bold,
                    color: color,
                    height: 1.0,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(bottom: bottomPadding),
                    child: Text(
                      monthYear,
                      style: TextStyle(
                        fontSize: adaptiveMonthSize,
                        color: theme.colorScheme.onSurface,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: spacing2),
            Text(
              dayName,
              style: TextStyle(
                fontSize: adaptiveDayNameSize,
                color: theme.colorScheme.onSurface.withOpacity(0.6),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTableCalendar(double fontScale, ThemeData theme, int animationKey) {
    return TweenAnimationBuilder<double>(
      key: ValueKey('table-calendar-$animationKey'),
      duration: const Duration(milliseconds: 450), // Reduced from 700ms
      tween: Tween(begin: 0.0, end: 1.0),
      curve: Curves.easeOut,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 20 * (1 - value)),
          child: Transform.scale(
            scale: value,
            child: Opacity(
              opacity: value,
              child: child,
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16.0),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: TableCalendar<IslamicEvent>(
          key: ValueKey('table-calendar-content-$animationKey'), // Key for calendar content
          firstDay: DateTime.utc(2020, 1, 1),
          lastDay: DateTime.utc(2030, 12, 31),
          focusedDay: _focusedDay,
          selectedDayPredicate: (day) {
            return isSameDay(_selectedDay, day);
          },
          calendarFormat: _calendarFormat,
          eventLoader: (day) {
            final normalized = DateTime.utc(day.year, day.month, day.day);
            return _events[normalized] ?? [];
          },
          startingDayOfWeek: StartingDayOfWeek.sunday,
          onDaySelected: _onDaySelected,
          onFormatChanged: (format) {
            setState(() {
              _calendarFormat = format;
            });
          },
          onPageChanged: (focusedDay) {
            setState(() {
              _focusedDay = focusedDay;
            });
          },
          calendarStyle: CalendarStyle(
            outsideDaysVisible: true,
            weekendTextStyle: TextStyle(
              color: theme.colorScheme.error,
              fontSize: 14 * fontScale,
            ),
            defaultTextStyle: TextStyle(
              color: theme.colorScheme.onSurface,
              fontSize: 14 * fontScale,
            ),
            selectedTextStyle: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
            todayTextStyle: TextStyle(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.bold,
              fontSize: 14 * fontScale,
            ),
            selectedDecoration: BoxDecoration(
              shape: BoxShape.circle,
              color: theme.colorScheme.primary,
              boxShadow: [
                BoxShadow(
                  color: theme.colorScheme.primary.withOpacity(0.4),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            todayDecoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: theme.colorScheme.primary,
                width: 2,
              ),
              color: Colors.transparent,
            ),
            markerDecoration: BoxDecoration(
              shape: BoxShape.circle,
              color: theme.colorScheme.secondary,
            ),
            markersMaxCount: 3,
          ),
          headerStyle: HeaderStyle(
            formatButtonVisible: true,
            formatButtonDecoration: BoxDecoration(
              color: theme.colorScheme.primary,
              borderRadius: BorderRadius.circular(12),
            ),
            formatButtonTextStyle: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
            formatButtonPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 6,
            ),
            titleCentered: true,
            titleTextStyle: TextStyle(
              fontSize: 16 * fontScale,
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
            leftChevronIcon: Icon(
              Icons.chevron_left,
              color: theme.colorScheme.primary,
            ),
            rightChevronIcon: Icon(
              Icons.chevron_right,
              color: theme.colorScheme.primary,
            ),
            headerPadding: const EdgeInsets.symmetric(vertical: 8.0),
          ),
          daysOfWeekStyle: DaysOfWeekStyle(
            weekdayStyle: TextStyle(
              fontSize: 13 * fontScale,
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface.withOpacity(0.7),
            ),
            weekendStyle: TextStyle(
              fontSize: 13 * fontScale,
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.error.withOpacity(0.7),
            ),
            dowTextFormatter: (date, locale) {
              // Use short day names to ensure they fit properly
              switch (date.weekday) {
                case 1:
                  return 'Mon';
                case 2:
                  return 'Tue';
                case 3:
                  return 'Wed';
                case 4:
                  return 'Thu';
                case 5:
                  return 'Fri';
                case 6:
                  return 'Sat';
                case 7:
                  return 'Sun';
                default:
                  return '';
              }
            },
          ),
          calendarBuilders: CalendarBuilders(
            dowBuilder: (context, day) {
              // Custom day of week builder to ensure proper spacing
              return Center(
                child: Text(
                  intl.DateFormat.E().format(day),
                  style: TextStyle(
                    fontSize: 11 * fontScale,
                    fontWeight: FontWeight.w600,
                    color: day.weekday == DateTime.sunday || day.weekday == DateTime.saturday
                        ? theme.colorScheme.error.withOpacity(0.7)
                        : theme.colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildEventsList(double fontScale, ThemeData theme, int animationKey) {
    if (_isLoading) {
      return TweenAnimationBuilder<double>(
        key: ValueKey('loading-events-$animationKey'),
        duration: const Duration(milliseconds: 400), // Reduced from 600ms
        tween: Tween(begin: 0.0, end: 1.0),
        curve: Curves.easeOut,
        builder: (context, value, child) {
          return Transform.translate(
            offset: Offset(0, 20 * (1 - value)),
            child: Transform.scale(
              scale: value,
              child: Opacity(
                opacity: value,
                child: child,
              ),
            ),
          );
        },
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                color: theme.colorScheme.primary,
              ),
              const SizedBox(height: 16),
              Text(
                'Loading events...',
                style: TextStyle(
                  fontSize: 14 * fontScale,
                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return CustomScrollView(
      key: ValueKey('events-scroll-$animationKey'), // Key for scroll view recreation
      slivers: [
        // Upcoming Events Section
        if (_upcomingEvents.isNotEmpty) ...[
          SliverToBoxAdapter(
            child: TweenAnimationBuilder<double>(
              key: ValueKey('upcoming-header-$animationKey'),
              duration: const Duration(milliseconds: 300), // Reduced from 500ms
              tween: Tween(begin: 0.0, end: 1.0),
              curve: Curves.easeOut,
              builder: (context, value, child) {
                return Transform.translate(
                  offset: Offset(0, 20 * (1 - value)),
                  child: Transform.scale(
                    scale: value,
                    child: Opacity(
                      opacity: value,
                      child: child,
                    ),
                  ),
                );
              },
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Row(
                  children: [
                    Icon(
                      Icons.upcoming,
                      color: theme.colorScheme.primary,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Upcoming Events',
                      style: TextStyle(
                        fontSize: 18 * fontScale,
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: TweenAnimationBuilder<double>(
              key: ValueKey('upcoming-carousel-$animationKey'),
              duration: const Duration(milliseconds: 400), // Reduced from 600ms
              tween: Tween(begin: 0.0, end: 1.0),
              curve: Curves.easeOut,
              builder: (context, value, child) {
                return Transform.translate(
                  offset: Offset(0, 20 * (1 - value)),
                  child: Transform.scale(
                    scale: value,
                    child: Opacity(
                      opacity: value,
                      child: child,
                    ),
                  ),
                );
              },
              child: SizedBox(
                height: 150,
                child: ListView.builder(
                  key: ValueKey('upcoming-list-$_animationKey'), // Key for list recreation
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  scrollDirection: Axis.horizontal,
                  itemCount: _upcomingEvents.length > 5 ? 5 : _upcomingEvents.length,
                  itemBuilder: (context, index) {
                    final event = _upcomingEvents[index];
                    return TweenAnimationBuilder<double>(
                      key: ValueKey('upcoming-item-$index-$_animationKey'), // Staggered key
                      duration: Duration(milliseconds: 250 + (index * 50)), // Reduced from 400 + index*80
                      tween: Tween(begin: 0.0, end: 1.0),
                      curve: Curves.easeOut,
                      builder: (context, itemValue, child) {
                        return Transform.translate(
                          offset: Offset(10 * (1 - itemValue), 0),
                          child: Transform.scale(
                            scale: itemValue,
                            child: Opacity(
                              opacity: itemValue,
                              child: child,
                            ),
                          ),
                        );
                      },
                      child: _buildUpcomingEventCard(event, fontScale, theme),
                    );
                  },
                ),
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 16)),
        ],

        // Selected Day Events Header
        SliverToBoxAdapter(
          child: TweenAnimationBuilder<double>(
            key: ValueKey('events-header-$animationKey'),
            duration: const Duration(milliseconds: 300), // Reduced from 500ms
            tween: Tween(begin: 0.0, end: 1.0),
            curve: Curves.easeOut,
            builder: (context, value, child) {
              return Transform.translate(
                offset: Offset(0, 20 * (1 - value)),
                child: Transform.scale(
                  scale: value,
                  child: Opacity(
                    opacity: value,
                    child: child,
                  ),
                ),
              );
            },
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: Row(
                children: [
                  Icon(
                    Icons.event,
                    color: theme.colorScheme.primary,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Events on ${intl.DateFormat('MMM d').format(_selectedDay)}',
                      style: TextStyle(
                        fontSize: 18 * fontScale,
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurface,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        // Selected Day Events List
        if (_selectedEvents.isEmpty)
          SliverFillRemaining(
            child: TweenAnimationBuilder<double>(
              key: ValueKey('empty-events-$animationKey'),
              duration: const Duration(milliseconds: 400), // Reduced from 600ms
              tween: Tween(begin: 0.0, end: 1.0),
              curve: Curves.easeOut,
              builder: (context, value, child) {
                return Transform.translate(
                  offset: Offset(0, 20 * (1 - value)),
                  child: Transform.scale(
                    scale: value,
                    child: Opacity(
                      opacity: value,
                      child: child,
                    ),
                  ),
                );
              },
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.event_busy,
                      size: 64,
                      color: theme.colorScheme.onSurface.withOpacity(0.3),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No events on this day',
                      style: TextStyle(
                        fontSize: 16 * fontScale,
                        color: theme.colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            sliver: SliverList(
              key: ValueKey('events-list-$_animationKey'), // Key for list recreation
              delegate: SliverChildBuilderDelegate(
                    (context, index) {
                  return TweenAnimationBuilder<double>(
                    key: ValueKey('event-item-$index-$_animationKey'), // Staggered key
                    duration: Duration(milliseconds: 250 + (index * 50)), // Reduced from 400 + index*80
                    tween: Tween(begin: 0.0, end: 1.0),
                    curve: Curves.easeOut,
                    builder: (context, itemValue, child) {
                      return Transform.translate(
                        offset: Offset(0, 10 * (1 - itemValue)),
                        child: Transform.scale(
                          scale: itemValue,
                          child: Opacity(
                            opacity: itemValue,
                            child: child,
                          ),
                        ),
                      );
                    },
                    child: IslamicEventCard(
                      event: _selectedEvents[index],
                      fontScale: fontScale,
                    ),
                  );
                },
                childCount: _selectedEvents.length,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildUpcomingEventCard(
      IslamicEvent event,
      double fontScale,
      ThemeData theme,
      ) {
    return Container(
      width: 200,
      margin: const EdgeInsets.only(right: 12),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            _onDaySelected(event.gregorianDate, event.gregorianDate);
          },
          child: Padding(
            padding: const EdgeInsets.all(12),
            // Make content scrollable
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          event.title,
                          style: TextStyle(
                            fontSize: 14 * fontScale,
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onSurface,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (event.isImportant)
                        Icon(
                          Icons.star,
                          color: Colors.amber[700],
                          size: 16,
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    intl.DateFormat('MMM d, yyyy').format(event.gregorianDate),
                    style: TextStyle(
                      fontSize: 12 * fontScale,
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    event.hijriDate.shortFormattedDate,
                    style: TextStyle(
                      fontSize: 11 * fontScale,
                      color: theme.colorScheme.onSurface.withOpacity(0.6),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (event.daysUntil > 0) ...[
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.secondary.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'In ${event.daysUntil} ${event.daysUntil == 1 ? 'day' : 'days'}',
                        style: TextStyle(
                          fontSize: 10 * fontScale,
                          color: theme.colorScheme.secondary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}