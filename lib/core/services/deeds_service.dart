// lib/core/services/deeds_service.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:audioplayers/audioplayers.dart';
import '../utils/spiritual_keywords.dart';

class DeedsService extends ChangeNotifier {
  Map<String, DailyDeeds> _deedsData = {};
  final AudioPlayer _audioPlayer = AudioPlayer();

  DeedsService() {
    _loadData();
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    final dataJson = prefs.getString('deeds_data');
    if (dataJson != null) {
      final Map<String, dynamic> decoded = json.decode(dataJson);
      _deedsData = decoded.map((key, value) => MapEntry(key, DailyDeeds.fromJson(value)));
    }
    notifyListeners();
  }

  Future<void> _saveData() async {
    final prefs = await SharedPreferences.getInstance();
    final dataJson = json.encode(_deedsData.map((key, value) => MapEntry(key, value.toJson())));
    await prefs.setString('deeds_data', dataJson);
  }

  String _dateToKey(DateTime date) => '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  DailyDeeds getDeedsForDate(DateTime date) {
    final key = _dateToKey(date);
    return _deedsData.putIfAbsent(key, () => DailyDeeds());
  }

  void updateDeedsForDate(DateTime date, DailyDeeds deeds) {
    final key = _dateToKey(date);
    _deedsData[key] = deeds;
    _saveData();
    notifyListeners();
    _evaluateAndAlert(deeds);
  }

  // --- CORRECTED: Recalculate points from scratch every time ---
  int getTotalGoodDeeds() {
    int total = 0;
    for (var dailyDeeds in _deedsData.values) {
      total += dailyDeeds.calculateGoodPoints();
    }
    return total;
  }

  // --- CORRECTED: Recalculate points from scratch every time ---
  int getTotalBadDeeds() {
    int total = 0;
    for (var dailyDeeds in _deedsData.values) {
      total += dailyDeeds.calculateBadPoints();
    }
    return total;
  }

  void _evaluateAndAlert(DailyDeeds deeds) async {
    final diff = deeds.calculateGoodPoints() - deeds.calculateBadPoints();
    if (diff < -50) {
      await _audioPlayer.play(AssetSource('sounds/warning.mp3'));
    } else if (diff > 50) {
      await _audioPlayer.play(AssetSource('sounds/success.mp3'));
    }
  }

  String getUserStatus() {
    final diff = getTotalGoodDeeds() - getTotalBadDeeds();
    if (diff < -500) return 'Critical Danger – Immediate Repentance Needed';
    if (diff < 0) return 'In Danger – Balance Falling';
    if (diff < 300) return 'Good – Keep Growing';
    if (diff < 1000) return 'Very Good – On the Right Path';
    return 'Excellent – Jannah is Near, InshaAllah';
  }

  IconData getStatusIcon() {
    final status = getUserStatus();
    if (status.contains('Danger')) return Icons.warning_amber;
    if (status.contains('Good')) return Icons.thumb_up;
    if (status.contains('Very Good')) return Icons.star;
    return Icons.emoji_events;
  }

  Color getStatusColor() {
    final status = getUserStatus();
    if (status.contains('Danger')) return Colors.red;
    if (status.contains('Good')) return Colors.green;
    return Colors.amber;
  }

  String analyzeDeeds() {
    int missedFard = 0;
    int majorSins = 0;
    int minorSins = 0;
    int tahajjudDays = 0;
    int sadaqahActs = 0;
    for (var day in _deedsData.values) {
      missedFard += day.prayers.values.where((p) => !p).length;
      tahajjudDays += day.tahajjud ? 1 : 0;
      for (var sin in day.badDeeds) {
        if (sin.contains('Major') || sin.contains('Kabira')) majorSins++;
        if (sin.contains('Minor') || sin.contains('Sagira')) minorSins++;
      }
      sadaqahActs += day.goodDeeds.where((deed) => deed.toLowerCase().contains('sadaqah') || deed.toLowerCase().contains('charity')).length;
    }

    return '''
🌟 Key Insights from Your Amal Namah:

• Missed Fard Prayers: $missedFard
  ${missedFard > 0 ? '⚠️ Warning: This blocks acceptance of nafl deeds. Make Qada immediately!' : '✅ Mashallah - Consistent in Fard'}

• Tahajjud Performed: $tahajjudDays days
  ${tahajjudDays > 30 ? '🌟 Elite habit! The doors of Jannah open for you.' : tahajjudDays > 0 ? 'Good start - Aim for daily' : 'Consider starting - Highest reward after Fard'}

• Sadaqah Acts: $sadaqahActs
  ${sadaqahActs > 10 ? '💎 Excellent! Wealth in Jannah multiplying.' : 'Start small - Every dirham counts'}

• Major Sins: $majorSins
  ${majorSins > 0 ? '🚨 Critical: Seek sincere Tawbah. Allah is Forgiving.' : 'Alhamdulillah - Protected from Kabair'}

• Minor Sins: $minorSins
  ${minorSins > 20 ? '📈 Accumulating - Small holes sink the ship. Daily Istighfar!' : 'Good control - Stay vigilant'}

Remember: "The scale will be set up, and hearts will be in throats." (Hadith)
''';
  }

  String projectYearly(int currentDiff) {
    final daysRecorded = _deedsData.length;
    if (daysRecorded == 0) return 'Begin your journey today!';
    final avgDaily = currentDiff / daysRecorded;
    final yearly = (avgDaily * 365).round();
    return '''
🔮 One-Year Projection (Based on Current Pattern):

Net Balance Projection: $yearly points

 ${yearly > 5000
        ? '🌟 Paradise Path: At this rate, you\'ll enter Jannah with a heavy scale. Keep this momentum - Allah loves consistency!'
        : yearly > 1000
        ? '✅ Strong Progress: Good deeds outweighing. The gates of mercy are wide open. Alhamdulillah!'
        : yearly > 0
        ? '⚖️ Balanced but Fragile: Slight edge to good. One slip could tip it - Stay steadfast!'
        : yearly > -1000
        ? '⚠️ Danger Zone: Bad deeds slightly heavier. This is the moment to change - Tawbah is open!'
        : '🚨 Regret Path: Major imbalance. The scale tips toward Jahannam. Repent NOW before it\'s sealed!'}
    ''';
  }
}

class DailyDeeds {
  Map<String, bool> prayers = {'Fajr': false, 'Zuhr': false, 'Asr': false, 'Maghrib': false, 'Isha': false};
  int qadaCount = 0;
  bool tahajjud = false;
  bool witr = false;
  bool nafl = false;
  int tasbeehCount = 0;
  int daroodCount = 0;
  bool quranRecited = false;
  int quranPages = 0;
  List<String> goodDeeds = [];
  List<String> badDeeds = [];

  DailyDeeds();

  int calculateGoodPoints() {
    final missedFard = prayers.values.where((p) => !p).length;
    final multiplier = missedFard == 0 ? 1.0 : 0.5;

    int points = prayers.values.where((p) => p).length * 50;
    points += qadaCount * 25;
    points += tahajjud ? 100 : 0;
    points += witr ? 30 : 0;
    points += nafl ? 20 : 0;
    points += (tasbeehCount * multiplier).round() as int;
    points += (daroodCount * 2 * multiplier).round() as int;
    points += quranRecited ? (quranPages * 10 * multiplier).round() as int : 0;

    for (var deed in goodDeeds) {
      final result = SpiritualKeywords.analyzeText(deed);
      // --- CORRECTED: Give base points for any good deed, plus bonus if recognized ---
      int deedPoints = 10; // Base points for trying to do good
      if (result['score'] != null) {
        deedPoints += result['score'] as int;
      }
      points += (deedPoints * multiplier).round() as int;
    }

    return points;
  }

  int calculateBadPoints() {
    int points = prayers.values.where((p) => !p).length * 100;

    for (var deed in badDeeds) {
      final result = SpiritualKeywords.analyzeText(deed);
      // --- CORRECTED: Give base points for any bad deed, plus penalty if recognized ---
      int deedPoints = 10; // Base points for acknowledging a bad deed
      if (result['score'] != null) {
        deedPoints += result['score'] as int;
      }
      points += deedPoints;
    }

    return points;
  }

  Map<String, dynamic> toJson() => {
    'prayers': prayers,
    'qadaCount': qadaCount,
    'tahajjud': tahajjud,
    'witr': witr,
    'nafl': nafl,
    'tasbeehCount': tasbeehCount,
    'daroodCount': daroodCount,
    'quranRecited': quranRecited,
    'quranPages': quranPages,
    'goodDeeds': goodDeeds,
    'badDeeds': badDeeds,
  };

  DailyDeeds.fromJson(Map<String, dynamic> json)
      : prayers = Map<String, bool>.from(json['prayers'] ?? {}),
        qadaCount = json['qadaCount'] ?? 0,
        tahajjud = json['tahajjud'] ?? false,
        witr = json['witr'] ?? false,
        nafl = json['nafl'] ?? false,
        tasbeehCount = json['tasbeehCount'] ?? 0,
        daroodCount = json['daroodCount'] ?? 0,
        quranRecited = json['quranRecited'] ?? false,
        quranPages = json['quranPages'] ?? 0,
        goodDeeds = List<String>.from(json['goodDeeds'] ?? []),
        badDeeds = List<String>.from(json['badDeeds'] ?? []);
}