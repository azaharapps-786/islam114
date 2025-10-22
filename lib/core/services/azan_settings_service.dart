import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AzanSettingsService with ChangeNotifier {
  bool _azanEnabled = false;
  final Map<String, bool> _prayerAzanEnabled = {
    'Fajr': true,
    'Sunrise': false,
    'Dhuhr': true,
    'Asr': true,
    'Maghrib': true,
    'Isha': true,
    'Tahajjud': false,
  };

  bool get azanEnabled => _azanEnabled;
  Map<String, bool> get prayerAzanEnabled => Map.unmodifiable(_prayerAzanEnabled);

  AzanSettingsService() {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      _azanEnabled = prefs.getBool('azan_enabled') ?? false;

      for (final prayer in _prayerAzanEnabled.keys) {
        final key = 'azan_${prayer.toLowerCase()}';
        _prayerAzanEnabled[prayer] = prefs.getBool(key) ?? _getDefaultSetting(prayer);
      }

      notifyListeners();
    } catch (e) {
      debugPrint('Error loading Azan settings: $e');
    }
  }

  bool _getDefaultSetting(String prayer) {
    // Enable Azan for all prayers except Sunrise and Tahajjud by default
    return prayer != 'Sunrise' && prayer != 'Tahajjud';
  }

  Future<void> setAzanEnabled(bool enabled) async {
    _azanEnabled = enabled;
    await _saveSetting('azan_enabled', enabled);
    notifyListeners();
  }

  Future<void> setPrayerAzanEnabled(String prayer, bool enabled) async {
    _prayerAzanEnabled[prayer] = enabled;
    await _saveSetting('azan_${prayer.toLowerCase()}', enabled);
    notifyListeners();
  }

  Future<void> _saveSetting(String key, bool value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(key, value);
    } catch (e) {
      debugPrint('Error saving Azan setting: $e');
    }
  }

  bool isAzanEnabledForPrayer(String prayer) {
    // Fixed: Check if the prayer exists in the map first
    if (_prayerAzanEnabled.containsKey(prayer)) {
      return _azanEnabled && (_prayerAzanEnabled[prayer] ?? false);
    }
    return false;
  }
}