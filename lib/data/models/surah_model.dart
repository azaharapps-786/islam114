// data/models/surah_model.dart
import 'dart:convert';

class Surah {
  final int id;
  final String name;            // Arabic name (used for 'arabic' language)
  final String transliteration; // English transliteration
  final String translation;     // English translation
  final String assameseName;    // Assamese name (may be empty)
  final String hindiName;       // Hindi name (may be empty)
  final String bengaliName;     // Bengali name (may be empty)
  final int totalVerses;
  final String revelationType;

  const Surah({
    required this.id,
    required this.name,
    required this.transliteration,
    required this.translation,
    required this.assameseName,
    required this.hindiName,
    required this.bengaliName,
    required this.totalVerses,
    required this.revelationType,
  });

  /// -----------------------------------------------------------------
  ///  Factory that builds a Surah from minimal JSON (number + name).
  /// -----------------------------------------------------------------
  factory Surah.fromJson(Map<String, dynamic> json, {String? language}) {
    final number = json['number'] as int? ?? 0;
    final localName = json['name'] as String? ?? '';

    // English fallback data
    final englishData = _englishFallback[number - 1];

    // Set language-specific name
    String assamese = '';
    String hindi = '';
    String bengali = '';
    if (language != null && localName.isNotEmpty) {
      switch (language.toLowerCase()) {
        case 'assamese':
          assamese = localName;
          break;
        case 'hindi':
          hindi = localName;
          break;
        case 'bengali':
          bengali = localName;
          break;
        case 'arabic':
        // For Arabic, "name" in JSON is Arabic script — use it for display, but fallback provides standard Arabic
          break;
        case 'english':
        // For English, "name" is transliteration, but we use fallback
          break;
      }
    }

    return Surah(
      id: number,
      name: language == 'arabic' ? localName : (englishData['arabic'] as String),
      transliteration: englishData['transliteration'] as String,
      translation: englishData['translation'] as String,
      assameseName: assamese,
      hindiName: hindi,
      bengaliName: bengali,
      totalVerses: englishData['totalVerses'] as int,
      revelationType: englishData['revelationType'] as String,
    );
  }

  /// -----------------------------------------------------------------
  ///  English fallback data (hardcoded for all fields).
  /// -----------------------------------------------------------------
  static const List<Map<String, dynamic>> _englishFallback = [
    {'arabic': 'الفاتحة', 'transliteration': 'Al-Fatihah', 'translation': 'The Opening', 'totalVerses': 7, 'revelationType': 'Meccan'},
    {'arabic': 'البقرة', 'transliteration': 'Al-Baqarah', 'translation': 'The Cow', 'totalVerses': 286, 'revelationType': 'Medinan'},
    {'arabic': 'آل عمران', 'transliteration': 'Aal-E-Imran', 'translation': 'The Family of Imran', 'totalVerses': 200, 'revelationType': 'Medinan'},
    {'arabic': 'النساء', 'transliteration': 'An-Nisa', 'translation': 'The Women', 'totalVerses': 176, 'revelationType': 'Medinan'},
    {'arabic': 'المائدة', 'transliteration': 'Al-Ma\'idah', 'translation': 'The Table Spread', 'totalVerses': 120, 'revelationType': 'Medinan'},
    {'arabic': 'الأنعام', 'transliteration': 'Al-An\'am', 'translation': 'The Cattle', 'totalVerses': 165, 'revelationType': 'Meccan'},
    {'arabic': 'الأعراف', 'transliteration': 'Al-A\'raf', 'translation': 'The Heights', 'totalVerses': 206, 'revelationType': 'Meccan'},
    {'arabic': 'الأنفال', 'transliteration': 'Al-Anfal', 'translation': 'The Spoils of War', 'totalVerses': 75, 'revelationType': 'Medinan'},
    {'arabic': 'التوبة', 'transliteration': 'At-Tawbah', 'translation': 'The Repentance', 'totalVerses': 129, 'revelationType': 'Medinan'},
    {'arabic': 'يونس', 'transliteration': 'Yunus', 'translation': 'Jonah', 'totalVerses': 109, 'revelationType': 'Meccan'},
    {'arabic': 'هود', 'transliteration': 'Hud', 'translation': 'Hud', 'totalVerses': 123, 'revelationType': 'Meccan'},
    {'arabic': 'يوسف', 'transliteration': 'Yusuf', 'translation': 'Joseph', 'totalVerses': 111, 'revelationType': 'Meccan'},
    {'arabic': 'الرعد', 'transliteration': 'Ar-Ra\'d', 'translation': 'The Thunder', 'totalVerses': 43, 'revelationType': 'Medinan'},
    {'arabic': 'إبراهيم', 'transliteration': 'Ibrahim', 'translation': 'Abraham', 'totalVerses': 52, 'revelationType': 'Meccan'},
    {'arabic': 'الحجر', 'transliteration': 'Al-Hijr', 'translation': 'The Rocky Tract', 'totalVerses': 99, 'revelationType': 'Meccan'},
    {'arabic': 'النحل', 'transliteration': 'An-Nahl', 'translation': 'The Bee', 'totalVerses': 128, 'revelationType': 'Meccan'},
    {'arabic': 'الإسراء', 'transliteration': 'Al-Isra', 'translation': 'The Night Journey', 'totalVerses': 111, 'revelationType': 'Meccan'},
    {'arabic': 'الكهف', 'transliteration': 'Al-Kahf', 'translation': 'The Cave', 'totalVerses': 110, 'revelationType': 'Meccan'},
    {'arabic': 'مريم', 'transliteration': 'Maryam', 'translation': 'Mary', 'totalVerses': 98, 'revelationType': 'Meccan'},
    {'arabic': 'طه', 'transliteration': 'Taha', 'translation': 'Ta-Ha', 'totalVerses': 135, 'revelationType': 'Meccan'},
    {'arabic': 'الأنبياء', 'transliteration': 'Al-Anbiya', 'translation': 'The Prophets', 'totalVerses': 112, 'revelationType': 'Meccan'},
    {'arabic': 'الحج', 'transliteration': 'Al-Hajj', 'translation': 'The Pilgrimage', 'totalVerses': 78, 'revelationType': 'Medinan'},
    {'arabic': 'المؤمنون', 'transliteration': 'Al-Mu\'minun', 'translation': 'The Believers', 'totalVerses': 118, 'revelationType': 'Meccan'},
    {'arabic': 'النور', 'transliteration': 'An-Nur', 'translation': 'The Light', 'totalVerses': 64, 'revelationType': 'Medinan'},
    {'arabic': 'الفرقان', 'transliteration': 'Al-Furqan', 'translation': 'The Criterion', 'totalVerses': 77, 'revelationType': 'Meccan'},
    {'arabic': 'الشعراء', 'transliteration': 'Ash-Shu\'ara', 'translation': 'The Poets', 'totalVerses': 227, 'revelationType': 'Meccan'},
    {'arabic': 'النمل', 'transliteration': 'An-Naml', 'translation': 'The Ant', 'totalVerses': 93, 'revelationType': 'Meccan'},
    {'arabic': 'القصص', 'transliteration': 'Al-Qasas', 'translation': 'The Stories', 'totalVerses': 88, 'revelationType': 'Meccan'},
    {'arabic': 'العنكبوت', 'transliteration': 'Al-Ankabut', 'translation': 'The Spider', 'totalVerses': 69, 'revelationType': 'Meccan'},
    {'arabic': 'الروم', 'transliteration': 'Ar-Rum', 'translation': 'The Romans', 'totalVerses': 60, 'revelationType': 'Meccan'},
    {'arabic': 'لقمان', 'transliteration': 'Luqman', 'translation': 'Luqman', 'totalVerses': 34, 'revelationType': 'Meccan'},
    {'arabic': 'السجدة', 'transliteration': 'As-Sajdah', 'translation': 'The Prostration', 'totalVerses': 30, 'revelationType': 'Meccan'},
    {'arabic': 'الأحزاب', 'transliteration': 'Al-Ahzab', 'translation': 'The Confederates', 'totalVerses': 73, 'revelationType': 'Medinan'},
    {'arabic': 'سبأ', 'transliteration': 'Saba', 'translation': 'Sheba', 'totalVerses': 54, 'revelationType': 'Meccan'},
    {'arabic': 'فاطر', 'transliteration': 'Fatir', 'translation': 'The Originator', 'totalVerses': 45, 'revelationType': 'Meccan'},
    {'arabic': 'يس', 'transliteration': 'Ya-Sin', 'translation': 'Ya-Sin', 'totalVerses': 83, 'revelationType': 'Meccan'},
    {'arabic': 'الصافات', 'transliteration': 'As-Saffat', 'translation': 'Those Ranged in Ranks', 'totalVerses': 182, 'revelationType': 'Meccan'},
    {'arabic': 'ص', 'transliteration': 'Sad', 'translation': 'Sad', 'totalVerses': 88, 'revelationType': 'Meccan'},
    {'arabic': 'الزمر', 'transliteration': 'Az-Zumar', 'translation': 'The Groups', 'totalVerses': 75, 'revelationType': 'Meccan'},
    {'arabic': 'غافر', 'transliteration': 'Ghafir', 'translation': 'The Forgiver', 'totalVerses': 85, 'revelationType': 'Meccan'},
    {'arabic': 'فصلت', 'transliteration': 'Fussilat', 'translation': 'Explained in Detail', 'totalVerses': 54, 'revelationType': 'Meccan'},
    {'arabic': 'الشورى', 'transliteration': 'Ash-Shura', 'translation': 'The Consultation', 'totalVerses': 53, 'revelationType': 'Meccan'},
    {'arabic': 'الزخرف', 'transliteration': 'Az-Zukhruf', 'translation': 'The Ornaments of Gold', 'totalVerses': 89, 'revelationType': 'Meccan'},
    {'arabic': 'الدخان', 'transliteration': 'Ad-Dukhan', 'translation': 'The Smoke', 'totalVerses': 59, 'revelationType': 'Meccan'},
    {'arabic': 'الجاثية', 'transliteration': 'Al-Jathiyah', 'translation': 'The Kneeling', 'totalVerses': 37, 'revelationType': 'Meccan'},
    {'arabic': 'الأحقاف', 'transliteration': 'Al-Ahqaf', 'translation': 'The Wind-Curved Sandhills', 'totalVerses': 35, 'revelationType': 'Meccan'},
    {'arabic': 'محمد', 'transliteration': 'Muhammad', 'translation': 'Muhammad', 'totalVerses': 38, 'revelationType': 'Medinan'},
    {'arabic': 'الفتح', 'transliteration': 'Al-Fath', 'translation': 'The Victory', 'totalVerses': 29, 'revelationType': 'Medinan'},
    {'arabic': 'الحجرات', 'transliteration': 'Al-Hujurat', 'translation': 'The Private Apartments', 'totalVerses': 18, 'revelationType': 'Medinan'},
    {'arabic': 'ق', 'transliteration': 'Qaf', 'translation': 'Qaf', 'totalVerses': 45, 'revelationType': 'Meccan'},
    {'arabic': 'الذاريات', 'transliteration': 'Adh-Dhariyat', 'translation': 'The Winnowing Winds', 'totalVerses': 60, 'revelationType': 'Meccan'},
    {'arabic': 'الطور', 'transliteration': 'At-Tur', 'translation': 'The Mount', 'totalVerses': 49, 'revelationType': 'Meccan'},
    {'arabic': 'النجم', 'transliteration': 'An-Najm', 'translation': 'The Star', 'totalVerses': 62, 'revelationType': 'Meccan'},
    {'arabic': 'القمر', 'transliteration': 'Al-Qamar', 'translation': 'The Moon', 'totalVerses': 55, 'revelationType': 'Meccan'},
    {'arabic': 'الرحمن', 'transliteration': 'Ar-Rahman', 'translation': 'The Beneficent', 'totalVerses': 78, 'revelationType': 'Medinan'},
    {'arabic': 'الواقعة', 'transliteration': 'Al-Waqi\'ah', 'translation': 'The Inevitable', 'totalVerses': 96, 'revelationType': 'Meccan'},
    {'arabic': 'الحديد', 'transliteration': 'Al-Hadid', 'translation': 'The Iron', 'totalVerses': 29, 'revelationType': 'Medinan'},
    {'arabic': 'المجادلة', 'transliteration': 'Al-Mujadilah', 'translation': 'The Pleading Woman', 'totalVerses': 22, 'revelationType': 'Medinan'},
    {'arabic': 'الحشر', 'transliteration': 'Al-Hashr', 'translation': 'The Exile', 'totalVerses': 24, 'revelationType': 'Medinan'},
    {'arabic': 'الممتحنة', 'transliteration': 'Al-Mumtahanah', 'translation': 'She That is to be examined', 'totalVerses': 13, 'revelationType': 'Medinan'},
    {'arabic': 'الصف', 'transliteration': 'As-Saff', 'translation': 'The Ranks', 'totalVerses': 14, 'revelationType': 'Medinan'},
    {'arabic': 'الجمعة', 'transliteration': 'Al-Jumu\'ah', 'translation': 'The Congregation, Friday', 'totalVerses': 11, 'revelationType': 'Medinan'},
    {'arabic': 'المنافقون', 'transliteration': 'Al-Munafiqun', 'translation': 'The Hypocrites', 'totalVerses': 11, 'revelationType': 'Medinan'},
    {'arabic': 'التغابن', 'transliteration': 'At-Taghabun', 'translation': 'The Mutual Disillusion', 'totalVerses': 18, 'revelationType': 'Medinan'},
    {'arabic': 'الطلاق', 'transliteration': 'At-Talaq', 'translation': 'The Divorce', 'totalVerses': 12, 'revelationType': 'Medinan'},
    {'arabic': 'التحريم', 'transliteration': 'At-Tahrim', 'translation': 'The Prohibition', 'totalVerses': 12, 'revelationType': 'Medinan'},
    {'arabic': 'الملك', 'transliteration': 'Al-Mulk', 'translation': 'The Sovereignty', 'totalVerses': 30, 'revelationType': 'Meccan'},
    {'arabic': 'القلم', 'transliteration': 'Al-Qalam', 'translation': 'The Pen', 'totalVerses': 52, 'revelationType': 'Meccan'},
    {'arabic': 'الحاقة', 'transliteration': 'Al-Haqqah', 'translation': 'The Inevitable', 'totalVerses': 52, 'revelationType': 'Meccan'},
    {'arabic': 'المعارج', 'transliteration': 'Al-Ma\'arij', 'translation': 'The Ascending Stairways', 'totalVerses': 44, 'revelationType': 'Meccan'},
    {'arabic': 'نوح', 'transliteration': 'Nuh', 'translation': 'Noah', 'totalVerses': 28, 'revelationType': 'Meccan'},
    {'arabic': 'الجن', 'transliteration': 'Al-Jinn', 'translation': 'The Jinn', 'totalVerses': 28, 'revelationType': 'Meccan'},
    {'arabic': 'المزمل', 'transliteration': 'Al-Muzzammil', 'translation': 'The Enshrouded One', 'totalVerses': 20, 'revelationType': 'Meccan'},
    {'arabic': 'المدثر', 'transliteration': 'Al-Muddaththir', 'translation': 'The Cloaked One', 'totalVerses': 56, 'revelationType': 'Meccan'},
    {'arabic': 'القيامة', 'transliteration': 'Al-Qiyamah', 'translation': 'The Resurrection', 'totalVerses': 40, 'revelationType': 'Meccan'},
    {'arabic': 'الإنسان', 'transliteration': 'Al-Insan', 'translation': 'The Man', 'totalVerses': 31, 'revelationType': 'Medinan'},
    {'arabic': 'المرسلات', 'transliteration': 'Al-Mursalat', 'translation': 'The Emissaries', 'totalVerses': 50, 'revelationType': 'Meccan'},
    {'arabic': 'النبأ', 'transliteration': 'An-Naba', 'translation': 'The Tidings', 'totalVerses': 40, 'revelationType': 'Meccan'},
    {'arabic': 'النازعات', 'transliteration': 'An-Nazi\'at', 'translation': 'Those Who Drag Forth', 'totalVerses': 46, 'revelationType': 'Meccan'},
    {'arabic': 'عبس', 'transliteration': 'Abasa', 'translation': 'He Frowned', 'totalVerses': 42, 'revelationType': 'Meccan'},
    {'arabic': 'التكوير', 'transliteration': 'At-Takwir', 'translation': 'The Overthrowing', 'totalVerses': 29, 'revelationType': 'Meccan'},
    {'arabic': 'الانفطار', 'transliteration': 'Al-Infitar', 'translation': 'The Cleaving', 'totalVerses': 19, 'revelationType': 'Meccan'},
    {'arabic': 'المطففين', 'transliteration': 'Al-Mutaffifin', 'translation': 'The Defrauders', 'totalVerses': 36, 'revelationType': 'Meccan'},
    {'arabic': 'الانشقاق', 'transliteration': 'Al-Inshiqaq', 'translation': 'The Sundering', 'totalVerses': 25, 'revelationType': 'Meccan'},
    {'arabic': 'البروج', 'transliteration': 'Al-Buruj', 'translation': 'The Mansions of the Stars', 'totalVerses': 22, 'revelationType': 'Meccan'},
    {'arabic': 'الطارق', 'transliteration': 'At-Tariq', 'translation': 'The Morning Star', 'totalVerses': 17, 'revelationType': 'Meccan'},
    {'arabic': 'الأعلى', 'transliteration': 'Al-A\'la', 'translation': 'The Most High', 'totalVerses': 19, 'revelationType': 'Meccan'},
    {'arabic': 'الغاشية', 'transliteration': 'Al-Ghashiyah', 'translation': 'The Overwhelming', 'totalVerses': 26, 'revelationType': 'Meccan'},
    {'arabic': 'الفجر', 'transliteration': 'Al-Fajr', 'translation': 'The Dawn', 'totalVerses': 30, 'revelationType': 'Meccan'},
    {'arabic': 'البلد', 'transliteration': 'Al-Balad', 'translation': 'The City', 'totalVerses': 20, 'revelationType': 'Meccan'},
    {'arabic': 'الشمس', 'transliteration': 'Ash-Shams', 'translation': 'The Sun', 'totalVerses': 15, 'revelationType': 'Meccan'},
    {'arabic': 'الليل', 'transliteration': 'Al-Layl', 'translation': 'The Night', 'totalVerses': 21, 'revelationType': 'Meccan'},
    {'arabic': 'الضحى', 'transliteration': 'Ad-Duha', 'translation': 'The Morning Hours', 'totalVerses': 11, 'revelationType': 'Meccan'},
    {'arabic': 'الشرح', 'transliteration': 'Ash-Sharh', 'translation': 'The Relief', 'totalVerses': 8, 'revelationType': 'Meccan'},
    {'arabic': 'التين', 'transliteration': 'At-Tin', 'translation': 'The Fig', 'totalVerses': 8, 'revelationType': 'Meccan'},
    {'arabic': 'العلق', 'transliteration': 'Al-Alaq', 'translation': 'The Clot', 'totalVerses': 19, 'revelationType': 'Meccan'},
    {'arabic': 'القدر', 'transliteration': 'Al-Qadr', 'translation': 'The Power', 'totalVerses': 5, 'revelationType': 'Meccan'},
    {'arabic': 'البينة', 'transliteration': 'Al-Bayyinah', 'translation': 'The Clear Proof', 'totalVerses': 8, 'revelationType': 'Medinan'},
    {'arabic': 'الزلزلة', 'transliteration': 'Az-Zalzalah', 'translation': 'The Earthquake', 'totalVerses': 8, 'revelationType': 'Medinan'},
    {'arabic': 'العاديات', 'transliteration': 'Al-Adiyat', 'translation': 'The Courser', 'totalVerses': 11, 'revelationType': 'Meccan'},
    {'arabic': 'القارعة', 'transliteration': 'Al-Qari\'ah', 'translation': 'The Calamity', 'totalVerses': 11, 'revelationType': 'Meccan'},
    {'arabic': 'التكاثر', 'transliteration': 'At-Takathur', 'translation': 'The Rivalry in Worldly Increase', 'totalVerses': 8, 'revelationType': 'Meccan'},
    {'arabic': 'العصر', 'transliteration': 'Al-Asr', 'translation': 'The Declining Day', 'totalVerses': 3, 'revelationType': 'Meccan'},
    {'arabic': 'الهمزة', 'transliteration': 'Al-Humazah', 'translation': 'The Traducer', 'totalVerses': 9, 'revelationType': 'Meccan'},
    {'arabic': 'الفيل', 'transliteration': 'Al-Fil', 'translation': 'The Elephant', 'totalVerses': 5, 'revelationType': 'Meccan'},
    {'arabic': 'قريش', 'transliteration': 'Quraysh', 'translation': 'Quraysh', 'totalVerses': 4, 'revelationType': 'Meccan'},
    {'arabic': 'الماعون', 'transliteration': 'Al-Ma\'un', 'translation': 'The Small Kindnesses', 'totalVerses': 7, 'revelationType': 'Meccan'},
    {'arabic': 'الكوثر', 'transliteration': 'Al-Kawthar', 'translation': 'The Abundance', 'totalVerses': 3, 'revelationType': 'Meccan'},
    {'arabic': 'الكافرون', 'transliteration': 'Al-Kafirun', 'translation': 'The Disbelievers', 'totalVerses': 6, 'revelationType': 'Meccan'},
    {'arabic': 'النصر', 'transliteration': 'An-Nasr', 'translation': 'The Divine Support', 'totalVerses': 3, 'revelationType': 'Medinan'},
    {'arabic': 'المسد', 'transliteration': 'Al-Lahab', 'translation': 'The Palm Fiber', 'totalVerses': 5, 'revelationType': 'Meccan'},
    {'arabic': 'الإخلاص', 'transliteration': 'Al-Ikhlas', 'translation': 'The Sincerity', 'totalVerses': 4, 'revelationType': 'Meccan'},
    {'arabic': 'الفلق', 'transliteration': 'Al-Falaq', 'translation': 'The Daybreak', 'totalVerses': 5, 'revelationType': 'Meccan'},
    {'arabic': 'الناس', 'transliteration': 'An-Nas', 'translation': 'Mankind', 'totalVerses': 6, 'revelationType': 'Meccan'},
  ];

  /// -----------------------------------------------------------------
  ///  Helper – create a new instance with some fields overridden.
  /// -----------------------------------------------------------------
  Surah copyWith({
    int? id,
    String? name,
    String? transliteration,
    String? translation,
    String? assameseName,
    String? hindiName,
    String? bengaliName,
    int? totalVerses,
    String? revelationType,
  }) {
    return Surah(
      id: id ?? this.id,
      name: name ?? this.name,
      transliteration: transliteration ?? this.transliteration,
      translation: translation ?? this.translation,
      assameseName: assameseName ?? this.assameseName,
      hindiName: hindiName ?? this.hindiName,
      bengaliName: bengaliName ?? this.bengaliName,
      totalVerses: totalVerses ?? this.totalVerses,
      revelationType: revelationType ?? this.revelationType,
    );
  }

  /// -----------------------------------------------------------------
  ///  Useful for logging / debugging.
  /// -----------------------------------------------------------------
  @override
  String toString() {
    return 'Surah(id: $id, name: $name, transliteration: $transliteration, '
        'translation: $translation, assameseName: $assameseName, '
        'hindiName: $hindiName, bengaliName: $bengaliName, totalVerses: $totalVerses, '
        'revelationType: $revelationType)';
  }

  /// -----------------------------------------------------------------
  ///  Equality – handy when you put Surah objects in a Set/List.
  /// -----------------------------------------------------------------
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Surah &&
        other.id == id &&
        other.name == name &&
        other.transliteration == transliteration &&
        other.translation == translation &&
        other.assameseName == assameseName &&
        other.hindiName == hindiName &&
        other.bengaliName == bengaliName &&
        other.totalVerses == totalVerses &&
        other.revelationType == revelationType;
  }

  @override
  int get hashCode =>
      id.hashCode ^
      name.hashCode ^
      transliteration.hashCode ^
      translation.hashCode ^
      assameseName.hashCode ^
      hindiName.hashCode ^
      bengaliName.hashCode ^
      totalVerses.hashCode ^
      revelationType.hashCode;
}