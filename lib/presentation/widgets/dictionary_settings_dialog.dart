import 'package:flutter/material.dart';

class DictionarySettingsDialog extends StatefulWidget {
  final double fontScale;
  final bool isDarkMode;
  final String readingMode;
  final String selectedLanguage;
  final Function(double) onFontScaleChanged;
  final Function(bool) onDarkModeChanged;
  final Function(String) onReadingModeChanged;
  final Function(String) onLanguageChanged;
  final VoidCallback onResetLanguageDialog; // Keep this for compatibility but we won't use it

  const DictionarySettingsDialog({
    super.key,
    required this.fontScale,
    required this.isDarkMode,
    required this.readingMode,
    required this.selectedLanguage,
    required this.onFontScaleChanged,
    required this.onDarkModeChanged,
    required this.onReadingModeChanged,
    required this.onLanguageChanged,
    required this.onResetLanguageDialog,
  });

  @override
  State<DictionarySettingsDialog> createState() => _DictionarySettingsDialogState();
}

class _DictionarySettingsDialogState extends State<DictionarySettingsDialog> {
  late double _fontScale;
  late bool _isDarkMode;
  late String _readingMode;
  late String _selectedLanguage;

  @override
  void initState() {
    super.initState();
    _fontScale = widget.fontScale;
    _isDarkMode = widget.isDarkMode;
    _readingMode = widget.readingMode;
    _selectedLanguage = widget.selectedLanguage;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      title: const Text('Dictionary Settings'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Font Size
            Text(
              'Font Size',
              style: theme.textTheme.titleMedium,
            ),
            Row(
              children: [
                const Icon(Icons.text_fields, size: 20),
                Expanded(
                  child: Slider(
                    value: _fontScale,
                    min: 0.8,
                    max: 1.4,
                    divisions: 6,
                    onChanged: (value) {
                      setState(() {
                        _fontScale = value;
                      });
                      widget.onFontScaleChanged(value);
                    },
                  ),
                ),
                const Icon(Icons.text_fields, size: 28),
              ],
            ),
            Text(
              '${(_fontScale * 100).round()}%',
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: 16),

            // Reading Mode
            Text(
              'Reading Mode',
              style: theme.textTheme.titleMedium,
            ),
            RadioListTile<String>(
              title: const Text('Standard'),
              value: 'standard',
              groupValue: _readingMode,
              onChanged: (value) {
                setState(() {
                  _readingMode = value!;
                });
                widget.onReadingModeChanged(value!);
              },
            ),
            RadioListTile<String>(
              title: const Text('Comfort'),
              value: 'comfort',
              groupValue: _readingMode,
              onChanged: (value) {
                setState(() {
                  _readingMode = value!;
                });
                widget.onReadingModeChanged(value!);
              },
            ),
            RadioListTile<String>(
              title: const Text('Focused'),
              value: 'focused',
              groupValue: _readingMode,
              onChanged: (value) {
                setState(() {
                  _readingMode = value!;
                });
                widget.onReadingModeChanged(value!);
              },
            ),
            const SizedBox(height: 16),

            // Dictionary Language
            Text(
              'Dictionary Language',
              style: theme.textTheme.titleMedium,
            ),
            RadioListTile<String>(
              title: const Text('English'),
              value: 'english',
              groupValue: _selectedLanguage,
              onChanged: (value) {
                setState(() {
                  _selectedLanguage = value!;
                });
                widget.onLanguageChanged(value!);
              },
            ),
            RadioListTile<String>(
              title: const Text('Assamese (Coming Soon)'),
              value: 'assamese',
              groupValue: _selectedLanguage,
              onChanged: null, // Disabled - no callback
              activeColor: Colors.grey, // Greyed out when disabled
            ),
            const SizedBox(height: 16),

            // Dark Mode
            Text(
              'Appearance',
              style: theme.textTheme.titleMedium,
            ),
            SwitchListTile(
              title: const Text('Dark Mode'),
              subtitle: const Text('Apply dark theme to dictionary only'),
              value: _isDarkMode,
              onChanged: (value) {
                setState(() {
                  _isDarkMode = value;
                });
                widget.onDarkModeChanged(value);
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: const Text('OK'),
        ),
      ],
    );
  }
}