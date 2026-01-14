import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/services/settings_service.dart';

class DaroodPage extends StatelessWidget {
  final String language;

  const DaroodPage({super.key, required this.language});

  @override
  Widget build(BuildContext context) {
    final double fontScale = Provider.of<SettingsService>(context).fontScale;
    final String langKey = language.toLowerCase();

    // Dynamic page title & section labels
    final Map<String, Map<String, String>> langContent = {
      'english': {
        'title': 'Durood-e-Ibrahimi',
        'transliteration': 'Transliteration',
        'translation': 'Translation',
      },
      'hindi': {
        'title': 'दरूद-ए-इब्राहिमी',
        'transliteration': 'उच्चारण',
        'translation': 'अनुवाद',
      },
      'bengali': {
        'title': 'দরূদ-ই-ইব্রাহিমী',
        'transliteration': 'উচ্চারণ',
        'translation': 'অনুবাদ',
      },
      'assamese': {
        'title': 'দৰূদ-ই-ইব্ৰাহীমী',
        'transliteration': 'উচ্চাৰণ',
        'translation': 'অনুবাদ',
      },
    };

    // Fallback to English if language not found
    final Map<String, String> currentLang = langContent[langKey] ?? langContent['english']!;

    // Durood content (already good, just using dynamic keys)
    final Map<String, dynamic> data = {
      'arabic': 'اللَّهُمَّ صَلِّ عَلَى مُحَمَّدٍ وَعَلَى آلِ مُحَمَّدٍ كَمَا صَلَّيْتَ عَلَى إِبْرَاهِيمَ وَعَلَى آلِ إِبْرَاهِيمَ إِنَّكَ حَمِيدٌ مَجِيدٌ، اللَّهُمَّ بَارِكْ عَلَى مُحَمَّدٍ وَعَلَى آلِ مُحَمَّدٍ كَمَا بَارَكْتَ عَلَى إِبْرَاهِيمَ وَعَلَى آلِ إِبْرَاهِيمَ إِنَّكَ حَمِيدٌ مَجِيدٌ',
      'transliterations': {
        'english': 'Allahumma salli \'ala Muhammadin wa \'ala ali Muhammadin kama sallayta \'ala Ibrahima wa \'ala ali Ibrahima innaka Hamidun Majid. Allahumma barik \'ala Muhammadin wa \'ala ali Muhammadin kama barakta \'ala Ibrahima wa \'ala ali Ibrahima innaka Hamidun Majid.',
        'hindi': 'अल्लाहुम्मा सल्लि अला मुहम्मदिन व अला आलि मुहम्मदिन कमा सल्लैता अला इब्राहीमा व अला आलि इब्राहीमा इन्नका हमीदुन मजीद। अल्लाहुम्मा बारिक अला मुहम्मदिन व अला आलि मुहम्मदिन कमा बारक्ता अला इब्राहीमा व अला आलि इब्राहीमा इन्नका हमीदुन मजीद।',
        'bengali': 'আল্লাহুম্মা সাল্লি আলা মুহাম্মাদিওঁ ওয়া আলা আলি মুহাম্মাদিন কামা সাল্লাইতা আলা ইব্রাহীমা ওয়া আলা আলি ইব্রাহীমা ইন্নাকা হামীদুম মাজীদ। আল্লাহুম্মা বারিক আলা মুহাম্মাদিওঁ ওয়া আলা আলি মুহাম্মাদিন কামা বারাকতা আলা ইব্রাহীমা ওয়া আলা আলি ইব্রাহীমা ইন্নাকা হামীদুম মাজীদ।',
        'assamese': 'আল্লাহুম্মা ছাল্লি আলা মুহাম্মাদিওঁ ওয়া আলা আলি মুহাম্মাদিন কামা ছাল্লাইতা আলা ইব্ৰাহীমা ওয়া আলা আলি ইব্ৰাহীমা ইন্নাকা হামীদুম মাজীদ। আল্লাহুম্মা বাৰিক আলা মুহাম্মাদিওঁ ওয়া আলা আলি মুহাম্মাদিন কামা বাৰাকতা আলা ইব্ৰাহীমা ওয়া আলা আলি ইব্ৰাহীমা ইন্নাকা হামীদুম মাজীদ।',
      },
      'translations': {
        'english': 'O Allah, let Your Peace come upon Muhammad and the family of Muhammad, as you have sent peace upon Ibrahim and his family. Truly, You are Praiseworthy and Glorious. O Allah, bless Muhammad and the family of Muhammad, as you have blessed Ibrahim and his family. Truly, You are Praiseworthy and Glorious.',
        'hindi': 'ऐ अल्लाह! रहमत नाज़िल फर मुहम्मद (सल्लल्लाहु अलैहि वसल्लम) पर और उनकी आल (औलाद) पर, जिस तरह तूने रहमत नाज़िल फरमाई इब्राहीम (अलैहिस्सलाम) पर और उनकी आल पर, बेशक तू तारीफ के लायक और बड़ी बुजुर्गी वाला है।',
        'bengali': 'হে আল্লাহ! মুহাম্মদ (সা.) ও তাঁর বংশধরদের ওপর রহমত বর্ষণ করুন, যেভাবে আপনি ইব্রাহিম (আ.) ও তাঁর বংশধরদের ওপর রহমত বর্ষণ করেছিলেন। নিশ্চয়ই আপনি প্রশংসিত ও সম্মানিত। হে আল্লাহ! মুহাম্মদ (সা.) ও তাঁর বংশধরদের ওপর বরকত বর্ষণ করুন...',
        'assamese': 'হে আল্লাহ! মুহাম্মদ (ছাঃ) আৰু তেওঁৰ বংশধৰসকলৰ ওপৰত ৰহমত বৰ্ষণ কৰক, যেনেকৈ আপুনি ইব্ৰাহিম (আঃ) আৰু তেওঁৰ বংশধৰসকলৰ ওপৰত ৰহমত বৰ্ষণ কৰিছিল। নিশ্চয় আপুনি প্রশংসিত আৰু সম্মানিত।',
      }
    };

    return Scaffold(
      backgroundColor: const Color(0xFF063B3B),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          currentLang['title']!,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Arabic Card (same in all languages)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.white24),
              ),
              child: Text(
                data['arabic'],
                textAlign: TextAlign.center,
                textDirection: TextDirection.rtl,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: (26 * fontScale).clamp(22.0, 32.0),
                  fontFamily: 'Amiri',
                  height: 1.8,
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Transliteration Header
            _buildLabel(currentLang['transliteration']!),
            _buildContentBox(
              data['transliterations'][langKey] ?? data['transliterations']['english'],
              fontScale,
              Colors.white70,
            ),

            const SizedBox(height: 20),

            // Translation Header
            _buildLabel(currentLang['translation']!),
            _buildContentBox(
              data['translations'][langKey] ?? data['translations']['english'],
              fontScale,
              Colors.white,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        text.toUpperCase(),
        style: const TextStyle(
          color: Colors.tealAccent,
          fontWeight: FontWeight.bold,
          fontSize: 12,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildContentBox(String text, double fontScale, Color textColor) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.black26,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: textColor,
          fontSize: (16 * fontScale).clamp(14.0, 20.0),
          height: 1.5,
        ),
      ),
    );
  }
}