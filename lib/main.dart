import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:islam114/presentation/pages/niyat_list_page.dart';

import 'presentation/pages/dua_page.dart';
import 'core/services/settings_service.dart';
import 'core/services/deeds_service.dart';
import 'core/services/remote_config_service.dart';
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
import 'firebase_options.dart';

final RouteObserver<PageRoute<dynamic>> routeObserver =
RouteObserver<PageRoute<dynamic>>();

// ═══════════════════════════════════════════════════════════════════════════════
// Route → Feature Key mapping (used to block disabled features)
// ═══════════════════════════════════════════════════════════════════════════════
const Map<String, String> _routeFeatureMap = {
  '/surahList': 'quran',
  '/surahDetail': 'quran',
  '/dictionary': 'dictionary',
  '/bookmarks': 'bookmarks',
  '/tasbeeh': 'tasbeeh',
  '/qibla': 'qibla',
  '/calendar': 'calendar',
  '/hadith': 'hadith',
  '/namaz': 'namaz_times',
  '/more': 'more_options',
  '/settings': 'settings',
  '/darood': 'darood',
  '/allahNames': 'allah_names',
  '/niyat': 'niyat',
  '/library': 'library',
  '/rabbanaDuas': 'dua',
  '/amalNamah': 'amal_namah',
};

// ═══════════════════════════════════════════════════════════════════════════════
// Global Quran data preload cache
// ═══════════════════════════════════════════════════════════════════════════════
class QuranDataCache {
  static final Map<String, dynamic> jsonCache = {};
  static bool isPreloaded = false;
  static Future<void>? _preloadFuture;

  static const List<String> languages = [
    'english',
    'assamese',
    'hindi',
    'bengali',
    'arabic',
  ];

  static Future<void> preloadAll() {
    return _preloadFuture ??= _doPreload();
  }

  static String key(String language, bool isTafseer) =>
      '$language$isTafseer';

  static Future<void> _doPreload() async {
    final Map<String, String> filesToLoad = {};

    for (final lang in languages) {
      filesToLoad[key(lang, false)] =
      'assets/data/quran_$lang.json';
      filesToLoad[key(lang, true)] =
      'assets/data/quran_${lang}_tafseer.json';
    }

    filesToLoad['arabic'] = 'assets/data/quran_arabic.json';
    filesToLoad['transliteration'] =
    'assets/data/quran_english_transliteration.json';

    for (final lang in languages) {
      filesToLoad['dict_$lang'] =
      'assets/dictionaries/quran_dictionary_$lang.json';
    }

    await Future.wait(filesToLoad.entries.map((entry) async {
      final cacheKey = entry.key;
      final path = entry.value;

      if (jsonCache.containsKey(cacheKey)) return;

      try {
        final String jsonString = await rootBundle.loadString(path);
        jsonCache[cacheKey] = json.decode(jsonString);
      } catch (e) {
        debugPrint('QuranDataCache: skipped/failed "$path" -> $e');
      }
    }));

    isPreloaded = true;
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Remote Block Screen (Maintenance / Force Update)
// ═══════════════════════════════════════════════════════════════════════════════
class RemoteBlockScreen extends StatelessWidget {
  final String title;
  final String message;
  final IconData icon;

  const RemoteBlockScreen({
    super.key,
    required this.title,
    required this.message,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF1B5E20), Color(0xFF0D3B0E)],
            ),
          ),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon,
                      size: 72,
                      color: Colors.white.withOpacity(0.9)),
                  const SizedBox(height: 28),
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    message,
                    style: TextStyle(
                      fontSize: 15,
                      color: Colors.white.withOpacity(0.8),
                      height: 1.6,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Admin Banner Widget
// ═══════════════════════════════════════════════════════════════════════════════
class AdminBanner extends StatelessWidget {
  final String message;
  final String type;

  const AdminBanner({
    super.key,
    required this.message,
    required this.type,
  });

  Color get _backgroundColor {
    switch (type) {
      case 'warning':
        return const Color(0xFFFFF3E0);
      case 'error':
        return const Color(0xFFFFEBEE);
      case 'success':
        return const Color(0xFFE8F5E9);
      default:
        return const Color(0xFFE3F2FD);
    }
  }

  Color get _textColor {
    switch (type) {
      case 'warning':
        return const Color(0xFFE65100);
      case 'error':
        return const Color(0xFFC62828);
      case 'success':
        return const Color(0xFF2E7D32);
      default:
        return const Color(0xFF1565C0);
    }
  }

  Color get _iconColor => _textColor;

  IconData get _icon {
    switch (type) {
      case 'warning':
        return Icons.warning_amber_rounded;
      case 'error':
        return Icons.error_rounded;
      case 'success':
        return Icons.check_circle_rounded;
      default:
        return Icons.info_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding:
      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: _backgroundColor,
        border: Border(
          bottom:
          BorderSide(color: _iconColor.withOpacity(0.3), width: 1),
        ),
      ),
      child: Row(
        children: [
          Icon(_icon, size: 20, color: _iconColor),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                fontSize: 13,
                color: _textColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Feature Disabled Dialog — shown when user taps a disabled feature
// ═══════════════════════════════════════════════════════════════════════════════
void showFeatureDisabledDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12)),
      title: const Row(
        children: [
          Icon(Icons.block_rounded, color: Colors.orange, size: 24),
          SizedBox(width: 10),
          Text('Feature Unavailable',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
        ],
      ),
      content: const Text(
        'This feature has been temporarily disabled by the administrator. Please check back later.',
        style: TextStyle(fontSize: 14, height: 1.5),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('OK',
              style: TextStyle(fontWeight: FontWeight.w600)),
        ),
      ],
    ),
  );
}

// ═══════════════════════════════════════════════════════════════════════════════
// MAIN
// ═══════════════════════════════════════════════════════════════════════════════
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

  try {
    await Firebase.initializeApp(options: currentPlatform);
    debugPrint('✅ Firebase initialized');
  } catch (e) {
    debugPrint('❌ Firebase init failed: $e');
  }

  final remoteConfig = RemoteConfigService();
  try {
    await remoteConfig.initialize();
    debugPrint('✅ Remote config initialized');
  } catch (e) {
    debugPrint('❌ Remote config init failed: $e');
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SettingsService()),
        ChangeNotifierProvider(create: (_) => PrayerTimesProvider()),
        ChangeNotifierProvider(create: (_) => DeedsService()),
        ChangeNotifierProvider.value(value: remoteConfig),
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

class _Islam114AppState extends State<Islam114App>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  bool _isInitialized = false;
  bool _showMaintenance = false;
  bool _showForceUpdate = false;

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
    final settingsService =
    Provider.of<SettingsService>(context, listen: false);
    final prayerTimesProvider =
    Provider.of<PrayerTimesProvider>(context, listen: false);
    final remoteConfig =
    Provider.of<RemoteConfigService>(context, listen: false);

    try {
      await settingsService.loadSettings();
    } catch (e) {
      debugPrint('⚠️ Settings load failed: $e');
    }

    try {
      await prayerTimesProvider.initialize();
    } catch (e) {
      debugPrint('⚠️ Prayer times init failed: $e');
    }

    try {
      await QuranDataCache.preloadAll();
    } catch (e) {
      debugPrint('⚠️ Quran cache failed: $e');
    }

    // ── Remote config callbacks ────────────────────────────────────
    remoteConfig.onMaintenanceModeChanged = () {
      if (mounted)
        setState(() => _showMaintenance = remoteConfig.maintenanceMode);
    };

    remoteConfig.onForceUpdateRequired = () async {
      final supported = await remoteConfig.isVersionSupported();
      if (mounted) setState(() => _showForceUpdate = !supported);
    };

    // ── Check initial state ───────────────────────────────────────
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) {
      setState(() {
        _showMaintenance = remoteConfig.maintenanceMode;
      });
      if (remoteConfig.forceUpdate) {
        final supported = await remoteConfig.isVersionSupported();
        if (mounted) setState(() => _showForceUpdate = !supported);
      }
    }

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

  // ════════════════════════════════════════════════════════════════════════
  // Check if a feature is disabled by admin
  // ════════════════════════════════════════════════════════════════════════
  bool _isFeatureDisabled(String routeName, RemoteConfigService remoteConfig) {
    final featureKey = _routeFeatureMap[routeName];
    if (featureKey == null) return false;
    return remoteConfig.isFeatureDisabled(featureKey);
  }

  @override
  Widget build(BuildContext context) {
    final remoteConfig = Provider.of<RemoteConfigService>(context);

    // ── Maintenance mode blocks everything ────────────────────────
    if (_isInitialized && _showMaintenance) {
      return RemoteBlockScreen(
        title: 'Maintenance Mode',
        message: remoteConfig.maintenanceMessage,
        icon: Icons.build,
      );
    }

    // ── Force update blocks everything ────────────────────────────
    if (_isInitialized && _showForceUpdate) {
      return RemoteBlockScreen(
        title: 'Update Required',
        message: remoteConfig.forceUpdateMessage,
        icon: Icons.system_update,
      );
    }

    return Consumer<SettingsService>(
      builder: (context, settingsService, child) {
        // ── Theme (admin override) ────────────────────────────────
        ThemeMode effectiveTheme;
        if (remoteConfig.forcedTheme == 'light') {
          effectiveTheme = ThemeMode.light;
        } else if (remoteConfig.forcedTheme == 'dark') {
          effectiveTheme = ThemeMode.dark;
        } else {
          effectiveTheme =
              settingsService.themeMode ?? ThemeMode.system;
        }

        return MaterialApp(
          title: 'Islam114',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: effectiveTheme,

          // ── NO `routes` map — everything goes through onGenerateRoute
          //    so disabled-feature checks are never bypassed ───────
          initialRoute: '/home',

          onGenerateRoute: (settings) {
            final routeName = settings.name;

            // ── FEATURE DISABLE CHECK ─────────────────────────────
            if (routeName != null &&
                _isFeatureDisabled(routeName, remoteConfig)) {
              return PageRouteBuilder(
                pageBuilder: (context, animation, secondaryAnimation) {
                  // Show dialog after the page renders
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    showFeatureDisabledDialog(context);
                    // Go back after dialog
                    Future.delayed(const Duration(milliseconds: 100), () {
                      if (Navigator.canPop(context)) {
                        Navigator.pop(context);
                      }
                    });
                  });
                  return const Scaffold(
                    body: SizedBox.shrink(),
                  );
                },
                transitionDuration: Duration.zero,
                reverseTransitionDuration: Duration.zero,
              );
            }

            // ── NORMAL ROUTE HANDLING ─────────────────────────────
            if (routeName == null) return null;

            switch (routeName) {
              case '/home':
                return MaterialPageRoute(
                  builder: (_) => _isInitialized
                      ? FadeTransition(
                    opacity: _fadeAnimation,
                    child: ScaleTransition(
                      scale: _scaleAnimation,
                      child: const HomePage(),
                    ),
                  )
                      : const SplashScreen(),
                );

              case '/settings':
                return MaterialPageRoute(
                    builder: (_) => const SettingsPage());

              case '/surahList':
                return MaterialPageRoute(
                    builder: (_) => const SurahListPage());

              case '/surahDetail':
                return MaterialPageRoute(
                    builder: (_) => const SurahDetailPage());

              case '/bookmarks':
                return MaterialPageRoute(
                    builder: (_) => const BookmarksPage());

              case '/tasbeeh':
                return MaterialPageRoute(
                    builder: (_) => const TasbeehPage());

              case '/namaz':
                return MaterialPageRoute(
                    builder: (_) => const NamazTimesPage());

              case '/dictionary':
                return MaterialPageRoute(
                    builder: (_) => const QuranDictionaryPage());

              case '/calendar':
                return MaterialPageRoute(
                    builder: (_) => const IslamicCalendarPage());

              case '/more':
                return MaterialPageRoute(
                    builder: (_) => const MoreOptionsPage());

              case '/hadith':
                return MaterialPageRoute(
                    builder: (_) => const BukhariHadithPage());

              case '/qibla':
                return MaterialPageRoute(
                    builder: (_) => const QiblaPage());

              case '/niyat':
                return MaterialPageRoute(
                    builder: (_) => const NiyatListPage());

              case '/library':
                return MaterialPageRoute(
                    builder: (_) => const LibraryListPage());

              case '/about':
                return MaterialPageRoute(
                    builder: (_) => const AboutUsPage());

              case '/darood':
                final args =
                settings.arguments as Map<String, dynamic>?;
                final language =
                    args?['language'] as String? ?? 'english';
                return MaterialPageRoute(
                  builder: (_) =>
                      DaroodPage(language: language),
                );

              case '/allahNames':
                final args =
                settings.arguments as Map<String, dynamic>?;
                final language =
                    args?['language'] as String? ?? 'english';
                return MaterialPageRoute(
                  builder: (_) =>
                      AllahNamesPage(language: language),
                );

              case '/rabbanaDuas':
                final args =
                settings.arguments as Map<String, dynamic>?;
                final language =
                    args?['language'] as String? ?? 'english';
                final title =
                    args?['title'] as String? ?? 'Rabbana Duas';
                return MaterialPageRoute(
                  builder: (_) => DuaPage(
                      title: title, language: language),
                );

              case '/amalNamah':
                final args =
                settings.arguments as Map<String, dynamic>?;
                final language =
                    args?['language'] as String? ?? 'english';
                final title =
                    args?['title'] as String? ?? 'Amal Namah';
                return MaterialPageRoute(
                  builder: (_) => AmalNamahDashboard(
                      language: language, title: title),
                );

              default:
                return null;
            }
          },

          // ── BANNER ──────────────────────────────────────────────
          builder: (context, child) {
            if (remoteConfig.bannerEnabled &&
                remoteConfig.bannerMessage.isNotEmpty) {
              return Column(
                children: [
                  AdminBanner(
                    message: remoteConfig.bannerMessage,
                    type: remoteConfig.bannerType,
                  ),
                  Expanded(child: child!),
                ],
              );
            }
            return child!;
          },

          navigatorObservers: [routeObserver],
        );
      },
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// SplashScreen
// ═══════════════════════════════════════════════════════════════════════════════
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
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
      CurvedAnimation(
          parent: _logoController, curve: Curves.elasticOut),
    );

    _textAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
          parent: _textController, curve: Curves.easeInOut),
    );

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: const Interval(0.6, 1.0, curve: Curves.easeInOut),
      ),
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
            colors: [Color(0xFF2E7D32), Color(0xFF1B5E20)],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ListenableBuilder(
                listenable: Listenable.merge(
                    [_logoAnimation, _pulseAnimation]),
                builder: (context, child) {
                  return Transform.scale(
                    scale:
                    _logoAnimation.value * _pulseAnimation.value,
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
                      child: const Icon(Icons.mosque,
                          size: 70, color: Color(0xFF2E7D32)),
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
                      offset: Offset(
                          0, 20 * (1 - _textAnimation.value)),
                      child: const Text(
                        'Islam114',
                        style: TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 1.2,
                        ),
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
                      offset: Offset(
                          0, 20 * (1 - _textAnimation.value)),
                      child: const Text(
                        'Your Islamic Companion',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white70,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 8),
              ListenableBuilder(
                listenable: _textAnimation,
                builder: (context, child) {
                  return FadeTransition(
                    opacity: _textAnimation,
                    child: Transform.translate(
                      offset: Offset(
                          0, 20 * (1 - _textAnimation.value)),
                      child: const Text(
                        'Developer: AzaharApps',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white54,
                          letterSpacing: 0.5,
                        ),
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
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 3),
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
              style: const TextStyle(
                  fontSize: 24, fontWeight: FontWeight.bold),
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