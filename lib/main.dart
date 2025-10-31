// lib/main.dart
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
import 'presentation/pages/quran_dictionary_page.dart';
import 'presentation/pages/islamic_calendar_page.dart';
import 'presentation/pages/more_options_page.dart';
import 'presentation/pages/bukhari_hadith_page.dart';

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
          themeMode: ThemeMode.light,
          home: const HomePage(),
          routes: {
            '/home': (context) => const HomePage(),
            '/settings': (context) => const SettingsPage(),
            '/surahList': (context) => const SurahListPage(),
            '/tasbeeh': (context) => const TasbeehPage(),
            '/namaz': (context) => const NamazTimesPage(),
            '/dictionary': (context) => const QuranDictionaryPage(),
            '/calendar': (context) => const IslamicCalendarPage(),
            '/more': (context) => const MoreOptionsPage(),
            '/hadith': (context) => const BukhariHadithPage(),
          },
          onGenerateRoute: (settings) {
            // Handle routes with arguments
            if (settings.name != null) {
              // Check if it's one of our special routes
              if (settings.name == '/rabbanaDuas' ||
                  settings.name == '/daroodIbrahim' ||
                  settings.name == '/niyat' ||
                  settings.name == '/library' ||
                  settings.name == '/quranScience' ||
                  settings.name == '/allahNames') {

                final args = settings.arguments as Map<String, dynamic>?;
                final language = args?['language'] ?? 'english';
                final title = args?['title'] ?? 'Islamic Content';

                return MaterialPageRoute(
                  builder: (context) => PlaceholderPage(
                    title: title,
                    language: language,
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

// Updated Placeholder page to show the selected language
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
            const Icon(
              Icons.construction,
              size: 64,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            Text(
              '$title Page',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Language: ${language[0].toUpperCase() + language.substring(1)}',
              style: const TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'This page is under construction',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
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