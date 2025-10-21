import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:haptic_feedback/haptic_feedback.dart';

// --- CORRECTED IMPORT PATHS ---
import '../../core/services/settings_service.dart';
import '../widgets/home_feature_card.dart';
import '../widgets/home_banner.dart';
import '../widgets/home_bottom_bar.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  void initState() {
    super.initState();
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

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // 1. Banner
            const HomeBanner(),
            // 2. Main Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16.0, vertical: 8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // 3. Primary Features (Quran)
                    _buildSectionTitle('Holy Quran', fontScale),
                    const SizedBox(height: 8),
                    _buildFeatureGrid(_primaryFeatures, 2, fontScale),
                    const SizedBox(height: 24),
                    // 4. Secondary Features
                    _buildSectionTitle('Tools & More', fontScale),
                    const SizedBox(height: 8),
                    _buildFeatureGrid(_secondaryFeatures, 3, fontScale),
                    const SizedBox(height: 24), // Padding for bottom bar
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      // 5. Bottom Bar
      bottomNavigationBar: const HomeBottomBar(),
    );
  }

  Widget _buildSectionTitle(String title, double fontScale) {
    return Padding(
      padding: const EdgeInsets.only(left: 4.0),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 22 * fontScale,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.8),
        ),
      ),
    );
  }

  Widget _buildFeatureGrid(List<Map<String, dynamic>> features,
      int crossAxisCount, double fontScale) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Calculate aspect ratio for a responsive card
        double aspectRatio = (constraints.maxWidth / crossAxisCount) / 120;
        if (aspectRatio < 1.0) aspectRatio = 1.0;

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: aspectRatio,
          ),
          itemCount: features.length,
          itemBuilder: (context, index) {
            final feature = features[index];

            // FIX: Create local variables to capture the correct values for the onTap callback
            final String route = feature['route'];
            final Map<String, dynamic>? params = feature['params'];

            return HomeFeatureCard(
              title: feature['title'],
              iconPath: feature['icon'],
              emojiIcon: feature['emoji'], // FIX: Added the emojiIcon parameter
              onTap: () {
                // HapticFeedback.light(HapticFeedbackType.selection); // FIX: Re-enabled haptics
                // FIX: Use the local variables for navigation
                Navigator.pushNamed(context, route, arguments: params);
              },
            );
          },
        );
      },
    );
  }
}