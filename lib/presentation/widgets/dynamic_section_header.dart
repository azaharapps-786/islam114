// lib/presentation/widgets/dynamic_section_header.dart
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle, Clipboard, ClipboardData;
import 'package:provider/provider.dart';

import '../../core/services/settings_service.dart';

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

  // --- Animation State ---
  late AnimationController _controller;
  late Animation<double> _animation;
  bool _isExpanded = false;

  // Size Constants
  static const Duration _animationDuration = Duration(milliseconds: 400);
  static const double _collapsedHeight = 40.0;
  static const double _expandedHeight = 280.0;

  // REMOVED static const double _expandedWidth = 280.0; - This will be calculated dynamically

  // --- Data State ---
  Map<String, dynamic>? _randomVerse;
  bool _isLoading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    // Initialize Animation Controller
    _controller =
        AnimationController(vsync: this, duration: _animationDuration);
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
    _loadRandomVerse();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void reloadVerse() {
    _loadRandomVerse();
  }

  Future<void> _loadRandomVerse() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _hasError = false;
      _randomVerse = null;
    });

    try {
      final String jsonString = await rootBundle.loadString(
          'assets/data/quran_english.json');
      final List<dynamic> jsonData = json.decode(jsonString);

      if (jsonData.isNotEmpty) {
        final random = Random();
        final randomIndex = random.nextInt(jsonData.length);
        final selectedVerse = Map<String, dynamic>.from(jsonData[randomIndex]);

        if (mounted) {
          setState(() {
            _randomVerse = selectedVerse;
            _isLoading = false;
          });
        }
      } else {
        if (mounted) setState(() {
          _hasError = true;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading random verse: $e');
      if (mounted) setState(() {
        _hasError = true;
        _isLoading = false;
      });
    }
  }

  void _toggleExpansion() {
    // Only allow toggle if the verse is loaded or has an error
    // Note: The original Hadith header didn't check for verse data, only loading state.
    // Keeping your logic to prevent toggling if data is not available yet.
    if (_randomVerse != null || _hasError || _isLoading) {
      if (_isExpanded) {
        _controller.reverse();
      } else {
        _loadRandomVerse();
        _controller.forward();
      }

      setState(() {
        _isExpanded = !_isExpanded;
      });
    }
  }

  // --- Dynamic Island Content (Switches between Ayat Today Text and Full Verse) ---
  Widget _buildDynamicIslandContent(ThemeData theme) {
    const Color expandedTextColor = Colors.white;

    // Collapsed Content (Ayat Today text)
    // FIX: Changed the collapsed text color to white to match Hadith Today
    final collapsedContent = Center(
      child: Text(
        'Ayat Today',
        style: TextStyle(
          fontSize: 14 * widget.fontScale,
          fontWeight: FontWeight.bold,
          color: expandedTextColor, // Should be white to show up on the collapsed island color
        ),
      ),
    );

    // Expanded Content (Verse)
    Widget expandedContent;
    if (_isLoading) {
      expandedContent = const Center(
          child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2, color: expandedTextColor,)
          )
      );
    } else if (_hasError || _randomVerse == null) {
      expandedContent = Center(
        child: Text(
          'Error loading verse. Tap to retry.',
          style: TextStyle(
              fontSize: 14 * widget.fontScale, color: expandedTextColor),
        ),
      );
    } else {
      final verse = _randomVerse!;
      expandedContent = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Verse Reference and Close Button
          Padding(
            padding: const EdgeInsets.fromLTRB(16.0, 12.0, 16.0, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Random Verse: ${verse['sura']}:${verse['aya']}',
                  style: TextStyle(
                    fontSize: 14 * widget.fontScale,
                    fontWeight: FontWeight.bold,
                    color: expandedTextColor.withOpacity(0.8),
                  ),
                ),
                GestureDetector(
                  onTap: _toggleExpansion,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: expandedTextColor.withOpacity(0.2),
                    ),
                    child: const Icon(
                        Icons.close, size: 18, color: expandedTextColor),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // Scrollable Content Area (Arabic + Translation)
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Arabic Text
                  if (verse['arabic'] != null && verse['arabic'].isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: Text(
                        verse['arabic'],
                        style: TextStyle(
                          fontSize: 18 * widget.fontScale,
                          fontFamily: 'Uthmanic',
                          height: 1.5,
                          color: expandedTextColor,
                        ),
                        textAlign: TextAlign.right,
                        textDirection: TextDirection.rtl,
                      ),
                    ),

                  // Translation
                  Text(
                    '${verse['translation'] ?? 'No translation available.'}',
                    style: TextStyle(
                      fontSize: 14 * widget.fontScale,
                      fontStyle: FontStyle.italic,
                      color: expandedTextColor.withOpacity(0.8),
                    ),
                    maxLines: null,
                    overflow: TextOverflow.fade,
                  ),
                ],
              ),
            ),
          ),
          // Action Buttons
          Padding(
            padding: const EdgeInsets.fromLTRB(16.0, 0, 16.0, 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  icon: const Icon(
                      Icons.refresh, size: 18, color: expandedTextColor),
                  label: const Text(
                      'New Verse', style: TextStyle(color: expandedTextColor)),
                  onPressed: _loadRandomVerse,
                ),
                const SizedBox(width: 8),
                TextButton.icon(
                  icon: const Icon(
                      Icons.copy, size: 18, color: expandedTextColor),
                  label: const Text(
                      'Copy', style: TextStyle(color: expandedTextColor)),
                  onPressed: () {
                    final text = 'Surah ${verse['sura']}:${verse['aya']}\n${verse['arabic']}\n${verse['translation']}';
                    Clipboard.setData(ClipboardData(text: text));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Verse copied')),
                    );
                  },
                ),
              ],
            ),
          )
        ],
      );
    }

    // Use AnimatedSwitcher to smoothly transition content
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 250),
      transitionBuilder: (Widget child, Animation<double> animation) {
        return FadeTransition(
          opacity: animation,
          child: child,
        );
      },
      child: _isExpanded
          ? KeyedSubtree(
          key: const ValueKey('expanded_content'), child: expandedContent)
          : KeyedSubtree(
          key: const ValueKey('collapsed_content'), child: collapsedContent),
    );
  }

  // Helper widget to hold the actual title structure
  Widget _getTitleContent(ThemeData theme) {
    // Width property is controlled by the parent AnimatedBuilder
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.book_outlined,
              color: theme.colorScheme.primary,
              size: 24 * widget.fontScale,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                widget.title, // "Holy Quran"
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
          thickness: 1,
        ),
      ],
    );
  }


  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenWidth = MediaQuery
        .of(context)
        .size
        .width;
    final double paddingHorizontal = 16.0;

    // Fixed constant for the title's maximum reserved space
    final double titleMaxWidth = 200.0 * widget.fontScale;
    const double spaceBetween = 8.0; // A small assumed space if not using spaceBetween

    // Using theme colors (as defined in the previous solution)
    final Color islandCollapsedColor = theme.colorScheme.primary.withOpacity(
        0.8);
    const Color islandExpandedColor = Colors.black;

    // Define the required width for the collapsed state
    const double collapsedIslandWidth = 120.0;

    return Padding(
      padding: EdgeInsets.symmetric(
          horizontal: paddingHorizontal, vertical: 8.0),
      child: AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          // 1. Calculate the current width of the shrinking title element
          // The title shrinks from titleMaxWidth down to 0.0 using ReverseAnimation.
          final double titleShrinkFactor = ReverseAnimation(_animation).value;
          final double currentTitleWidth = titleMaxWidth * titleShrinkFactor;

          // 2. Calculate the total available width for the island
          // Total space in the Row (ScreenWidth - 2*Padding)
          // minus the current space taken by the Title and the fixed gap.
          final double maxRowWidth = screenWidth - (paddingHorizontal * 2);

          // The space consumed by the title and the small gap in the expanded state is 0.
          // In the collapsed state, the island only occupies collapsedIslandWidth.

          // We must define the maximum target width the island can reach.
          // When expanded (animation.value = 1), currentTitleWidth is nearly 0.
          final double targetExpandedWidth = maxRowWidth - currentTitleWidth -
              (spaceBetween * (1 - _animation.value));

          // Interpolate current island width:
          // Start: collapsedIslandWidth
          // End (capped): targetExpandedWidth (which should be close to maxRowWidth)

          // Interpolate the width from collapsed size to the calculated available space
          final double currentIslandWidth = Tween<double>(
              begin: collapsedIslandWidth,
              end: targetExpandedWidth
          ).evaluate(_animation);

          // Ensure the island doesn't shrink smaller than its collapsed size
          final double finalIslandWidth = max(
              collapsedIslandWidth, currentIslandWidth);


          // Animate height and border radius (these are fine)
          final double currentHeight = Tween<double>(
              begin: _collapsedHeight, end: _expandedHeight).evaluate(
              _animation);
          final double currentRadius = Tween<double>(
              begin: _collapsedHeight / 2, end: 20.0).evaluate(_animation);
          final Color blendedColor = Color.lerp(
              islandCollapsedColor, islandExpandedColor, _animation.value)!;


          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Static Title Part (Left side - Shrinks and disappears)
              // We reuse the animation values calculated above
              SizeTransition(
                sizeFactor: ReverseAnimation(_animation),
                // Shrink when animation forwards
                axis: Axis.horizontal,
                child: SizedBox(
                  width: titleMaxWidth, // Use the max width here
                  child: Opacity(
                    opacity: 1.0 - _animation.value, // Fade out as it shrinks
                    child: Transform.scale(
                      scale: 1.0 - _animation.value,
                      alignment: Alignment.centerLeft,
                      child: _getTitleContent(theme),
                    ),
                  ),
                ),
              ),

              // 2. Dynamic Island Part (Right side - Expands/Contracts)
              // NOTE: The `AnimatedBuilder` for the island is now the outer one.
              GestureDetector(
                onTap: _toggleExpansion,
                child: Container(
                  height: currentHeight,
                  width: finalIslandWidth, // Use the calculated width

                  decoration: BoxDecoration(
                    color: blendedColor,
                    borderRadius: BorderRadius.circular(currentRadius),
                    boxShadow: [
                      BoxShadow(
                        color: islandExpandedColor.withOpacity(
                            _animation.value * 0.4),
                        blurRadius: 12 * _animation.value,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: _buildDynamicIslandContent(theme),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}