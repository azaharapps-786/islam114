import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:haptic_feedback/haptic_feedback.dart';
import '../../core/services/settings_service.dart';

class LibraryListPage extends StatelessWidget {
  const LibraryListPage({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsService>(context);
    final double fontScale = settings.fontScale;

    // 1. GET LANGUAGE FROM NAVIGATION ARGUMENTS (Most Reliable)
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    String currentLang = args?['language']?.toString().toLowerCase() ?? 'english';

    // 2. FALLBACK TO SERVICE (If navigation fails)
    if (currentLang == 'english') {
      try {
        currentLang = (settings as dynamic).selectedLanguage?.toString().toLowerCase() ??
            (settings as dynamic).language?.toString().toLowerCase() ??
            'english';
      } catch (e) {
        currentLang = 'english';
      }
    }

    final List<Map<String, String>> books = [
      {
        'id': '1',
        'english_title': 'Quran and Science',
        'hindi_title': 'कुरान और विज्ञान',
        'bengali_title': 'কুরআন ও বিজ্ঞান',
        'assamese_title': 'কোৰআন আৰু বিজ্ঞান',
        'english_desc': 'Exploring the scientific miracles in the Holy Quran.',
        'hindi_desc': 'पवित्र कुरान में वैज्ञानिक चमत्कारों की खोज।',
        'bengali_desc': 'পবিত্র কুরআনের বৈজ্ঞানিক অলৌকিকতা অনুসন্ধান।',
        'assamese_desc': 'পবিত্ৰ কোৰআনৰ বৈজ্ঞানিক অলৌকিকতাৰ সন্ধান।',
        'icon': '🔬',
      },
    ];

    return Scaffold(
      backgroundColor: const Color(0xDDD0F7F0),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFF0A4D4D),
        centerTitle: true,
        title: Text(
          _getAppBarTitle(currentLang), // Localized AppBar Title
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: (20 * fontScale).clamp(18, 24),
          ),
        ),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: books.length,
        itemBuilder: (context, index) {
          final book = books[index];

          // Logic to select title and description based on language
          String title = book['${currentLang}_title'] ?? book['english_title']!;
          String desc = book['${currentLang}_desc'] ?? book['english_desc']!;

          return _buildBookCard(context, title, desc, book['icon']!, fontScale);
        },
      ),
    );
  }

  // Helper to translate the AppBar title too
  String _getAppBarTitle(String lang) {
    switch (lang) {
      case 'assamese': return "ইছলামিক লাইব্ৰেৰী";
      case 'bengali': return "ইসলামিক লাইব্রেরি";
      case 'hindi': return "इस्लामिक लाइब्रेरी";
      default: return "Islamic Library";
    }
  }

  Widget _buildBookCard(BuildContext context, String title, String desc, String icon, double fontScale) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0A4D4D).withOpacity(0.15),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            Haptics.vibrate(HapticsType.selection);
          },
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0A4D4D).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Text(icon, style: const TextStyle(fontSize: 30)),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 18 * fontScale,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF0A4D4D),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        desc,
                        style: TextStyle(
                          fontSize: 13 * fontScale,
                          color: Colors.grey[600],
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
              ],
            ),
          ),
        ),
      ),
    );
  }
}