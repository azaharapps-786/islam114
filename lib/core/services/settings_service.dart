// lib/core/services/settings_service.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_constants.dart';
import '../enums/calculation_method.dart';

class SettingsService extends ChangeNotifier {
  late SharedPreferences _prefs;
  ThemeMode _themeMode = ThemeMode.light;
  double _fontScale = 1.0;
  CalculationMethod _calculationMethod = CalculationMethod.ummAlQura;
  bool _showArabic = true;
  Color _backgroundColor = const Color(0xFFE8F5E8);

  ThemeMode get themeMode => _themeMode;
  double get fontScale => _fontScale;
  CalculationMethod get calculationMethod => _calculationMethod;
  bool get showArabic => _showArabic;
  Color get backgroundColor => _backgroundColor;

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
}