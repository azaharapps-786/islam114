import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:islam114/presentation/pages/niyat_list_page.dart';
import 'package:provider/provider.dart';

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
import 'presentation/pages/allah_names_page.dart';
import 'presentation/pages/library_list_page.dart';
import 'presentation/pages/about_us_page.dart';

final RouteObserver<PageRoute<dynamic>> routeObserver = RouteObserver<PageRoute<dynamic>>();

// ──────────────────────────────────────────────────────────────────────────────
// Global Quran data preload cache
// ──────────────────────────────────────────────────────────────────────────────
class QuranDataCache {
  /// key -> decoded JSON (List or Map depending on file)
  static final Map<String, dynamic> jsonCache = {};

  static bool isPreloaded = false;
  static Future<void>? _preloadFuture;

  /// Languages supported across the app
  static const List<String> languages = [
    'english',
    'assamese',
    'hindi',
    'bengali',
    'arabic',
  ];

  /// Call this once, early (e.g. during splash screen init), and await it
  /// before showing the main app UI.
  static Future<void> preloadAll() {
    return _preloadFuture ??= _doPreload();
  }

  /// Build the same cache key used by SurahDetailPage:
  /// '$_language$_isTafseer'  e.g. 'englishfalse', 'englishtrue'
  static String key(String language, bool isTafseer) => '$language$isTafseer';

  static Future<void> _doPreload() async {
    final Map<String, String> filesToLoad = {};

    // Non-tafseer + tafseer translation files for every language
    for (final lang in languages) {
      filesToLoad[key(lang, false)] = 'assets/data/quran_$lang.json';
      filesToLoad[key(lang, true)] = 'assets/data/quran_${lang}_tafseer.json';
    }

    // Arabic verses (used as a separate source for arabic text overlay)
    filesToLoad['arabic'] = 'assets/data/quran_arabic.json';

    // English transliteration (used across all languages)
    filesToLoad['transliteration'] = 'assets/data/quran_english_transliteration.json';

    // ── FIX #3: Quran Dictionary files ──────────────────────────────────
    // Preload all dictionary language files so QuranDictionaryPage never
    // needs to call rootBundle.loadString at runtime.
    for (final lang in languages) {
      filesToLoad['dict_$lang'] = 'assets/dictionaries/quran_dictionary_$lang.json';
    }

    await Future.wait(filesToLoad.entries.map((entry) async {
      final cacheKey = entry.key;
      final path = entry.value;

      // Skip if already loaded somehow
      if (jsonCache.containsKey(cacheKey)) return;

      try {
        final String jsonString = await rootBundle.loadString(path);
        jsonCache[cacheKey] = json.decode(jsonString);
      } catch (e) {
        // Some tafseer/language/dictionary files may not exist for every
        // language — that's fine, pages already have fallback handling.
        debugPrint('QuranDataCache: skipped/failed "$path" -> $e');
      }
    }));

    isPreloaded = true;
  }
}

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
    final prayerTimesProvider = Provider.of<PrayerTimesProvider>(context, listen: false);

    await Future.wait([
      settingsService.loadSettings(),
      prayerTimesProvider.initialize(),
      QuranDataCache.preloadAll(),
    ]);

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
              ? ListenableBuilder(
            listenable: _animationController,
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
            '/library': (context) => const LibraryListPage(),
            '/about': (context) => const AboutUsPage(),
          },
          navigatorObservers: [routeObserver],
          onGenerateRoute: (settings) {
            if (settings.name != null) {
              if (settings.name == '/darood') {
                final args = settings.arguments as Map<String, dynamic>?;
                final language = args?['language'] as String? ?? 'english';

                return MaterialPageRoute(
                  builder: (context) => DaroodPage(language: language),
                );
              }

              if (settings.name == '/allahNames') {
                final args = settings.arguments as Map<String, dynamic>?;
                final language = args?['language'] as String? ?? 'english';

                return MaterialPageRoute(
                  builder: (context) => AllahNamesPage(language: language),
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
// SplashScreen
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
            colors: [Color(0xFF2E7D32), Color(0xFF1B5E20)], // Deep Green Gradient
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ListenableBuilder(
                listenable: Listenable.merge([_logoAnimation, _pulseAnimation]),
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
                      child: const Icon(Icons.mosque, size: 70, color: Color(0xFF2E7D32)), // Green Icon
                    ),
                  );
                },
              ),
              const SizedBox(height: 40),
              ListenableBuilder(
                listenable: _textAnimation,
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
              ListenableBuilder(
                listenable: _textAnimation,
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
              const SizedBox(height: 8), // Spacing before developer name
              ListenableBuilder(
                listenable: _textAnimation,
                builder: (context, child) {
                  return FadeTransition(
                    opacity: _textAnimation,
                    child: Transform.translate(
                      offset: Offset(0, 20 * (1 - _textAnimation.value)),
                      child: const Text(
                        'Developer: AzaharApps',
                        style: TextStyle(fontSize: 14, color: Colors.white54, letterSpacing: 0.5),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 60),
              ListenableBuilder(
                listenable: _textAnimation,
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