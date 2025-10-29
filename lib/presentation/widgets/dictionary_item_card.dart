import 'package:flutter/material.dart';
import '../../data/models/quran_dictionary_model.dart';

class DictionaryItemCard extends StatelessWidget {
  final QuranDictionaryItem item;
  final double fontScale;
  final String readingMode;

  const DictionaryItemCard({
    super.key,
    required this.item,
    required this.fontScale,
    required this.readingMode,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Adjust padding and spacing based on reading mode
    double cardPadding = 16.0;
    double titleSpacing = 8.0;
    double contentSpacing = 12.0;

    if (readingMode == 'comfort') {
      cardPadding = 20.0;
      titleSpacing = 12.0;
      contentSpacing = 16.0;
    } else if (readingMode == 'focused') {
      cardPadding = 24.0;
      titleSpacing = 16.0;
      contentSpacing = 20.0;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 16.0),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Padding(
        padding: EdgeInsets.all(cardPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title and Location
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title,
                        style: TextStyle(
                          fontSize: 20 * fontScale,
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      SizedBox(height: titleSpacing),
                      Text(
                        item.subheading,
                        style: TextStyle(
                          fontSize: 16 * fontScale,
                          fontStyle: FontStyle.italic,
                          color: theme.colorScheme.onSurface.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    item.location,
                    style: TextStyle(
                      fontSize: 14 * fontScale,
                      fontWeight: FontWeight.w500,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: contentSpacing),

            // Arabic Word
            if (item.arabicWord.isNotEmpty) ...[
              Text(
                item.arabicWord,
                style: TextStyle(
                  fontSize: 24 * fontScale,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
                textDirection: TextDirection.rtl,
              ),
              SizedBox(height: contentSpacing),
            ],

            // Transliteration
            if (item.transliteration.isNotEmpty) ...[
              Text(
                item.transliteration,
                style: TextStyle(
                  fontSize: 18 * fontScale,
                  fontStyle: FontStyle.italic,
                  color: theme.colorScheme.onSurface.withOpacity(0.8),
                ),
              ),
              SizedBox(height: contentSpacing),
            ],

            // Translation
            if (item.translation.isNotEmpty) ...[
              Text(
                item.translation,
                style: TextStyle(
                  fontSize: 16 * fontScale,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              SizedBox(height: contentSpacing),
            ],

            // Arabic Verse Part
            if (item.arabicVersePart.isNotEmpty) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: theme.colorScheme.outline.withOpacity(0.2),
                  ),
                ),
                child: Text(
                  item.arabicVersePart,
                  style: TextStyle(
                    fontSize: 18 * fontScale,
                    color: theme.colorScheme.onSurface,
                  ),
                  textDirection: TextDirection.rtl,
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}