// lib/presentation/widgets/surah_settings_dialog.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/services/settings_service.dart'; // Updated import

class SurahSettingsDialog extends StatefulWidget {
  final String language;
  final int surahNumber;
  final bool isTafseer;

  const SurahSettingsDialog({
    super.key,
    required this.language,
    required this.surahNumber,
    required this.isTafseer,
  });

  @override
  State<SurahSettingsDialog> createState() => _SurahSettingsDialogState();
}

class _SurahSettingsDialogState extends State<SurahSettingsDialog> {
  late SurahDisplaySettings _currentSettings;
  final List<String> _availableLanguages = ['english', 'assamese', 'hindi', 'bengali'];
  final List<String> _availableTafseers = ['english', 'assamese', 'hindi', 'bengali', 'arabic'];

  @override
  void initState() {
    super.initState();
    final settingsService = Provider.of<SettingsService>(context, listen: false);
    _currentSettings = settingsService.surahDisplaySettings[widget.language] ??
        SurahDisplaySettings.defaultFor(widget.language);
  }

  void _updateSettings() {
    final settingsService = Provider.of<SettingsService>(context, listen: false);
    settingsService.updateSurahDisplaySettings(widget.language, _currentSettings);
  }

  void _toggleOption(String option, bool value) {
    setState(() {
      switch (option) {
        case 'showArabic':
          _currentSettings = _currentSettings.copyWith(showArabic: value);
          break;
        case 'showTranslation':
          _currentSettings = _currentSettings.copyWith(showTranslation: value);
          break;
        case 'showTransliteration':
          _currentSettings = _currentSettings.copyWith(showTransliteration: value);
          break;
        case 'showTafseer':
          _currentSettings = _currentSettings.copyWith(showTafseer: value);
          break;
      }

      // Ensure at least one option is enabled
      if (!_currentSettings.hasVisibleContent) {
        // Re-enable Arabic as fallback
        _currentSettings = _currentSettings.copyWith(showArabic: true);
      }
    });
    _updateSettings();
  }

  void _toggleAdditionalTranslation(String language, bool value) {
    setState(() {
      final updatedTranslations = Map<String, bool>.from(_currentSettings.additionalTranslations);
      updatedTranslations[language] = value;
      _currentSettings = _currentSettings.copyWith(additionalTranslations: updatedTranslations);
    });
    _updateSettings();
  }

  void _toggleAdditionalTafseer(String language, bool value) {
    setState(() {
      final updatedTafseers = Map<String, bool>.from(_currentSettings.additionalTafseers);
      updatedTafseers[language] = value;
      _currentSettings = _currentSettings.copyWith(additionalTafseers: updatedTafseers);
    });
    _updateSettings();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final settingsService = Provider.of<SettingsService>(context);
    final double fontScale = settingsService.fontScale;
    final isArabicQuran = widget.language == 'arabic';

    return Container(
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Display Settings',
            style: TextStyle(
              fontSize: 20 * fontScale,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 20),

          // Basic Display Options
          _buildOptionSwitch(
            title: 'Arabic Text',
            value: _currentSettings.showArabic,
            onChanged: (value) => _toggleOption('showArabic', value),
            enabled: true,
            fontScale: fontScale,
          ),

          if (!isArabicQuran) ...[
            _buildOptionSwitch(
              title: '${_capitalize(widget.language)} Translation',
              value: _currentSettings.showTranslation,
              onChanged: (value) => _toggleOption('showTranslation', value),
              fontScale: fontScale,
            ),

            _buildOptionSwitch(
              title: '${_capitalize(widget.language)} Transliteration',
              value: _currentSettings.showTransliteration,
              onChanged: (value) => _toggleOption('showTransliteration', value),
              fontScale: fontScale,
            ),
          ],

          if (widget.isTafseer) ...[
            _buildOptionSwitch(
              title: '${_capitalize(widget.language)} Tafseer',
              value: _currentSettings.showTafseer,
              onChanged: (value) => _toggleOption('showTafseer', value),
              fontScale: fontScale,
            ),
          ],

          const SizedBox(height: 20),

          // Advanced Options Expansion
          _buildAdvancedOptions(theme, fontScale),

          const SizedBox(height: 20),

          // Close Button
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close', style: TextStyle(fontSize: 16 * fontScale)),
          ),
        ],
      ),
    );
  }

  Widget _buildOptionSwitch({
    required String title,
    required bool value,
    required Function(bool) onChanged,
    required double fontScale,
    bool enabled = true,
  }) {
    return SwitchListTile(
      title: Text(title, style: TextStyle(fontSize: 16 * fontScale)),
      value: value,
      onChanged: enabled ? onChanged : null,
    );
  }

  Widget _buildAdvancedOptions(ThemeData theme, double fontScale) {
    return ExpansionTile(
      title: Text('Advanced Options', style: TextStyle(fontSize: 16 * fontScale)),
      children: [
        // Additional Translations
        _buildSectionTitle('Additional Translations', fontScale),
        ..._availableLanguages.where((lang) => lang != widget.language).map((lang) {
          return _buildOptionSwitch(
            title: '${_capitalize(lang)} Translation',
            value: _currentSettings.additionalTranslations[lang] ?? false,
            onChanged: (value) => _toggleAdditionalTranslation(lang, value),
            fontScale: fontScale,
          );
        }).toList(),

        // Additional Tafseers
        if (widget.isTafseer) ...[
          _buildSectionTitle('Additional Tafseers', fontScale),
          ..._availableTafseers.where((lang) => lang != widget.language).map((lang) {
            return _buildOptionSwitch(
              title: '${_capitalize(lang)} Tafseer',
              value: _currentSettings.additionalTafseers[lang] ?? false,
              onChanged: (value) => _toggleAdditionalTafseer(lang, value),
              fontScale: fontScale,
            );
          }).toList(),
        ],
      ],
    );
  }

  Widget _buildSectionTitle(String title, double fontScale) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14 * fontScale,
          fontWeight: FontWeight.bold,
          color: Colors.grey[600],
        ),
      ),
    );
  }

  String _capitalize(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }
}