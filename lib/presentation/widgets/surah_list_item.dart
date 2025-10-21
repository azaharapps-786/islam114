import 'package:flutter/material.dart';
import '../../data/models/surah_model.dart';

class SurahListItem extends StatelessWidget {
  final Surah surah;
  final String surahName;
  final double fontScale;
  final VoidCallback onTap;

  const SurahListItem({
    super.key,
    required this.surah,
    required this.surahName,
    required this.fontScale,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).colorScheme.primary,
          foregroundColor: Colors.white,
          child: Text(
            '${surah.id}',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16 * fontScale,
            ),
          ),
        ),
        title: Text(
          surahName,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16 * fontScale,
          ),
        ),
        subtitle: Text(
          surah.translation,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
            fontSize: 14 * fontScale,
          ),
        ),
        trailing: Text(
          '${surah.totalVerses} verses',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
            fontSize: 12 * fontScale,
          ),
        ),
        onTap: onTap,
      ),
    );
  }
}