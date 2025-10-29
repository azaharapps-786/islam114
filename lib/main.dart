import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/services/settings_service.dart';
import 'core/themes/app_theme.dart';
import 'core/providers/prayer_times_provider.dart';
import 'presentation/pages/home_page.dart';
import 'presentation/pages/settings_page.dart';
import 'presentation/pages/surah_list_page.dart';
import 'presentation/pages/tasbeeh_page.dart';
import 'presentation/pages/namaz_times_page.dart';
import 'presentation/pages/quran_dictionary_page.dart'; // Add this import

void main() async {
  // Ensure Flutter bindings are initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Load settings before running the app
  final settingsService = SettingsService();
  await settingsService.loadSettings();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(
          value: settingsService,
        ),
        ChangeNotifierProvider(
          create: (_) => PrayerTimesProvider(),
        ),
      ],
      child: const Islam114App(),
    ),
  );
}

class Islam114App extends StatelessWidget {
  const Islam114App({super.key});

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
          home: const HomePage(),
          routes: {
            '/home': (context) => const HomePage(),
            '/settings': (context) => const SettingsPage(),
            '/surahList': (context) => const SurahListPage(),
            '/tasbeeh': (context) => const TasbeehPage(),
            '/namaz': (context) => const NamazTimesPage(),
            '/dictionary': (context) => const QuranDictionaryPage(), // Add this route
          },
        );
      },
    );
  }
}