import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:provider/provider.dart';
import 'package:haptic_feedback/haptic_feedback.dart';

import '../../core/services/settings_service.dart';
import '../widgets/more_option_card.dart';

class MoreOptionsPage extends StatefulWidget {
  const MoreOptionsPage({super.key});

  @override
  State<MoreOptionsPage> createState() => _MoreOptionsPageState();
}

class _MoreOptionsPageState extends State<MoreOptionsPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late List<Animation<double>> _cardFadeAnimations;
  late List<Animation<double>> _cardScaleAnimations;
  late List<Animation<double>> _cardBounceAnimations;

  @override
  void initState() {
    super.initState();

    // Polished iOS-style and Origin OS 6-inspired bouncy animation with staggered card entrances
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1000), // Extended duration for longer, smoother fluidity
      vsync: this,
    );

    // Staggered animations for individual cards to enhance fluidity like Origin OS 6 layered reveals
    // Adjusted stagger and capped ends to ensure end <= 1.0 for all intervals to prevent assertion failure
    final stagger = 0.08; // Slightly increased stagger for more deliberate, smoother sequencing
    _cardFadeAnimations = List.generate(6, (index) {
      final begin = index * stagger;
      final end = math.min(1.0, 0.85 + (index * stagger)); // Cap end at 1.0
      return Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
          parent: _controller,
          curve: Interval(
            begin,
            end,
            curve: Curves.easeOutQuint, // Smoother easing curve for gradual fade
          ),
        ),
      );
    });

    _cardScaleAnimations = List.generate(6, (index) {
      final begin = 0.05 + (index * stagger);
      final end = math.min(1.0, 0.9 + (index * stagger)); // Cap end at 1.0
      return Tween<double>(begin: 0.9, end: 1.0).animate( // Slightly smaller initial scale for more pronounced bounce
        CurvedAnimation(
          parent: _controller,
          curve: Interval(
            begin,
            end,
            curve: Curves.elasticOut, // Bouncy elastic curve for enhanced Apple-like overshoot
          ),
        ),
      );
    });

    _cardBounceAnimations = List.generate(6, (index) {
      final begin = 0.1 + (index * stagger);
      final end = math.min(1.0, 0.95 + (index * stagger)); // Cap end at 1.0
      return Tween<double>(begin: 20.0, end: 0.0).animate( // Vertical bounce from below
        CurvedAnimation(
          parent: _controller,
          curve: Interval(
            begin,
            end,
            curve: Curves.elasticOut, // Sync with scale for cohesive bouncy effect
          ),
        ),
      );
    });

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  final List<Map<String, dynamic>> _moreOptions = [
    {
      'title': 'Rabbana Duas',
      'icon': Icons.menu_book_outlined,
      'color': Colors.green,
      'route': '/rabbanaDuas',
    },
    {
      'title': 'Darood',
      'icon': Icons.favorite_border,
      'color': Colors.red,
      'route': '/daroodIbrahim',
    },
    {
      'title': 'Niyat',
      'icon': Icons.mosque_outlined,
      'color': Colors.blue,
      'route': '/niyat',
    },
    {
      'title': 'Library',
      'icon': Icons.auto_stories,
      'color': Colors.purple,
      'route': '/library',
    },
    {
      'title': 'Quran & Science',
      'icon': Icons.science_outlined,
      'color': Colors.teal,
      'route': '/quranScience',
    },
    {
      'title': '99 Names',
      'icon': Icons.star_border,
      'color': Colors.amber,
      'route': '/allahNames',
    },
  ];

  void _showLanguageSelectionDialog(BuildContext context, String route, String title) {
    final double fontScale = Provider.of<SettingsService>(context, listen: false).fontScale;

    showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black54,
      builder: (BuildContext context) {
        return Center(
          child: Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            elevation: 16,
            insetPadding: const EdgeInsets.symmetric(horizontal: 24),
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.85,
                maxHeight: MediaQuery.of(context).size.height * 0.7,
              ),
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.language,
                        color: Theme.of(context).colorScheme.primary,
                        size: 28,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Select Language',
                        style: TextStyle(
                          fontSize: 22 * fontScale,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Flexible(
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildLanguageOption(
                            context: context,
                            language: 'English',
                            route: route,
                            title: title,
                            fontScale: fontScale,
                            isAvailable: true,
                          ),
                          const SizedBox(height: 12),
                          _buildLanguageOption(
                            context: context,
                            language: 'Assamese',
                            route: route,
                            title: title,
                            fontScale: fontScale,
                            isAvailable: true,
                          ),
                          const SizedBox(height: 12),
                          _buildLanguageOption(
                            context: context,
                            language: 'Hindi',
                            route: route,
                            title: title,
                            fontScale: fontScale,
                            isAvailable: true,
                          ),
                          const SizedBox(height: 12),
                          _buildLanguageOption(
                            context: context,
                            language: 'Bengali',
                            route: route,
                            title: title,
                            fontScale: fontScale,
                            isAvailable: true,
                          ),
                          const SizedBox(height: 12),
                          _buildLanguageOption(
                            context: context,
                            language: 'More Languages',
                            route: route,
                            title: title,
                            fontScale: fontScale,
                            isAvailable: false,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Cancel',
                        style: TextStyle(
                          fontSize: 16 * fontScale,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildLanguageOption({
    required BuildContext context,
    required String language,
    required String route,
    required String title,
    required double fontScale,
    required bool isAvailable,
  }) {
    final theme = Theme.of(context);

    return Material(
      color: isAvailable
          ? theme.colorScheme.primary.withOpacity(0.08)
          : Colors.grey.withOpacity(0.12),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: isAvailable
            ? () {
          Navigator.of(context).pop();
          Navigator.pushNamed(
            context,
            route,
            arguments: {
              'language': language.toLowerCase(),
              'title': title,
            },
          );
        }
            : null,
        borderRadius: BorderRadius.circular(16),
        splashColor: theme.colorScheme.primary.withOpacity(0.1),
        highlightColor: theme.colorScheme.primary.withOpacity(0.05),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isAvailable
                      ? theme.colorScheme.primary.withOpacity(0.15)
                      : Colors.grey.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.language,
                  color: isAvailable
                      ? theme.colorScheme.primary
                      : Colors.grey,
                  size: 22,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  language,
                  style: TextStyle(
                    fontSize: 16 * fontScale,
                    fontWeight: FontWeight.w600,
                    color: isAvailable
                        ? theme.colorScheme.onSurface
                        : Colors.grey,
                  ),
                ),
              ),
              if (!isAvailable)
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.lock_outline,
                    color: Colors.grey,
                    size: 18,
                  ),
                )
              else
                Icon(
                  Icons.arrow_forward_ios,
                  color: theme.colorScheme.primary.withOpacity(0.5),
                  size: 16,
                ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final double fontScale = Provider.of<SettingsService>(context).fontScale;
    final theme = Theme.of(context);
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Colors.green[50],
      appBar: AppBar(
        title: Text(
          'More Options',
          style: TextStyle(
            fontSize: (18 * fontScale).clamp(14.0, 22.0),
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: Colors.white,
        elevation: 2,
        centerTitle: true,
        shadowColor: Colors.black.withOpacity(0.2),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 12),
              _buildFeatureGrid(fontScale, theme, screenWidth),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureGrid(double fontScale, ThemeData theme, double screenWidth) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = screenWidth > 600 ? 3 : 2;
        double aspectRatio = (constraints.maxWidth / crossAxisCount) / 140;
        if (aspectRatio < 0.85) aspectRatio = 0.85;

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: aspectRatio,
          ),
          itemCount: _moreOptions.length,
          itemBuilder: (context, index) {
            final option = _moreOptions[index];
            // Individual card animations for staggered, polished reveal on visible background
            return AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return Opacity(
                  opacity: _cardFadeAnimations[index].value,
                  child: Transform.translate(
                    offset: Offset(0, _cardBounceAnimations[index].value), // Add vertical bounce
                    child: Transform.scale(
                      scale: _cardScaleAnimations[index].value,
                      child: MoreOptionCard(
                        title: option['title'],
                        icon: option['icon'],
                        color: option['color'],
                        fontScale: fontScale,
                        onTap: () => _showLanguageSelectionDialog(
                          context,
                          option['route'],
                          option['title'],
                        ),
                      ),
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}