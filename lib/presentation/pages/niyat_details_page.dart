import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:haptic_feedback/haptic_feedback.dart';
import '../../core/services/settings_service.dart';

class NiyatDetailsPage extends StatelessWidget {
  final String title;
  final String language;

  const NiyatDetailsPage({
    super.key,
    required this.title,
    required this.language,
  });

  Map<String, dynamic> getNiyatData() {
    final Map<String, Map<String, dynamic>> data = {
      // ── Daily Fard Prayers ─────────────────────────────
      'Fajr Prayer': {
        'arabic': 'نَوَيْتُ أَنْ أُصَلِّيَ لِلَّهِ تَعَالَى رَكْعَتَيْ صَلَاةِ الْفَجْرِ فَرْضًا لِلَّهِ تَعَالَى مُتَوَجِّهًا إِلَى جِهَةِ الْكَعْبَةِ الشَّرِيفَةِ اللَّهُ أَكْبَرُ',
        'transliterations': {
          'english': "Nawaitu an usalliya lillahi ta'ala rak'atay salatil fajri fardan lillahi ta'ala mutawajjihan ila jihatil ka'bati sh-sharifah Allahu Akbar.",
          'hindi': 'नवैतु अन उसल्लिया लिल्लाहि तआला रकअतैन सलातिल फज्र फरज़न लिल्लाहि तआला मुतवज्जिहन इला जिहतिल काबतिश शरीफा अल्लाहु अकबर।',
          'bengali': 'নাওয়াইতু আন উসাল্লিয়া লিল্লাহি তা‘আলা রাক‘আতাই সালাতিল ফজরি ফারদান লিল্লাহি তা‘আলা মুতাওয়াজ্জিহান ইলা জিহাতিল কা‘বাতিশ শারীফাহ আল্লাহু আকবার।',
          'assamese': 'নাৱাইতু আন উছাল্লিয়া লিল্লাহি তা‘আলা ৰক‘আতাই ছালাতিল ফজৰি ফৰজন লিল্লাহি তা‘আলা মুতাৱাজ্জিহান ইলা জিহাতিল কা‘বাতিশ শ্বৰীফা আল্লাহু আকবৰ।',
        },
        'translations': {
          'english': 'I intend to offer two rak’ats of the Fajr obligatory prayer for Allah Ta’ala, facing towards the Holy Kaaba. Allahu Akbar.',
          'hindi': 'मैं अल्लाह तआला के लिए फज्र की दो रकअत फर्ज़ नमाज़ अदा करने की नियत करता/करती हूँ, क़िबला शरीफ की तरफ़ मुंह करके। अल्लाहु अकबर।',
          'bengali': 'আমি আল্লাহ তা‘আলার জন্য ফজরের দুই রাকাত ফরজ নামাজ আদায় করার নিয়ত করছি, কিবলার দিকে মুখ করে। আল্লাহু আকবার।',
          'assamese': 'মই আল্লাহ তা‘আলাৰ বাবে ফজৰৰ দুই ৰকাত ফৰজ নামাজ আদায় কৰাৰ নিয়ত কৰিছোঁ, কিবলাৰ ফালে মুখ কৰি। আল্লাহু আকবৰ।',
        }
      },
      'Zuhr Prayer': {
        'arabic': 'نَوَيْتُ أَنْ أُصَلِّيَ لِلَّهِ تَعَالَى أَرْبَعَ رَكَعَاتٍ صَلَاةِ الظُّهْرِ فَرْضًا لِلَّهِ تَعَالَى مُتَوَجِّهًا إِلَى جِهَةِ الْكَعْبَةِ الشَّرِيفَةِ اللَّهُ أَكْبَرُ',
        'transliterations': {
          'english': "Nawaitu an usalliya lillahi ta'ala arba'a raka'atin salatiz zuhri fardan lillahi ta'ala mutawajjihan ila jihatil ka'bati sh-sharifah Allahu Akbar.",
          'hindi': 'नवैतु अन उसल्लिया लिल्लाहि तआला अरबा रकआत सलातिज़ ज़ुह्र फरज़न लिल्लाहि तआला मुतवज्जिहन इला जिहतिल काबतिश शरीफा अल्लाहु अकबर।',
          'bengali': 'নাওয়াইতু আন উসাল্লিয়া লিল্লাহি তা‘আলা আরবা রাকাআত সালাতিজ জুহরি ফারদান লিল্লাহি তা‘আলা মুতাওয়াজ্জিহান ইলা জিহাতিল কা‘বাতিশ শারীফাহ আল্লাহু আকবার।',
          'assamese': 'নাৱাইতু আন উছাল্লিয়া লিল্লাহি তা‘আলা আৰবা ৰকাআত ছালাতিজ জোহৰি ফৰজন লিল্লাহি তা‘আলা মুতাৱাজ্জিহান ইলা জিহাতিল কা‘বাতিশ শ্বৰীফা আল্লাহু আকবৰ।',
        },
        'translations': {
          'english': 'I intend to offer four rak’ats of the Zuhr obligatory prayer for Allah Ta’ala, facing towards the Holy Kaaba. Allahu Akbar.',
          'hindi': 'मैं अल्लाह तआला के लिए ज़ुहर की चार रकअत फर्ज़ नमाज़ अदा करने की नियत करता/करती हूँ, क़िबला शरीफ की तरफ़ मुंह करके। अल्लाहु अकबर।',
          'bengali': 'আমি আল্লাহ তা‘আলার জন্য যোহরের চার রাকাত ফরজ নামাজ আদায় করার নিয়ত করছি, কিবলার দিকে মুখ করে। আল্লাহু আকবার।',
          'assamese': 'মই আল্লাহ তা‘আলাৰ বাবে জোহৰৰ চাৰি ৰকাত ফৰজ নামাজ আদায় কৰাৰ নিয়ত কৰিছোঁ, কিবলাৰ ফালে মুখ কৰি। আল্লাহু আকবৰ।',
        }
      },
      'Asr Prayer': {
        'arabic': 'نَوَيْتُ أَنْ أُصَلِّيَ لِلَّهِ تَعَالَى أَرْبَعَ رَكَعَاتٍ صَلَاةِ الْعَصْرِ فَرْضًا لِلَّهِ تَعَالَى مُتَوَجِّهًا إِلَى جِهَةِ الْكَعْبَةِ الشَّرِيفَةِ اللَّهُ أَكْبَرُ',
        'transliterations': {
          'english': "Nawaitu an usalliya lillahi ta'ala arba'a raka'atin salatil asri fardan lillahi ta'ala mutawajjihan ila jihatil ka'bati sh-sharifah Allahu Akbar.",
          'hindi': 'नवैतु अन उसल्लिया लिल्लाहि तआला अरबा रकआत सलातिल अस्र फरज़न लिल्लाहि तआला मुतवज्जिहन इला जिहतिल काबतिश शरीफा अल्लाहु अकबर।',
          'bengali': 'নাওয়াইতু আন উসাল্লিয়া লিল্লাহি তা‘আলা আরবা রাকাআত সালাতিল আসরি ফারদান লিল্লাহি তা‘আলা মুতাওয়াজ্জিহান ইলা জিহাতিল কা‘বাতিশ শারীফাহ আল্লাহু আকবার।',
          'assamese': 'নাৱাইতু আন উছাল্লিয়া লিল্লাহি তা‘আলা আৰবা ৰকাআত ছালাতিল আছৰি ফৰজন লিল্লাহি তা‘আলা মুতাৱাজ্জিহান ইলা জিহাতিল কা‘বাতিশ শ্বৰীফা আল্লাহু আকবৰ।',
        },
        'translations': {
          'english': 'I intend to offer four rak’ats of the Asr obligatory prayer for Allah Ta’ala, facing towards the Holy Kaaba. Allahu Akbar.',
          'hindi': 'मैं अल्लाह तआला के लिए अस्र की चार रकअत फर्ज़ नमाज़ अदा करने की नियत करता/करती हूँ, क़िबला शरीफ की तरफ़ मुंह करके। अल्लाहु अकबर।',
          'bengali': 'আমি আল্লাহ তা‘আলার জন্য আসরের চার রাকাত ফরজ নামাজ আদায় করার নিয়ত করছি, কিবলার দিকে মুখ করে। আল্লাহু আকবার।',
          'assamese': 'মই আল্লাহ তা‘আলাৰ বাবে আছৰৰ চাৰি ৰকাত ফৰজ নামাজ আদায় কৰাৰ নিয়ত কৰিছোঁ, কিবলাৰ ফালে মুখ কৰি। আল্লাহু আকবৰ।',
        }
      },
      'Maghrib Prayer': {
        'arabic': 'نَوَيْتُ أَنْ أُصَلِّيَ لِلَّهِ تَعَالَى ثَلَاثَ رَكَعَاتٍ صَلَاةِ الْمَغْرِبِ فَرْضًا لِلَّهِ تَعَالَى مُتَوَجِّهًا إِلَى جِهَةِ الْكَعْبَةِ الشَّرِيفَةِ اللَّهُ أَكْبَرُ',
        'transliterations': {
          'english': "Nawaitu an usalliya lillahi ta'ala thalatha raka'atin salatil maghribi fardan lillahi ta'ala mutawajjihan ila jihatil ka'bati sh-sharifah Allahu Akbar.",
          'hindi': 'नवैतु अन उसल्लिया लिल्लाहि तआला सलासा रकआत सलातिल मग़रिब फरज़न लिल्लाहि तआला मुतवज्जिहन इला जिहतिल काबतिश शरीफा अल्लाहु अकबर।',
          'bengali': 'নাওয়াইতু আন উসাল্লিয়া লিল্লাহি তা‘আলা সালাসা রাকাআত সালাতিল মাগরিব ফারদান লিল্লাহি তা‘আলা মুতাওয়াজ্জিহান ইলা জিহাতিল কা‘বাতিশ শারীফাহ আল্লাহু আকবার।',
          'assamese': 'নাৱাইতু আন উছাল্লিয়া লিল্লাহি তা‘আলা থলাথা ৰকাআত ছালাতিল মাগৰিব ফৰজন লিল্লাহি তা‘আলা মুতাৱাজ্জিহান ইলা জিহাতিল কা‘বাতিশ শ্বৰীফা আল্লাহু আকবৰ।',
        },
        'translations': {
          'english': 'I intend to offer three rak’ats of the Maghrib obligatory prayer for Allah Ta’ala, facing towards the Holy Kaaba. Allahu Akbar.',
          'hindi': 'मैं अल्लाह तआला के लिए मग़रिब की तीन रकअत फर्ज़ नमाज़ अदा करने की नियत करता/करती हूँ, क़िबला शरीफ की तरफ़ मुंह करके। अल्लाहु अकबर।',
          'bengali': 'আমি আল্লাহ তা‘আলার জন্য মাগরিবের তিন রাকাত ফরজ নামাজ আদায় করার নিয়ত করছি, কিবলার দিকে মুখ করে। আল্লাহু আকবার।',
          'assamese': 'মই আল্লাহ তা‘আলাৰ বাবে মাগৰিবৰ তিনি ৰকাত ফৰজ নামাজ আদায় কৰাৰ নিয়ত কৰিছোঁ, কিবলাৰ ফালে মুখ কৰি। আল্লাহু আকবৰ।',
        }
      },
      'Isha Prayer': {
        'arabic': 'نَوَيْتُ أَنْ أُصَلِّيَ لِلَّهِ تَعَالَى أَرْبَعَ رَكَعَاتٍ صَلَاةِ الْعِشَاءِ فَرْضًا لِلَّهِ تَعَالَى مُتَوَجِّهًا إِلَى جِهَةِ الْكَعْبَةِ الشَّرِيفَةِ اللَّهُ أَكْبَرُ',
        'transliterations': {
          'english': "Nawaitu an usalliya lillahi ta'ala arba'a raka'atin salatil isha'i fardan lillahi ta'ala mutawajjihan ila jihatil ka'bati sh-sharifah Allahu Akbar.",
          'hindi': 'नवैतु अन उसल्लिया लिल्लाहि तआला अरबा रकआत सलातिल इशा फरज़न लिल्लाहि तआला मुतवज्जिहन इला जिहतिल काबतिश शरीफा अल्लाहु अकबर।',
          'bengali': 'নাওয়াইতু আন উসাল্লিয়া লিল্লাহি তা‘আলা আরবা রাকাআত সালাতিল ইশা ফারদান লিল্লাহি তা‘আলা মুতাওয়াজ্জিহান ইলা জিহাতিল কা‘বাতিশ শারীফাহ আল্লাহু আকবার।',
          'assamese': 'নাৱাইতু আন উছাল্লিয়া লিল্লাহি তা‘আলা আৰবা ৰকাআত ছালাতিল ইশা ফৰজন লিল্লাহি তা‘আলা মুতাৱাজ্জিহান ইলা জিহাতিল কা‘বাতিশ শ্বৰীফা আল্লাহু আকবৰ।',
        },
        'translations': {
          'english': 'I intend to offer four rak’ats of the Isha obligatory prayer for Allah Ta’ala, facing towards the Holy Kaaba. Allahu Akbar.',
          'hindi': 'मैं अल्लाह तआला के लिए इशा की चार रकअत फर्ज़ नमाज़ अदा करने की नियत करता/करती हूँ, क़िबला शरीफ की तरफ़ मुंह करके। अल्लाहु अकबर।',
          'bengali': 'আমি আল্লাহ তা‘আলার জন্য এশার চার রাকাত ফরজ নামাজ আদায় করার নিয়ত করছি, কিবলার দিকে মুখ করে। আল্লাহু আকবার।',
          'assamese': 'মই আল্লাহ তা‘আলাৰ বাবে এশাৰ চাৰি ৰকাত ফৰজ নামাজ আদায় কৰাৰ নিয়ত কৰিছোঁ, কিবলাৰ ফালে মুখ কৰি। আল্লাহু আকবৰ।',
        }
      },

      // ── Janaza Niyats ─────────────────────────────
      'Janaza Niyat (Male Deceased)': {
        'arabic': 'نَوَيْتُ أَنْ أُصَلِّيَ لِلَّهِ تَعَالَى أَرْبَعَ تَكْبِيرَاتٍ صَلَاةَ الْجَنَازَةِ عَلَى هَذَا الْمَيِّتِ فَرْضَ الْكِفَايَةِ مُتَوَجِّهًا إِلَى جِهَةِ الْكَعْبَةِ الشَّرِيفَةِ اللَّهُ أَكْبَرُ',
        'transliterations': {
          'english': "Nawaitu an usalliya lillahi ta'ala arba'a takbiratin salatal janazati 'ala hadhal mayyiti fardal kifayati mutawajjihan ila jihatil ka'bati sh-sharifah Allahu Akbar.",
          'hindi': 'नवैतु अन उसल्लिया लिल्लाहि तआला अरबा तकबीरात सलातल जनाज़ा अला हाज़ल मय्यित फरज़ल किफायति मुतवज्जिहन इला जिहतिल काबतिश शरीफा अल्लाहु अकबर।',
          'bengali': 'নাওয়াইতু আন উসাল্লিয়া লিল্লাহি তা‘আলা আরবা তাকবীরাত সালাতাল জানাজাতি আলা হাযাল মাইয়্যিতি ফারদাল কিফায়াতি মুতাওয়াজ্জিহান ইলা জিহাতিল কা‘বাতিশ শারীফাহ আল্লাহু আকবার।',
          'assamese': 'নাৱাইতু আন উছাল্লিয়া লিল্লাহি তা‘আলা আৰবা তাকবীৰাত ছালাতাল জানাজা আলা হাজাল মাইয়্যিতি ফৰজল কিফায়তি মুতাৱাজ্জিহান ইলা জিহাতিল কা‘বাতিশ শ্বৰীফা আল্লাহু আকবৰ।',
        },
        'translations': {
          'english': 'I intend to pray four takbirs of Janaza prayer for Allah Ta’ala upon this deceased (male), as fard kifayah, facing the Holy Kaaba. Allahu Akbar.',
          'hindi': 'मैं अल्लाह तआला के लिए इस मय्यित (पुरुष) पर चार तकबीरों वाली नमाज़-ए-जनाज़ा अदा करने की नियत करता/करती हूँ, फर्ज़-ए-किफाया, क़िबला की तरफ़ मुंह करके। अल्लाहु अकबर।',
          'bengali': 'আমি আল্লাহ তা‘আলার জন্য এই মাইয়্যিত (পুরুষ) এর উপর চার তাকবীরের জানাজা নামাজ আদায় করার নিয়ত করছি, ফরজে কিফায়া, কিবলার দিকে মুখ করে। আল্লাহু আকবার।',
          'assamese': 'মই আল্লাহ তা‘আলাৰ বাবে এই মৃত (পুৰুষ)ৰ ওপৰত চাৰি তাকবীৰৰ জানাজা নামাজ আদায় কৰাৰ নিয়ত কৰিছোঁ, ফৰজে কিফায়া, কিবলাৰ ফালে মুখ কৰি। আল্লাহু আকবৰ।',
        }
      },
      'Janaza Niyat (Female Deceased)': {
        'arabic': 'نَوَيْتُ أَنْ أُصَلِّيَ لِلَّهِ تَعَالَى أَرْبَعَ تَكْبِيرَاتٍ صَلَاةَ الْجَنَازَةِ عَلَى هَذِهِ الْمَيِّتَةِ فَرْضَ الْكِفَايَةِ مُتَوَجِّهًا إِلَى جِهَةِ الْكَعْبَةِ الشَّرِيفَةِ اللَّهُ أَكْبَرُ',
        'transliterations': {
          'english': "Nawaitu an usalliya lillahi ta'ala arba'a takbiratin salatal janazati 'ala haazihil mayyitati fardal kifayati mutawajjihan ila jihatil ka'bati sh-sharifah Allahu Akbar.",
          'hindi': 'नवैतु अन उसल्लिया लिल्लाहि तआला अरबा तकबीरात सलातल जनाज़ा अला हाज़िहिल मय्यितह फरज़ल किफायति मुतवज्जिहन इला जिहतिल काबतिश शरीफा अल्लाहु अकबर।',
          'bengali': 'নাওয়াইতু আন উসাল্লিয়া লিল্লাহি তা‘আলা আরবা তাকবীরাত সালাতাল জানাজাতি আলা হাযিহিল মাইয়্যিতাতি ফারদাল কিফায়াতি মুতাওয়াজ্জিহান ইলা জিহাতিল কা‘বাতিশ শারীফাহ আল্লাহু আকবার।',
          'assamese': 'নাৱাইতু আন উছাল্লিয়া লিল্লাহি তা‘আলা আৰবা তাকবীৰাত ছালাতাল জানাজা আলা হাজিহিল মাইয়্যিতাতি ফৰজল কিফায়তি মুতাৱাজ্জিহান ইলা জিহাতিল কা‘বাতিশ শ্বৰীফা আল্লাহু আকবৰ।',
        },
        'translations': {
          'english': 'I intend to pray four takbirs of Janaza prayer for Allah Ta’ala upon this deceased (female), as fard kifayah, facing the Holy Kaaba. Allahu Akbar.',
          'hindi': 'मैं अल्लाह तआला के लिए इस मय्यित (स्त्री) पर चार तकबीरों वाली नमाज़-ए-जनाज़ा अदा करने की नियत करता/करती हूँ, फर्ज़-ए-किफाया, क़िबला की तरफ़ मुंह करके। अल्लाहु अकबर।',
          'bengali': 'আমি আল্লাহ তা‘আলার জন্য এই মাইয়্যিত (নারী) এর উপর চার তাকবীরের জানাজা নামাজ আদায় করার নিয়ত করছি, ফরজে কিফায়া, কিবলার দিকে মুখ করে। আল্লাহু আকবার।',
          'assamese': 'মই আল্লাহ তা‘আলাৰ বাবে এই মৃত (মহিলা)ৰ ওপৰত চাৰি তাকবীৰৰ জানাজা নামাজ আদায় কৰাৰ নিয়ত কৰিছোঁ, ফৰজে কিফায়া, কিবলাৰ ফালে মুখ কৰি। আল্লাহু আকবৰ।',
        }
      },

      // ── Eid Prayers ─────────────────────────────
      'Eid-ul-Fitr': {
        'arabic': 'نَوَيْتُ أَنْ أُصَلِّيَ لِلَّهِ تَعَالَى رَكْعَتَيْ صَلَاةِ عِيدِ الْفِطْرِ وَاجِبًا مَعَ سِتِّ تَكْبِيرَاتٍ زَائِدَاتٍ مُتَوَجِّهًا إِلَى جِهَةِ الْكَعْبَةِ الشَّرِيفَةِ اللَّهُ أَكْبَرُ',
        'transliterations': {
          'english': "Nawaitu an usalliya lillahi ta'ala rak'atay salati 'Idil Fitr wajiban ma'a sitta takbiratin za'idatin mutawajjihan ila jihatil ka'bati sh-sharifah Allahu Akbar.",
          'hindi': 'नवैतु अन उसल्लिया लिल्लाहि तआला रकअतैन सलाति ईदिल फित्र वाजिबन मअ सित्त तकबीरातिन जाइदातिन मुतवज्जिहन इला जिहतिल काबतिश शरीफा अल्लाहु अकबर।',
          'bengali': 'নাওয়াইতু আন উসাল্লিয়া লিল্লাহি তা‘আলা রাক‘আতাই সালাতি ঈদিল ফিতর ওয়াজিবান মা‘আ সিত্তা তাকবীরাতিন জায়িদাতিন মুতাওয়াজ্জিহান ইলা জিহাতিল কা‘বাতিশ শারীফাহ আল্লাহু আকবার।',
          'assamese': 'নাৱাইতু আন উছাল্লিয়া লিল্লাহি তা‘আলা ৰক‘আতাই ছালাতি ঈদিল ফিতৰ ওৱাজিবন মা‘আ ছিট্টা তাকবীৰাতিন জাইদাতিন মুতাৱাজ্জিহান ইলা জিহাতিল কা‘বাতিশ শ্বৰীফা আল্লাহু আকবৰ।',
        },
        'translations': {
          'english': 'I intend to offer two rak’ats of Eid-ul-Fitr wajib prayer with six additional takbeers for Allah Ta’ala, facing towards the Holy Kaaba. Allahu Akbar.',
          'hindi': 'मैं अल्लाह तआला के लिए ईद-उल-फित्र की दो रकअत वाजिब नमाज़ छह ज़ाइद तकबीरों के साथ अदा करने की नियत करता/करती हूँ, क़िबला शरीफ की तरफ़ मुंह करके। अल्लाहु अकबर।',
          'bengali': 'আমি আল্লাহ তা‘আলার জন্য ঈদ-উল-ফিতরের দুই রাকাত ওয়াজিব নামাজ ছয় অতিরিক্ত তাকবীর সহ আদায় করার নিয়ত করছি, কিবলার দিকে মুখ করে। আল্লাহু আকবার।',
          'assamese': 'মই আল্লাহ তা‘আলাৰ বাবে ঈদ-উল-ফিতৰৰ দুই ৰকাত ওৱাজিব নামাজ ছয় অতিৰিক্ত তাকবীৰৰ সৈতে আদায় কৰাৰ নিয়ত কৰিছোঁ, কিবলাৰ ফালে মুখ কৰি। আল্লাহু আকবৰ।',
        }
      },
      'Eid-ul-Adha': {
        'arabic': 'نَوَيْتُ أَنْ أُصَلِّيَ لِلَّهِ تَعَالَى رَكْعَتَيْ صَلَاةِ عِيدِ الْأَضْحَى وَاجِبًا مَعَ سِتِّ تَكْبِيرَاتٍ زَائِدَاتٍ مُتَوَجِّهًا إِلَى جِهَةِ الْكَعْبَةِ الشَّرِيفَةِ اللَّهُ أَكْبَرُ',
        'transliterations': {
          'english': "Nawaitu an usalliya lillahi ta'ala rak'atay salati eidil adha wajiban ma'a sitti takbiratin za'idatin mutawajjihan ila jihatil ka'batish sharifati Allahu Akbar.",
          'hindi': 'नवैतु अन उसल्लिया लिल्लाहि तआला रकअतयि सलाति ईदिल अज़हा वाजिबन मअ सित्ति तकबीरातिन ज़ाइदातिन मुतवज्जिहन इला जिहतिल काबतिश शरीफति अल्लाहु अकबर।',
          'bengali': 'নাওয়াইতু আন উসাল্লিয়া লিল্লাহি তাআলা রাকাআতাই সালাতি ঈদিল আযহা ওয়াজিবান মাআ সিত্তা তাকবীরাতিন যায়েদাতিন মুতাওয়াজ্জিহান ইলা জিহাতিল কাবাতিশ শারীফাতি আল্লাহু আকবার।',
          'assamese': 'নাৱাইতু আন উছাল্লিয়া লিল্লাহি তাআলা ৰাকাআতাই ছালাতি ঈদিল আজহা ওৱাজিবান মাআ ছিট্টা তাকবীৰাতিন জাইদাতিন মুতাৱাজ্জিহান ইলা জিহাতিল কাবাতিশ শ্বৰীফাতি আল্লাহু আকবৰ।',
        },
        'translations': {
          'english': 'I intend to perform two rakats of Eid-ul-Adha Wajib prayer with six additional Takbirs for the sake of Allah, facing the Kaaba. Allah is the Greatest.',
          'hindi': 'मैं नियत करता हूँ दो रकअत नमाज़ ईदुल अज़हा की वाजिब, छह ज़ायद तकबीरों के साथ, अल्लाह के लिए, रुख काबा शरीफ की तरफ, अल्लाहु अकबर।',
          'bengali': 'আমি আল্লাহর সন্তুষ্টির উদ্দেশ্যে কাবামুখী হয়ে অতিরিক্ত ছয় তাকবীরের সাথে ঈদুল আযহার দুই রাকাত ওয়াজিব নামাজ আদায়ের নিয়ত করছি, আল্লাহু আকবার।',
          'assamese': 'মই আল্লাহৰ সন্তুষ্টিৰ বাবে কাবামুখী হৈ অতিৰিক্ত ছয় তাকবীৰৰ সৈতে ঈদুল আজহাৰ দুই ৰাকাত ওৱাজিব নামাজ আদায় কৰিবলৈ নিয়ত কৰিছোঁ, আল্লাহু আকবৰ।',
        }
      },

      // ── Sunnah & Nawafil Prayers ─────────────────────────────
      'Tahajjud': {
        'arabic': 'نَوَيْتُ أَنْ أُصَلِّيَ لِلَّهِ تَعَالَى رَكْعَتَيْ صَلَاةِ التَّهَجُّدِ نَفْلًا مُتَوَجِّهًا إِلَى جِهَةِ الْكَعْبَةِ الشَّرِيفَةِ اللَّهُ أَكْبَرُ',
        'transliterations': {
          'english': "Nawaitu an usalliya lillahi ta'ala rak'atay salatit tahajjudi naflan mutawajjihan ila jihatil ka'batish sharifati Allahu Akbar.",
          'hindi': 'नवैतु अन उसल्लिया लिल्लाहि तआला रकअतयि सलातित तहज्जुदि नफ्लन मुतवज्जिहन इला जिहतिल काबतिश शरीफति अल्लाहु अकबर।',
          'bengali': 'নাওয়াইতু আন উসাল্লিয়া লিল্লাহি তাআলা রাকাআতাই সালাতিত তাহাজ্জুদি নাফ্লান মুতাওয়াজ্জিহান ইলা জিহাতিল কাবাতিশ শারীফাতি আল্লাহু আকবার।',
          'assamese': 'নাৱাইতু আন উছাল্লিয়া লিল্লাহি তাআলা ৰাকাআতাই ছালাতিত তাহাজ্জুদি নাফলান মুতাৱাজ্জিহান ইলা জিহাতিল কাবাতিশ শ্বৰীফাতি আল্লাহু আকবৰ।',
        },
        'translations': {
          'english': 'I intend to perform two rakats of Tahajjud Nafl prayer for the sake of Allah, facing the Kaaba. Allah is the Greatest.',
          'hindi': 'मैं नियत करता हूँ दो रकअत नमाज़ तहज्जुद की नफ़्ल, अल्लाह तआला के लिए, रुख मेरा काबा शरीफ की तरफ, अल्लाहु अकबर।',
          'bengali': 'আমি আল্লাহর সন্তুষ্টির উদ্দেশ্যে কেবলামুখী হয়ে তাহাজ্জুদের দুই রাকাত নফল নামাজ আদায়ের নিয়ত করছি, আল্লাহু আকবার।',
          'assamese': 'মই আল্লাহৰ সন্তুষ্টিৰ বাবে কিবলামুখী হৈ তাহাজ্জুদৰ দুই ৰাকাত নফল নামাজ আদায় কৰিবলৈ নিয়ত কৰিছোঁ, আল্লাহু আকবৰ।',
        }
      },
      'Salat-al-Tasbeeh': {
        'arabic': 'نَوَيْتُ أَنْ أُصَلِّيَ لِلَّهِ تَعَالَى أَرْبَعَ رَكَعَاتِ صَلَاةِ التَّسْبِيحِ نَفْلًا مُتَوَجِّهًا إِلَى جِهَةِ الْكَعْبَةِ الشَّرِيفَةِ اللَّهُ أَكْبَرُ',
        'transliterations': {
          'english': "Nawaitu an usalliya lillahi ta'ala arba'a raka'ati salatit tasbeehi naflan mutawajjihan ila jihatil ka'batish sharifati Allahu Akbar.",
          'hindi': 'नवैतु अन उसल्लिया लिल्लाहि तआला अरबअ रकाति सलातित तस्बीहि नफ्लन मुतवज्जिहन इला जिहतिल काबतिश शरीफति अल्लाहु अकबर।',
          'bengali': 'নাওয়াইতু আন উসাল্লিয়া লিল্লাহি তাআলা আরবাআ রাকাআতি সালাতিত তাসবীহ নাফ্লান মুতাওয়াজ্জিহান ইলা জিহাতিল কাবাতিশ শারীফাতি আল্লাহু আকবার।',
          'assamese': 'নাৱাইতু আন উছাল্লিয়া লিল্লাহি তাআলা আৰবাআ ৰাকাআতি ছালাতিত তাছবীহ নাফলান মুতাৱাজ্জিহান ইলা জিহাতিল কাবাতিশ শ্বৰীফাতি আল্লাহু আকবৰ।',
        },
        'translations': {
          'english': 'I intend to perform four rakats of Salat-al-Tasbeeh Nafl prayer for the sake of Allah, facing the Kaaba. Allah is the Greatest.',
          'hindi': 'मैं नियत करता हूँ चार रकअत नमाज़ सलात-अल-तस्बीह की नफ़्ल, अल्लाह तआला के लिए, रुख मेरा काबा शरीफ की तरफ, अल्लाहु अकबर।',
          'bengali': 'আমি আল্লাহর সন্তুষ্টির উদ্দেশ্যে কেবলামুখী হয়ে সালাতুত তাসবীহ এর চার রাকাত নফল নামাজ আদায়ের নিয়ত করছি, আল্লাহু আকবার।',
          'assamese': 'মই আল্লাহৰ সন্তুষ্টিৰ বাবে কিবলামুখী হৈ ছালাতুত তাছবীহৰ চাৰি ৰাকাত নফল নামাজ আদায় কৰিবলৈ নিয়ত কৰিছোঁ, আল্লাহু আকবৰ।',
        }
      },
      'Salat-al-Hajat': {
        'arabic': 'نَوَيْتُ أَنْ أُصَلِّيَ لِلَّهِ تَعَالَى رَكْعَتَيْ صَلَاةِ الْحَاجَةِ نَفْلًا مُتَوَجِّهًا إِلَى جِهَةِ الْكَعْبَةِ الشَّرِيفَةِ اللَّهُ أَكْبَرُ',
        'transliterations': {
          'english': "Nawaitu an usalliya lillahi ta'ala rak'atay salatil hajati naflan mutawajjihan ila jihatil ka'batish sharifati Allahu Akbar.",
          'hindi': 'नवैतु अन उसल्लिया लिल्लाहि तआला रकअतयि सलातिल हाजति नफ्लन मुतवज्जिहन इला जिहतिल काबतिश शरीफति अल्लाहु अकबर।',
          'bengali': 'নাওয়াইতু আন উসাল্লিয়া লিল্লাহি তাআলা রাকাআতাই সালাতিল হাজাত naflan মুতাওয়াজ্জিহান ইলা জিহাতিল কাবাতিশ শারীফাতি আল্লাহু আকবার।',
          'assamese': 'নাৱাইতু আন উছাল্লিয়া লিল্লাহি তাআলা ৰাকাআতাই ছালাতিল হাজাত নাফলান মুতাৱাজ্জিহান ইলা জিহাতিল কাবাতিশ শ্বৰীফাতি আল্লাহু আকবৰ।',
        },
        'translations': {
          'english': 'I intend to perform two rakats of Salat-al-Hajat Nafl prayer for the sake of Allah, facing the Kaaba. Allah is the Greatest.',
          'hindi': 'मैं नियत करता हूँ दो रकअत नमाज़ सलात-अल-हाजत की नफ़्ल, अल्लाह तआला के लिए, रुख मेरा काबा शरीफ की तरफ, अल्लाहु अकबर।',
          'bengali': 'আমি আল্লাহর সন্তুষ্টির উদ্দেশ্যে কেবলামুখী হয়ে সালাতুল হাজত এর দুই রাকাত নফল নামাজ আদায়ের নিয়ত করছি, আল্লাহু আকবার।',
          'assamese': 'মই আল্লাহৰ সন্তুষ্টিৰ বাবে কিবলামুখী হৈ ছালাতুল হাজতৰ দুই ৰাকাত নফল নামাজ আদায় কৰিবলৈ নিয়ত কৰিছোঁ, আল্লাহু আকবৰ।',
        }
      },
      'Ishraq Prayer': {
        'arabic': 'نَوَيْتُ أَنْ أُصَلِّيَ لِلَّهِ تَعَالَى رَكْعَتَيْ صَلَاةِ الْإِشْرَاقِ نَفْلًا مُتَوَجِّهًا إِلَى جِهَةِ الْكَعْبَةِ الشَّرِيفَةِ اللَّهُ أَكْبَرُ',
        'transliterations': {
          'english': "Nawaitu an usalliya lillahi ta'ala rak'atay salatil ishraqi naflan mutawajjihan ila jihatil ka'batish sharifati Allahu Akbar.",
          'hindi': 'नवैतु अन उसल्लिया लिल्लाहि तआला रकअतयि सलातिल इशराकि नफ्लन मुतवज्जिहन इला जिहतिल काबतिश शरीफति अल्लाहु अकबर।',
          'bengali': 'নাওয়াইতু আন উসাল্লিয়া লিল্লাহি তাআলা রাকাআতাই সালাতিল ইশরাক নাফ্লান মুতাওয়াজ্জিহান ইলা জিহাতিল কাবাতিশ শারীফাতি আল্লাহু আকবার।',
          'assamese': 'নাৱাইতু আন উছাল্লিয়া লিল্লাহি তাআলা ৰাকাআতাই ছালাতিল ইশ্বৰাক নাফলান মুতাৱাজ্জিহান ইলা জিহাতিল কাবাতিশ শ্বৰীফাতি আল্লাহু আকবৰ।',
        },
        'translations': {
          'english': 'I intend to perform two rakats of Ishraq Nafl prayer for the sake of Allah, facing the Kaaba. Allah is the Greatest.',
          'hindi': 'मैं नियत करता हूँ दो रकअत नमाज़ इशराक की नफ़्ल, अल्लाह तआला के लिए, रुख मेरा काबा शरीफ की तरफ, अल्लाहु अकबर।',
          'bengali': 'আমি আল্লাহর সন্তুষ্টির উদ্দেশ্যে কেবলামুখী হয়ে ইশরাকের দুই রাকাত নফল নামাজ আদায়ের নিয়ত করছি, আল্লাহু আকবার।',
          'assamese': 'মই আল্লাহৰ সন্তুষ্টিৰ বাবে কিবলামুখী হৈ ইশ্বৰাকৰ দুই ৰাকাত নফল নামাজ আদায় কৰিবলৈ নিয়ত কৰিছোঁ, আল্লাহু আকবৰ।',
        }
      },
    }; // Map finishes here

    return data[title] ?? {
      'arabic': 'النية غير متوفرة حالياً',
      'transliterations': {'english': 'Niyat not available yet for this item'},
      'translations': {'english': 'Sorry, this niyat is not added yet.'},
    };
  }

  @override
  Widget build(BuildContext context) {
    final double fontScale = Provider.of<SettingsService>(context).fontScale;
    final niyat = getNiyatData();
    final String selectedLang = language.toLowerCase();

    final String transliterationText =
        niyat['transliterations']?[selectedLang] ?? niyat['transliterations']?['english'] ?? '';
    final String translationText =
        niyat['translations']?[selectedLang] ?? niyat['translations']?['english'] ?? '';

    return Scaffold(
      backgroundColor: const Color(0xFFF5F9F9),
      appBar: AppBar(
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontSize: (18 * fontScale).clamp(16.0, 22.0),
          ),
        ),
        backgroundColor: const Color(0xFF0A4D4D),
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Column(
          children: [
            _buildContentCard(
              title: "ARABIC",
              text: niyat['arabic'] ?? '',
              isArabic: true,
              fontScale: fontScale,
              accentColor: const Color(0xFF0A4D4D),
            ),
            const SizedBox(height: 20),
            _buildContentCard(
              title: "PRONUNCIATION (${language.toUpperCase()})",
              text: transliterationText,
              isArabic: false,
              fontScale: fontScale,
              accentColor: Colors.orange[800]!,
            ),
            const SizedBox(height: 20),
            _buildContentCard(
              title: "TRANSLATION (${language.toUpperCase()})",
              text: translationText,
              isArabic: false,
              fontScale: fontScale,
              accentColor: Colors.blueGrey[800]!,
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildContentCard({
    required String title,
    required String text,
    required bool isArabic,
    required double fontScale,
    required Color accentColor,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: accentColor.withOpacity(0.08),
            blurRadius: 25,
            offset: const Offset(0, 10),
          ),
        ],
        border: Border.all(color: accentColor.withOpacity(0.1), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: isArabic ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: isArabic ? MainAxisAlignment.end : MainAxisAlignment.start,
            children: [
              Icon(isArabic ? Icons.menu_book_rounded : Icons.record_voice_over_rounded,
                  size: 18, color: accentColor),
              const SizedBox(width: 10),
              Text(
                title,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  color: accentColor,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Divider(thickness: 1, height: 1),
          ),
          Text(
            text,
            textAlign: isArabic ? TextAlign.right : TextAlign.left,
            style: TextStyle(
              fontSize: (isArabic ? 24 : 17) * fontScale,
              height: isArabic ? 1.9 : 1.6,
              fontWeight: isArabic ? FontWeight.w600 : FontWeight.w500,
              color: const Color(0xFF1A1C1E),
              fontFamily: isArabic ? 'Amiri' : null,
            ),
          ),
        ],
      ),
    );
  }
}