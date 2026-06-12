// lib/presentation/widgets/dynamic_section_header.dart
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/services/settings_service.dart';
import 'package:islam114/main.dart';

class DynamicSectionHeader extends StatefulWidget {
  final String title;
  final double fontScale;

  const DynamicSectionHeader({
    super.key,
    required this.title,
    required this.fontScale,
  });

  @override
  State<DynamicSectionHeader> createState() => _DynamicSectionHeaderState();
}

class _DynamicSectionHeaderState extends State<DynamicSectionHeader>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  bool _isExpanded = false;

  static const Duration _animationDuration = Duration(milliseconds: 400);
  static const double _collapsedHeight = 40.0;
  static const double _expandedHeight = 180.0;

  Map<String, dynamic>? _lastReadMark;

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
      final settings = Provider.of<SettingsService>(context, listen: false);
      final marks = settings.lastReadMarks;

      Map<String, dynamic>? mostRecent;
      int? latestTimestamp;

      for (final entry in marks.entries) {
        final type = entry.value['type'];
        if (type == 'quran' || type == 'quran_tafseer') {
          final timestamp = entry.value['timestamp'] as int? ?? 0;
          if (latestTimestamp == null || timestamp > latestTimestamp) {
            latestTimestamp = timestamp;
            mostRecent = entry.value;
          }
        }
      }

      setState(() {
        _lastReadMark = mostRecent;
      });
      _controller.forward();
    }
    setState(() => _isExpanded = !_isExpanded);
  }

  void _continueReading() {
    if (_lastReadMark == null) {
      Navigator.pushNamed(
        context,
        '/surahDetail',
        arguments: {
          'surahNumber': 1,
          'language': Provider.of<SettingsService>(context, listen: false).selectedLanguage,
          'isTafseer': false,
        },
      );
    } else {
      Navigator.pushNamed(
        context,
        '/surahDetail',
        arguments: {
          'surahNumber': _lastReadMark!['surahNumber'],
          'language': _lastReadMark!['language'] ?? 'english',
          'isTafseer': _lastReadMark!['isTafseer'] ?? false,
          'initialVerse': _lastReadMark!['itemNumber'],
        },
      );
    }
    _controller.reverse();
    setState(() => _isExpanded = false);
  }

  /// Dampened font scale for island internals.
  /// Maps user fontScale ~[0.8..1.5] → island fs ~[0.85..1.1]
  double get _islandFs {
    return max(0.85, min(1.1, 0.85 + (widget.fontScale - 0.8) * 0.25));
  }

  Widget _buildCollapsedContent() {
    final fs = _islandFs;
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.menu_book, color: Colors.white, size: 16 * fs),
          const SizedBox(width: 5),
          Text(
            'Continue Reading',
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
    const Color textColor = Colors.white;
    final fs = _islandFs;

    Widget inner;
    if (_lastReadMark == null) {
      // ── No last-read mark: start journey prompt ──
      inner = Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.auto_stories,
                color: textColor.withOpacity(0.8), size: 32 * fs),
            const SizedBox(height: 8),
            Text(
              'Start Your Quran Journey',
              style: TextStyle(
                fontSize: 14 * fs,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              'Begin from Al-Fatiha (Surah 1)',
              style: TextStyle(
                fontSize: 11 * fs,
                color: textColor.withOpacity(0.7),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _continueReading,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                icon: const Icon(Icons.play_arrow,
                    color: Color(0xFF2E7D32), size: 16),
                label: const Text('Start Reading',
                    style:
                    TextStyle(color: Color(0xFF2E7D32), fontSize: 12)),
              ),
            ),
          ],
        ),
      );
    } else {
      // ── Has last-read mark: resume prompt ──
      final surahNum = _lastReadMark!['surahNumber'];
      final verseNum = _lastReadMark!['itemNumber'];
      final surahName = _lastReadMark!['itemName'] ?? 'Surah $surahNum';
      final isTafseer = _lastReadMark!['isTafseer'] ?? false;

      inner = Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Top row: type label + close
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  isTafseer ? 'Tafseer' : 'Quran',
                  style: TextStyle(
                    fontSize: 10 * fs,
                    color: textColor.withOpacity(0.7),
                  ),
                ),
                GestureDetector(
                  onTap: _toggleExpansion,
                  child: Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: textColor.withOpacity(0.2),
                    ),
                    child:
                    const Icon(Icons.close, size: 14, color: textColor),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),

            // Surah name
            Text(
              surahName,
              style: TextStyle(
                fontSize: 15 * fs,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),

            // Verse info
            Text(
              'Last read: Verse $verseNum',
              style: TextStyle(
                fontSize: 12 * fs,
                color: textColor.withOpacity(0.8),
              ),
            ),
            const SizedBox(height: 10),

            // Continue button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _continueReading,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                icon: const Icon(Icons.play_arrow,
                    color: Color(0xFF2E7D32), size: 16),
                label: const Text('Continue',
                    style:
                    TextStyle(color: Color(0xFF2E7D32), fontSize: 12)),
              ),
            ),
          ],
        ),
      );
    }

    return FittedBox(
      fit: BoxFit.scaleDown,
      child: SizedBox(width: availableWidth, child: inner),
    );
  }

  Widget _getTitleContent(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.book_outlined,
                color: theme.colorScheme.primary, size: 24 * widget.fontScale),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                widget.title,
                style: TextStyle(
                  fontSize: 22 * widget.fontScale,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
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
            color: theme.colorScheme.onSurface.withOpacity(0.1),
            thickness: 1),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final double paddingHorizontal = 16.0;
    final double titleMaxWidth = 200.0 * widget.fontScale;
    const double collapsedIslandWidth = 160.0;

    final Gradient dynamicGradient = LinearGradient(
      colors: [
        theme.colorScheme.tertiary.withOpacity(0.9),
        theme.colorScheme.primary,
      ],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: paddingHorizontal, vertical: 8.0),
      child: ListenableBuilder(
        listenable: _animation,
        builder: (context, child) {
          final double titleShrinkFactor =
              ReverseAnimation(_animation).value;
          final double currentTitleWidth = titleMaxWidth * titleShrinkFactor;
          final double maxRowWidth =
              screenWidth - (paddingHorizontal * 2);
          final double targetExpandedWidth =
              maxRowWidth - currentTitleWidth;
          final double currentIslandWidth = Tween<double>(
            begin: collapsedIslandWidth,
            end: targetExpandedWidth,
          ).evaluate(_animation);
          final double finalIslandWidth =
          max(collapsedIslandWidth, currentIslandWidth);
          final double currentHeight =
          Tween<double>(begin: _collapsedHeight, end: _expandedHeight)
              .evaluate(_animation);
          final double currentRadius =
          Tween<double>(begin: _collapsedHeight / 2, end: 20.0)
              .evaluate(_animation);

          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Left: title (shrinks on expand) ──
              SizeTransition(
                sizeFactor: ReverseAnimation(_animation),
                axis: Axis.horizontal,
                child: SizedBox(
                  width: titleMaxWidth,
                  child: Opacity(
                    opacity: 1.0 - _animation.value,
                    child: Transform.scale(
                      scale: 1.0 - _animation.value,
                      alignment: Alignment.centerLeft,
                      child: _getTitleContent(theme),
                    ),
                  ),
                ),
              ),

              // ── Right: dynamic island ──
              GestureDetector(
                onTap: _toggleExpansion,
                child: Container(
                  height: currentHeight,
                  width: finalIslandWidth,
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    gradient: dynamicGradient,
                    borderRadius: BorderRadius.circular(currentRadius),
                    boxShadow: [
                      BoxShadow(
                        color: theme.colorScheme.primary
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
                      child: _buildExpandedContent(finalIslandWidth),
                    )
                        : KeyedSubtree(
                      key: const ValueKey('collapsed'),
                      child: _buildCollapsedContent(),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}