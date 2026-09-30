// lib/presentation/pages/home_page.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'dart:ui' as ui;

import 'package:islam114/main.dart';
import '../../core/services/settings_service.dart';
import '../../core/services/remote_config_service.dart'; // ADDED
import '../widgets/home_feature_card.dart';
import '../widgets/home_bottom_bar.dart';
import '../widgets/tafseer_language_dialog.dart';
import '../widgets/dynamic_section_header.dart';
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

  DateTime _animationStartTime = DateTime.now();
  int _animationKey = 0;

  // ADDED: Map to link routes to admin toggle keys
  static const Map<String, String> _featureKeyMap = {
    '/surahList': 'quran',
    '/bookmarks': 'bookmarks',
    '/hadith': 'hadith',
    '/namaz': 'namaz_times',
    '/tasbeeh': 'tasbeeh',
    '/dictionary': 'dictionary',
    '/calendar': 'calendar',
    '/qibla': 'qibla',
    '/more': 'more_options',
  };

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
      transitionDuration: const Duration(milliseconds: 400),
      pageBuilder: (context, animation, secondaryAnimation) {
        return const TafseerLanguageDialog();
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        final scaleAnimation = Tween<double>(
          begin: 0.5,
          end: 1.0,
        ).animate(
          CurvedAnimation(
            parent: animation,
            curve: Curves.elasticOut,
          ),
        );

        final fadeAnimation = Tween<double>(
          begin: 0.0,
          end: 1.0,
        ).animate(
          CurvedAnimation(
            parent: animation,
            curve: const Interval(0.3, 1.0, curve: Curves.easeOut),
          ),
        );

        return FadeTransition(
          opacity: fadeAnimation,
          child: ScaleTransition(
            scale: scaleAnimation,
            child: child,
          ),
        );
      },
    );
  }

  static const List<Map<String, dynamic>> _primaryFeatures = [
    {'title': 'অসমীয়া কোৰআন', 'icon': 'assets/icons/quran_assamese.svg', 'route': '/surahList', 'params': {'language': 'assamese'}, 'emoji': '📖'},
    {'title': 'English Quran', 'icon': 'assets/icons/quran_english.svg', 'route': '/surahList', 'params': {'language': 'english'}, 'emoji': '📕'},
    {'title': 'हिन्दी   कुरान', 'icon': 'assets/icons/quran_hindi.svg', 'route': '/surahList', 'params': {'language': 'hindi'}, 'emoji': '📗'},
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
    final remoteConfig = Provider.of<RemoteConfigService>(context); // ADDED
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;
    final isSmallScreen = size.height < 700 || size.width < 360;
    final mainTextSize = isSmallScreen ? 24.0 : 32.0;
    final headerPadding = isSmallScreen ? 12.0 : 16.0;

    // ADDED: Filter out disabled features
    final activePrimaryFeatures = _primaryFeatures.where((f) {
      final route = f['route'] as String;
      final key = _featureKeyMap[route];
      if (key == null) return true;
      return !remoteConfig.isFeatureDisabled(key);
    }).toList();

    final activeSecondaryFeatures = _secondaryFeatures.where((f) {
      final route = f['route'] as String;
      final key = _featureKeyMap[route];
      if (key == null) return true;
      return !remoteConfig.isFeatureDisabled(key);
    }).toList();

    return Scaffold(
      body: SafeArea(
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

              // UPDATED: Conditionally show Primary Grid
              if (activePrimaryFeatures.isNotEmpty) ...[
                SliverPadding(
                  padding: const EdgeInsets.only(top: 16, bottom: 12),
                  sliver: SliverToBoxAdapter(
                    child: DynamicSectionHeader(
                      title: 'Holy Quran',
                      fontScale: fontScale,
                    ),
                  ),
                ),
                _buildSliverFeatureGrid(activePrimaryFeatures, 3, fontScale, theme),
              ],

              // UPDATED: Conditionally show Secondary Grid
              if (activeSecondaryFeatures.isNotEmpty) ...[
                SliverPadding(
                  padding: const EdgeInsets.only(top: 32, bottom: 12),
                  sliver: SliverToBoxAdapter(
                    child: DynamicHorizontalHeader(
                      title: 'Tools & More',
                      fontScale: fontScale,
                      theme: theme,
                    ),
                  ),
                ),
                _buildSliverFeatureGrid(activeSecondaryFeatures, 3, fontScale, theme),
              ],

              const SliverPadding(padding: EdgeInsets.only(bottom: 32)),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const HomeBottomBar(),
    );
  }

  Widget _buildSliverFeatureGrid(List<Map<String, dynamic>> features,
      int crossAxisCount, double fontScale, ThemeData theme) {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      sliver: SliverLayoutBuilder(
        builder: (context, constraints) {
          double aspectRatio = (constraints.crossAxisExtent / crossAxisCount) / 140;
          if (aspectRatio < 0.85) aspectRatio = 0.85;

          return SliverGrid(
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
                final int animationDurationMs = 400 + (index * 80);
                final int elapsedMs = DateTime.now().difference(_animationStartTime).inMilliseconds;

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

                if (elapsedMs > animationDurationMs) {
                  return cardContent;
                }

                return TweenAnimationBuilder<double>(
                  key: ValueKey('card$index-$_animationKey'),
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