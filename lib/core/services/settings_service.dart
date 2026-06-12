import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

import '../constants/app_constants.dart';
import '../enums/calculation_method.dart';

class SettingsService with ChangeNotifier {
  late SharedPreferences _prefs;
  ThemeMode _themeMode = ThemeMode.light;
  double _fontScale = 1.0;
  CalculationMethod _calculationMethod = CalculationMethod.ummAlQura;
  bool _showArabic = true;
  Color _backgroundColor = const Color(0xFFE8F5E8);

  // Global Language Selection
  String _selectedLanguage = 'english';

  // Separate settings for Quran and Tafseer
  Map<String, SurahDisplaySettings> _surahDisplaySettings = {};
  Map<String, SurahDisplaySettings> _tafseerDisplaySettings = {};

  // Bookmarked verses
  List<Map<String, dynamic>> _bookmarkedVerses = [];

  // ===== NEW: Last Read Marks =====
  Map<String, Map<String, dynamic>> _lastReadMarks = {};

  // Getters
  ThemeMode get themeMode => _themeMode;
  double get fontScale => _fontScale;
  CalculationMethod get calculationMethod => _calculationMethod;
  bool get showArabic => _showArabic;
  Color get backgroundColor => _backgroundColor;
  Map<String, SurahDisplaySettings> get surahDisplaySettings => _surahDisplaySettings;
  String get selectedLanguage => _selectedLanguage;
  Map<String, Map<String, dynamic>> get lastReadMarks => _lastReadMarks;

  Future<void> loadSettings() async {
    _prefs = await SharedPreferences.getInstance();

    _selectedLanguage = _prefs.getString('selected_language_key') ?? 'english';
    _themeMode = ThemeMode.light;
    _fontScale = _prefs.getDouble(AppConstants.fontScaleKey) ?? 1.0;

    final calculationMethodString = _prefs.getString(AppConstants.calculationMethodKey) ?? 'ummAlQura';
    _calculationMethod = CalculationMethod.values.firstWhere(
          (method) => method.toString() == calculationMethodString,
      orElse: () => CalculationMethod.ummAlQura,
    );

    _showArabic = _prefs.getBool('show_arabic_key') ?? true;

    final bgColorStr = _prefs.getString('background_color_key');
    _backgroundColor = bgColorStr != null ? Color(int.parse(bgColorStr)) : const Color(0xFFE8F5E8);

    _initializeDisplaySettings();
    await _loadDisplaySettings();
    await _loadTafseerDisplaySettings();
    await _loadBookmarkedVerses();
    await _loadLastReadMarks();

    notifyListeners();
  }

  Future<void> setSelectedLanguage(String lang) async {
    if (_selectedLanguage != lang) {
      _selectedLanguage = lang;
      await _prefs.setString('selected_language_key', lang);
      notifyListeners();
    }
  }

  SurahDisplaySettings getSurahDisplaySettings(String language, bool isTafseer) {
    if (isTafseer) {
      return _tafseerDisplaySettings[language] ?? SurahDisplaySettings.defaultForTafseer(language);
    } else {
      return _surahDisplaySettings[language] ?? SurahDisplaySettings.defaultFor(language);
    }
  }

  SurahDisplaySettings getTafseerDisplaySettings(String language) {
    return _tafseerDisplaySettings[language] ?? SurahDisplaySettings.defaultForTafseer(language);
  }

  // ── FIX #1 & #2: Force Consumer<SettingsService> rebuild on navigation ──
  /// Forces a rebuild of widgets listening to SettingsService.
  /// Used by SurahDetailPage when navigating with a new language/tafseer mode,
  /// to ensure VerseCard's Consumer<SettingsService> picks up the correct
  /// display settings (showTafseer, showTranslation, additionalTranslations, etc.)
  /// on the very first frame instead of only after some other settings change.
  void refreshDisplaySettings() {
    notifyListeners();
  }

  Future<void> updateThemeMode(ThemeMode newThemeMode) async {
    _themeMode = newThemeMode;
    await _prefs.setInt(AppConstants.themeKey, newThemeMode.index);
    notifyListeners();
  }

  Future<void> updateFontScale(double newScale) async {
    _fontScale = newScale;
    await _prefs.setDouble(AppConstants.fontScaleKey, newScale);
    notifyListeners();
  }

  CalculationMethod getCalculationMethod() {
    return _calculationMethod;
  }

  Future<void> setCalculationMethod(CalculationMethod method) async {
    _calculationMethod = method;
    notifyListeners();
    await _prefs.setString(AppConstants.calculationMethodKey, method.toString());
  }

  Future<void> setShowArabic(bool value) async {
    _showArabic = value;
    await _prefs.setBool('show_arabic_key', value);
    notifyListeners();
  }

  Future<void> setBackgroundColor(Color value) async {
    _backgroundColor = value;
    await _prefs.setString('background_color_key', value.value.toString());
    notifyListeners();
  }

  void _initializeDisplaySettings() {
    final languages = ['english', 'assamese', 'hindi', 'bengali', 'arabic'];
    for (final language in languages) {
      _surahDisplaySettings[language] = SurahDisplaySettings.defaultFor(language);
      _tafseerDisplaySettings[language] = SurahDisplaySettings.defaultForTafseer(language);
    }
  }

  Future<void> _loadDisplaySettings() async {
    final languages = ['english', 'assamese', 'hindi', 'bengali', 'arabic'];
    for (final language in languages) {
      final settingsJson = _prefs.getString('surah_display_settings_$language');
      if (settingsJson != null) {
        try {
          final Map<String, dynamic> settingsMap = json.decode(settingsJson);
          _surahDisplaySettings[language] = SurahDisplaySettings.fromJson(settingsMap);
        } catch (e) {
          debugPrint('Error loading display settings for $language: $e');
        }
      }
    }
  }

  Future<void> _loadTafseerDisplaySettings() async {
    final languages = ['english', 'assamese', 'hindi', 'bengali', 'arabic'];
    for (final language in languages) {
      final settingsJson = _prefs.getString('tafseer_display_settings_$language');
      if (settingsJson != null) {
        try {
          final Map<String, dynamic> settingsMap = json.decode(settingsJson);
          _tafseerDisplaySettings[language] = SurahDisplaySettings.fromJson(settingsMap);
        } catch (e) {
          debugPrint('Error loading Tafseer display settings for $language: $e');
        }
      }
    }
  }

  Future<void> _loadBookmarkedVerses() async {
    final bookmarksJson = _prefs.getString('bookmarked_verses');
    if (bookmarksJson != null) {
      try {
        final List<dynamic> bookmarksList = json.decode(bookmarksJson);
        _bookmarkedVerses = bookmarksList.map((item) => Map<String, dynamic>.from(item)).toList();
      } catch (e) {
        debugPrint('Error loading bookmarked verses: $e');
        _bookmarkedVerses = [];
      }
    }
  }

  // ===== NEW: Last Read Marks Methods =====

  Future<void> _loadLastReadMarks() async {
    final marksJson = _prefs.getString('last_read_marks');
    if (marksJson != null) {
      try {
        final Map<String, dynamic> marksMap = json.decode(marksJson);
        _lastReadMarks = marksMap.map(
              (key, value) => MapEntry(key, Map<String, dynamic>.from(value)),
        );
      } catch (e) {
        debugPrint('Error loading last read marks: $e');
        _lastReadMarks = {};
      }
    }
  }

  Future<void> _saveLastReadMarks() async {
    await _prefs.setString('last_read_marks', json.encode(_lastReadMarks));
  }

  /// Mark a Quran verse as last read for a specific surah
  /// Automatically unmarks any previous verse in the same surah
  Future<void> markQuranLastRead({
    required int surahNumber,
    required int verseNumber,
    required String surahName,
    String language = 'english',
    bool isTafseer = false,
  }) async {
    final modeSuffix = isTafseer ? '_tafseer' : '';
    final key = 'quran${modeSuffix}_$surahNumber';

    _lastReadMarks[key] = {
      'itemNumber': verseNumber,
      'itemName': surahName,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
      'type': isTafseer ? 'quran_tafseer' : 'quran',
      'surahNumber': surahNumber,
      'language': language,
      'isTafseer': isTafseer,
    };

    await _saveLastReadMarks();
    notifyListeners();
  }

  /// Mark a Hadith as last read for a specific chapter
  /// Automatically unmarks any previous hadith in the same chapter
  Future<void> markHadithLastRead({
    required String bookKey,
    required int chapterId,
    required int hadithNumber,
    required String chapterName,
  }) async {
    final key = '${bookKey}_$chapterId';

    _lastReadMarks[key] = {
      'itemNumber': hadithNumber,
      'itemName': chapterName,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
      'type': 'hadith',
      'bookKey': bookKey,
      'chapterId': chapterId,
    };

    await _saveLastReadMarks();
    notifyListeners();
  }

  /// Get last read mark for a specific Quran surah
  Map<String, dynamic>? getLastReadQuran(int surahNumber, {bool isTafseer = false}) {
    final modeSuffix = isTafseer ? '_tafseer' : '';
    return _lastReadMarks['quran${modeSuffix}_$surahNumber'];
  }

  /// Get last read mark for a specific Hadith chapter
  Map<String, dynamic>? getLastReadHadith(String bookKey, int chapterId) {
    return _lastReadMarks['${bookKey}_$chapterId'];
  }

  /// Get any last read mark (for surah/chapter list pages)
  /// Returns the most recent one
  Map<String, dynamic>? getMostRecentLastReadMark() {
    if (_lastReadMarks.isEmpty) return null;

    final sorted = _lastReadMarks.entries.toList()
      ..sort((a, b) =>
          (b.value['timestamp'] as int).compareTo(a.value['timestamp'] as int));

    return {
      'key': sorted.first.key,
      ...sorted.first.value,
    };
  }

  /// Find which surah number has a last read mark (for scrolling in list)
  int? getSurahNumberWithLastRead({bool isTafseer = false}) {
    final modeSuffix = isTafseer ? '_tafseer' : '';
    final prefix = 'quran${modeSuffix}_';

    for (final entry in _lastReadMarks.entries) {
      if (entry.key.startsWith(prefix)) {
        return entry.value['surahNumber'] as int?;
      }
    }
    return null;
  }

  /// Find which chapter ID has a last read mark (for scrolling in list)
  int? getChapterIdWithLastRead(String bookKey) {
    final prefix = '${bookKey}_';

    for (final entry in _lastReadMarks.entries) {
      if (entry.key.startsWith(prefix)) {
        return entry.value['chapterId'] as int?;
      }
    }
    return null;
  }

  /// Clear last read mark for a specific Quran surah
  Future<void> clearLastReadQuran(int surahNumber, {bool isTafseer = false}) async {
    final modeSuffix = isTafseer ? '_tafseer' : '';
    _lastReadMarks.remove('quran${modeSuffix}_$surahNumber');
    await _saveLastReadMarks();
    notifyListeners();
  }

  /// Clear last read mark for a specific Hadith chapter
  Future<void> clearLastReadHadith(String bookKey, int chapterId) async {
    _lastReadMarks.remove('${bookKey}_$chapterId');
    await _saveLastReadMarks();
    notifyListeners();
  }

  /// Check if a specific verse is marked as last read
  bool isQuranVerseLastRead(int surahNumber, int verseNumber, {bool isTafseer = false}) {
    final mark = getLastReadQuran(surahNumber, isTafseer: isTafseer);
    if (mark == null) return false;
    return mark['itemNumber'] == verseNumber;
  }

  /// Check if a specific hadith is marked as last read
  bool isHadithLastRead(String bookKey, int chapterId, int hadithNumber) {
    final mark = getLastReadHadith(bookKey, chapterId);
    if (mark == null) return false;
    return mark['itemNumber'] == hadithNumber;
  }

  // ===== END: Last Read Marks Methods =====

  Future<void> _saveSettings() async {
    for (final entry in _surahDisplaySettings.entries) {
      await _prefs.setString(
        'surah_display_settings_${entry.key}',
        json.encode(entry.value.toJson()),
      );
    }
    for (final entry in _tafseerDisplaySettings.entries) {
      await _prefs.setString(
        'tafseer_display_settings_${entry.key}',
        json.encode(entry.value.toJson()),
      );
    }
    await _prefs.setString('bookmarked_verses', json.encode(_bookmarkedVerses));
  }

  void updateSurahDisplaySettings(String language, SurahDisplaySettings settings) {
    _surahDisplaySettings[language] = settings;
    _saveSettings();
    notifyListeners();
  }

  void updateTafseerDisplaySettings(String language, SurahDisplaySettings settings) {
    _tafseerDisplaySettings[language] = settings;
    _saveSettings();
    notifyListeners();
  }

  void toggleBookmark({
    required int surahNumber,
    required int verseNumber,
    required Map<String, dynamic> verseData,
    required String language,
    required bool isTafseer,
  }) {
    final bookmarkKey = '$surahNumber:$verseNumber:$language:${isTafseer ? 'tafseer' : 'quran'}';
    final wasBookmarked = isBookmarked(surahNumber, verseNumber, language, isTafseer);

    if (wasBookmarked) {
      _bookmarkedVerses.removeWhere((verse) => verse['key'] == bookmarkKey);
    } else {
      _bookmarkedVerses.add({
        'key': bookmarkKey,
        'surahNumber': surahNumber,
        'verseNumber': verseNumber,
        'verseData': verseData,
        'language': language,
        'isTafseer': isTafseer,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      });
    }
    _saveSettings();
    notifyListeners();
  }

  bool isBookmarked(int surahNumber, int verseNumber, String language, bool isTafseer) {
    final bookmarkKey = '$surahNumber:$verseNumber:$language:${isTafseer ? 'tafseer' : 'quran'}';
    return _bookmarkedVerses.any((verse) => verse['key'] == bookmarkKey);
  }

  List<Map<String, dynamic>> getBookmarkedVerses() {
    return List.from(_bookmarkedVerses);
  }
}

class SurahDisplaySettings {
  final bool showArabic;
  final bool showTranslation;
  final bool showTransliteration;
  final bool showTafseer;
  final Map<String, bool> additionalTranslations;
  final Map<String, bool> additionalTransliterations;
  final Map<String, bool> additionalTafseers;

  const SurahDisplaySettings({
    required this.showArabic,
    required this.showTranslation,
    required this.showTransliteration,
    required this.showTafseer,
    required this.additionalTranslations,
    required this.additionalTransliterations,
    required this.additionalTafseers,
  });

  factory SurahDisplaySettings.defaultFor(String language) {
    final isArabic = language == 'arabic';
    final isEnglish = language == 'english';

    final Map<String, bool> defaultAdvancedTranslations = {};
    if (isEnglish) {
      defaultAdvancedTranslations['assamese'] = true;
      defaultAdvancedTranslations['hindi'] = true;
    }

    return SurahDisplaySettings(
      showArabic: isArabic,
      showTranslation: !isArabic,
      showTransliteration: !isArabic,
      showTafseer: false,
      additionalTranslations: defaultAdvancedTranslations,
      additionalTransliterations: {},
      additionalTafseers: {},
    );
  }

  factory SurahDisplaySettings.defaultForTafseer(String language) {
    return SurahDisplaySettings(
      showArabic: false,
      showTranslation: true,
      showTransliteration: false,
      showTafseer: true,
      additionalTranslations: {},
      additionalTransliterations: {},
      additionalTafseers: {},
    );
  }

  SurahDisplaySettings copyWith({
    bool? showArabic,
    bool? showTranslation,
    bool? showTransliteration,
    bool? showTafseer,
    Map<String, bool>? additionalTranslations,
    Map<String, bool>? additionalTransliterations,
    Map<String, bool>? additionalTafseers,
  }) {
    return SurahDisplaySettings(
      showArabic: showArabic ?? this.showArabic,
      showTranslation: showTranslation ?? this.showTranslation,
      showTransliteration: showTransliteration ?? this.showTransliteration,
      showTafseer: showTafseer ?? this.showTafseer,
      additionalTranslations: additionalTranslations ?? this.additionalTranslations,
      additionalTransliterations: additionalTransliterations ?? this.additionalTransliterations,
      additionalTafseers: additionalTafseers ?? this.additionalTafseers,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'showArabic': showArabic,
      'showTranslation': showTranslation,
      'showTransliteration': showTransliteration,
      'showTafseer': showTafseer,
      'additionalTranslations': additionalTranslations,
      'additionalTransliterations': additionalTransliterations,
      'additionalTafseers': additionalTafseers,
    };
  }

  factory SurahDisplaySettings.fromJson(Map<String, dynamic> json) {
    return SurahDisplaySettings(
      showArabic: json['showArabic'] ?? true,
      showTranslation: json['showTranslation'] ?? true,
      showTransliteration: json['showTransliteration'] ?? true,
      showTafseer: json['showTafseer'] ?? false,
      additionalTranslations: Map<String, bool>.from(json['additionalTranslations'] ?? {}),
      additionalTransliterations: Map<String, bool>.from(json['additionalTransliterations'] ?? {}),
      additionalTafseers: Map<String, bool>.from(json['additionalTafseers'] ?? {}),
    );
  }

  bool get hasVisibleContent {
    return showArabic || showTranslation || showTransliteration || showTafseer ||
        additionalTranslations.values.any((enabled) => enabled) ||
        additionalTransliterations.values.any((enabled) => enabled) ||
        additionalTafseers.values.any((enabled) => enabled);
  }
}