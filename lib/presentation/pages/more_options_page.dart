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

    _controller = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    const stagger = 0.08;

    // 7 cards including Amal Namah
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
    {'title': 'Rabbana Duas', 'icon': Icons.menu_book_outlined, 'color': Colors.green, 'route': '/rabbanaDuas'},
    {'title': 'Darood', 'icon': Icons.favorite_border, 'color': Colors.red, 'route': '/daroodIbrahim'},
    {'title': 'Niyat', 'icon': Icons.mosque_outlined, 'color': Colors.blue, 'route': '/niyat'},
    {'title': 'Library', 'icon': Icons.auto_stories, 'color': Colors.purple, 'route': '/library'},
    {'title': 'Quran & Science', 'icon': Icons.science_outlined, 'color': Colors.teal, 'route': '/quranScience'},
    {'title': '99 Names', 'icon': Icons.star_border, 'color': Colors.amber, 'route': '/allahNames'},
    {
      'title': 'Amal Namah',
      'icon': Icons.book_outlined,
      'color': Colors.orange[700],
      'route': '/amalNamah',
      'skipLanguageDialog': true, // ← This tells the app to skip the dialog for this card
    },
  ];

  void _showLanguageSelectionDialog(BuildContext context, String route, String title) {
    showGeneralDialog(
      context: context,
      barrierLabel: 'Language Selection',
      barrierDismissible: true,
      barrierColor: Colors.black.withOpacity(0.5),
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, animation1, animation2) {
        return _MoreOptionsLanguageDialog(route: route, title: title);
      },
      transitionBuilder: (context, animation1, animation2, child) {
        return FadeTransition(
          opacity: CurvedAnimation(
            parent: animation1,
            curve: const Interval(0.0, 1.0, curve: Curves.easeOut),
          ),
          child: ScaleTransition(
            scale: CurvedAnimation(
              parent: animation1,
              curve: const Interval(0.0, 1.0, curve: Curves.elasticOut),
            ),
            child: child,
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final double fontScale = Provider.of<SettingsService>(context).fontScale;
    final theme = Theme.of(context);
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
                          // Check if this card should skip the language dialog
                          final bool skipDialog = option['skipLanguageDialog'] == true;

                          if (skipDialog) {
                            // Direct navigation for Amal Namah (English only)
                            Navigator.pushNamed(
                              context,
                              option['route'],
                              arguments: {
                                'language': 'english',
                                'title': option['title'],
                              },
                            );
                          } else {
                            // Show language dialog for all other features
                            _showLanguageSelectionDialog(
                              context,
                              option['route'],
                              option['title'],
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

// Language Selection Dialog — unchanged
class _MoreOptionsLanguageDialog extends StatelessWidget {
  final String route;
  final String title;

  const _MoreOptionsLanguageDialog({
    required this.route,
    required this.title,
  });

  final List<String> availableLanguages = const [
    'English',
    'Assamese',
    'Hindi',
    'Bengali',
  ];

  @override
  Widget build(BuildContext context) {
    final double fontScale = Provider.of<SettingsService>(context, listen: false).fontScale;
    final theme = Theme.of(context);

    return Center(
      child: Material(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(28.0),
        elevation: 10,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20.0, 20.0, 20.0, 16.0),
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: 320,
              maxHeight: 400,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Select Language',
                  textAlign: TextAlign.start,
                  style: TextStyle(
                    fontSize: (20 * fontScale).clamp(18.0, 24.0),
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 16),

                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: availableLanguages.length,
                    separatorBuilder: (context, index) => Divider(
                      height: 1,
                      color: theme.colorScheme.outlineVariant.withOpacity(0.3),
                      indent: 16,
                      endIndent: 16,
                    ),
                    itemBuilder: (context, index) {
                      final language = availableLanguages[index];
                      return _buildLanguageTile(context, language, fontScale, theme);
                    },
                  ),
                ),

                const SizedBox(height: 16),

                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () {
                        Haptics.vibrate(HapticsType.light);
                        Navigator.of(context).pop();
                      },
                      child: Text(
                        'Cancel',
                        style: TextStyle(
                          fontSize: (15 * fontScale).clamp(13.0, 17.0),
                          fontWeight: FontWeight.w500,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    TextButton(
                      onPressed: () {
                        Haptics.vibrate(HapticsType.medium);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('More languages coming soon')),
                        );
                      },
                      child: Text(
                        'More Languages',
                        style: TextStyle(
                          fontSize: (15 * fontScale).clamp(13.0, 17.0),
                          fontWeight: FontWeight.w500,
                          color: theme.colorScheme.secondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLanguageTile(
      BuildContext context, String language, double fontScale, ThemeData theme) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 8.0),
      leading: Icon(Icons.translate, color: theme.colorScheme.primary),
      title: Text(
        language,
        style: TextStyle(
          fontSize: (16 * fontScale).clamp(14.0, 18.0),
          fontWeight: FontWeight.w500,
          color: theme.colorScheme.onSurface,
        ),
      ),
      trailing: Icon(
        Icons.arrow_forward_ios,
        color: theme.colorScheme.primary.withOpacity(0.5),
        size: 14,
      ),
      onTap: () async {
        if (await Haptics.canVibrate()) {
          Haptics.vibrate(HapticsType.light);
        }

        Navigator.of(context).pop();
        Navigator.pushNamed(
          context,
          route,
          arguments: {
            'language': language.toLowerCase(),
            'title': title,
          },
        );
      },
    );
  }
}