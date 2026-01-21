import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/services/settings_service.dart';
import '../widgets/verse_card.dart';

class BookmarksPage extends StatelessWidget {
  const BookmarksPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Saved Verses'),
      ),
      body: Consumer<SettingsService>(
        builder: (context, settings, child) {
          final bookmarkedVerses = settings.getBookmarkedVerses();
          if (bookmarkedVerses.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(32.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.bookmark_border, size: 64, color: Colors.grey),
                    SizedBox(height: 16),
                    Text(
                      'No Saved Verses Yet',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Saved verses from any surah to see them here.',
                      style: TextStyle(fontSize: 14, color: Colors.grey),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }

          // FIXED: Sort by timestamp (newest first)
          final sortedBookmarks = List<Map<String, dynamic>>.from(bookmarkedVerses)
            ..sort((a, b) => (b['timestamp'] as int).compareTo(a['timestamp'] as int));

          // Group by surah for headers (optional enhancement)
          Map<int, List<Map<String, dynamic>>> groupedBySurah = <int, List<Map<String, dynamic>>>{};
          for (final bookmark in sortedBookmarks) {
            final surah = bookmark['surahNumber'] as int;
            groupedBySurah.putIfAbsent(surah, () => []).add(bookmark);
          }

          // FIXED: Build a flat list of widgets (header + verses per group) for simple ListView
          final List<Widget> groupedWidgets = [];

          // FIXED: Separate sort and forEach to avoid void chaining error
          final sortedEntries = groupedBySurah.entries.toList();
          sortedEntries.sort((a, b) => a.key.compareTo(b.key)); // Sort groups by surah number
          sortedEntries.forEach((surahEntry) {
            final surahNumber = surahEntry.key;
            final versesInGroup = surahEntry.value;

            // Add surah header
            groupedWidgets.add(
              Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Text(
                  'Surah $surahNumber',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
              ),
            );

            // Add verses for this surah
            groupedWidgets.addAll(
              versesInGroup.map<Widget>((bookmark) {
                final verseData = bookmark['verseData'] as Map<String, dynamic>;
                final verseNumber = bookmark['verseNumber'] as int;
                final language = bookmark['language'] as String;
                final isTafseer = bookmark['isTafseer'] as bool;
                final isBookmarked = true; // Always true in bookmarks

                return VerseCard(
                  key: ValueKey(bookmark['key']), // Unique key for rebuilds
                  surahNumber: surahNumber,
                  verseNumber: verseNumber,
                  arabic: verseData['arabic'] ?? '',
                  translation: verseData['translation'] ?? '',
                  transliteration: verseData['transliteration'] ?? '',
                  tafseer: verseData['tafseer'] ?? '',
                  language: language,
                  isTafseer: isTafseer,
                  isBookmarked: isBookmarked,
                  onShare: () => _shareBookmark(
                      context, surahNumber, verseNumber, verseData['arabic'] ?? '', verseData['translation'] ?? ''),
                  onCopy: () => _copyBookmark(
                      context, surahNumber, verseNumber, verseData['arabic'] ?? '', verseData['translation'] ?? ''),
                  onBookmark: () => _toggleBookmarkInList(context, bookmark),
                  fontScale: settings.fontScale,
                  // FIXED: Added the required cachedData parameter
                  cachedData: {}, // Empty map since we don't need cached data in bookmarks
                );
              }),
            );

            // Add spacer between groups
            groupedWidgets.add(const SizedBox(height: 16));
          });

          return ListView(
            padding: const EdgeInsets.all(16.0),
            children: groupedWidgets,
          );
        },
      ),
    );
  }

  // FIXED: Moved helpers to class level; added required imports
  // Helper: Share bookmark (adapted from surah_detail)
  void _shareBookmark(BuildContext context, int surahNumber, int verseNumber, String arabic, String translation) {
    final verseText = '$surahNumber:$verseNumber\n$arabic\n\n$translation';
    Share.share(verseText);
  }

  // Helper: Copy bookmark (adapted)
  void _copyBookmark(BuildContext context, int surahNumber, int verseNumber, String arabic, String translation) {
    final verseText = '$surahNumber:$verseNumber\n$arabic\n\n$translation';
    Clipboard.setData(ClipboardData(text: verseText));
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Verse $surahNumber:$verseNumber copied to clipboard')),
      );
    }
  }

  // Helper: Toggle bookmark from list (removes it)
  void _toggleBookmarkInList(BuildContext context, Map<String, dynamic> bookmark) {
    final settings = Provider.of<SettingsService>(context, listen: false);
    settings.toggleBookmark(
      surahNumber: bookmark['surahNumber'],
      verseNumber: bookmark['verseNumber'],
      verseData: bookmark['verseData'],
      language: bookmark['language'],
      isTafseer: bookmark['isTafseer'],
    );
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bookmark removed')),
      );
    }
  }
}