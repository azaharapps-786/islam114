// lib/presentation/widgets/dynamic_horizontal_header.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'dart:convert';
import 'dart:math';

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

  // Hadith Data Fields
  List<dynamic> _hadiths = [];
  Map<String, dynamic>? _currentHadith;
  bool _isLoading = true;

  // Animation Fields
  late AnimationController _controller;
  late Animation<double> _animation;
  bool _isExpanded = false;

  // Size Constants
  static const Duration _animationDuration = Duration(milliseconds: 350);
  static const double _collapsedHeight = 40.0;

  // Increased size constants
  static const double _expandedHeight = 320.0;
  static const double _expandedWidth = 400.0;


  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: _animationDuration);
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
    _loadHadithData();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // --- Data Loading & Selection (No changes) ---

  Future<void> _loadHadithData() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final String jsonString = await rootBundle.loadString('assets/data/sahih_al_bukhari.json');
      final Map<String, dynamic> data = json.decode(jsonString);

      _hadiths = data['hadiths'] ?? [];

      setState(() {
        _isLoading = false;
        _selectRandomHadith();
      });

    } catch (e) {
      debugPrint('Error loading Hadith data: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _currentHadith = {'english': 'Failed to load Hadith data.', 'number': 0};
        });
      }
    }
  }

  void _selectRandomHadith() {
    if (_hadiths.isNotEmpty) {
      final random = Random();
      final index = random.nextInt(_hadiths.length);
      setState(() {
        _currentHadith = _hadiths[index];
      });
    } else {
      setState(() {
        _currentHadith = {'english': 'Hadith list is empty.', 'number': 0};
      });
    }
  }

  void _toggleExpansion() {
    if (_isLoading) return;

    if (_isExpanded) {
      _controller.reverse();
    } else {
      _selectRandomHadith();
      _controller.forward();
    }

    setState(() {
      _isExpanded = !_isExpanded;
    });
  }

  // --- Widget Builders (No changes) ---

  Widget _buildContent() {
    if (_isLoading) {
      return Center(
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
          ),
        ),
      );
    }

    final hadithNumber = _currentHadith?['number']?.toString() ?? 'N/A';
    final hadithText = _currentHadith?['english']?.toString() ?? 'No text available.';
    final hadithAr = _currentHadith?['arabic']?.toString() ?? 'N/A';

    // Content for the expanded island
    final expandedContent = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Arabic Text (Optional, small preview)
          if (hadithAr.isNotEmpty)
            Text(
              hadithAr,
              style: TextStyle(
                fontSize: 16 * widget.fontScale,
                color: Colors.white.withOpacity(0.9),
                fontFamily: 'Uthmanic',
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.right,
            ),
          const SizedBox(height: 8),

          // English Hadith Text
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Text(
                hadithText,
                style: TextStyle(
                  fontSize: 14 * widget.fontScale,
                  color: Colors.white,
                  height: 1.5,
                  fontStyle: FontStyle.italic,
                ),
                maxLines: null,
                overflow: TextOverflow.fade,
              ),
            ),
          ),
          const SizedBox(height: 8),
          // Hadith Number
          Text(
            'Sahih al-Bukhari | Hadith No: $hadithNumber',
            style: TextStyle(
              fontSize: 10 * widget.fontScale,
              fontWeight: FontWeight.w600,
              color: Colors.white.withOpacity(0.7),
            ),
            textAlign: TextAlign.end,
          ),
        ],
      ),
    );

    // Content for the collapsed title (Simple indicator)
    final collapsedContent = Center(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.format_quote,
            color: Colors.white,
            size: 20 * widget.fontScale,
          ),
          const SizedBox(width: 8),
          Text(
            'Hadith Today',
            style: TextStyle(
              fontSize: 14 * widget.fontScale,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );

    // Use AnimatedSwitcher for smooth content transition
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 250),
      transitionBuilder: (Widget child, Animation<double> animation) {
        return FadeTransition(
          opacity: animation,
          child: child,
        );
      },
      child: _isExpanded
          ? KeyedSubtree(key: const ValueKey('expanded_hadith'), child: expandedContent)
          : KeyedSubtree(key: const ValueKey('collapsed_hadith_title'), child: collapsedContent),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Determine the available width for the Dynamic Island
    final screenWidth = MediaQuery.of(context).size.width;
    final double maxIslandWidth = screenWidth - 32.0;

    // Define the color gradient for the expanded island
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
          // 1. Static Title Part (Left side - Shrinks and disappears)
          AnimatedBuilder(
            animation: _animation,
            builder: (context, child) {

              final double scale = Tween<double>(begin: 1.0, end: 0.0).evaluate(_animation);
              final double opacity = Tween<double>(begin: 1.0, end: 0.0).evaluate(_animation);

              return SizeTransition(
                sizeFactor: ReverseAnimation(_animation), // Shrink when animation forwards
                axis: Axis.horizontal,
                child: SizedBox(
                  // *** INCREASED WIDTH HERE TO PREVENT TRUNCATION ***
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
            // The structure for "Tools & More" title
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.menu_book,
                      color: widget.theme.colorScheme.onSurface,
                      size: 22 * widget.fontScale,
                    ),
                    const SizedBox(width: 8),
                    // Use Expanded to ensure the title takes up the remaining space without wrapping prematurely
                    Expanded(
                      child: Text(
                        widget.title, // "Tools & More"
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
                  thickness: 1,
                  indent: 0,
                  endIndent: 0,
                ),
              ],
            ),
          ),

          // 2. Dynamic Island Part (Right side - Expands/Contracts)
          GestureDetector(
            onTap: _toggleExpansion,
            child: AnimatedBuilder(
              animation: _animation,
              builder: (context, child) {
                // Determine the target width, capping it at the available screen space
                final double targetWidth = min(_expandedWidth, maxIslandWidth);

                // Animate height and width
                final double currentHeight = Tween<double>(begin: _collapsedHeight, end: _expandedHeight).evaluate(_animation);
                // Animate the width from collapsed (140.0) to the target width
                final double currentWidth = Tween<double>(begin: 140.0, end: targetWidth).evaluate(_animation);
                final double currentRadius = Tween<double>(begin: _collapsedHeight / 2, end: 20.0).evaluate(_animation);

                return Container(
                  height: currentHeight,
                  width: currentWidth,

                  decoration: BoxDecoration(
                    gradient: dynamicGradient,
                    borderRadius: BorderRadius.circular(currentRadius),
                    boxShadow: [
                      BoxShadow(
                        color: widget.theme.colorScheme.primary.withOpacity(_animation.value * 0.4),
                        blurRadius: 12 * _animation.value,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: child,
                );
              },
              child: _buildContent(),
            ),
          ),
        ],
      ),
    );
  }
}