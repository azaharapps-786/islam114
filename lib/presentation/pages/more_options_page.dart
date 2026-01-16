import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:haptic_feedback/haptic_feedback.dart';
import '../../core/services/settings_service.dart';
import '../widgets/more_option_card.dart';

class MoreOptionsPage extends StatefulWidget {
  const MoreOptionsPage({super.key});

  @override
  State<MoreOptionsPage> createState() => _MoreOptionsPageState();
}

class _MoreOptionsPageState extends State<MoreOptionsPage> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late List<Animation<double>> _cardFadeAnimations;
  late List<Animation<double>> _cardScaleAnimations;
  late List<Animation<double>> _cardBounceAnimations;
  String _selectedLanguage = 'english'; // default

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    const stagger = 0.08;
    _cardFadeAnimations = List.generate(7, (index) {
      final begin = index * stagger;
      final end = math.min(1.0, 0.85 + (index * stagger));
      return Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
          parent: _controller,
          curve: Interval(begin, end, curve: Curves.easeOutQuint),
        ),
      );
    });
    _cardScaleAnimations = List.generate(7, (index) {
      final begin = 0.05 + (index * stagger);
      final end = math.min(1.0, 0.9 + (index * stagger));
      return Tween<double>(begin: 0.9, end: 1.0).animate(
        CurvedAnimation(
          parent: _controller,
          curve: Interval(begin, end, curve: Curves.elasticOut),
        ),
      );
    });
    _cardBounceAnimations = List.generate(7, (index) {
      final begin = 0.1 + (index * stagger);
      final end = math.min(1.0, 0.95 + (index * stagger));
      return Tween<double>(begin: 20.0, end: 0.0).animate(
        CurvedAnimation(
          parent: _controller,
          curve: Interval(begin, end, curve: Curves.elasticOut),
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
      'icon': Icons.menu_book_rounded,
      'color': Colors.green,
      'route': '/rabbanaDuas'
    },
    {
      'title': 'Darood',
      'icon': Icons.favorite_rounded,
      'color': Colors.redAccent,
      'route': '/darood',
    },
    {
      'title': 'Niyat',
      'icon': Icons.mosque_rounded,
      'color': Colors.blueAccent,
      'route': '/niyat'
    },
    {
      'title': 'Library',
      'icon': Icons.library_books_rounded,
      'color': Colors.purpleAccent,
      'route': '/library'
    },
    {
      'title': 'Quran & Science',
      'icon': Icons.biotech_rounded,
      'color': Colors.teal,
      'route': '/quranScience'
    },
    {
      'title': '99 Names',
      'icon': Icons.auto_awesome_rounded,
      'color': Colors.amber,
      'route': '/allahNames'
    },
    {
      'title': 'Amal Namah',
      'icon': Icons.book_rounded,
      'color': Colors.orange[700],
      'route': '/amalNamah',
      'skipLanguageDialog': true,
    },
  ];

  void _showLanguageSelectionDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Select Language'),
        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ...['english', 'assamese', 'hindi', 'bengali'].map((lang) {
              final isSelected = lang == _selectedLanguage;
              return ListTile(
                dense: true,
                leading: Icon(
                  isSelected ? Icons.check_circle : Icons.translate,
                  color: isSelected ? Theme.of(context).colorScheme.primary : null,
                ),
                title: Text(
                  lang[0].toUpperCase() + lang.substring(1),
                  style: TextStyle(
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                onTap: () {
                  Haptics.vibrate(HapticsType.light);
                  setState(() => _selectedLanguage = lang);
                  Navigator.pop(context);
                },
              );
            }),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final double fontScale = Provider.of<SettingsService>(context).fontScale;
    final theme = Theme.of(context);
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF0A4D4D),
              Color(0xFF0E7A6E),
              Color(0xFF1A9C8A),
              Color(0xFFE8F5E9),
            ],
            stops: [0.0, 0.3, 0.7, 1.0],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              Column(
                children: [
                  AppBar(
                    title: Text(
                      'More Options',
                      style: TextStyle(
                        fontSize: (18 * fontScale).clamp(14.0, 22.0),
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    backgroundColor: Colors.transparent,
                    elevation: 0,
                    centerTitle: true,
                    flexibleSpace: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            const Color(0xFF0A4D4D),
                            const Color(0xFF0E7A6E).withOpacity(0.9),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Expanded(
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
                ],
              ),
              Positioned(
                right: 24,
                bottom: 32,
                child: FloatingActionButton.extended(
                  onPressed: () {
                    Haptics.vibrate(HapticsType.light);
                    _showLanguageSelectionDialog(context);
                  },
                  label: Text(
                    'Language: ${_selectedLanguage[0].toUpperCase() + _selectedLanguage.substring(1)}',
                    style: TextStyle(
                      fontSize: (14 * fontScale).clamp(12.0, 16.0),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  icon: const Icon(Icons.translate_rounded, size: 20),
                  backgroundColor: Colors.white.withOpacity(0.92),
                  foregroundColor: const Color(0xFF0A4D4D),
                  elevation: 6,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(32),
                  ),
                ),
              ),
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
            return AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return Opacity(
                  opacity: _cardFadeAnimations[index].value,
                  child: Transform.translate(
                    offset: Offset(0, _cardBounceAnimations[index].value),
                    child: Transform.scale(
                      scale: _cardScaleAnimations[index].value,
                      child: MoreOptionCard(
                        title: option['title'],
                        icon: option['icon'],
                        color: option['color'],
                        fontScale: fontScale,
                        onTap: () {
                          final bool skipDialog = option['skipLanguageDialog'] == true;
                          if (skipDialog) {
                            Navigator.pushNamed(
                              context,
                              option['route'],
                              arguments: {
                                'language': 'english',
                                'title': option['title'],
                              },
                            );
                          } else {
                            Navigator.pushNamed(
                              context,
                              option['route'],
                              arguments: {
                                'language': _selectedLanguage,
                                'title': option['title'],
                              },
                            );
                          }
                        },
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