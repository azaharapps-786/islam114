import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/services/settings_service.dart';

class TafseerSettingsDialog extends StatefulWidget {
  final String language;

  const TafseerSettingsDialog({
    super.key,
    required this.language,
  });

  @override
  State<TafseerSettingsDialog> createState() => _TafseerSettingsDialogState();
}

class _TafseerSettingsDialogState extends State<TafseerSettingsDialog> {
  // We no longer need a local state variable for settings.
  // We will fetch it directly from the service inside the Consumer's builder.

  void _updateSettings(BuildContext context, SurahDisplaySettings newSettings) {
    // The context is needed to get the provider
    final settingsService = Provider.of<SettingsService>(context, listen: false);
    settingsService.updateTafseerDisplaySettings(widget.language, newSettings);
  }

  void _toggleArabic(BuildContext context, bool value) {
    final settingsService = Provider.of<SettingsService>(context, listen: false);
    final currentSettings = settingsService.getTafseerDisplaySettings(widget.language);
    _updateSettings(context, currentSettings.copyWith(showArabic: value));
  }

  void _toggleTranslation(BuildContext context, bool value) {
    final settingsService = Provider.of<SettingsService>(context, listen: false);
    final currentSettings = settingsService.getTafseerDisplaySettings(widget.language);
    _updateSettings(context, currentSettings.copyWith(showTranslation: value));
  }

  void _toggleTransliteration(BuildContext context, bool value) {
    final settingsService = Provider.of<SettingsService>(context, listen: false);
    final currentSettings = settingsService.getTafseerDisplaySettings(widget.language);
    _updateSettings(context, currentSettings.copyWith(showTransliteration: value));
  }

  String _capitalize(String s) => s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // FIX: Wrap the AlertDialog in a Consumer.
    // This makes the dialog rebuild whenever settings are updated.
    return Consumer<SettingsService>(
      builder: (context, settingsService, child) {
        // Get the latest settings from the service every time the builder runs.
        final currentSettings = settingsService.getTafseerDisplaySettings(widget.language);
        final double fontScale = settingsService.fontScale;

        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          backgroundColor: theme.cardColor,
          contentPadding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          title: Center(
            child: Text(
              'Tafseer Settings',
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
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                    child: Text(
                      'Arabic Text',
                      style: TextStyle(
                        fontSize: 18 * fontScale,
                        fontWeight: FontWeight.bold,
                        color: theme.primaryColor,
                      ),
                    ),
                  ),
                  SwitchListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                    dense: true,
                    title: Text(
                      'Show Arabic Text',
                      style: TextStyle(fontSize: 15),
                    ),
                    // FIX: Use the value from the settingsService, fetched inside the builder.
                    value: currentSettings.showArabic,
                    // FIX: Pass the context to the toggle function.
                    onChanged: (value) => _toggleArabic(context, value),
                  ),

                  const Divider(height: 4),

                  // Translation Section
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                    child: Text(
                      '${_capitalize(widget.language)} Translation',
                      style: TextStyle(
                        fontSize: 18 * fontScale,
                        fontWeight: FontWeight.bold,
                        color: theme.primaryColor,
                      ),
                    ),
                  ),
                  SwitchListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                    dense: true,
                    title: Text(
                      'Show ${_capitalize(widget.language)} Translation',
                      style: TextStyle(fontSize: 15),
                    ),
                    value: currentSettings.showTranslation,
                    onChanged: (value) => _toggleTranslation(context, value),
                  ),

                  const Divider(height: 4),

                  // Transliteration Section
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                    child: Text(
                      '${_capitalize(widget.language)} Transliteration',
                      style: TextStyle(
                        fontSize: 18 * fontScale,
                        fontWeight: FontWeight.bold,
                        color: theme.primaryColor,
                      ),
                    ),
                  ),
                  SwitchListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                    dense: true,
                    title: Text(
                      'Show ${_capitalize(widget.language)} Transliteration',
                      style: TextStyle(fontSize: 15),
                    ),
                    value: currentSettings.showTransliteration,
                    onChanged: (value) => _toggleTransliteration(context, value),
                  ),
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
      },
    );
  }
}