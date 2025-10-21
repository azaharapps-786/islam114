// This is a basic Flutter widget test for our Islam114 app.
//
// We are testing that the main app widget can be built and displayed
// without any errors. This is a fundamental "smoke test" to ensure
// the app starts up correctly.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:islam114/main.dart';
import 'package:islam114/core/services/settings_service.dart';
import 'package:islam114/presentation/pages/home_page.dart';

void main() {
  testWidgets('Islam114 App smoke test', (WidgetTester tester) async {
    // 1. Create an instance of our SettingsService
    final settingsService = SettingsService();

    // 2. Build our app and trigger a frame.
    // We wrap it in Provider to supply the settings service, just like in main.dart
    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: settingsService,
        child: const Islam114App(),
      ),
    );

    // 3. Verify that the home page is built by finding its title.
    // We use 'find.byType' to look for the HomePage widget itself.
    expect(find.byType(HomePage), findsOneWidget);

    // 4. (Optional) Verify that a specific text on the home page appears.
    // Let's check for the "Holy Quran" section title.
    expect(find.text('Holy Quran'), findsOneWidget);

    // 5. (Optional) Verify that one of our feature cards appears.
    // Let's check for the "Assamese Quran" card.
    expect(find.text('অসমীয়া কোৰআন'), findsOneWidget);
  });
}