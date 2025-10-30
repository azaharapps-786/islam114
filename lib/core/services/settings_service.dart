// lib/core/services/settings_service.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_constants.dart';
import '../enums/calculation_method.dart';

class SettingsService extends ChangeNotifier {
  late SharedPreferences _prefs;
  ThemeMode _themeMode = ThemeMode.system;
  double _fontScale = 1.0;
  CalculationMethod _calculationMethod = CalculationMethod.ummAlQura;

  ThemeMode get themeMode => _themeMode;
  double get fontScale => _fontScale;
  CalculationMethod get calculationMethod => _calculationMethod;

  Future<void> loadSettings() async {
    _prefs = await SharedPreferences.getInstance();
    final themeIndex = _prefs.getInt(AppConstants.themeKey) ?? 0;
    _themeMode = ThemeMode.values[themeIndex];
    _fontScale = _prefs.getDouble(AppConstants.fontScaleKey) ?? 1.0;

    // Load calculation method
    final calculationMethodString = _prefs.getString(AppConstants.calculationMethodKey) ?? 'ummAlQura';
    _calculationMethod = CalculationMethod.values.firstWhere(
          (method) => method.toString() == calculationMethodString,
      orElse: () => CalculationMethod.ummAlQura,
    );

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
}