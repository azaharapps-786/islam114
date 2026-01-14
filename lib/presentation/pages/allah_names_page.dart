import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:haptic_feedback/haptic_feedback.dart';
import 'package:auto_size_text/auto_size_text.dart'; // ← Added this import

import '../../core/services/settings_service.dart';

class AllahNamesPage extends StatefulWidget {
  const AllahNamesPage({super.key});

  @override
  State<AllahNamesPage> createState() => _AllahNamesPageState();
}

class _AllahNamesPageState extends State<AllahNamesPage> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  String _searchQuery = "";

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // Full 99 Names Data Structure (unchanged)
  final List<Map<String, String>> _allNames = [
    {'number': '1', 'arabic': 'الرَّحْمَٰنُ', 'trans': 'Ar-Rahman', 'meaning': 'The Most Merciful', 'hindi': 'अत्यंत दयालु', 'bengali': 'পরম করুণাময়', 'assamese': 'অতি দয়ালু'},
    {'number': '2', 'arabic': 'الرَّحِيمُ', 'trans': 'Ar-Raheem', 'meaning': 'The Especially Merciful', 'hindi': 'विशेष रूप से दयालु', 'bengali': 'বিশেষ করুণাময়', 'assamese': 'বিশেষ দয়ালু'},
    {'number': '3', 'arabic': 'الْمَلِكُ', 'trans': 'Al-Malik', 'meaning': 'The Sovereign / The King', 'hindi': 'राजा', 'bengali': 'সম্রাট', 'assamese': 'ৰজা'},
    {'number': '4', 'arabic': 'الْقُدُّوسُ', 'trans': 'Al-Quddus', 'meaning': 'The Most Holy', 'hindi': 'पवित्र', 'bengali': 'পরম পবিত্র', 'assamese': 'পৰম পবিত্ৰ'},
    {'number': '5', 'arabic': 'السَّلَامُ', 'trans': 'As-Salam', 'meaning': 'The Source of Peace', 'hindi': 'शांति का स्रोत', 'bengali': 'শান্তির উৎস', 'assamese': 'শান্তিৰ উৎস'},
    {'number': '6', 'arabic': 'الْمُؤْمِنُ', 'trans': 'Al-Mu\'min', 'meaning': 'The Giver of Faith', 'hindi': 'ईमान देने वाला', 'bengali': 'বিশ্বাসদানকারী', 'assamese': 'বিশ্বাস দিয়া'},
    {'number': '7', 'arabic': 'الْمُهَيْمِنُ', 'trans': 'Al-Muhaymin', 'meaning': 'The Guardian', 'hindi': 'रक्षक', 'bengali': 'রক্ষাকারী', 'assamese': 'ৰক্ষক'},
    {'number': '8', 'arabic': 'الْعَزِيزُ', 'trans': 'Al-Aziz', 'meaning': 'The Almighty', 'hindi': 'परम शक्तिशाली', 'bengali': 'সর্বশক্তিমান', 'assamese': 'সৰ্বশক্তিমান'},
    {'number': '9', 'arabic': 'الْجَبَّارُ', 'trans': 'Al-Jabbar', 'meaning': 'The Compeller', 'hindi': 'जबरदस्त', 'bengali': 'পরাক্রমশালী', 'assamese': 'পৰাক্ৰমশালী'},
    {'number': '10', 'arabic': 'الْمُتَكَبِّرُ', 'trans': 'Al-Mutakabbir', 'meaning': 'The Supreme', 'hindi': 'महान', 'bengali': 'মহান', 'assamese': 'মহান'},
    {'number': '11', 'arabic': 'الْخَالِقُ', 'trans': 'Al-Khaliq', 'meaning': 'The Creator', 'hindi': 'सृष्टिकर्ता', 'bengali': 'স্রষ্টা', 'assamese': 'সৃষ্টিকৰ্তা'},
    {'number': '12', 'arabic': 'الْبَارِئُ', 'trans': 'Al-Bari\'', 'meaning': 'The Originator', 'hindi': 'उत्पादक', 'bengali': 'উৎপাদক', 'assamese': 'উৎপাদক'},
    {'number': '13', 'arabic': 'الْمُصَوِّرُ', 'trans': 'Al-Musawwir', 'meaning': 'The Fashioner', 'hindi': 'रूप देने वाला', 'bengali': 'রূপদাতা', 'assamese': 'ৰূপদাতা'},
    {'number': '14', 'arabic': 'الْغَفَّارُ', 'trans': 'Al-Ghaffar', 'meaning': 'The All-Forgiving', 'hindi': 'क्षमा करने वाला', 'bengali': 'ক্ষমাকারী', 'assamese': 'ক্ষমাকাৰী'},
    {'number': '15', 'arabic': 'الْقَهَّارُ', 'trans': 'Al-Qahhar', 'meaning': 'The Subduer', 'hindi': 'दबाने वाला', 'bengali': 'দমনকারী', 'assamese': 'দমনকাৰী'},
    {'number': '16', 'arabic': 'الْوَهَّابُ', 'trans': 'Al-Wahhab', 'meaning': 'The Bestower', 'hindi': 'दाता', 'bengali': 'দাতা', 'assamese': 'দাতা'},
    {'number': '17', 'arabic': 'الرَّزَّاقُ', 'trans': 'Ar-Razzaq', 'meaning': 'The Provider', 'hindi': 'रिज़्क देने वाला', 'bengali': 'রিজিক দানকারী', 'assamese': 'ৰিজিক দানকাৰী'},
    {'number': '18', 'arabic': 'الْفَتَّاحُ', 'trans': 'Al-Fattah', 'meaning': 'The Opener', 'hindi': 'द्वार खोलने वाला', 'bengali': 'দ্বার উন্মোচনকারী', 'assamese': 'দ্বাৰ উন্মোচনকাৰী'},
    {'number': '19', 'arabic': 'الْعَلِيمُ', 'trans': 'Al-Alim', 'meaning': 'The All-Knowing', 'hindi': 'सब जानने वाला', 'bengali': 'সর্বজ্ঞ', 'assamese': 'সৰ্বজ্ঞ'},
    {'number': '20', 'arabic': 'الْقَابِضُ', 'trans': 'Al-Qabid', 'meaning': 'The Constrictor', 'hindi': 'संकोच करने वाला', 'bengali': 'সংকোচকারী', 'assamese': 'সংকোচকাৰী'},
    {'number': '21', 'arabic': 'الْبَاسِطُ', 'trans': 'Al-Basit', 'meaning': 'The Expander', 'hindi': 'विस्तार करने वाला', 'bengali': 'বিস্তারকারী', 'assamese': 'বিস্তাৰকাৰী'},
    {'number': '22', 'arabic': 'الْخَافِضُ', 'trans': 'Al-Khafid', 'meaning': 'The Abaser', 'hindi': 'नीचा करने वाला', 'bengali': 'নিচুকারী', 'assamese': 'নমাই দিয়া'},
    {'number': '23', 'arabic': 'الرَّافِعُ', 'trans': 'Ar-Rafi\'', 'meaning': 'The Exalter', 'hindi': 'ऊँचा करने वाला', 'bengali': 'উচ্চকারী', 'assamese': 'উচ্চ কৰা'},
    {'number': '24', 'arabic': 'الْمُعِزُّ', 'trans': 'Al-Mu\'izz', 'meaning': 'The Honorer', 'hindi': 'इज्जत देने वाला', 'bengali': 'সম্মানদাতা', 'assamese': 'সন্মান দিয়া'},
    {'number': '25', 'arabic': 'المُذِلُّ', 'trans': 'Al-Mudhill', 'meaning': 'The Humiliator', 'hindi': 'अपमान करने वाला', 'bengali': 'অপমানকারী', 'assamese': 'অপমান কৰা'},
    {'number': '26', 'arabic': 'السَّمِيعُ', 'trans': 'As-Sami\'', 'meaning': 'The All-Hearing', 'hindi': 'सब सुनने वाला', 'bengali': 'সর্বশ্রোতা', 'assamese': 'সৰ্বশ্ৰোতা'},
    {'number': '27', 'arabic': 'الْبَصِيرُ', 'trans': 'Al-Basir', 'meaning': 'The All-Seeing', 'hindi': 'सब देखने वाला', 'bengali': 'সর্বদ্রষ্টা', 'assamese': 'সৰ্বদ্ৰষ্টা'},
    {'number': '28', 'arabic': 'الْحَكَمُ', 'trans': 'Al-Hakam', 'meaning': 'The Judge', 'hindi': 'न्यायाधीश', 'bengali': 'বিচারক', 'assamese': 'বিচাৰক'},
    {'number': '29', 'arabic': 'الْعَدْلُ', 'trans': 'Al-Adl', 'meaning': 'The Just', 'hindi': 'न्यायप्रिय', 'bengali': 'ন্যায়পরায়ণ', 'assamese': 'ন্যায়পৰায়ণ'},
    {'number': '30', 'arabic': 'اللَّطِيفُ', 'trans': 'Al-Latif', 'meaning': 'The Subtle One', 'hindi': 'सूक्ष्म', 'bengali': 'সূক্ষ্ম', 'assamese': 'সূক্ষ্ম'},
    {'number': '31', 'arabic': 'الْخَبِيرُ', 'trans': 'Al-Khabir', 'meaning': 'The All-Aware', 'hindi': 'सबसे अच्छी तरह जानने वाला', 'bengali': 'সর্বজ্ঞাত', 'assamese': 'সৰ্বজ্ঞাত'},
    {'number': '32', 'arabic': 'الْحَلِيمُ', 'trans': 'Al-Halim', 'meaning': 'The Forbearing', 'hindi': 'सहनशील', 'bengali': 'সহনশীল', 'assamese': 'সহনশীল'},
    {'number': '33', 'arabic': 'الْعَظِيمُ', 'trans': 'Al-Azim', 'meaning': 'The Magnificent', 'hindi': 'महान', 'bengali': 'মহান', 'assamese': 'মহান'},
    {'number': '34', 'arabic': 'الْغَفُورُ', 'trans': 'Al-Ghafur', 'meaning': 'The All-Forgiving', 'hindi': 'बहुत क्षमा करने वाला', 'bengali': 'অতি ক্ষমাশীল', 'assamese': 'অতি ক্ষমাশীল'},
    {'number': '35', 'arabic': 'الشَّكُورُ', 'trans': 'Ash-Shakur', 'meaning': 'The Appreciative', 'hindi': 'गुणग्राहक', 'bengali': 'গুণগ্রাহী', 'assamese': 'গুণগ্ৰাহী'},
    {'number': '36', 'arabic': 'الْعَلِيُّ', 'trans': 'Al-Aliyy', 'meaning': 'The Most High', 'hindi': 'सर्वोच्च', 'bengali': 'সর্বোচ্চ', 'assamese': 'সৰ্বোচ্চ'},
    {'number': '37', 'arabic': 'الْكَبِيرُ', 'trans': 'Al-Kabir', 'meaning': 'The Most Great', 'hindi': 'महानतम', 'bengali': 'মহানতম', 'assamese': 'মহানতম'},
    {'number': '38', 'arabic': 'الْحَفِيظُ', 'trans': 'Al-Hafiz', 'meaning': 'The Preserver', 'hindi': 'रक्षक', 'bengali': 'রক্ষাকারী', 'assamese': 'ৰক্ষক'},
    {'number': '39', 'arabic': 'المُقِيتُ', 'trans': 'Al-Muqit', 'meaning': 'The Sustainer', 'hindi': 'पालनहार', 'bengali': 'পালনকারী', 'assamese': 'পালনকাৰী'},
    {'number': '40', 'arabic': 'الْحَسِيبُ', 'trans': 'Al-Hasib', 'meaning': 'The Reckoner', 'hindi': 'हिसाब करने वाला', 'bengali': 'হিসাবকারী', 'assamese': 'হিচাপ কৰা'},
    {'number': '41', 'arabic': 'الْجَلِيلُ', 'trans': 'Al-Jalil', 'meaning': 'The Majestic', 'hindi': 'प्रतापी', 'bengali': 'মহিমান্বিত', 'assamese': 'মহিমান্বিত'},
    {'number': '42', 'arabic': 'الْكَرِيمُ', 'trans': 'Al-Karim', 'meaning': 'The Generous', 'hindi': 'उदार', 'bengali': 'উদার', 'assamese': 'উদাৰ'},
    {'number': '43', 'arabic': 'الرَّقِيبُ', 'trans': 'Ar-Raqib', 'meaning': 'The Watchful', 'hindi': 'निगरानी करने वाला', 'bengali': 'পর্যবেক্ষক', 'assamese': 'পৰ্যবেক্ষক'},
    {'number': '44', 'arabic': 'الْمُجِيبُ', 'trans': 'Al-Mujib', 'meaning': 'The Responsive', 'hindi': 'उत्तर देने वाला', 'bengali': 'উত্তরদাতা', 'assamese': 'উত্তৰ দিয়া'},
    {'number': '45', 'arabic': 'الْوَاسِعُ', 'trans': 'Al-Wasi\'', 'meaning': 'The All-Encompassing', 'hindi': 'व्यापक', 'bengali': 'ব্যাপক', 'assamese': 'ব্যাপক'},
    {'number': '46', 'arabic': 'الْحَكِيمُ', 'trans': 'Al-Hakim', 'meaning': 'The Wise', 'hindi': 'बुद्धिमान', 'bengali': 'জ্ঞানী', 'assamese': 'জ্ঞানী'},
    {'number': '47', 'arabic': 'الْوَدُودُ', 'trans': 'Al-Wadud', 'meaning': 'The Loving', 'hindi': 'प्रेम करने वाला', 'bengali': 'প্রেমময়', 'assamese': 'প্ৰেমময়'},
    {'number': '48', 'arabic': 'الْمَجِيدُ', 'trans': 'Al-Majid', 'meaning': 'The Glorious', 'hindi': 'महिमामय', 'bengali': 'মহিমাময়', 'assamese': 'মহিমাময়'},
    {'number': '49', 'arabic': 'الْبَاعِثُ', 'trans': 'Al-Ba\'ith', 'meaning': 'The Resurrector', 'hindi': 'पुनर्जीवित करने वाला', 'bengali': 'পুনর্জীবিতকারী', 'assamese': 'পুনৰ্জীৱিত কৰা'},
    {'number': '50', 'arabic': 'الشَّهِيدُ', 'trans': 'Ash-Shahid', 'meaning': 'The Witness', 'hindi': 'साक्षी', 'bengali': 'সাক্ষী', 'assamese': 'সাক্ষী'},
    {'number': '51', 'arabic': 'الْحَقُّ', 'trans': 'Al-Haqq', 'meaning': 'The Truth', 'hindi': 'सत्य', 'bengali': 'সত্য', 'assamese': 'সত্য'},
    {'number': '52', 'arabic': 'الْوَكِيلُ', 'trans': 'Al-Wakil', 'meaning': 'The Trustee', 'hindi': 'भरोसेमंद', 'bengali': 'বিশ্বস্ত', 'assamese': 'বিশ্বাসযোগ্য'},
    {'number': '53', 'arabic': 'الْقَوِيُّ', 'trans': 'Al-Qawiyy', 'meaning': 'The Most Strong', 'hindi': 'सबसे शक्तिशाली', 'bengali': 'সর্বশক্তিমান', 'assamese': 'সৰ্বশক্তিশালী'},
    {'number': '54', 'arabic': 'الْمَتِينُ', 'trans': 'Al-Matin', 'meaning': 'The Firm', 'hindi': 'दृढ़', 'bengali': 'দৃঢ়', 'assamese': 'দৃঢ়'},
    {'number': '55', 'arabic': 'الْوَلِيُّ', 'trans': 'Al-Waliyy', 'meaning': 'The Protecting Friend', 'hindi': 'रक्षक मित्र', 'bengali': 'রক্ষাকারী বন্ধু', 'assamese': 'ৰক্ষাকাৰী বন্ধু'},
    {'number': '56', 'arabic': 'الْحَمِيدُ', 'trans': 'Al-Hamid', 'meaning': 'The Praiseworthy', 'hindi': 'प्रशंसनीय', 'bengali': 'প্রশংসনীয়', 'assamese': 'প্ৰশংসনীয়'},
    {'number': '57', 'arabic': 'الْمُحْصِي', 'trans': 'Al-Muhsi', 'meaning': 'The Reckoner', 'hindi': 'गणना करने वाला', 'bengali': 'গণনাকারী', 'assamese': 'গণনা কৰা'},
    {'number': '58', 'arabic': 'الْمُبْدِئُ', 'trans': 'Al-Mubdi\'', 'meaning': 'The Originator', 'hindi': 'आरंभ करने वाला', 'bengali': 'আদিকারী', 'assamese': 'আৰম্ভ কৰা'},
    {'number': '59', 'arabic': 'الْمُعِيدُ', 'trans': 'Al-Mu\'id', 'meaning': 'The Restorer', 'hindi': 'पुनर्स्थापक', 'bengali': 'পুনঃস্থাপক', 'assamese': 'পুনঃস্থাপক'},
    {'number': '60', 'arabic': 'الْمُحْيِي', 'trans': 'Al-Muhyi', 'meaning': 'The Giver of Life', 'hindi': 'जीवन देने वाला', 'bengali': 'জীবনদাতা', 'assamese': 'জীৱন দিয়া'},
    {'number': '61', 'arabic': 'اَلْمُمِيتُ', 'trans': 'Al-Mumit', 'meaning': 'The Creator of Death', 'hindi': 'मृत्यु देने वाला', 'bengali': 'মৃত্যুদাতা', 'assamese': 'মৃত্যু দিয়া'},
    {'number': '62', 'arabic': 'الْحَيُّ', 'trans': 'Al-Hayy', 'meaning': 'The Ever-Living', 'hindi': 'सदा जीवित', 'bengali': 'চিরঞ্জীব', 'assamese': 'চিৰঞ্জীৱ'},
    {'number': '63', 'arabic': 'الْقَيُّومُ', 'trans': 'Al-Qayyum', 'meaning': 'The Self-Subsisting', 'hindi': 'स्वयंभू', 'bengali': 'স্বয়ংভূ', 'assamese': 'স্বয়ংভূ'},
    {'number': '64', 'arabic': 'الْوَاجِدُ', 'trans': 'Al-Wajid', 'meaning': 'The Finder', 'hindi': 'प्राप्त करने वाला', 'bengali': 'প্রাপ্তকারী', 'assamese': 'প্ৰাপ্তকাৰী'},
    {'number': '65', 'arabic': 'الْمَاجِدُ', 'trans': 'Al-Majid', 'meaning': 'The Glorious', 'hindi': 'महान', 'bengali': 'মহিমান্বিত', 'assamese': 'মহিমান্বিত'},
    {'number': '66', 'arabic': 'الْواحِدُ', 'trans': 'Al-Wahid', 'meaning': 'The One', 'hindi': 'एक', 'bengali': 'এক', 'assamese': 'এক'},
    {'number': '67', 'arabic': 'الْأَحَدُ', 'trans': 'Al-Ahad', 'meaning': 'The Unique', 'hindi': 'अद्वितीय', 'bengali': 'অদ্বিতীয়', 'assamese': 'অদ্বিতীয়'},
    {'number': '68', 'arabic': 'الصَّمَدُ', 'trans': 'As-Samad', 'meaning': 'The Eternal', 'hindi': 'शाश्वत', 'bengali': 'শাশ্বত', 'assamese': 'শাশ্বত'},
    {'number': '69', 'arabic': 'الْقَادِرُ', 'trans': 'Al-Qadir', 'meaning': 'The All-Powerful', 'hindi': 'सर्वशक्तिमान', 'bengali': 'সর্বশক্তিমান', 'assamese': 'সৰ্বশক্তিমান'},
    {'number': '70', 'arabic': 'الْمُقْتَدِرُ', 'trans': 'Al-Muqtadir', 'meaning': 'The Determiner', 'hindi': 'निर्धारक', 'bengali': 'নির্ধারক', 'assamese': 'নিৰ্ধাৰক'},
    {'number': '71', 'arabic': 'الْمُقَدِّمُ', 'trans': 'Al-Muqaddim', 'meaning': 'The Expediter', 'hindi': 'आगे करने वाला', 'bengali': 'অগ্রবর্তীকারী', 'assamese': 'অগ্ৰগামী'},
    {'number': '72', 'arabic': 'الْمُؤَخِّرُ', 'trans': 'Al-Mu\'akhkhir', 'meaning': 'The Delayer', 'hindi': 'पीछे करने वाला', 'bengali': 'পশ্চাদপসরণকারী', 'assamese': 'পিছুৱাই দিয়া'},
    {'number': '73', 'arabic': 'الأَوَّلُ', 'trans': 'Al-Awwal', 'meaning': 'The First', 'hindi': 'प्रथम', 'bengali': 'প্রথম', 'assamese': 'প্ৰথম'},
    {'number': '74', 'arabic': 'الآخِرُ', 'trans': 'Al-Akhir', 'meaning': 'The Last', 'hindi': 'अंतिम', 'bengali': 'শেষ', 'assamese': 'শেষ'},
    {'number': '75', 'arabic': 'الظَّاهِرُ', 'trans': 'Az-Zahir', 'meaning': 'The Manifest', 'hindi': 'प्रकट', 'bengali': 'প্রকাশিত', 'assamese': 'প্ৰকাশিত'},
    {'number': '76', 'arabic': 'الْبَاطِنُ', 'trans': 'Al-Batin', 'meaning': 'The Hidden', 'hindi': 'गुप्त', 'bengali': 'গোপন', 'assamese': 'গোপন'},
    {'number': '77', 'arabic': 'الْوَالِي', 'trans': 'Al-Wali', 'meaning': 'The Governor', 'hindi': 'शासक', 'bengali': 'শাসক', 'assamese': 'শাসক'},
    {'number': '78', 'arabic': 'الْمُتَعَالِي', 'trans': 'Al-Muta\'ali', 'meaning': 'The Exalted', 'hindi': 'उच्च', 'bengali': 'উচ্চ', 'assamese': 'উচ্চ'},
    {'number': '79', 'arabic': 'الْبَرُّ', 'trans': 'Al-Barr', 'meaning': 'The Source of Goodness', 'hindi': 'नेकी का स्रोत', 'bengali': 'কল্যাণের উৎস', 'assamese': 'কল্যাণৰ উৎস'},
    {'number': '80', 'arabic': 'التَّوَابُ', 'trans': 'At-Tawwab', 'meaning': 'The Acceptor of Repentance', 'hindi': 'तौबा कबूल करने वाला', 'bengali': 'তওবা গ্রহণকারী', 'assamese': 'তওবা গ্ৰহণকাৰী'},
    {'number': '81', 'arabic': 'الْمُنْتَقِمُ', 'trans': 'Al-Muntaqim', 'meaning': 'The Avenger', 'hindi': 'प्रतिशोध लेने वाला', 'bengali': 'প্রতিশোধ গ্রহণকারী', 'assamese': 'প্ৰতিশোধ লোৱা'},
    {'number': '82', 'arabic': 'الْعَفُوُّ', 'trans': 'Al-Afuww', 'meaning': 'The Pardoner', 'hindi': 'क्षमा करने वाला', 'bengali': 'ক্ষমাকারী', 'assamese': 'ক্ষমাকাৰী'},
    {'number': '83', 'arabic': 'الرَّؤُوفُ', 'trans': 'Ar-Ra\'uf', 'meaning': 'The Compassionate', 'hindi': 'दयालु', 'bengali': 'দয়ালু', 'assamese': 'দয়ালু'},
    {'number': '84', 'arabic': 'مَالِكُ الْمُلْكِ', 'trans': 'Malik-ul-Mulk', 'meaning': 'The Eternal Owner of Sovereignty', 'hindi': 'राज्य का मालिक', 'bengali': 'রাজ্যের মালিক', 'assamese': 'ৰাজ্যৰ মালিক'},
    {'number': '85', 'arabic': 'ذُو الْجَلَالِ وَالْإِكْرَامِ', 'trans': 'Dhul-Jalal wal-Ikram', 'meaning': 'The Lord of Majesty and Bounty', 'hindi': 'महिमा और सम्मान का स्वामी', 'bengali': 'মহিমা ও সম্মানের অধিপতি', 'assamese': 'মহিমা আৰু সন্মানৰ অধিপতি'},
    {'number': '86', 'arabic': 'الْمُقْسِطُ', 'trans': 'Al-Muqsit', 'meaning': 'The Equitable', 'hindi': 'न्याय करने वाला', 'bengali': 'ন্যায়পরায়ণ', 'assamese': 'ন্যায়পৰায়ণ'},
    {'number': '87', 'arabic': 'الْجَامِعُ', 'trans': 'Al-Jami\'', 'meaning': 'The Gatherer', 'hindi': 'एकत्र करने वाला', 'bengali': 'একত্রকারী', 'assamese': 'একত্ৰ কৰা'},
    {'number': '88', 'arabic': 'الْغَنِيُّ', 'trans': 'Al-Ghaniyy', 'meaning': 'The Self-Sufficient', 'hindi': 'निस्वार्थ', 'bengali': 'নিঃস্বার্থ', 'assamese': 'নিঃস্বাৰ্থ'},
    {'number': '89', 'arabic': 'الْمُغْنِي', 'trans': 'Al-Mughni', 'meaning': 'The Enricher', 'hindi': 'समृद्ध करने वाला', 'bengali': 'সমৃদ্ধকারী', 'assamese': 'সমৃদ্ধকাৰী'},
    {'number': '90', 'arabic': 'الْمَانِعُ', 'trans': 'Al-Mani\'', 'meaning': 'The Preventer', 'hindi': 'रोकने वाला', 'bengali': 'প্রতিরোধকারী', 'assamese': 'প্ৰতিৰোধকাৰী'},
    {'number': '91', 'arabic': 'الضَّارُّ', 'trans': 'Ad-Darr', 'meaning': 'The Distresser', 'hindi': 'कष्ट देने वाला', 'bengali': 'কষ্টদাতা', 'assamese': 'কষ্ট দিয়া'},
    {'number': '92', 'arabic': 'النَّافِعُ', 'trans': 'An-Nafi\'', 'meaning': 'The Benefactor', 'hindi': 'लाभ पहुँचाने वाला', 'bengali': 'উপকারকারী', 'assamese': 'উপকাৰী'},
    {'number': '93', 'arabic': 'النُّورُ', 'trans': 'An-Nur', 'meaning': 'The Light', 'hindi': 'प्रकाश', 'bengali': 'আলো', 'assamese': 'পোহৰ'},
    {'number': '94', 'arabic': 'الْهَادِي', 'trans': 'Al-Hadi', 'meaning': 'The Guide', 'hindi': 'मार्गदर्शक', 'bengali': 'পথপ্রদর্শক', 'assamese': 'পথপ্ৰদৰ্শক'},
    {'number': '95', 'arabic': 'الْبَدِيعُ', 'trans': 'Al-Badi\'', 'meaning': 'The Incomparable', 'hindi': 'अनुपम', 'bengali': 'অনুপম', 'assamese': 'অনুপম'},
    {'number': '96', 'arabic': 'الْبَاقِي', 'trans': 'Al-Baqi', 'meaning': 'The Everlasting', 'hindi': 'शाश्वत', 'bengali': 'চিরস্থায়ী', 'assamese': 'চিৰস্থায়ী'},
    {'number': '97', 'arabic': 'الْوَارِثُ', 'trans': 'Al-Warith', 'meaning': 'The Inheritor', 'hindi': 'उत्तराधिकारी', 'bengali': 'উত্তরাধিকারী', 'assamese': 'উত্তৰাধিকাৰী'},
    {'number': '98', 'arabic': 'الرَّشِيدُ', 'trans': 'Ar-Rashid', 'meaning': 'The Guide to the Right Path', 'hindi': 'सही मार्ग दिखाने वाला', 'bengali': 'সঠিক পথের দিকনির্দেশক', 'assamese': 'সঠিক পথৰ দিশদৰ্শক'},
    {'number': '99', 'arabic': 'الصَّبُورُ', 'trans': 'As-Sabur', 'meaning': 'The Patient', 'hindi': 'धैर्यवान', 'bengali': 'ধৈর্যশীল', 'assamese': 'ধৈৰ্য্যশীল'},
  ];

  @override
  Widget build(BuildContext context) {
    final double fontScale = Provider.of<SettingsService>(context).fontScale;

    final filteredNames = _allNames.where((name) {
      return name['trans']!.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          name['number'] == _searchQuery;
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xDDD0F7F0), // Clean light background
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
          // Professional Search Bar Container
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
    // Staggered Animation Logic with Clamping Fix
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
              color: const Color(0xFF0A4D4D).withOpacity(0.06),
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
              // Future: Navigate to detail page if needed
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
                    name['trans']!,
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
                    name['meaning']!,
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