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

  // FIX: Separate settings for Quran and Tafseer
  // Surah display settings by language (for Quran)
  Map<String, SurahDisplaySettings> _surahDisplaySettings = {};

  // Tafseer display settings by language (for Tafseer)
  Map<String, SurahDisplaySettings> _tafseerDisplaySettings = {};

  // Bookmarked verses
  List<Map<String, dynamic>> _bookmarkedVerses = [];

  // Getters
  ThemeMode get themeMode => _themeMode;
  double get fontScale => _fontScale;
  CalculationMethod get calculationMethod => _calculationMethod;
  bool get showArabic => _showArabic;
  Color get backgroundColor => _backgroundColor;
  Map<String, SurahDisplaySettings> get surahDisplaySettings => _surahDisplaySettings;
  String get selectedLanguage => _selectedLanguage;

  Future<void> loadSettings() async {
    _prefs = await SharedPreferences.getInstance();

    // Load persisted global language
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
    await _loadTafseerDisplaySettings(); // FIX: Load Tafseer settings separately
    await _loadBookmarkedVerses();

    notifyListeners();
  }

  Future<void> setSelectedLanguage(String lang) async {
    if (_selectedLanguage != lang) {
      _selectedLanguage = lang;
      await _prefs.setString('selected_language_key', lang);
      notifyListeners();
    }
  }

  // FIX: Smart getter that returns the correct settings based on mode
  SurahDisplaySettings getSurahDisplaySettings(String language, bool isTafseer) {
    if (isTafseer) {
      return _tafseerDisplaySettings[language] ?? SurahDisplaySettings.defaultForTafseer(language);
    } else {
      return _surahDisplaySettings[language] ?? SurahDisplaySettings.defaultFor(language);
    }
  }

  // FIX: Dedicated getter for Tafseer settings
  SurahDisplaySettings getTafseerDisplaySettings(String language) {
    return _tafseerDisplaySettings[language] ?? SurahDisplaySettings.defaultForTafseer(language);
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

  // FIX: Separate loader for Tafseer settings
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

  Future<void> _saveSettings() async {
    // Save Quran settings
    for (final entry in _surahDisplaySettings.entries) {
      await _prefs.setString(
        'surah_display_settings_${entry.key}',
        json.encode(entry.value.toJson()),
      );
    }
    // FIX: Save Tafseer settings with a different key
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

  // FIX: Dedicated updater for Tafseer settings
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

// --- THIS IS THE CLASS THAT WAS MISSING ---
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

  // FIX: New factory for Tafseer defaults
  factory SurahDisplaySettings.defaultForTafseer(String language) {
    // For Tafseer, default to showing translation but not Arabic or transliteration
    return SurahDisplaySettings(
      showArabic: false,
      showTranslation: true,
      showTransliteration: false,
      showTafseer: true, // Always show Tafseer in Tafseer mode
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