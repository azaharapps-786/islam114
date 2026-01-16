import 'package:flutter/material.dart';
import 'package:islam114/presentation/pages/niyat_list_page.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';

import 'presentation/pages/dua_page.dart';
import 'core/services/settings_service.dart';
import 'core/services/deeds_service.dart';
import 'core/themes/app_theme.dart';
import 'core/providers/prayer_times_provider.dart';
import 'presentation/pages/home_page.dart';
import 'presentation/pages/settings_page.dart';
import 'presentation/pages/surah_list_page.dart';
import 'presentation/pages/surah_detail_page.dart';
import 'presentation/pages/bookmarks_page.dart';
import 'presentation/pages/tasbeeh_page.dart';
import 'presentation/pages/namaz_times_page.dart';
import 'presentation/pages/quran_dictionary_page.dart';
import 'presentation/pages/islamic_calendar_page.dart';
import 'presentation/pages/more_options_page.dart';
import 'presentation/pages/bukhari_hadith_page.dart';
import 'presentation/pages/qibla_page.dart';
import 'presentation/pages/amal_namah_dashboard.dart';
import 'presentation/pages/darood_page.dart';
import 'presentation/pages/allah_names_page.dart'; // ← Make sure this import exists!

final RouteObserver<PageRoute<dynamic>> routeObserver = RouteObserver<PageRoute<dynamic>>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.white,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SettingsService()),
        ChangeNotifierProvider(create: (_) => PrayerTimesProvider()),
        ChangeNotifierProvider(create: (_) => DeedsService()),
      ],
      child: const Islam114App(),
    ),
  );
}

class Islam114App extends StatefulWidget {
  const Islam114App({super.key});

  @override
  State<Islam114App> createState() => _Islam114AppState();
}

class _Islam114AppState extends State<Islam114App> with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeInOut),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.6, curve: Curves.elasticOut),
      ),
    );

    _initializeApp();
  }

  Future<void> _initializeApp() async {
    final settingsService = Provider.of<SettingsService>(context, listen: false);
    await settingsService.loadSettings();

    final prayerTimesProvider = Provider.of<PrayerTimesProvider>(context, listen: false);
    await prayerTimesProvider.initialize();

    if (mounted) {
      setState(() {
        _isInitialized = true;
      });
      _animationController.forward();
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsService>(
      builder: (context, settingsService, child) {
        return MaterialApp(
          title: 'Islam114',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: settingsService.themeMode,
          home: _isInitialized
              ? AnimatedBuilder(
            animation: _animationController,
            builder: (context, child) {
              return FadeTransition(
                opacity: _fadeAnimation,
                child: ScaleTransition(
                  scale: _scaleAnimation,
                  child: const HomePage(),
                ),
              );
            },
          )
              : const SplashScreen(),
          routes: {
            '/home': (context) => const HomePage(),
            '/settings': (context) => const SettingsPage(),
            '/surahList': (context) => const SurahListPage(),
            '/surahDetail': (context) => const SurahDetailPage(),
            '/bookmarks': (context) => const BookmarksPage(),
            '/tasbeeh': (context) => const TasbeehPage(),
            '/namaz': (context) => const NamazTimesPage(),
            '/dictionary': (context) => const QuranDictionaryPage(),
            '/calendar': (context) => const IslamicCalendarPage(),
            '/more': (context) => const MoreOptionsPage(),
            '/hadith': (context) => const BukhariHadithPage(),
            '/qibla': (context) => const QiblaPage(),
            '/niyat': (context) => const NiyatListPage(),
            // '/darood' and '/allahNames' are intentionally NOT here → handled by onGenerateRoute
          },
          navigatorObservers: [routeObserver],
          onGenerateRoute: (settings) {
            if (settings.name != null) {
              // Handle Darood with language
              if (settings.name == '/darood') {
                final args = settings.arguments as Map<String, dynamic>?;
                final language = args?['language'] as String? ?? 'english';

                return MaterialPageRoute(
                  builder: (context) => DaroodPage(language: language),
                );
              }

              // Handle REAL 99 Names page (AllahNamesPage)
              // Handle REAL 99 Names page (AllahNamesPage)
              if (settings.name == '/allahNames') {
                final args = settings.arguments as Map<String, dynamic>?;
                final language = args?['language'] as String? ?? 'english';

                return MaterialPageRoute(
                  builder: (context) => AllahNamesPage(language: language), // Pass the language parameter here
                );
              }

              if (settings.name == '/rabbanaDuas') {
                final args = settings.arguments as Map<String, dynamic>?;
                final language = args?['language'] as String? ?? 'english';
                final title = args?['title'] as String? ?? 'Rabbana Duas';

                return MaterialPageRoute(
                  builder: (context) => DuaPage(
                    title: title,
                    language: language,
                  ),
                );
              }

              // Amal Namah
              if (settings.name == '/amalNamah') {
                final args = settings.arguments as Map<String, dynamic>?;
                final language = args?['language'] as String? ?? 'english';
                final title = args?['title'] as String? ?? 'Amal Namah';

                return MaterialPageRoute(
                  builder: (context) => AmalNamahDashboard(
                    language: language,
                    title: title,
                  ),
                );
              }
            }
            return null;
          },
        );
      },
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// SplashScreen & PlaceholderPage (unchanged)
// ──────────────────────────────────────────────────────────────────────────────

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  late AnimationController _logoController;
  late AnimationController _textController;
  late Animation<double> _logoAnimation;
  late Animation<double> _textAnimation;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();

    _logoController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _textController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _logoAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.elasticOut),
    );

    _textAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _textController, curve: Curves.easeInOut),
    );

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _logoController, curve: const Interval(0.6, 1.0, curve: Curves.easeInOut)),
    )..addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _logoController.reverse();
      } else if (status == AnimationStatus.dismissed) {
        _logoController.forward();
      }
    });

    _logoController.forward();
    _textController.forward();
  }

  @override
  void dispose() {
    _logoController.dispose();
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF1E88E5), Color(0xFF1565C0)],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedBuilder(
                animation: Listenable.merge([_logoAnimation, _pulseAnimation]),
                builder: (context, child) {
                  return Transform.scale(
                    scale: _logoAnimation.value * _pulseAnimation.value,
                    child: Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: const Icon(Icons.mosque, size: 70, color: Color(0xFF1E88E5)),
                    ),
                  );
                },
              ),
              const SizedBox(height: 40),
              AnimatedBuilder(
                animation: _textAnimation,
                builder: (context, child) {
                  return FadeTransition(
                    opacity: _textAnimation,
                    child: Transform.translate(
                      offset: Offset(0, 20 * (1 - _textAnimation.value)),
                      child: const Text(
                        'Islam114',
                        style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 1.2),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 10),
              AnimatedBuilder(
                animation: _textAnimation,
                builder: (context, child) {
                  return FadeTransition(
                    opacity: _textAnimation,
                    child: Transform.translate(
                      offset: Offset(0, 20 * (1 - _textAnimation.value)),
                      child: const Text(
                        'Your Islamic Companion',
                        style: TextStyle(fontSize: 16, color: Colors.white70, letterSpacing: 0.5),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 60),
              AnimatedBuilder(
                animation: _textAnimation,
                builder: (context, child) {
                  return FadeTransition(
                    opacity: _textAnimation,
                    child: const SizedBox(
                      width: 30,
                      height: 30,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class PlaceholderPage extends StatelessWidget {
  final String title;
  final String language;

  const PlaceholderPage({
    super.key,
    required this.title,
    required this.language,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        elevation: 4,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.construction, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              '$title Page',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Language: ${language[0].toUpperCase() + language.substring(1)}',
              style: const TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            const Text(
              'This page is under construction',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Go Back'),
            ),
          ],
        ),
      ),
    );
  }
}