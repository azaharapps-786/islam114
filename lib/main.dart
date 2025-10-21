import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/services/settings_service.dart';
import 'core/themes/app_theme.dart';
import 'presentation/pages/home_page.dart';
import 'presentation/pages/settings_page.dart';
import 'presentation/pages/surah_list_page.dart';

void main() async {
  // Ensure Flutter bindings are initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Load settings before running the app
  final settingsService = SettingsService();
  await settingsService.loadSettings();

  runApp(
    ChangeNotifierProvider.value(
      value: settingsService,
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
          },
        );
      },
    );
  }
}