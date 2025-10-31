// lib/presentation/widgets/hadith_card.dart
import 'package:flutter/material.dart';

class HadithCard extends StatelessWidget {
  final int hadithNumber;
  final String textAr;
  final String text;
  final String? narrator;
  final double fontScale;
  final bool showArabic;

  const HadithCard({
    super.key,
    required this.hadithNumber,
    required this.textAr,
    required this.text,
    this.narrator,
    required this.fontScale,
    this.showArabic = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '$hadithNumber',
                    style: TextStyle(
                      fontSize: 12 * fontScale,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                if (narrator != null && narrator!.isNotEmpty)
                  Expanded(
                    child: Text(
                      'Narrated by: $narrator',
                      style: TextStyle(
                        fontSize: 12 * fontScale,
                        fontStyle: FontStyle.italic,
                        color: theme.colorScheme.onSurface.withOpacity(0.7),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            if (showArabic && textAr.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Text(
                  textAr,
                  style: TextStyle(
                    fontSize: 18 * fontScale,
                    fontWeight: FontWeight.w500,
                    color: theme.colorScheme.onSurface,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.right,
                ),
              ),
            if (text.isNotEmpty)
              Text(
                text,
                style: TextStyle(
                  fontSize: 14 * fontScale,
                  color: theme.colorScheme.onSurface.withOpacity(0.8),
                  height: 1.5,
                ),
              ),
            if (textAr.isEmpty && text.isEmpty)
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  'No text available for this hadith.',
                  style: TextStyle(
                    fontSize: 14 * fontScale,
                    color: theme.colorScheme.onSurface.withOpacity(0.5),
                    fontStyle: FontStyle.italic,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
          ],
        ),
      ),
    );
  }
}