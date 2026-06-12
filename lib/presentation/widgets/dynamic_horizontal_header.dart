// lib/presentation/widgets/dynamic_horizontal_header.dart
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/providers/prayer_times_provider.dart';

class DynamicHorizontalHeader extends StatefulWidget {
  final String title;
  final double fontScale;
  final ThemeData theme;

  const DynamicHorizontalHeader({
    super.key,
    required this.title,
    required this.fontScale,
    required this.theme,
  });

  @override
  State<DynamicHorizontalHeader> createState() => _DynamicHorizontalHeaderState();
}

class _DynamicHorizontalHeaderState extends State<DynamicHorizontalHeader>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  bool _isExpanded = false;

  static const Duration _animationDuration = Duration(milliseconds: 350);
  static const double _collapsedHeight = 40.0;
  static const double _expandedHeight = 220.0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: _animationDuration);
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggleExpansion() {
    if (_isExpanded) {
      _controller.reverse();
    } else {
      _controller.forward();
    }
    setState(() => _isExpanded = !_isExpanded);
  }

  void _goToPrayerTimes() {
    Navigator.pushNamed(context, '/namaz');
    _controller.reverse();
    setState(() => _isExpanded = false);
  }

  /// Dampened font scale for island internals.
  /// Maps user fontScale ~[0.8..1.5] → island fs ~[0.85..1.1]
  /// so content never outgrows the fixed-height container.
  double get _islandFs {
    return max(0.85, min(1.1, 0.85 + (widget.fontScale - 0.8) * 0.25));
  }

  String _formatTime(String? time24) {
    if (time24 == null || time24.isEmpty) return '--:--';
    try {
      final parts = time24.split(':');
      final hour = int.parse(parts[0]);
      final minute = parts[1];
      final hour12 = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
      final ampm = hour >= 12 ? 'PM' : 'AM';
      return '$hour12:$minute $ampm';
    } catch (_) {
      return time24;
    }
  }

  String _getCountdown(String? time24) {
    if (time24 == null || time24.isEmpty) return 'Calculating...';
    try {
      final parts = time24.split(':');
      final hour = int.parse(parts[0]);
      final minute = int.parse(parts[1]);

      final now = DateTime.now();
      var prayerDateTime = DateTime(now.year, now.month, now.day, hour, minute);

      if (prayerDateTime.isBefore(now)) {
        prayerDateTime = prayerDateTime.add(const Duration(days: 1));
      }

      final diff = prayerDateTime.difference(now);
      final hours = diff.inHours;
      final minutes = diff.inMinutes.remainder(60);

      if (hours > 0) {
        return '${hours}h ${minutes}m remaining';
      }
      return '${minutes}m remaining';
    } catch (_) {
      return 'Calculating...';
    }
  }

  IconData _getPrayerIcon(String? prayerName) {
    switch (prayerName?.toLowerCase()) {
      case 'fajr':
        return Icons.nightlight_round;
      case 'dhuhr':
      case 'zuhr':
        return Icons.wb_sunny;
      case 'asr':
        return Icons.wb_twilight;
      case 'maghrib':
        return Icons.nights_stay;
      case 'isha':
        return Icons.dark_mode;
      case 'tahajjud':
        return Icons.bedtime;
      default:
        return Icons.access_time;
    }
  }

  Widget _buildCollapsedContent() {
    final fs = _islandFs;
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.mosque, color: Colors.white, size: 16 * fs),
          const SizedBox(width: 5),
          Text(
            'Next Prayer',
            style: TextStyle(
              fontSize: 12 * fs,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExpandedContent(double availableWidth) {
    final prayerProvider = Provider.of<PrayerTimesProvider>(context);
    final nextPrayer = prayerProvider.nextPrayer;
    final nextPrayerName = nextPrayer?.name;
    final nextPrayerTimeStr = nextPrayer?.time;
    final fs = _islandFs;

    return FittedBox(
      fit: BoxFit.scaleDown,
      child: SizedBox(
        width: availableWidth,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── Top row: label + close ──
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Upcoming Prayer',
                    style: TextStyle(
                      fontSize: 10 * fs,
                      color: Colors.white.withOpacity(0.7),
                    ),
                  ),
                  GestureDetector(
                    onTap: _toggleExpansion,
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.2),
                      ),
                      child: const Icon(Icons.close, size: 14, color: Colors.white),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // ── Prayer icon + name + time ──
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      _getPrayerIcon(nextPrayerName),
                      color: Colors.white,
                      size: 24 * fs,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          nextPrayerName ?? 'Loading...',
                          style: TextStyle(
                            fontSize: 17 * fs,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 1),
                        Text(
                          _formatTime(nextPrayerTimeStr),
                          style: TextStyle(
                            fontSize: 12 * fs,
                            color: Colors.white.withOpacity(0.8),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // ── Countdown bar ──
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.hourglass_top,
                      color: Colors.white.withOpacity(0.7),
                      size: 14 * fs,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      _getCountdown(nextPrayerTimeStr),
                      style: TextStyle(
                        fontSize: 12 * fs,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),

              // ── Action button ──
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _goToPrayerTimes,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  icon: const Icon(Icons.schedule, color: Color(0xFF2E7D32), size: 16),
                  label: const Text(
                    'View All Times',
                    style: TextStyle(color: Color(0xFF2E7D32), fontSize: 12),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final double maxIslandWidth = screenWidth - 32.0;

    final Gradient dynamicGradient = LinearGradient(
      colors: [
        widget.theme.colorScheme.tertiary.withOpacity(0.9),
        widget.theme.colorScheme.primary,
      ],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );

    return Padding(
      padding: const EdgeInsets.only(left: 16.0, right: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Left: title column (shrinks on expand) ──
          ListenableBuilder(
            listenable: _animation,
            builder: (context, child) {
              final double scale =
              Tween<double>(begin: 1.0, end: 0.0).evaluate(_animation);
              final double opacity =
              Tween<double>(begin: 1.0, end: 0.0).evaluate(_animation);

              return SizeTransition(
                sizeFactor: ReverseAnimation(_animation),
                axis: Axis.horizontal,
                child: SizedBox(
                  width: 200.0 * widget.fontScale,
                  child: Opacity(
                    opacity: opacity,
                    child: Transform.scale(
                      scale: scale,
                      alignment: Alignment.centerLeft,
                      child: child,
                    ),
                  ),
                ),
              );
            },
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.menu_book,
                        color: widget.theme.colorScheme.onSurface,
                        size: 22 * widget.fontScale),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        widget.title,
                        style: TextStyle(
                          fontSize: 22 * widget.fontScale,
                          fontWeight: FontWeight.bold,
                          color: widget.theme.colorScheme.onSurface,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Divider(
                    height: 1,
                    color: widget.theme.colorScheme.onSurface.withOpacity(0.1),
                    thickness: 1),
              ],
            ),
          ),

          // ── Right: dynamic island ──
          GestureDetector(
            onTap: _toggleExpansion,
            child: ListenableBuilder(
              listenable: _animation,
              builder: (context, child) {
                final double targetWidth = min(380.0, maxIslandWidth);
                final double currentHeight =
                Tween<double>(begin: _collapsedHeight, end: _expandedHeight)
                    .evaluate(_animation);
                final double currentWidth =
                Tween<double>(begin: 140.0, end: targetWidth)
                    .evaluate(_animation);
                final double currentRadius =
                Tween<double>(begin: _collapsedHeight / 2, end: 20.0)
                    .evaluate(_animation);

                return Container(
                  height: currentHeight,
                  width: currentWidth,
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    gradient: dynamicGradient,
                    borderRadius: BorderRadius.circular(currentRadius),
                    boxShadow: [
                      BoxShadow(
                        color: widget.theme.colorScheme.primary
                            .withOpacity(_animation.value * 0.4),
                        blurRadius: 12 * _animation.value,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    child: _isExpanded
                        ? KeyedSubtree(
                      key: const ValueKey('expanded'),
                      child: _buildExpandedContent(currentWidth),
                    )
                        : KeyedSubtree(
                      key: const ValueKey('collapsed'),
                      child: _buildCollapsedContent(),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}