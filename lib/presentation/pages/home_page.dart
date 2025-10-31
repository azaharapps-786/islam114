// lib/presentation/pages/home_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:haptic_feedback/haptic_feedback.dart';
import 'dart:ui' as ui; // For better blur effects if needed

// --- CORRECTED IMPORT PATHS ---
import 'package:islam114/main.dart'; // Import for global RouteObserver from main.dart
import '../../core/services/settings_service.dart';
import '../widgets/home_feature_card.dart';
import '../widgets/home_bottom_bar.dart';

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
  int _animationKey = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _headerController = AnimationController(
      duration: const Duration(milliseconds: 500), // Reduced from 1500ms for faster header animation
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
    _headerController.dispose();
    // Unsubscribe from the global RouteObserver to prevent memory leaks.
    final modalRoute = ModalRoute.of(context);
    if (modalRoute is PageRoute) {
      routeObserver.unsubscribe(this);
    }
    super.dispose();
  }

  // Restart the header animation and trigger a rebuild for card animations.
  void _restartAnimation() {
    _headerController.reset();
    _headerController.forward();
    _animationKey++;
    // Force a rebuild to replay card animations via key changes and recreation.
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void didPopNext() {
    // Triggered when returning to this route (e.g., popping back from another page).
    print('didPopNext called: Restarting HomePage animation'); // Debug log for verification.
    _restartAnimation();
  }

  // Define the features for the grid
  final List<Map<String, dynamic>> _primaryFeatures = [
    {
      'title': 'অসমীয়া কোৰআন',
      'icon': 'assets/icons/quran_assamese.svg',
      'route': '/surahList',
      'params': {'language': 'assamese'},
      'emoji': '📖'
    },
    {
      'title': 'English Quran',
      'icon': 'assets/icons/quran_english.svg',
      'route': '/surahList',
      'params': {'language': 'english'},
      'emoji': '📕'
    },
    {
      'title': 'हिन्दी क़ुरआन',
      'icon': 'assets/icons/quran_hindi.svg',
      'route': '/surahList',
      'params': {'language': 'hindi'},
      'emoji': '📗'
    },
    {
      'title': 'Arabic Quran',
      'icon': 'assets/icons/quran_arabic.svg',
      'route': '/surahList',
      'params': {'language': 'arabic'},
      'emoji': '📘'
    },
    {
      'title': 'Bengali Quran',
      'icon': 'assets/icons/quran_bengali.svg',
      'route': '/surahList',
      'params': {'language': 'bengali'},
      'emoji': '📙'
    },
    {
      'title': 'Quran Tafseer',
      'icon': 'assets/icons/tafseer.svg',
      'route': '/tafseer',
      'params': null,
      'emoji': '📚'
    },
    {
      'title': 'Saved Verses',
      'icon': 'assets/icons/bookmark.svg',
      'route': '/bookmarks',
      'params': null,
      'emoji': '🔖'
    },
  ];

  final List<Map<String, dynamic>> _secondaryFeatures = [
    {
      'title': 'Bukhari Hadith',
      'icon': 'assets/icons/hadith.svg',
      'route': '/hadith',
      'emoji': '📜'
    },
    {
      'title': 'Namaz Times',
      'icon': 'assets/icons/namaz.svg',
      'route': '/namaz',
      'emoji': '🙏'
    },
    {
      'title': 'Tasbeeh Counter',
      'icon': 'assets/icons/tasbeeh.svg',
      'route': '/tasbeeh',
      'emoji': '📿'
    },
    {
      'title': 'Quran Dictionary',
      'icon': 'assets/icons/dictionary.svg',
      'route': '/dictionary',
      'emoji': '🔤'
    },
    {
      'title': 'Islamic Calendar',
      'icon': 'assets/icons/calendar.svg',
      'route': '/calendar',
      'emoji': '📅'
    },
    {
      'title': 'Qibla Direction',
      'icon': 'assets/icons/qibla.svg',
      'route': '/qibla',
      'emoji': '🧭'
    },
    {
      'title': 'More Options',
      'icon': 'assets/icons/more.svg',
      'route': '/more',
      'emoji': '➕'
    },
  ];

  @override
  Widget build(BuildContext context) {
    // This makes the font scale available to all text widgets below
    final double fontScale = Provider.of<SettingsService>(context).fontScale;
    final theme = Theme.of(context);

    // Get screen size for responsive adjustments
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenHeight < 700 || screenWidth < 360;

    // Calculate responsive font sizes
    final mainTextSize = isSmallScreen ? 24.0 : 32.0;
    final headerPadding = isSmallScreen ? 12.0 : 16.0;

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
          child: Column(
            children: [
              // 1. Enhanced Arabic Text Header with Built-in Animations
              AnimatedBuilder(
                animation: _headerController,
                builder: (context, child) {
                  return Transform.translate(
                    offset: Offset(0, _slideAnimation.value * MediaQuery.of(context).size.height),
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
                              // Animated Arabic Shahada with Fade and Scale
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
                              // Subtle English translation below with delayed fade
                              TweenAnimationBuilder<double>(
                                duration: const Duration(milliseconds: 1500), // Reduced from 2000ms for faster subtitle fade
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
              // 2. Main Content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16.0, vertical: 8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // 3. Primary Features (Quran)
                      _buildSectionTitle('Holy Quran', fontScale, theme),
                      const SizedBox(height: 12),
                      _buildFeatureGrid(_primaryFeatures, 3, fontScale, theme, _animationKey),
                      const SizedBox(height: 32),
                      // 4. Secondary Features
                      _buildSectionTitle('Tools & More', fontScale, theme),
                      const SizedBox(height: 12),
                      _buildFeatureGrid(_secondaryFeatures, 3, fontScale, theme, _animationKey),
                      const SizedBox(height: 32), // Padding for bottom bar
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      // 5. Bottom Bar
      bottomNavigationBar: const HomeBottomBar(),
    );
  }

  Widget _buildSectionTitle(String title, double fontScale, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 8.0),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withOpacity(0.7),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.onSurface.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(
            Icons.book_outlined,
            color: theme.colorScheme.primary,
            size: 24 * fontScale,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 22 * fontScale,
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureGrid(List<Map<String, dynamic>> features,
      int crossAxisCount, double fontScale, ThemeData theme, int animationKey) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Calculate aspect ratio for a more square, visually appealing card
        double aspectRatio = (constraints.maxWidth / crossAxisCount) / 140;
        if (aspectRatio < 0.85) aspectRatio = 0.85; // Ensure cards aren't too tall

        return GridView.builder(
          key: ValueKey('grid-$animationKey'), // Unique key on GridView to force full recreation.
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: aspectRatio,
          ),
          itemCount: features.length,
          itemBuilder: (context, index) {
            final feature = features[index];

            // FIX: Create local variables to capture the correct values for the onTap callback
            final String route = feature['route'];
            final Map<String, dynamic>? params = feature['params'];

            return TweenAnimationBuilder<double>(
              key: ValueKey('card$index-$animationKey'), // Unique key to force recreation and animation restart.
              duration: Duration(milliseconds: 400 + (index * 80)), // Reduced base from 600ms and stagger from 100ms for faster cards
              tween: Tween(begin: 0.0, end: 1.0),
              curve: Curves.easeOut,
              builder: (context, value, child) {
                return Transform.translate(
                  offset: Offset(0, 20 * (1 - value)),
                  child: Transform.scale(
                    scale: value,
                    child: Opacity(
                      opacity: value,
                      child: HomeFeatureCard(
                        title: feature['title'],
                        iconPath: feature['icon'],
                        emojiIcon: feature['emoji'],
                        onTap: () {
                          //HapticFeedback.medium(HapticFeedbackType.selection); // Enhanced haptic
                          // Optional: Add a micro-animation or snackbar feedback here
                          Navigator.pushNamed(context, route, arguments: params);
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