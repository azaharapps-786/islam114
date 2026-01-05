// lib/presentation/pages/home_page.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'dart:ui' as ui;

import 'package:islam114/main.dart';
import '../../core/services/settings_service.dart';
import '../widgets/home_feature_card.dart';
import '../widgets/home_bottom_bar.dart';
import '../widgets/tafseer_language_dialog.dart';
// NEW IMPORT for the Dynamic Section Header
import '../widgets/dynamic_section_header.dart'; // Replaces the old DynamicVerseIsland
// ADDED IMPORT for the Dynamic Horizontal Header
import '../widgets/dynamic_horizontal_header.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin, RouteAware, WidgetsBindingObserver {
  late AnimationController _headerController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _slideAnimation;

  // Track when the animation sequence started
  DateTime _animationStartTime = DateTime.now();
  int _animationKey = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _headerController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _headerController, curve: Curves.easeInOut),
    );
    _scaleAnimation = Tween<double>(begin: 0.95, end: 1.0).animate(
      CurvedAnimation(parent: _headerController, curve: Curves.elasticOut),
    );
    _slideAnimation = Tween<double>(begin: -0.1, end: 0.0).animate(
      CurvedAnimation(parent: _headerController, curve: Curves.easeOut),
    );

    _restartAnimation();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final modalRoute = ModalRoute.of(context);
    if (modalRoute is PageRoute) {
      routeObserver.subscribe(this, modalRoute as PageRoute<dynamic>);
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _restartAnimation();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _headerController.dispose();
    final modalRoute = ModalRoute.of(context);
    if (modalRoute is PageRoute) {
      routeObserver.unsubscribe(this);
    }
    super.dispose();
  }

  void _restartAnimation() {
    _headerController.reset();
    _headerController.forward();
    if (mounted) {
      setState(() {
        // Reset the start time so animations play again
        _animationStartTime = DateTime.now();
        _animationKey++;
      });
    }
  }

  @override
  void didPopNext() {
    _restartAnimation();
  }

  void _showTafseerLanguageDialog(BuildContext context) {
    showGeneralDialog(
      context: context,
      barrierLabel: 'Tafseer Language Selection',
      barrierDismissible: true,
      barrierColor: Colors.black.withOpacity(0.5),
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, animation1, animation2) => const TafseerLanguageDialog(),
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

  // Static constant data (unchanged)
  static const List<Map<String, dynamic>> _primaryFeatures = [
    {'title': 'অসমীয়া কোৰআন', 'icon': 'assets/icons/quran_assamese.svg', 'route': '/surahList', 'params': {'language': 'assamese'}, 'emoji': '📖'},
    {'title': 'English Quran', 'icon': 'assets/icons/quran_english.svg', 'route': '/surahList', 'params': {'language': 'english'}, 'emoji': '📕'},
    {'title': 'हिन्दी   क़ुरान', 'icon': 'assets/icons/quran_hindi.svg', 'route': '/surahList', 'params': {'language': 'hindi'}, 'emoji': '📗'},
    {'title': 'Arabic Quran', 'icon': 'assets/icons/quran_arabic.svg', 'route': '/surahList', 'params': {'language': 'arabic'}, 'emoji': '📘'},
    {'title': 'Bengali Quran', 'icon': 'assets/icons/quran_bengali.svg', 'route': '/surahList', 'params': {'language': 'bengali'}, 'emoji': '📙'},
    {'title': 'Quran Tafseer', 'icon': 'assets/icons/tafseer.svg', 'route': '/tafseerLanguageSelection', 'params': null, 'emoji': '📚'},
    {'title': 'Saved Verses', 'icon': 'assets/icons/bookmark.svg', 'route': '/bookmarks', 'params': null, 'emoji': '⭐'},
  ];

  static const List<Map<String, dynamic>> _secondaryFeatures = [
    {'title': 'Bukhari Hadith', 'icon': 'assets/icons/hadith.svg', 'route': '/hadith', 'emoji': '📜'},
    {'title': 'Namaz Times', 'icon': 'assets/icons/namaz.svg', 'route': '/namaz', 'emoji': '🙏'},
    {'title': 'Tasbeeh Counter', 'icon': 'assets/icons/tasbeeh.svg', 'route': '/tasbeeh', 'emoji': '📿'},
    {'title': 'Quran Dictionary', 'icon': 'assets/icons/dictionary.svg', 'route': '/dictionary', 'emoji': '🔤'},
    {'title': 'Islamic Calendar', 'icon': 'assets/icons/calendar.svg', 'route': '/calendar', 'emoji': '📅'},
    {'title': 'Qibla Direction', 'icon': 'assets/icons/qibla.svg', 'route': '/qibla', 'emoji': '🧭'},
    {'title': 'More Options', 'icon': 'assets/icons/more.svg', 'route': '/more', 'emoji': '➕'},
  ];

  @override
  Widget build(BuildContext context) {
    final double fontScale = Provider.of<SettingsService>(context).fontScale;
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;
    final isSmallScreen = size.height < 700 || size.width < 360;
    final mainTextSize = isSmallScreen ? 24.0 : 32.0;
    final headerPadding = isSmallScreen ? 12.0 : 16.0;

    return Scaffold(
      body: SafeArea( // Revert back to using SafeArea here
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                theme.colorScheme.primary.withOpacity(0.05),
                theme.colorScheme.surface,
              ],
              stops: const [0.0, 1.0],
            ),
          ),
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // Header
              SliverToBoxAdapter(
                child: RepaintBoundary(
                  child: AnimatedBuilder(
                    animation: _headerController,
                    builder: (context, child) {
                      return Transform.translate(
                        offset: Offset(0, _slideAnimation.value * size.height),
                        child: Transform.scale(
                          scale: _scaleAnimation.value,
                          child: FadeTransition(
                            opacity: _fadeAnimation,
                            child: Container(
                              width: double.infinity,
                              padding: EdgeInsets.symmetric(vertical: headerPadding * 1.5),
                              margin: const EdgeInsets.only(bottom: 8.0),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    theme.colorScheme.primary.withOpacity(0.9),
                                    theme.colorScheme.primaryContainer,
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: theme.colorScheme.primary.withOpacity(0.3),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Column(
                                children: [
                                  Center(
                                    child: FittedBox(
                                      fit: BoxFit.scaleDown,
                                      child: Text(
                                        'لَا إِلَٰهَ إِلَّا ٱلَّٰهُ مُحَمَّدٌ رَسُولُ ٱلَّٰهِ',
                                        style: TextStyle(
                                          fontSize: mainTextSize * fontScale * 1.0,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                          fontFamily: 'Uthmanic',
                                          height: 1.2,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                  ),
                                  TweenAnimationBuilder<double>(
                                    duration: const Duration(milliseconds: 1500),
                                    tween: Tween(begin: 0.0, end: 1.0),
                                    builder: (context, value, child) {
                                      return Opacity(
                                        opacity: value,
                                        child: Padding(
                                          padding: const EdgeInsets.only(top: 4.0),
                                          child: child,
                                        ),
                                      );
                                    },
                                    child: Text(
                                      'There is no god but Allah, Muhammad is the Messenger of Allah',
                                      style: TextStyle(
                                        fontSize: (mainTextSize * 0.53) * fontScale,
                                        fontWeight: FontWeight.w300,
                                        color: Colors.white.withOpacity(0.9),
                                        fontStyle: FontStyle.italic,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),

              // Title 1: HOLY QURAN Dynamic Island Header (Vertical)
              SliverPadding(
                padding: const EdgeInsets.only(top: 16, bottom: 12), // Horizontal padding handled inside the widget
                sliver: SliverToBoxAdapter(
                  child: DynamicSectionHeader(
                    title: 'Holy Quran',
                    fontScale: fontScale,
                  ),
                ),
              ),

              // Feature Grid 1
              _buildSliverFeatureGrid(_primaryFeatures, 3, fontScale, theme),

              // Title 2: Tools & More (Horizontal Dynamic Island)
              SliverPadding(
                // REMOVED explicit horizontal padding (left: 16, right: 16) as DynamicHorizontalHeader has internal padding/margin
                padding: const EdgeInsets.only(top: 32, bottom: 12),
                sliver: SliverToBoxAdapter(
                  child: DynamicHorizontalHeader(
                    title: 'Tools & More',
                    fontScale: fontScale,
                    theme: theme,
                  ),
                ),
              ),

              // Feature Grid 2
              _buildSliverFeatureGrid(_secondaryFeatures, 3, fontScale, theme),

              // Bottom padding
              const SliverPadding(padding: EdgeInsets.only(bottom: 32)),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const HomeBottomBar(),
    );
  }

  // DELETED: _buildSectionTitle method has been removed as it is now replaced by DynamicHorizontalHeader

  Widget _buildSliverFeatureGrid(List<Map<String, dynamic>> features,
      int crossAxisCount, double fontScale, ThemeData theme) {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      sliver: SliverLayoutBuilder(
        builder: (context, constraints) {
          double aspectRatio = (constraints.crossAxisExtent / crossAxisCount) / 140;
          if (aspectRatio < 0.85) aspectRatio = 0.85;

          return SliverGrid(
            // Key forces rebuild on restart
            key: ValueKey('grid-${features.hashCode}-$_animationKey'),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: aspectRatio,
            ),
            delegate: SliverChildBuilderDelegate(
                  (context, index) {
                final feature = features[index];
                final String route = feature['route'];
                final Map<String, dynamic>? params = feature['params'];

                // 1. Calculate how long this specific item's animation takes
                final int animationDurationMs = 400 + (index * 80);

                // 2. Check time elapsed since the page loaded (or restart called)
                final int elapsedMs = DateTime.now().difference(_animationStartTime).inMilliseconds;

                // 3. Define the widget content (The Card)
                final cardContent = _PressableCard(
                  title: feature['title'],
                  iconPath: feature['icon'],
                  emojiIcon: feature['emoji'],
                  onTap: () {
                    HapticFeedback.lightImpact();
                    if (route == '/tafseerLanguageSelection') {
                      _showTafseerLanguageDialog(context);
                    } else {
                      Navigator.pushNamed(context, route, arguments: params);
                    }
                  },
                );

                // 4. Logic: If the animation "should have finished" by now, return Static widget.
                //    Otherwise, return the Animation.
                if (elapsedMs > animationDurationMs) {
                  // Render static (No animation, instant show)
                  return cardContent;
                }

                // Render animated (Still within the animation window)
                return TweenAnimationBuilder<double>(
                  key: ValueKey('card$index-$_animationKey'), // Key ensures it resets
                  duration: Duration(milliseconds: animationDurationMs),
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
                  child: cardContent,
                );
              },
              childCount: features.length,
            ),
          );
        },
      ),
    );
  }
}

class _PressableCard extends StatefulWidget {
  final String title;
  final String? iconPath;
  final String emojiIcon;
  final VoidCallback onTap;

  const _PressableCard({
    required this.title,
    this.iconPath,
    required this.emojiIcon,
    required this.onTap,
  });

  @override
  State<_PressableCard> createState() => _PressableCardState();
}

class _PressableCardState extends State<_PressableCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    _controller.forward();
  }

  void _onTapUp(TapUpDetails details) {
    _controller.reverse();
  }

  void _onTapCancel() {
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: GestureDetector(
        onTapDown: _onTapDown,
        onTapUp: _onTapUp,
        onTapCancel: _onTapCancel,
        onTap: widget.onTap,
        child: AnimatedBuilder(
          animation: _scaleAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: _scaleAnimation.value,
              child: HomeFeatureCard(
                title: widget.title,
                iconPath: widget.iconPath,
                emojiIcon: widget.emojiIcon,
                onTap: widget.onTap,
              ),
            );
          },
        ),
      ),
    );
  }
}
