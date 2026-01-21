import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/services/settings_service.dart';

class SurahSettingsDialog extends StatefulWidget {
  final String language;
  final bool isTafseerMode;

  const SurahSettingsDialog({
    super.key,
    required this.language,
    required this.isTafseerMode,
  });

  @override
  State<SurahSettingsDialog> createState() => _SurahSettingsDialogState();
}

class _SurahSettingsDialogState extends State<SurahSettingsDialog> {
  late SurahDisplaySettings _currentSettings;

  static const List<String> _languages = ['arabic', 'english', 'hindi', 'assamese', 'bengali'];

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

  void _toggleArabic(bool value) {
    setState(() => _currentSettings = _currentSettings.copyWith(showArabic: value));
    _updateSettings();
  }

  void _toggleTranslation(String lang, bool value) {
    setState(() {
      if (lang == widget.language) {
        _currentSettings = _currentSettings.copyWith(showTranslation: value);
      } else {
        final updated = Map<String, bool>.from(_currentSettings.additionalTranslations);
        updated[lang] = value;
        _currentSettings = _currentSettings.copyWith(additionalTranslations: updated);
      }
    });
    _updateSettings();
  }

  void _toggleTransliteration(String lang, bool value) {
    setState(() {
      if (lang == widget.language) {
        _currentSettings = _currentSettings.copyWith(showTransliteration: value);
      } else {
        final updated = Map<String, bool>.from(_currentSettings.additionalTransliterations);
        updated[lang] = value;
        _currentSettings = _currentSettings.copyWith(additionalTransliterations: updated);
      }
    });
    _updateSettings();
  }

  void _toggleTafseer(String lang, bool value) {
    setState(() {
      if (lang == widget.language) {
        _currentSettings = _currentSettings.copyWith(showTafseer: value);
      } else {
        final updated = Map<String, bool>.from(_currentSettings.additionalTafseers);
        updated[lang] = value;
        _currentSettings = _currentSettings.copyWith(additionalTafseers: updated);
      }
    });
    _updateSettings();
  }

  bool _isTranslationEnabled(String lang) =>
      lang == widget.language ? _currentSettings.showTranslation : _currentSettings.additionalTranslations[lang] ?? false;

  bool _isTransliterationEnabled(String lang) =>
      lang == widget.language ? _currentSettings.showTransliteration : _currentSettings.additionalTransliterations[lang] ?? false;

  bool _isTafseerEnabled(String lang) =>
      lang == widget.language ? _currentSettings.showTafseer : _currentSettings.additionalTafseers[lang] ?? false;

  String _capitalize(String s) => s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

  Widget _buildSectionTitle(String title, double fontScale) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8), // Further reduced vertical padding
      child: Text(
        title,
        style: TextStyle(
          fontSize: 18 * fontScale,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).primaryColor,
        ),
      ),
    );
  }

  Widget _buildSwitch(String title, bool value, void Function(bool) onChanged, {bool isPrimary = false}) {
    return SwitchListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0), // No vertical padding
      dense: true, // Make the tile more compact
      title: Row(
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 15, // Slightly smaller font
              fontWeight: isPrimary ? FontWeight.bold : FontWeight.normal,
              color: isPrimary ? Theme.of(context).primaryColor : null,
            ),
          ),
          if (isPrimary) ...[
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1), // Smaller padding
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(3),
              ),
              child: Text(
                'Primary',
                style: TextStyle(
                  fontSize: 10, // Smaller font
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).primaryColor,
                ),
              ),
            ),
          ],
        ],
      ),
      value: value,
      onChanged: onChanged,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final settingsService = Provider.of<SettingsService>(context);
    final double fontScale = settingsService.fontScale;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: theme.cardColor,
      contentPadding: const EdgeInsets.fromLTRB(16, 16, 16, 8), // Reduced bottom padding
      title: Center(
        child: Text(
          'Display Settings',
          style: TextStyle(fontSize: 22 * fontScale, fontWeight: FontWeight.bold),
        ),
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Arabic Text Section
              _buildSectionTitle('Arabic Text', fontScale),
              _buildSwitch(
                'Show Arabic Text',
                _currentSettings.showArabic,
                _toggleArabic,
              ),

              const Divider(height: 4), // Further reduced height

              // Translations Section
              _buildSectionTitle('Translations', fontScale),
              ..._languages.where((l) => l != 'arabic').map((lang) {
                final bool isPrimary = lang == widget.language;
                return _buildSwitch(
                  _capitalize(lang),
                  _isTranslationEnabled(lang),
                      (bool newValue) => _toggleTranslation(lang, newValue),
                  isPrimary: isPrimary,
                );
              }),

              const Divider(height: 4), // Further reduced height

              // Transliterations Section
              _buildSectionTitle('Transliterations', fontScale),
              ..._languages.where((l) => l != 'arabic').map((lang) {
                final bool isPrimary = lang == widget.language;
                return _buildSwitch(
                  _capitalize(lang),
                  _isTransliterationEnabled(lang),
                      (bool newValue) => _toggleTransliteration(lang, newValue),
                  isPrimary: isPrimary,
                );
              }),

              // Tafseer Section (only when in Tafseer mode)
              if (widget.isTafseerMode) ...[
                const Divider(height: 4), // Further reduced height
                _buildSectionTitle('Tafseer', fontScale),
                ..._languages.map((lang) {
                  final bool isPrimary = lang == widget.language;
                  return _buildSwitch(
                    _capitalize(lang),
                    _isTafseerEnabled(lang),
                        (bool newValue) => _toggleTafseer(lang, newValue),
                    isPrimary: isPrimary,
                  );
                }),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Close', style: TextStyle(fontSize: 16 * fontScale)),
        ),
      ],
    );
  }
}