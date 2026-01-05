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

  // Surah display settings by language
  Map<String, SurahDisplaySettings> _surahDisplaySettings = {};

  // Bookmarked verses
  List<Map<String, dynamic>> _bookmarkedVerses = [];

  ThemeMode get themeMode => _themeMode;
  double get fontScale => _fontScale;
  CalculationMethod get calculationMethod => _calculationMethod;
  bool get showArabic => _showArabic;
  Color get backgroundColor => _backgroundColor;
  Map<String, SurahDisplaySettings> get surahDisplaySettings => _surahDisplaySettings;

  Future<void> loadSettings() async {
    _prefs = await SharedPreferences.getInstance();
    final themeIndex = _prefs.getInt(AppConstants.themeKey) ?? 1;
    _themeMode = ThemeMode.light;
    _fontScale = _prefs.getDouble(AppConstants.fontScaleKey) ?? 1.0;

    // Load calculation method
    final calculationMethodString = _prefs.getString(AppConstants.calculationMethodKey) ?? 'ummAlQura';
    _calculationMethod = CalculationMethod.values.firstWhere(
          (method) => method.toString() == calculationMethodString,
      orElse: () => CalculationMethod.ummAlQura,
    );

    // Load show Arabic
    _showArabic = _prefs.getBool('show_arabic_key') ?? true;

    // Load background color
    final bgColorStr = _prefs.getString('background_color_key');
    _backgroundColor = bgColorStr != null ? Color(int.parse(bgColorStr)) : const Color(0xFFE8F5E8);

    // Initialize display settings
    _initializeDisplaySettings();

    // Load display settings
    await _loadDisplaySettings();

    // Load bookmarked verses
    await _loadBookmarkedVerses();

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

  // Initialize display settings
  void _initializeDisplaySettings() {
    final languages = ['english', 'assamese', 'hindi', 'bengali', 'arabic'];
    for (final language in languages) {
      _surahDisplaySettings[language] = SurahDisplaySettings.defaultFor(language);
    }
  }

  // Load display settings from preferences
  Future<void> _loadDisplaySettings() async {
    final languages = ['english', 'assamese', 'hindi', 'bengali', 'arabic'];

    for (final language in languages) {
      final settingsJson = _prefs.getString('surah_display_settings_$language');
      if (settingsJson != null) {
        try {
          final Map<String, dynamic> settingsMap = json.decode(settingsJson);
          _surahDisplaySettings[language] = SurahDisplaySettings.fromJson(settingsMap);
        } catch (e) {
          // If loading fails, keep the default settings that were just initialized
          print('Error loading display settings for $language: $e');
        }
      }
    }
  }

  // Load bookmarked verses from preferences
  Future<void> _loadBookmarkedVerses() async {
    final bookmarksJson = _prefs.getString('bookmarked_verses');
    if (bookmarksJson != null) {
      try {
        final List<dynamic> bookmarksList = json.decode(bookmarksJson);
        _bookmarkedVerses = bookmarksList.map((item) => Map<String, dynamic>.from(item)).toList();
      } catch (e) {
        print('Error loading bookmarked verses: $e');
        _bookmarkedVerses = [];
      }
    }
  }

  // Centralized saving logic
  Future<void> _saveSettings() async {
    // Save display settings
    for (final entry in _surahDisplaySettings.entries) {
      await _prefs.setString(
        'surah_display_settings_${entry.key}',
        json.encode(entry.value.toJson()),
      );
    }

    // Save bookmarked verses
    await _prefs.setString(
      'bookmarked_verses',
      json.encode(_bookmarkedVerses),
    );
  }

  // Update display settings for a language
  void updateSurahDisplaySettings(String language, SurahDisplaySettings settings) {
    _surahDisplaySettings[language] = settings;
    _saveSettings();
    notifyListeners();
  }

  // FIXED: Bookmark management - Check state BEFORE mutating to ensure symmetric toggle
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
      // Remove existing bookmark
      _bookmarkedVerses.removeWhere((verse) => verse['key'] == bookmarkKey);
    } else {
      // Add new bookmark
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

// SurahDisplaySettings class - now only defined here
class SurahDisplaySettings {
  final bool showArabic;
  final bool showTranslation;
  final bool showTransliteration;
  final bool showTafseer;
  final Map<String, bool> additionalTranslations;
  final Map<String, bool> additionalTransliterations; // FIXED: Separate map for transliterations
  final Map<String, bool> additionalTafseers;

  const SurahDisplaySettings({
    required this.showArabic,
    required this.showTranslation,
    required this.showTransliteration,
    required this.showTafseer,
    required this.additionalTranslations,
    required this.additionalTransliterations, // FIXED: Separate map for transliterations
    required this.additionalTafseers,
  });

  factory SurahDisplaySettings.defaultFor(String language) {
    final isArabic = language == 'arabic';
    final isEnglish = language == 'english';

    // Create a map of default advanced translations/tafseers
    final Map<String, bool> defaultAdvancedTranslations = {};
    final Map<String, bool> defaultAdvancedTransliterations = {}; // FIXED: Separate map for transliterations
    final Map<String, bool> defaultAdvancedTafseers = {};

    // Set defaults ONLY for English language
    if (isEnglish) {
      // For English, enable Assamese and Hindi by default
      defaultAdvancedTranslations['assamese'] = true;
      defaultAdvancedTranslations['hindi'] = true;
      // All other languages will remain false by default
    }

    return SurahDisplaySettings(
      showArabic: isArabic, // FIXED: Only show Arabic by default for Arabic language
      showTranslation: !isArabic, // No primary translation for Arabic Quran
      showTransliteration: !isArabic, // No primary transliteration for Arabic Quran
      showTafseer: false,
      // Use the new maps for the advanced options
      additionalTranslations: defaultAdvancedTranslations,
      additionalTransliterations: defaultAdvancedTransliterations, // FIXED: Separate map for transliterations
      additionalTafseers: defaultAdvancedTafseers,
    );
  }

  SurahDisplaySettings copyWith({
    bool? showArabic,
    bool? showTranslation,
    bool? showTransliteration,
    bool? showTafseer,
    Map<String, bool>? additionalTranslations,
    Map<String, bool>? additionalTransliterations, // FIXED: Separate map for transliterations
    Map<String, bool>? additionalTafseers,
  }) {
    return SurahDisplaySettings(
      showArabic: showArabic ?? this.showArabic,
      showTranslation: showTranslation ?? this.showTranslation,
      showTransliteration: showTransliteration ?? this.showTransliteration,
      showTafseer: showTafseer ?? this.showTafseer,
      additionalTranslations: additionalTranslations ?? this.additionalTranslations,
      additionalTransliterations: additionalTransliterations ?? this.additionalTransliterations, // FIXED: Separate map for transliterations
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
      'additionalTransliterations': additionalTransliterations, // FIXED: Separate map for transliterations
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
      additionalTransliterations: Map<String, bool>.from(json['additionalTransliterations'] ?? {}), // FIXED: Separate map for transliterations
      additionalTafseers: Map<String, bool>.from(json['additionalTafseers'] ?? {}),
    );
  }

  // Check if at least one display option is enabled
  bool get hasVisibleContent {
    return showArabic || showTranslation || showTransliteration || showTafseer ||
        additionalTranslations.values.any((enabled) => enabled) ||
        additionalTransliterations.values.any((enabled) => enabled) || // FIXED: Check transliterations too
        additionalTafseers.values.any((enabled) => enabled);
  }
}