import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:haptic_feedback/haptic_feedback.dart';
import 'package:auto_size_text/auto_size_text.dart';
import '../../core/services/settings_service.dart';

class AllahNamesPage extends StatefulWidget {
  final String? language;

  const AllahNamesPage({super.key, this.language});

  @override
  State<AllahNamesPage> createState() => _AllahNamesPageState();
}

class _AllahNamesPageState extends State<AllahNamesPage> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  String _searchQuery = "";
  late String _currentLanguage;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _controller.forward();

    // Initialize language from widget parameter or default to english
    _currentLanguage = widget.language ?? 'english';
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // Updated data structure with separate transliterations for each language
  final List<Map<String, String>> _allNames = [
    {'number': '1', 'arabic': 'الرَّحْمَٰنُ', 'trans': 'Ar-Rahman', 'trans_hindi': 'अर-रह्मान', 'trans_bengali': 'আর-রাহমান', 'trans_assamese': 'আৰ-ৰহমান', 'meaning': 'The Most Merciful', 'hindi': 'अत्यंत दयालु', 'bengali': 'পরম করুণাময়', 'assamese': 'অতি দয়ালু'},
    {'number': '2', 'arabic': 'الرَّحِيمُ', 'trans': 'Ar-Raheem', 'trans_hindi': 'अर-रहीम', 'trans_bengali': 'আর-রাহীম', 'trans_assamese': 'আৰ-ৰহীম', 'meaning': 'The Especially Merciful', 'hindi': 'विशेष रूप से दयालु', 'bengali': 'বিশেষ করুণাময়', 'assamese': 'বিশেষ দয়ালু'},
    {'number': '3', 'arabic': 'الْمَلِكُ', 'trans': 'Al-Malik', 'trans_hindi': 'अल-मलिक', 'trans_bengali': 'আল-মালিক', 'trans_assamese': 'আল-মালিক', 'meaning': 'The Sovereign / The King', 'hindi': 'राजा', 'bengali': 'সম্রাট', 'assamese': 'ৰজা'},
    {'number': '4', 'arabic': 'الْقُدُّوسُ', 'trans': 'Al-Quddus', 'trans_hindi': 'अल-क़ुद्दूस', 'trans_bengali': 'আল-কুদ্দুস', 'trans_assamese': 'আল-কুদ্দুছ', 'meaning': 'The Most Holy', 'hindi': 'पवित्र', 'bengali': 'পরম পবিত্র', 'assamese': 'পৰম পবিত্ৰ'},
    {'number': '5', 'arabic': 'السَّلَامُ', 'trans': 'As-Salam', 'trans_hindi': 'अस-सलाम', 'trans_bengali': 'আস-সালাম', 'trans_assamese': 'আছ-ছালাম', 'meaning': 'The Source of Peace', 'hindi': 'शांति का स्रोत', 'bengali': 'শান্তির উৎস', 'assamese': 'শান্তিৰ উৎস'},
    {'number': '6', 'arabic': 'الْمُؤْمِنُ', 'trans': 'Al-Mu\'min', 'trans_hindi': 'अल-मुअ्मिन', 'trans_bengali': 'আল-মুমিন', 'trans_assamese': 'আল-মুমিন', 'meaning': 'The Giver of Faith', 'hindi': 'ईमान देने वाला', 'bengali': 'বিশ্বাসদানকারী', 'assamese': 'বিশ্বাস দিয়া'},
    {'number': '7', 'arabic': 'الْمُهَيْمِنُ', 'trans': 'Al-Muhaymin', 'trans_hindi': 'अल-मुहैमिन', 'trans_bengali': 'আল-মুহায়মিন', 'trans_assamese': 'আল-মুহাইমিন', 'meaning': 'The Guardian', 'hindi': 'रक्षक', 'bengali': 'রক্ষাকারী', 'assamese': 'ৰক্ষক'},
    {'number': '8', 'arabic': 'الْعَزِيزُ', 'trans': 'Al-Aziz', 'trans_hindi': 'अल-अज़ीज़', 'trans_bengali': 'আল-আজিজ', 'trans_assamese': 'আল-আজিজ', 'meaning': 'The Almighty', 'hindi': 'परम शक्तिशाली', 'bengali': 'সর্বশক্তিমান', 'assamese': 'সৰ্বশক্তিমান'},
    {'number': '9', 'arabic': 'الْجَبَّارُ', 'trans': 'Al-Jabbar', 'trans_hindi': 'अल-जब्बार', 'trans_bengali': 'আল-জাব্বার', 'trans_assamese': 'আল-জাব্বাৰ', 'meaning': 'The Compeller', 'hindi': 'जबरदस्त', 'bengali': 'পরাক্রমশালী', 'assamese': 'পৰাক্ৰমশালী'},
    {'number': '10', 'arabic': 'الْمُتَكَبِّرُ', 'trans': 'Al-Mutakabbir', 'trans_hindi': 'अल-मुतकब्बिर', 'trans_bengali': 'আল-মুতাকাব্বির', 'trans_assamese': 'আল-মুতাকাব্বিৰ', 'meaning': 'The Supreme', 'hindi': 'महान', 'bengali': 'মহান', 'assamese': 'মহান'},
    {'number': '11', 'arabic': 'الْخَالِقُ', 'trans': 'Al-Khaliq', 'trans_hindi': 'अल-खालिक़', 'trans_bengali': 'আল-খালিক', 'trans_assamese': 'আল-খালিক', 'meaning': 'The Creator', 'hindi': 'सृष्टिकर्ता', 'bengali': 'স্রষ্টা', 'assamese': 'সৃষ্টিকৰ্তা'},
    {'number': '12', 'arabic': 'الْبَارِئُ', 'trans': 'Al-Bari\'', 'trans_hindi': 'अल-बारी', 'trans_bengali': 'আল-বারি', 'trans_assamese': 'আল-বাৰী', 'meaning': 'The Originator', 'hindi': 'उत्पादक', 'bengali': 'উৎপাদক', 'assamese': 'উৎপাদক'},
    {'number': '13', 'arabic': 'الْمُصَوِّرُ', 'trans': 'Al-Musawwir', 'trans_hindi': 'अल-मुसव्विर', 'trans_bengali': 'আল-মুসাওয়ির', 'trans_assamese': 'আল-মুছাওৱিৰ', 'meaning': 'The Fashioner', 'hindi': 'रूप देने वाला', 'bengali': 'রূপদাতা', 'assamese': 'ৰূপদাতা'},
    {'number': '14', 'arabic': 'الْغَفَّارُ', 'trans': 'Al-Ghaffar', 'trans_hindi': 'अल-ग़फ्फार', 'trans_bengali': 'আল-গাফফার', 'trans_assamese': 'আল-গাফ্ফাৰ', 'meaning': 'The All-Forgiving', 'hindi': 'क्षमा करने वाला', 'bengali': 'ক্ষমাকারী', 'assamese': 'ক্ষমাকাৰী'},
    {'number': '15', 'arabic': 'الْقَهَّارُ', 'trans': 'Al-Qahhar', 'trans_hindi': 'अल-क़ह्हार', 'trans_bengali': 'আল-কাহহার', 'trans_assamese': 'আল-কাহ্হাৰ', 'meaning': 'The Subduer', 'hindi': 'दबाने वाला', 'bengali': 'দমনকারী', 'assamese': 'দমনকাৰী'},
    {'number': '16', 'arabic': 'الْوَهَّابُ', 'trans': 'Al-Wahhab', 'trans_hindi': 'अल-वह्हाब', 'trans_bengali': 'আল-ওয়াহহাব', 'trans_assamese': 'আল-ৱাহ্হাব', 'meaning': 'The Bestower', 'hindi': 'दाता', 'bengali': 'দাতা', 'assamese': 'দাতা'},
    {'number': '17', 'arabic': 'الرَّزَّاقُ', 'trans': 'Ar-Razzaq', 'trans_hindi': 'अर-रज़्ज़ाक़', 'trans_bengali': 'আর-রাযযাক', 'trans_assamese': 'আৰ-ৰায্যাক', 'meaning': 'The Provider', 'hindi': 'रिज़्क देने वाला', 'bengali': 'রিজিক দানকারী', 'assamese': 'ৰিজিক দানকাৰী'},
    {'number': '18', 'arabic': 'الْفَتَّاحُ', 'trans': 'Al-Fattah', 'trans_hindi': 'अल-फत्ताह', 'trans_bengali': 'আল-ফাত্তাহ', 'trans_assamese': 'আল-ফাত্তাহ', 'meaning': 'The Opener', 'hindi': 'द्वार खोलने वाला', 'bengali': 'দ্বার উন্মোচনকারী', 'assamese': 'দ্বাৰ উন্মোচনকাৰী'},
    {'number': '19', 'arabic': 'الْعَلِيمُ', 'trans': 'Al-Alim', 'trans_hindi': 'अल-अलीम', 'trans_bengali': 'আল-আলিম', 'trans_assamese': 'আল-আলিম', 'meaning': 'The All-Knowing', 'hindi': 'सब जानने वाला', 'bengali': 'সর্বজ্ঞ', 'assamese': 'সৰ্বজ্ঞ'},
    {'number': '20', 'arabic': 'الْقَابِضُ', 'trans': 'Al-Qabid', 'trans_hindi': 'अल-क़ाबिद', 'trans_bengali': 'আল-কাবিদ', 'trans_assamese': 'আল-কাবিদ', 'meaning': 'The Constrictor', 'hindi': 'संकोच करने वाला', 'bengali': 'সংকোচকারী', 'assamese': 'সংকোচকাৰী'},
    {'number': '21', 'arabic': 'الْبَاسِطُ', 'trans': 'Al-Basit', 'trans_hindi': 'अल-बासित', 'trans_bengali': 'আল-বাসিত', 'trans_assamese': 'আল-বাছিত', 'meaning': 'The Expander', 'hindi': 'विस्तार करने वाला', 'bengali': 'বিস্তারকারী', 'assamese': 'বিস্তাৰকাৰী'},
    {'number': '22', 'arabic': 'الْخَافِضُ', 'trans': 'Al-Khafid', 'trans_hindi': 'अल-खाफिद', 'trans_bengali': 'আল-খাফিদ', 'trans_assamese': 'আল-খাফিদ', 'meaning': 'The Abaser', 'hindi': 'नीचा करने वाला', 'bengali': 'নিচুকারী', 'assamese': 'নমাই দিয়া'},
    {'number': '23', 'arabic': 'الرَّافِعُ', 'trans': 'Ar-Rafi\'', 'trans_hindi': 'अर-रफ़ी', 'trans_bengali': 'আর-রাফি', 'trans_assamese': 'আৰ-ৰাফী', 'meaning': 'The Exalter', 'hindi': 'ऊँचा करने वाला', 'bengali': 'উচ্চকারী', 'assamese': 'উচ্চ কৰা'},
    {'number': '24', 'arabic': 'الْمُعِزُّ', 'trans': 'Al-Mu\'izz', 'trans_hindi': 'अल-मुअज़्ज़', 'trans_bengali': 'আল-মুইজ', 'trans_assamese': 'আল-মুইজ', 'meaning': 'The Honorer', 'hindi': 'इज्जत देने वाला', 'bengali': 'সম্মানদাতা', 'assamese': 'সন্মান দিয়া'},
    {'number': '25', 'arabic': 'المُذِلُّ', 'trans': 'Al-Mudhill', 'trans_hindi': 'अल-मुज़िल', 'trans_bengali': 'আল-মুজিল', 'trans_assamese': 'আল-মুজিল', 'meaning': 'The Humiliator', 'hindi': 'अपमान करने वाला', 'bengali': 'অপমানকারী', 'assamese': 'অপমান কৰা'},
    {'number': '26', 'arabic': 'السَّمِيعُ', 'trans': 'As-Sami\'', 'trans_hindi': 'अस-समी', 'trans_bengali': 'আস-সামি', 'trans_assamese': 'আছ-ছামী', 'meaning': 'The All-Hearing', 'hindi': 'सब सुनने वाला', 'bengali': 'সর্বশ্রোতা', 'assamese': 'সৰ্বশ্ৰোতা'},
    {'number': '27', 'arabic': 'الْبَصِيرُ', 'trans': 'Al-Basir', 'trans_hindi': 'अल-बसीर', 'trans_bengali': 'আল-বাসির', 'trans_assamese': 'আল-বাছিৰ', 'meaning': 'The All-Seeing', 'hindi': 'सब देखने वाला', 'bengali': 'সর্বদ্রষ্টা', 'assamese': 'সৰ্বদ্ৰষ্টা'},
    {'number': '28', 'arabic': 'الْحَكَمُ', 'trans': 'Al-Hakam', 'trans_hindi': 'अल-हकम', 'trans_bengali': 'আল-হাকাম', 'trans_assamese': 'আল-হাকাম', 'meaning': 'The Judge', 'hindi': 'न्यायाधीश', 'bengali': 'বিচারক', 'assamese': 'বিচাৰক'},
    {'number': '29', 'arabic': 'الْعَدْلُ', 'trans': 'Al-Adl', 'trans_hindi': 'अल-अदल', 'trans_bengali': 'আল-আদল', 'trans_assamese': 'আল-আদল', 'meaning': 'The Just', 'hindi': 'न्यायप्रिय', 'bengali': 'ন্যায়পরায়ণ', 'assamese': 'ন্যায়পৰায়ণ'},
    {'number': '30', 'arabic': 'اللَّطِيفُ', 'trans': 'Al-Latif', 'trans_hindi': 'अल-लतीफ़', 'trans_bengali': 'আল-লাতিফ', 'trans_assamese': 'আল-লাতিফ', 'meaning': 'The Subtle One', 'hindi': 'सूक्ष्म', 'bengali': 'সূক্ষ্ম', 'assamese': 'সূক্ষ্ম'},
    {'number': '31', 'arabic': 'الْخَبِيرُ', 'trans': 'Al-Khabir', 'trans_hindi': 'अल-खबीर', 'trans_bengali': 'আল-খাবির', 'trans_assamese': 'আল-খাবিৰ', 'meaning': 'The All-Aware', 'hindi': 'सबसे अच्छी तरह जानने वाला', 'bengali': 'সর্বজ্ঞাত', 'assamese': 'সৰ্বজ্ঞাত'},
    {'number': '32', 'arabic': 'الْحَلِيمُ', 'trans': 'Al-Halim', 'trans_hindi': 'अल-हलीम', 'trans_bengali': 'আল-হালিম', 'trans_assamese': 'আল-হালিম', 'meaning': 'The Forbearing', 'hindi': 'सहनशील', 'bengali': 'সহনশীল', 'assamese': 'সহনশীল'},
    {'number': '33', 'arabic': 'الْعَظِيمُ', 'trans': 'Al-Azim', 'trans_hindi': 'अल-अज़ीम', 'trans_bengali': 'আল-আজিম', 'trans_assamese': 'আল-আজিম', 'meaning': 'The Magnificent', 'hindi': 'महान', 'bengali': 'মহান', 'assamese': 'মহান'},
    {'number': '34', 'arabic': 'الْغَفُورُ', 'trans': 'Al-Ghafur', 'trans_hindi': 'अल-ग़फ़ूर', 'trans_bengali': 'আল-গাফুর', 'trans_assamese': 'আল-গাফুৰ', 'meaning': 'The All-Forgiving', 'hindi': 'बहुत क्षमा करने वाला', 'bengali': 'অতি ক্ষমাশীল', 'assamese': 'অতি ক্ষমাশীল'},
    {'number': '35', 'arabic': 'الشَّكُورُ', 'trans': 'Ash-Shakur', 'trans_hindi': 'अश-शकूर', 'trans_bengali': 'আশ-শাকুর', 'trans_assamese': 'আছ-ছাকুৰ', 'meaning': 'The Appreciative', 'hindi': 'गुणग्राहक', 'bengali': 'গুণগ্রাহী', 'assamese': 'গুণগ্ৰাহী'},
    {'number': '36', 'arabic': 'الْعَلِيُّ', 'trans': 'Al-Aliyy', 'trans_hindi': 'अल-अली', 'trans_bengali': 'আল-আলি', 'trans_assamese': 'আল-আলী', 'meaning': 'The Most High', 'hindi': 'सर्वोच्च', 'bengali': 'সর্বোচ্চ', 'assamese': 'সৰ্বোচ্চ'},
    {'number': '37', 'arabic': 'الْكَبِيرُ', 'trans': 'Al-Kabir', 'trans_hindi': 'अल-कबीर', 'trans_bengali': 'আল-কাবির', 'trans_assamese': 'আল-কাবিৰ', 'meaning': 'The Most Great', 'hindi': 'महानतम', 'bengali': 'মহানতম', 'assamese': 'মহানতম'},
    {'number': '38', 'arabic': 'الْحَفِيظُ', 'trans': 'Al-Hafiz', 'trans_hindi': 'अल-हफ़ीज़', 'trans_bengali': 'আল-হাফিজ', 'trans_assamese': 'আল-হাফিজ', 'meaning': 'The Preserver', 'hindi': 'रक्षक', 'bengali': 'রক্ষাকারী', 'assamese': 'ৰক্ষক'},
    {'number': '39', 'arabic': 'المُقِيتُ', 'trans': 'Al-Muqit', 'trans_hindi': 'अल-मुक़ीत', 'trans_bengali': 'আল-মুকিত', 'trans_assamese': 'আল-মুকিত', 'meaning': 'The Sustainer', 'hindi': 'पालनहार', 'bengali': 'পালনকারী', 'assamese': 'পালনকাৰী'},
    {'number': '40', 'arabic': 'الْحَسِيبُ', 'trans': 'Al-Hasib', 'trans_hindi': 'अल-हसीब', 'trans_bengali': 'আল-হাসিব', 'trans_assamese': 'আল-হাছিব', 'meaning': 'The Reckoner', 'hindi': 'हिसाब करने वाला', 'bengali': 'হিসাবকারী', 'assamese': 'হিচাপ কৰা'},
    {'number': '41', 'arabic': 'الْجَلِيلُ', 'trans': 'Al-Jalil', 'trans_hindi': 'अल-जलील', 'trans_bengali': 'আল-জালিল', 'trans_assamese': 'আল-জালিল', 'meaning': 'The Majestic', 'hindi': 'प्रतापी', 'bengali': 'মহিমান্বিত', 'assamese': 'মহিমান্বিত'},
    {'number': '42', 'arabic': 'الْكَرِيمُ', 'trans': 'Al-Karim', 'trans_hindi': 'अल-करीम', 'trans_bengali': 'আল-কারিম', 'trans_assamese': 'আল-কাৰিম', 'meaning': 'The Generous', 'hindi': 'उदार', 'bengali': 'উদার', 'assamese': 'উদাৰ'},
    {'number': '43', 'arabic': 'الرَّقِيبُ', 'trans': 'Ar-Raqib', 'trans_hindi': 'अर-रक़ीब', 'trans_bengali': 'আর-রাকিব', 'trans_assamese': 'আৰ-ৰাকিব', 'meaning': 'The Watchful', 'hindi': 'निगरानी करने वाला', 'bengali': 'পর্যবেক্ষক', 'assamese': 'পৰ্যবেক্ষক'},
    {'number': '44', 'arabic': 'الْمُجِيبُ', 'trans': 'Al-Mujib', 'trans_hindi': 'अल-मुजीब', 'trans_bengali': 'আল-মুজিব', 'trans_assamese': 'আল-মুজিব', 'meaning': 'The Responsive', 'hindi': 'उत्तर देने वाला', 'bengali': 'উত্তরদাতা', 'assamese': 'উত্তৰ দিয়া'},
    {'number': '45', 'arabic': 'الْوَاسِعُ', 'trans': 'Al-Wasi\'', 'trans_hindi': 'अल-वासी', 'trans_bengali': 'আল-ওয়াসি', 'trans_assamese': 'আল-ৱাছী', 'meaning': 'The All-Encompassing', 'hindi': 'व्यापक', 'bengali': 'ব্যাপক', 'assamese': 'ব্যাপক'},
    {'number': '46', 'arabic': 'الْحَكِيمُ', 'trans': 'Al-Hakim', 'trans_hindi': 'अल-हकीम', 'trans_bengali': 'আল-হাকিম', 'trans_assamese': 'আল-হাকিম', 'meaning': 'The Wise', 'hindi': 'बुद्धिमान', 'bengali': 'জ্ঞানী', 'assamese': 'জ্ঞানী'},
    {'number': '47', 'arabic': 'الْوَدُودُ', 'trans': 'Al-Wadud', 'trans_hindi': 'अल-वदूद', 'trans_bengali': 'আল-ওয়াদুদ', 'trans_assamese': 'আল-ৱাদুদ', 'meaning': 'The Loving', 'hindi': 'प्रेम करने वाला', 'bengali': 'প্রেমময়', 'assamese': 'প্ৰেমময়'},
    {'number': '48', 'arabic': 'الْمَجِيدُ', 'trans': 'Al-Majid', 'trans_hindi': 'अल-मजीद', 'trans_bengali': 'আল-মাজিদ', 'trans_assamese': 'আল-মাজিদ', 'meaning': 'The Glorious', 'hindi': 'महिमामय', 'bengali': 'মহিমাময়', 'assamese': 'মহিমাময়'},
    {'number': '49', 'arabic': 'الْبَاعِثُ', 'trans': 'Al-Ba\'ith', 'trans_hindi': 'अल-बाइस', 'trans_bengali': 'আল-বাইস', 'trans_assamese': 'আল-বাইছ', 'meaning': 'The Resurrector', 'hindi': 'पुनर्जीवित करने वाला', 'bengali': 'পুনর্জীবিতকারী', 'assamese': 'পুনৰ্জীৱিত কৰা'},
    {'number': '50', 'arabic': 'الشَّهِيدُ', 'trans': 'Ash-Shahid', 'trans_hindi': 'अश-शाहिद', 'trans_bengali': 'আশ-শাহিদ', 'trans_assamese': 'আছ-ছাহিদ', 'meaning': 'The Witness', 'hindi': 'साक्षी', 'bengali': 'সাক্ষী', 'assamese': 'সাক্ষী'},
    {'number': '51', 'arabic': 'الْحَقُّ', 'trans': 'Al-Haqq', 'trans_hindi': 'अल-हक़', 'trans_bengali': 'আল-হাক্ক', 'trans_assamese': 'আল-হাক্ক', 'meaning': 'The Truth', 'hindi': 'सत्य', 'bengali': 'সত্য', 'assamese': 'সত্য'},
    {'number': '52', 'arabic': 'الْوَكِيلُ', 'trans': 'Al-Wakil', 'trans_hindi': 'अल-वकील', 'trans_bengali': 'আল-ওয়াকিল', 'trans_assamese': 'আল-ৱাকিল', 'meaning': 'The Trustee', 'hindi': 'भरोसेमंद', 'bengali': 'বিশ্বস্ত', 'assamese': 'বিশ্বাসযোগ্য'},
    {'number': '53', 'arabic': 'الْقَوِيُّ', 'trans': 'Al-Qawiyy', 'trans_hindi': 'अल-क़वी', 'trans_bengali': 'আল-কাউয়ি', 'trans_assamese': 'আল-কাউয়ী', 'meaning': 'The Most Strong', 'hindi': 'सबसे शक्तिशाली', 'bengali': 'সর্বশক্তিমান', 'assamese': 'সৰ্বশক্তিশালী'},
    {'number': '54', 'arabic': 'الْمَتِينُ', 'trans': 'Al-Matin', 'trans_hindi': 'अल-मतीन', 'trans_bengali': 'আল-মাতিন', 'trans_assamese': 'আল-মাতিন', 'meaning': 'The Firm', 'hindi': 'दृढ़', 'bengali': 'দৃঢ়', 'assamese': 'দৃঢ়'},
    {'number': '55', 'arabic': 'الْوَلِيُّ', 'trans': 'Al-Waliyy', 'trans_hindi': 'अल-वली', 'trans_bengali': 'আল-ওয়ালি', 'trans_assamese': 'আল-ৱালী', 'meaning': 'The Protecting Friend', 'hindi': 'रक्षक मित्र', 'bengali': 'রক্ষাকারী বন্ধু', 'assamese': 'ৰক্ষাকাৰী বন্ধু'},
    {'number': '56', 'arabic': 'الْحَمِيدُ', 'trans': 'Al-Hamid', 'trans_hindi': 'अल-हमीद', 'trans_bengali': 'আল-হামিদ', 'trans_assamese': 'আল-হামিদ', 'meaning': 'The Praiseworthy', 'hindi': 'प्रशंसनीय', 'bengali': 'প্রশংসনীয়', 'assamese': 'প্ৰশংসনীয়'},
    {'number': '57', 'arabic': 'الْمُحْصِي', 'trans': 'Al-Muhsi', 'trans_hindi': 'अल-मुहसी', 'trans_bengali': 'আল-মুহসি', 'trans_assamese': 'আল-মুহছী', 'meaning': 'The Reckoner', 'hindi': 'गणना करने वाला', 'bengali': 'গণনাকারী', 'assamese': 'গণনা কৰা'},
    {'number': '58', 'arabic': 'الْمُبْدِئُ', 'trans': 'Al-Mubdi\'', 'trans_hindi': 'अल-मुब्दी', 'trans_bengali': 'আল-মুবদি', 'trans_assamese': 'আল-মুবদী', 'meaning': 'The Originator', 'hindi': 'आरंभ करने वाला', 'bengali': 'আদিকারী', 'assamese': 'আৰম্ভ কৰা'},
    {'number': '59', 'arabic': 'الْمُعِيدُ', 'trans': 'Al-Mu\'id', 'trans_hindi': 'अल-मुईद', 'trans_bengali': 'আল-মুইদ', 'trans_assamese': 'আল-মুইদ', 'meaning': 'The Restorer', 'hindi': 'पुनर्स्थापक', 'bengali': 'পুনঃস্থাপক', 'assamese': 'পুনঃস্থাপক'},
    {'number': '60', 'arabic': 'الْمُحْيِي', 'trans': 'Al-Muhyi', 'trans_hindi': 'अल-मुहयी', 'trans_bengali': 'আল-মুহই', 'trans_assamese': 'আল-মুহয়ী', 'meaning': 'The Giver of Life', 'hindi': 'जीवन देने वाला', 'bengali': 'জীবনদাতা', 'assamese': 'জীৱন দিয়া'},
    {'number': '61', 'arabic': 'اَلْمُمِيتُ', 'trans': 'Al-Mumit', 'trans_hindi': 'अल-मुमीत', 'trans_bengali': 'আল-মুমিত', 'trans_assamese': 'আল-মুমিত', 'meaning': 'The Creator of Death', 'hindi': 'मृत्यु देने वाला', 'bengali': 'মৃত্যুদাতা', 'assamese': 'মৃত্যু দিয়া'},
    {'number': '62', 'arabic': 'الْحَيُّ', 'trans': 'Al-Hayy', 'trans_hindi': 'अल-हय्य', 'trans_bengali': 'আল-হাই', 'trans_assamese': 'আল-হাই', 'meaning': 'The Ever-Living', 'hindi': 'सदा जीवित', 'bengali': 'চিরঞ্জীব', 'assamese': 'চিৰঞ্জীৱ'},
    {'number': '63', 'arabic': 'الْقَيُّومُ', 'trans': 'Al-Qayyum', 'trans_hindi': 'अल-क़य्यूम', 'trans_bengali': 'আল-কাইয়ুম', 'trans_assamese': 'আল-কাইয়ুম', 'meaning': 'The Self-Subsisting', 'hindi': 'स्वयंभू', 'bengali': 'স্বয়ংভূ', 'assamese': 'স্বয়ংভূ'},
    {'number': '64', 'arabic': 'الْوَاجِدُ', 'trans': 'Al-Wajid', 'trans_hindi': 'अल-वाजिद', 'trans_bengali': 'আল-ওয়াজিদ', 'trans_assamese': 'আল-ৱাজিদ', 'meaning': 'The Finder', 'hindi': 'प्राप्त करने वाला', 'bengali': 'প্রাপ্তকারী', 'assamese': 'প্ৰাপ্তকাৰী'},
    {'number': '65', 'arabic': 'الْمَاجِدُ', 'trans': 'Al-Majid', 'trans_hindi': 'अल-माजिद', 'trans_bengali': 'আল-মাজিদ', 'trans_assamese': 'আল-মাজিদ', 'meaning': 'The Glorious', 'hindi': 'महान', 'bengali': 'মহিমান্বিত', 'assamese': 'মহিমান্বিত'},
    {'number': '66', 'arabic': 'الْواحِدُ', 'trans': 'Al-Wahid', 'trans_hindi': 'अल-वाहिद', 'trans_bengali': 'আল-ওয়াহিদ', 'trans_assamese': 'আল-ৱাহিদ', 'meaning': 'The One', 'hindi': 'एक', 'bengali': 'এক', 'assamese': 'এক'},
    {'number': '67', 'arabic': 'الْأَحَدُ', 'trans': 'Al-Ahad', 'trans_hindi': 'अल-अहद', 'trans_bengali': 'আল-আহাদ', 'trans_assamese': 'আল-আহাদ', 'meaning': 'The Unique', 'hindi': 'अद्वितीय', 'bengali': 'অদ্বিতীয়', 'assamese': 'অদ্বিতীয়'},
    {'number': '68', 'arabic': 'الصَّمَدُ', 'trans': 'As-Samad', 'trans_hindi': 'अस-समद', 'trans_bengali': 'আস-সামাদ', 'trans_assamese': 'আছ-ছামাদ', 'meaning': 'The Eternal', 'hindi': 'शाश्वत', 'bengali': 'শাশ্বত', 'assamese': 'শাশ্বত'},
    {'number': '69', 'arabic': 'الْقَادِرُ', 'trans': 'Al-Qadir', 'trans_hindi': 'अल-क़ादिर', 'trans_bengali': 'আল-কাদির', 'trans_assamese': 'আল-কাদিৰ', 'meaning': 'The All-Powerful', 'hindi': 'सर्वशक्तिमान', 'bengali': 'সর্বশক্তিমান', 'assamese': 'সৰ্বশক্তিমান'},
    {'number': '70', 'arabic': 'الْمُقْتَدِرُ', 'trans': 'Al-Muqtadir', 'trans_hindi': 'अल-मुक़्तदिर', 'trans_bengali': 'আল-মুকতাদির', 'trans_assamese': 'আল-মুক্তাদিৰ', 'meaning': 'The Determiner', 'hindi': 'निर्धारक', 'bengali': 'নির্ধারক', 'assamese': 'নিৰ্ধাৰক'},
    {'number': '71', 'arabic': 'الْمُقَدِّمُ', 'trans': 'Al-Muqaddim', 'trans_hindi': 'अल-मुक़द्दिम', 'trans_bengali': 'আল-মুকাদ্দিম', 'trans_assamese': 'আল-মুকাদ্দিম', 'meaning': 'The Expediter', 'hindi': 'आगे करने वाला', 'bengali': 'অগ্রবর্তীকারী', 'assamese': 'অগ্ৰগামী'},
    {'number': '72', 'arabic': 'الْمُؤَخِّرُ', 'trans': 'Al-Mu\'akhkhir', 'trans_hindi': 'अल-मुअख्खिर', 'trans_bengali': 'আল-মুআখখির', 'trans_assamese': 'আল-মুআখ্খিৰ', 'meaning': 'The Delayer', 'hindi': 'पीछे करने वाला', 'bengali': 'পশ্চাদপসরণকারী', 'assamese': 'পিছুৱাই দিয়া'},
    {'number': '73', 'arabic': 'الأَوَّلُ', 'trans': 'Al-Awwal', 'trans_hindi': 'अल-अव्वल', 'trans_bengali': 'আল-আওয়াল', 'trans_assamese': 'আল-আওৱাল', 'meaning': 'The First', 'hindi': 'प्रथम', 'bengali': 'প্রথম', 'assamese': 'প্ৰথম'},
    {'number': '74', 'arabic': 'الآخِرُ', 'trans': 'Al-Akhir', 'trans_hindi': 'अल-आखिर', 'trans_bengali': 'আল-আখির', 'trans_assamese': 'আল-আখিৰ', 'meaning': 'The Last', 'hindi': 'अंतिम', 'bengali': 'শেষ', 'assamese': 'শেষ'},
    {'number': '75', 'arabic': 'الظَّاهِرُ', 'trans': 'Az-Zahir', 'trans_hindi': 'अज़-ज़ाहिर', 'trans_bengali': 'আজ-জাহির', 'trans_assamese': 'আজ-জাহিৰ', 'meaning': 'The Manifest', 'hindi': 'प्रकट', 'bengali': 'প্রকাশিত', 'assamese': 'প্ৰকাশিত'},
    {'number': '76', 'arabic': 'الْبَاطِنُ', 'trans': 'Al-Batin', 'trans_hindi': 'अल-बातिन', 'trans_bengali': 'আল-বাতিন', 'trans_assamese': 'আল-বাতিন', 'meaning': 'The Hidden', 'hindi': 'गुप्त', 'bengali': 'গোপন', 'assamese': 'গোপন'},
    {'number': '77', 'arabic': 'الْوَالِي', 'trans': 'Al-Wali', 'trans_hindi': 'अल-वाली', 'trans_bengali': 'আল-ওয়ালি', 'trans_assamese': 'আল-ৱালী', 'meaning': 'The Governor', 'hindi': 'शासक', 'bengali': 'শাসক', 'assamese': 'শাসক'},
    {'number': '78', 'arabic': 'الْمُتَعَالِي', 'trans': 'Al-Muta\'ali', 'trans_hindi': 'अल-मुतअाली', 'trans_bengali': 'আল-মুতাআলি', 'trans_assamese': 'আল-মুতাআলী', 'meaning': 'The Exalted', 'hindi': 'उच्च', 'bengali': 'উচ্চ', 'assamese': 'উচ্চ'},
    {'number': '79', 'arabic': 'الْبَرُّ', 'trans': 'Al-Barr', 'trans_hindi': 'अल-बर्र', 'trans_bengali': 'আল-বার', 'trans_assamese': 'আল-বাৰ', 'meaning': 'The Source of Goodness', 'hindi': 'नेकी का स्रोत', 'bengali': 'কল্যাণের উৎস', 'assamese': 'কল্যাণৰ উৎস'},
    {'number': '80', 'arabic': 'التَّوَابُ', 'trans': 'At-Tawwab', 'trans_hindi': 'अत-तव्वाब', 'trans_bengali': 'আত-তাওয়াব', 'trans_assamese': 'আত-তাওৱাব', 'meaning': 'The Acceptor of Repentance', 'hindi': 'तौबा कबूल करने वाला', 'bengali': 'তওবা গ্রহণকারী', 'assamese': 'তওবা গ্ৰহণকাৰী'},
    {'number': '81', 'arabic': 'الْمُنْتَقِمُ', 'trans': 'Al-Muntaqim', 'trans_hindi': 'अल-मुन्तक़िम', 'trans_bengali': 'আল-মুনতাকিম', 'trans_assamese': 'আল-মুন্তাকিম', 'meaning': 'The Avenger', 'hindi': 'प्रतिशोध लेने वाला', 'bengali': 'প্রতিশোধ গ্রহণকারী', 'assamese': 'প্ৰতিশোধ লোৱা'},
    {'number': '82', 'arabic': 'الْعَفُوُّ', 'trans': 'Al-Afuww', 'trans_hindi': 'अल-अफ़ुव्व', 'trans_bengali': 'আল-আফুও', 'trans_assamese': 'আল-আফুও', 'meaning': 'The Pardoner', 'hindi': 'क्षमा करने वाला', 'bengali': 'ক্ষমাকারী', 'assamese': 'ক্ষমাকাৰী'},
    {'number': '83', 'arabic': 'الرَّؤُوفُ', 'trans': 'Ar-Ra\'uf', 'trans_hindi': 'अर-रऊफ़', 'trans_bengali': 'আর-রাউফ', 'trans_assamese': 'আৰ-ৰাউফ', 'meaning': 'The Compassionate', 'hindi': 'दयालु', 'bengali': 'দয়ালু', 'assamese': 'দয়ালু'},
    {'number': '84', 'arabic': 'مَالِكُ الْمُلْكِ', 'trans': 'Malik-ul-Mulk', 'trans_hindi': 'मालिक-उल-मुल्क', 'trans_bengali': 'মালিক-উল-মুলক', 'trans_assamese': 'মালিক-উল-মুলক', 'meaning': 'The Eternal Owner of Sovereignty', 'hindi': 'राज्य का मालिक', 'bengali': 'রাজ্যের মালিক', 'assamese': 'ৰাজ্যৰ মালিক'},
    {'number': '85', 'arabic': 'ذُو الْجَلَالِ وَالْإِكْرَامِ', 'trans': 'Dhul-Jalal wal-Ikram', 'trans_hindi': 'ज़ुल-जलालि वल-इकराम', 'trans_bengali': 'জুল-জালাল ওয়াল-ইকরাম', 'trans_assamese': 'জুল-জালাল ৱাল-ইকৰাম', 'meaning': 'The Lord of Majesty and Bounty', 'hindi': 'महिमा और सम्मान का स्वामी', 'bengali': 'মহিমা ও সম্মানের অধিপতি', 'assamese': 'মহিমা আৰু সন্মানৰ অধিপতি'},
    {'number': '86', 'arabic': 'الْمُقْسِطُ', 'trans': 'Al-Muqsit', 'trans_hindi': 'अल-मुक़्सित', 'trans_bengali': 'আল-মুকসিত', 'trans_assamese': 'আল-মুক্সিত', 'meaning': 'The Equitable', 'hindi': 'न्याय करने वाला', 'bengali': 'ন্যায়পরায়ণ', 'assamese': 'ন্যায়পৰায়ণ'},
    {'number': '87', 'arabic': 'الْجَامِعُ', 'trans': 'Al-Jami\'', 'trans_hindi': 'अल-जामि', 'trans_bengali': 'আল-জামি', 'trans_assamese': 'আল-জামি', 'meaning': 'The Gatherer', 'hindi': 'एकत्र करने वाला', 'bengali': 'একত্রকারী', 'assamese': 'একত্ৰ কৰা'},
    {'number': '88', 'arabic': 'الْغَنِيُّ', 'trans': 'Al-Ghaniyy', 'trans_hindi': 'अल-ग़नी', 'trans_bengali': 'আল-গানি', 'trans_assamese': 'আল-গানী', 'meaning': 'The Self-Sufficient', 'hindi': 'निस्वार्थ', 'bengali': 'নিঃস্বার্থ', 'assamese': 'নিঃস্বাৰ্থ'},
    {'number': '89', 'arabic': 'الْمُغْنِي', 'trans': 'Al-Mughni', 'trans_hindi': 'अल-मुग़नी', 'trans_bengali': 'আল-মুগনি', 'trans_assamese': 'আল-মুগনী', 'meaning': 'The Enricher', 'hindi': 'समृद्ध करने वाला', 'bengali': 'সমৃদ্ধকারী', 'assamese': 'সমৃদ্ধকাৰী'},
    {'number': '90', 'arabic': 'الْمَانِعُ', 'trans': 'Al-Mani\'', 'trans_hindi': 'अल-मानि', 'trans_bengali': 'আল-মানি', 'trans_assamese': 'আল-মানি', 'meaning': 'The Preventer', 'hindi': 'रोकने वाला', 'bengali': 'প্রতিরোধকারী', 'assamese': 'প্ৰতিৰোধকাৰী'},
    {'number': '91', 'arabic': 'الضَّارُّ', 'trans': 'Ad-Darr', 'trans_hindi': 'अद-द़र्र', 'trans_bengali': 'আদ-দার', 'trans_assamese': 'আদ-দাৰ', 'meaning': 'The Distresser', 'hindi': 'कष्ट देने वाला', 'bengali': 'কষ্টদাতা', 'assamese': 'কষ্ট দিয়া'},
    {'number': '92', 'arabic': 'النَّافِعُ', 'trans': 'An-Nafi\'', 'trans_hindi': 'अन-नाफि', 'trans_bengali': 'আন-নাফি', 'trans_assamese': 'আন-নাফি', 'meaning': 'The Benefactor', 'hindi': 'लाभ पहुँचाने वाला', 'bengali': 'উপকারকারী', 'assamese': 'উপকাৰী'},
    {'number': '93', 'arabic': 'النُّورُ', 'trans': 'An-Nur', 'trans_hindi': 'अन-नूर', 'trans_bengali': 'আন-নুর', 'trans_assamese': 'আন-নূৰ', 'meaning': 'The Light', 'hindi': 'प्रकाश', 'bengali': 'আলো', 'assamese': 'পোহৰ'},
    {'number': '94', 'arabic': 'الْهَادِي', 'trans': 'Al-Hadi', 'trans_hindi': 'अल-हादी', 'trans_bengali': 'আল-হাদি', 'trans_assamese': 'আল-হাদী', 'meaning': 'The Guide', 'hindi': 'मार्गदर्शक', 'bengali': 'পথপ্রদর্শক', 'assamese': 'পথপ্ৰদৰ্শক'},
    {'number': '95', 'arabic': 'الْبَدِيعُ', 'trans': 'Al-Badi\'', 'trans_hindi': 'अल-बदी', 'trans_bengali': 'আল-বাদি', 'trans_assamese': 'আল-বাদী', 'meaning': 'The Incomparable', 'hindi': 'अनुपम', 'bengali': 'অনুপম', 'assamese': 'অনুপম'},
    {'number': '96', 'arabic': 'الْبَاقِي', 'trans': 'Al-Baqi', 'trans_hindi': 'अल-बाक़ी', 'trans_bengali': 'আল-বাকি', 'trans_assamese': 'আল-বাকী', 'meaning': 'The Everlasting', 'hindi': 'शाश्वत', 'bengali': 'চিরস্থায়ী', 'assamese': 'চিৰস্থায়ী'},
    {'number': '97', 'arabic': 'الْوَارِثُ', 'trans': 'Al-Warith', 'trans_hindi': 'अल-वारिस', 'trans_bengali': 'আল-ওয়ারিস', 'trans_assamese': 'আল-ৱারিছ', 'meaning': 'The Inheritor', 'hindi': 'उत्तराधिकारी', 'bengali': 'উত্তরাধিকারী', 'assamese': 'উত্তৰাধিকাৰী'},
    {'number': '98', 'arabic': 'الرَّشِيدُ', 'trans': 'Ar-Rashid', 'trans_hindi': 'अर-रशीद', 'trans_bengali': 'আর-রশিদ', 'trans_assamese': 'আৰ-ৰছিদ', 'meaning': 'The Guide to the Right Path', 'hindi': 'सही मार्ग दिखाने वाला', 'bengali': 'সঠিক পথের দিকনির্দেশক', 'assamese': 'সঠিক পথৰ দিশদৰ্শক'},
    {'number': '99', 'arabic': 'الصَّبُورُ', 'trans': 'As-Sabur', 'trans_hindi': 'अस-सबूर', 'trans_bengali': 'আস-সাবুর', 'trans_assamese': 'আছ-ছাবুৰ', 'meaning': 'The Patient', 'hindi': 'धैर्यवान', 'bengali': 'ধৈর্যশীল', 'assamese': 'ধৈৰ্য্যশীল'},
  ];

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsService>(context);
    final double fontScale = settings.fontScale;

    // Filter names based on search query
    final filteredNames = _allNames.where((name) {
      // Check in transliteration based on current language
      final transKey = _currentLanguage == 'english' ? 'trans' : 'trans_$_currentLanguage';
      final transliteration = name[transKey] ?? name['trans']!;

      // Check in meaning based on current language
      final meaningKey = _currentLanguage == 'english' ? 'meaning' : _currentLanguage;
      final meaning = name[meaningKey] ?? name['meaning']!;

      return transliteration.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          meaning.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          name['number'] == _searchQuery;
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xDDD0F7F0),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFF0A4D4D),
        centerTitle: true,
        title: Text(
          "99 Names of Allah",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: (20 * fontScale).clamp(18, 24),
          ),
        ),
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16.0),
            color: const Color(0xFF0A4D4D),
            child: TextField(
              onChanged: (value) => setState(() => _searchQuery = value),
              style: const TextStyle(color: Colors.white),
              cursorColor: Colors.white,
              decoration: InputDecoration(
                hintText: "Search name or number...",
                hintStyle: TextStyle(color: Colors.white.withOpacity(0.6)),
                prefixIcon: const Icon(Icons.search, color: Colors.white70),
                filled: true,
                fillColor: Colors.white.withOpacity(0.15),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
            ),
          ),
          Expanded(
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.all(16),
                  sliver: SliverGrid(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 16,
                      crossAxisSpacing: 16,
                      childAspectRatio: 0.9,
                    ),
                    delegate: SliverChildBuilderDelegate(
                          (context, index) {
                        final name = filteredNames[index];
                        return _buildNameCard(name, index, fontScale);
                      },
                      childCount: filteredNames.length,
                    ),
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 40)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNameCard(Map<String, String> name, int index, double fontScale) {
    // Get the appropriate transliteration based on current language
    final transKey = _currentLanguage == 'english' ? 'trans' : 'trans_$_currentLanguage';
    final transliteration = name[transKey] ?? name['trans']!;

    // Get the appropriate meaning based on current language
    final meaningKey = _currentLanguage == 'english' ? 'meaning' : _currentLanguage;
    final meaning = name[meaningKey] ?? name['meaning']!;

    final animation = CurvedAnimation(
      parent: _controller,
      curve: Interval(
        (index * 0.03).clamp(0.0, 0.99),
        1.0,
        curve: Curves.easeOutCubic,
      ),
    );

    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        final double opacityValue = animation.value.clamp(0.0, 1.0);
        return Opacity(
          opacity: opacityValue,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - opacityValue)),
            child: child,
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.black.withOpacity(0.05)),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0A4D4D).withOpacity(0.5),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: () {
              Haptics.vibrate(HapticsType.light);
            },
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircleAvatar(
                    radius: 14,
                    backgroundColor: const Color(0xFF0A4D4D).withOpacity(0.1),
                    child: Text(
                      name['number']!,
                      style: TextStyle(
                        fontSize: 10 * fontScale,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF0A4D4D),
                      ),
                    ),
                  ),
                  const Spacer(),
                  AutoSizeText(
                    name['arabic']!,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    minFontSize: 18,
                    stepGranularity: 0.5,
                    style: TextStyle(
                      fontSize: 20 * fontScale,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF0A4D4D),
                      fontFamily: 'Amiri',
                    ),
                  ),
                  const SizedBox(height: 4),
                  AutoSizeText(
                    transliteration, // Use language-specific transliteration
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    minFontSize: 12,
                    style: TextStyle(
                      fontSize: 15 * fontScale,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    meaning, // Use language-specific meaning
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11 * fontScale,
                      color: Colors.grey[600],
                      fontStyle: FontStyle.italic,
                    ),
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