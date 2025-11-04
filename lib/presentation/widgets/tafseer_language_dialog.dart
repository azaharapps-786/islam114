// lib/presentation/widgets/tafseer_language_dialog.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/services/settings_service.dart';

class TafseerLanguageDialog extends StatelessWidget {
  const TafseerLanguageDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final fontScale = Provider.of<SettingsService>(context).fontScale;
    final theme = Theme.of(context);

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Select Tafseer Language',
              style: TextStyle(
                fontSize: 22 * fontScale,
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 20),
            _buildLanguageOption(
              context,
              'অসমীয়া',
              'assamese',
              fontScale,
              theme,
            ),
            _buildLanguageOption(
              context,
              'English',
              'english',
              fontScale,
              theme,
            ),
            _buildLanguageOption(
              context,
              'हिन्दी',
              'hindi',
              fontScale,
              theme,
            ),
            _buildLanguageOption(
              context,
              'العربية',
              'arabic',
              fontScale,
              theme,
            ),
            _buildLanguageOption(
              context,
              'বাংলা',
              'bengali',
              fontScale,
              theme,
            ),
            const SizedBox(height: 10),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Cancel',
                style: TextStyle(
                  fontSize: 16 * fontScale,
                  color: theme.colorScheme.primary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLanguageOption(
      BuildContext context,
      String displayName,
      String languageCode,
      double fontScale,
      ThemeData theme,
      ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () {
          Navigator.of(context).pop();
          Navigator.pushNamed(
            context,
            '/surahList',
            arguments: {
              'language': languageCode,
              'isTafseer': true,
            },
          );
        },
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color: theme.colorScheme.primary.withOpacity(0.1),
          ),
          child: Text(
            displayName,
            style: TextStyle(
              fontSize: 18 * fontScale,
              fontWeight: FontWeight.w500,
              color: theme.colorScheme.onSurface,
            ),
          ),
        ),
      ),
    );
  }
}