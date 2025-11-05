import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/services/settings_service.dart'; // Updated import

class VerseCard extends StatelessWidget {
  final int surahNumber;
  final int verseNumber;
  final String arabic;
  final String translation;
  final String transliteration;
  final String tafseer;
  final String language;
  final bool isTafseer;
  final bool isBookmarked;
  final SurahDisplaySettings displaySettings;
  final VoidCallback onShare;
  final VoidCallback onCopy;
  final VoidCallback onBookmark;
  final double fontScale;

  const VerseCard({
    super.key,
    required this.surahNumber,
    required this.verseNumber,
    required this.arabic,
    required this.translation,
    required this.transliteration,
    required this.tafseer,
    required this.language,
    required this.isTafseer,
    required this.isBookmarked,
    required this.displaySettings,
    required this.onShare,
    required this.onCopy,
    required this.onBookmark,
    required this.fontScale,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Verse Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '$surahNumber:$verseNumber',
                    style: TextStyle(
                      fontSize: 14 * fontScale,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ),
                // Action Buttons
                Row(
                  children: [
                    // Star bookmark icon - updated from bookmark to star
                    IconButton(
                      icon: Icon(
                        isBookmarked ? Icons.star : Icons.star_border,
                        color: isBookmarked ? Colors.amber : Colors.grey,
                      ),
                      onPressed: onBookmark,
                      tooltip: isBookmarked ? 'Remove bookmark' : 'Bookmark verse',
                    ),
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert),
                      itemBuilder: (context) => [
                        PopupMenuItem(
                          value: 'share',
                          child: Row(
                            children: [
                              const Icon(Icons.share, size: 20),
                              const SizedBox(width: 8),
                              Text('Share', style: TextStyle(fontSize: 14 * fontScale)),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: 'copy',
                          child: Row(
                            children: [
                              const Icon(Icons.content_copy, size: 20),
                              const SizedBox(width: 8),
                              Text('Copy', style: TextStyle(fontSize: 14 * fontScale)),
                            ],
                          ),
                        ),
                      ],
                      onSelected: (value) {
                        if (value == 'share') onShare();
                        if (value == 'copy') onCopy();
                      },
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Arabic Text
            if (displaySettings.showArabic && arabic.isNotEmpty)
              _buildTextSection(
                text: arabic,
                style: TextStyle(
                  fontSize: 20 * fontScale,
                  fontFamily: 'Uthmanic',
                  height: 1.8,
                ),
                alignment: TextAlign.right,
              ),

            // Transliteration
            if (displaySettings.showTransliteration && transliteration.isNotEmpty)
              _buildTextSection(
                text: transliteration,
                style: TextStyle(
                  fontSize: 14 * fontScale,
                  fontStyle: FontStyle.italic,
                  color: theme.colorScheme.onSurface.withOpacity(0.7),
                  height: 1.4,
                ),
              ),

            // Main Translation
            if (displaySettings.showTranslation && translation.isNotEmpty)
              _buildTextSection(
                text: translation,
                style: TextStyle(
                  fontSize: 16 * fontScale,
                  height: 1.6,
                ),
              ),

            // Tafseer
            if (displaySettings.showTafseer && tafseer.isNotEmpty)
              _buildTextSection(
                text: tafseer,
                style: TextStyle(
                  fontSize: 14 * fontScale,
                  color: theme.colorScheme.onSurface.withOpacity(0.8),
                  fontStyle: FontStyle.italic,
                  height: 1.5,
                ),
                isTafseer: true,
              ),

            // Additional Translations
            ..._buildAdditionalTranslations(theme),

            // Additional Tafseers
            ..._buildAdditionalTafseers(theme),
          ],
        ),
      ),
    );
  }

  Widget _buildTextSection({
    required String text,
    required TextStyle style,
    TextAlign alignment = TextAlign.left,
    bool isTafseer = false,
  }) {
    return Container(
      margin: EdgeInsets.only(top: isTafseer ? 12 : 8),
      child: Text(
        text,
        style: style,
        textAlign: alignment,
        textDirection: alignment == TextAlign.right ? TextDirection.rtl : TextDirection.ltr,
      ),
    );
  }

  List<Widget> _buildAdditionalTranslations(ThemeData theme) {
    final widgets = <Widget>[];
    displaySettings.additionalTranslations.forEach((lang, enabled) {
      if (enabled) {
        // This would need to fetch the actual translation text for the additional language
        // For now, we'll show a placeholder
        widgets.add(
          _buildTextSection(
            text: '[Additional $lang translation would go here]',
            style: TextStyle(
              fontSize: 14 * fontScale,
              color: theme.colorScheme.primary.withOpacity(0.8),
              height: 1.4,
            ),
          ),
        );
      }
    });
    return widgets;
  }

  List<Widget> _buildAdditionalTafseers(ThemeData theme) {
    final widgets = <Widget>[];
    displaySettings.additionalTafseers.forEach((lang, enabled) {
      if (enabled) {
        widgets.add(
          _buildTextSection(
            text: '[Additional $lang tafseer would go here]',
            style: TextStyle(
              fontSize: 13 * fontScale,
              color: theme.colorScheme.onSurface.withOpacity(0.6),
              fontStyle: FontStyle.italic,
              height: 1.4,
            ),
            isTafseer: true,
          ),
        );
      }
    });
    return widgets;
  }
}