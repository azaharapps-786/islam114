import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:haptic_feedback/haptic_feedback.dart';
import '../../core/services/settings_service.dart';
import 'niyat_details_page.dart';

class NiyatListPage extends StatelessWidget {
  const NiyatListPage({super.key});

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final String selectedLanguage = args?['language'] ?? 'english';
    final double fontScale = Provider.of<SettingsService>(context).fontScale;

    // Comprehensive Translation Map
    final Map<String, Map<String, dynamic>> uiLabels = {
      'english': {
        'header': 'Niyat (Intentions)',
        'special': 'Special Occasions',
        'fard': 'Daily Fard Prayers',
        'sunnah': 'Sunnah & Nawafil',
        'fard_sub': 'Rakats Fard',
        'titles': {
          'Eid-ul-Fitr': 'Eid-ul-Fitr',
          'Eid-ul-Adha': 'Eid-ul-Adha',
          'Janaza Male': 'Janaza (Male)',
          'Janaza Female': 'Janaza (Female)',
          'Fajr Prayer': 'Fajr Prayer',
          'Zuhr Prayer': 'Zuhr Prayer',
          'Asr Prayer': 'Asr Prayer',
          'Maghrib Prayer': 'Maghrib Prayer',
          'Isha Prayer': 'Isha Prayer',
          'Tahajjud': 'Tahajjud',
          'Salat-al-Tasbeeh': 'Salat-al-Tasbeeh',
          'Salat-al-Hajat': 'Salat-al-Hajat',
          'Ishraq Prayer': 'Ishraq Prayer',
        },
        'subs': {
          'tahajjud': 'Late Night Prayer',
          'tasbeeh': 'Prayer of Forgiveness',
          'hajat': 'Prayer for Need',
          'ishraq': 'Post-Sunrise Prayer',
        }
      },
      'hindi': {
        'header': 'नियत (इरादा)',
        'special': 'विशेष अवसर',
        'fard': 'दैनिक फ़र्ज़ नमाज़',
        'sunnah': 'सुन्नत और नवाफिल',
        'fard_sub': 'रकअत फ़र्ज़',
        'titles': {
          'Eid-ul-Fitr': 'ईदुल फ़ित्र',
          'Eid-ul-Adha': 'ईदुल अज़हा',
          'Janaza Male': 'जनाज़ा (पुरुष)',
          'Janaza Female': 'जनाज़ा (स्त्री)',
          'Fajr Prayer': 'फज्र की नमाज़',
          'Zuhr Prayer': 'जुहर की नमाज़',
          'Asr Prayer': 'असर की नमाज़',
          'Maghrib Prayer': 'मग़रिब की नमाज़',
          'Isha Prayer': 'ईशा की नमाज़',
          'Tahajjud': 'तहज्जुद',
          'Salat-al-Tasbeeh': 'सलात-अल-तस्बीह',
          'Salat-al-Hajat': 'सलात-अल-हाजत',
          'Ishraq Prayer': 'इशराक की नमाज़',
        },
        'subs': {
          'tahajjud': 'देर रात की नमाज़',
          'tasbeeh': 'क्षमा की नमाज़',
          'hajat': 'ज़रूरत के लिए नमाज़',
          'ishraq': 'सूर्योदय के बाद की नमाज़',
        }
      },
      'bengali': {
        'header': 'নিয়ত (উদ্দেশ্য)',
        'special': 'বিশেষ দিনসমূহ',
        'fard': 'দৈনিক ফরজ নামাজ',
        'sunnah': 'সুন্নত ও নফল',
        'fard_sub': 'রাকাত ফরজ',
        'titles': {
          'Eid-ul-Fitr': 'ঈদুল ফিতর',
          'Eid-ul-Adha': 'ঈদুল আযহা',
          'Janaza Male': 'জানাজা (পুরুষ)',
          'Janaza Female': 'জানাজা (নারী)',
          'Fajr Prayer': 'ফজর নামাজ',
          'Zuhr Prayer': 'যোহর নামাজ',
          'Asr Prayer': 'আসর নামাজ',
          'Maghrib Prayer': 'মাগরিব নামাজ',
          'Isha Prayer': 'এশা নামাজ',
          'Tahajjud': 'তাহাজ্জুদ',
          'Salat-al-Tasbeeh': 'সালাতুত তাসবীহ',
          'Salat-al-Hajat': 'সালাতুল হাজত',
          'Ishraq Prayer': 'ইশরাক নামাজ',
        },
        'subs': {
          'tahajjud': 'শেষ রাতের নামাজ',
          'tasbeeh': 'ক্ষমা প্রার্থনার নামাজ',
          'hajat': 'প্রয়োজনের নামাজ',
          'ishraq': 'সূর্যোদয়ের পরের নামাজ',
        }
      },
      'assamese': {
        'header': 'নিয়ত (অভিপ্ৰায়)',
        'special': 'বিশেষ অনুষ্ঠানসমূহ',
        'fard': 'দৈনিক ফৰজ নামাজ',
        'sunnah': 'ছুন্নত আৰু নফল',
        'fard_sub': 'ৰাকাত ফৰজ',
        'titles': {
          'Eid-ul-Fitr': 'ঈদুল ফিতৰ',
          'Eid-ul-Adha': 'ঈদুল আজহা',
          'Janaza Male': 'জানাজা (পুৰুষ)',
          'Janaza Female': 'জানাজা (মহিলা)',
          'Fajr Prayer': 'ফজৰ নামাজ',
          'Zuhr Prayer': 'জোহৰ নামাজ',
          'Asr Prayer': 'আছৰ নামাজ',
          'Maghrib Prayer': 'মাগৰিব নামাজ',
          'Isha Prayer': 'এশা নামাজ',
          'Tahajjud': 'তাহাজ্জুদ',
          'Salat-al-Tasbeeh': 'ছালাতুত তাছবীহ',
          'Salat-al-Hajat': 'ছালাতুল হাজত',
          'Ishraq Prayer': 'ইশ্বৰাক নামাজ',
        },
        'subs': {
          'tahajjud': 'শেষ নিশাৰ নামাজ',
          'tasbeeh': 'ক্ষমাৰ নামাজ',
          'hajat': 'প্ৰয়োজনৰ নামাজ',
          'ishraq': 'সূৰ্যোদয়ৰ পাছৰ নামাজ',
        }
      },
    };

    final labels = uiLabels[selectedLanguage.toLowerCase()] ?? uiLabels['english']!;
    final titles = labels['titles'] as Map<String, String>;
    final subs = labels['subs'] as Map<String, String>;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF063B3B), Color(0xFF0A4D4D), Color(0xFFF0F7F0)],
            stops: [0.0, 0.3, 1.0],
          ),
        ),
        child: SafeArea(
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              _buildHeader(context, fontScale, labels['header']!),

              _buildSectionHeader(labels['special']!, Icons.star_rounded, fontScale),
              _buildNiyatGrid([
                {'id': 'Eid-ul-Fitr', 'title': titles['Eid-ul-Fitr'], 'icon': Icons.celebration_rounded, 'color': Colors.orange},
                {'id': 'Eid-ul-Adha', 'title': titles['Eid-ul-Adha'], 'icon': Icons.festival_rounded, 'color': Colors.deepOrange},
                // Updated IDs to match your getNiyatData Map keys exactly
                // Male Janaza
                // Male Janaza
                {
                  'id': 'Janaza Niyat (Male Deceased)',
                  'title': titles['Janaza Male'],
                  'icon': Icons.account_box_rounded, // Boxed portrait look, very formal
                  'color': Colors.blueGrey.shade300,
                },

// Female Janaza
                {
                  'id': 'Janaza Niyat (Female Deceased)',
                  'title': titles['Janaza Female'],
                  'icon': Icons.portrait_rounded, // Slightly softer, elegant frame
                  'color': Colors.blueGrey.shade100,
                },
              ], fontScale, selectedLanguage),

              _buildSectionHeader(labels['fard']!, Icons.wb_sunny_rounded, fontScale),
              _buildNiyatList([
                {'id': 'Fajr Prayer', 'title': titles['Fajr Prayer'], 'subtitle': '2 ${labels['fard_sub']}'},
                {'id': 'Zuhr Prayer', 'title': titles['Zuhr Prayer'], 'subtitle': '4 ${labels['fard_sub']}'},
                {'id': 'Asr Prayer', 'title': titles['Asr Prayer'], 'subtitle': '4 ${labels['fard_sub']}'},
                {'id': 'Maghrib Prayer', 'title': titles['Maghrib Prayer'], 'subtitle': '3 ${labels['fard_sub']}'},
                {'id': 'Isha Prayer', 'title': titles['Isha Prayer'], 'subtitle': '4 ${labels['fard_sub']}'},
              ], fontScale, selectedLanguage),

              _buildSectionHeader(labels['sunnah']!, Icons.auto_awesome_rounded, fontScale),
              _buildNiyatList([
                {'id': 'Tahajjud', 'title': titles['Tahajjud'], 'subtitle': subs['tahajjud']},
                {'id': 'Salat-al-Tasbeeh', 'title': titles['Salat-al-Tasbeeh'], 'subtitle': subs['tasbeeh']},
                {'id': 'Salat-al-Hajat', 'title': titles['Salat-al-Hajat'], 'subtitle': subs['hajat']},
                {'id': 'Ishraq Prayer', 'title': titles['Ishraq Prayer'], 'subtitle': subs['ishraq']},
              ], fontScale, selectedLanguage),

              const SliverToBoxAdapter(child: SizedBox(height: 40)),
            ],
          ),
        ),
      ),
    );
  }

  // --- Helper Methods remain identical to your original code ---

  Widget _buildHeader(BuildContext context, double fontScale, String title) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
              padding: EdgeInsets.zero,
              alignment: Alignment.centerLeft,
            ),
            const SizedBox(height: 20),
            Text(title, style: TextStyle(fontSize: (28 * fontScale).clamp(24.0, 34.0), fontWeight: FontWeight.w900, color: Colors.white)),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, double fontScale) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
        child: Row(
          children: [
            Icon(icon, color: Colors.white70, size: 20),
            const SizedBox(width: 8),
            Text(title.toUpperCase(), style: TextStyle(color: Colors.white.withOpacity(0.9), fontWeight: FontWeight.bold, fontSize: (12 * fontScale).clamp(10.0, 14.0))),
          ],
        ),
      ),
    );
  }

  Widget _buildNiyatGrid(List<Map<String, dynamic>> items, double fontScale, String lang) {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2, // Changed to 2 to accommodate Janaza labels better
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.6
        ),
        delegate: SliverChildBuilderDelegate((context, index) {
          final item = items[index];
          return InkWell(
            onTap: () {
              Haptics.vibrate(HapticsType.light);
              Navigator.push(context, MaterialPageRoute(builder: (context) => NiyatDetailsPage(title: item['id'], language: lang)));
            },
            child: Container(
              decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.white12)),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(item['icon'], color: item['color'], size: 28),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: Text(item['title'], textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontSize: 13 * fontScale, fontWeight: FontWeight.w500)),
                  ),
                ],
              ),
            ),
          );
        },
          childCount: items.length,
        ),
      ),
    );
  }

  Widget _buildNiyatList(List<Map<String, dynamic>> items, double fontScale, String lang) {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate((context, index) {
          final item = items[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Container(
              decoration: BoxDecoration(color: Colors.white.withOpacity(0.9), borderRadius: BorderRadius.circular(24)),
              child: ListTile(
                title: Text(item['title'], style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(item['subtitle']),
                trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
                onTap: () {
                  Haptics.vibrate(HapticsType.light);
                  Navigator.push(context, MaterialPageRoute(builder: (context) => NiyatDetailsPage(title: item['id'], language: lang)));
                },
              ),
            ),
          );
        },
          childCount: items.length,
        ),
      ),
    );
  }
}