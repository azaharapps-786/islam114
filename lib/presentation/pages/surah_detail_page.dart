// lib/presentation/pages/surah_detail_page.dart
import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/services/settings_service.dart';
import '../widgets/verse_card.dart';
import '../widgets/surah_settings_dialog.dart';

class SurahDetailPage extends StatefulWidget {
  const SurahDetailPage({super.key});

  @override
  State<SurahDetailPage> createState() => _SurahDetailPageState();
}

class _SurahDetailPageState extends State<SurahDetailPage> {
  List<Map<String, dynamic>> _verses = [];
  List<Map<String, dynamic>> _filteredVerses = [];
  bool _isLoading = true;
  String _surahName = '';
  int _surahNumber = 0;
  String _language = 'english';
  bool _isTafseer = false;
  bool _isSearching = false;
  bool _showSearchBar = false;
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();

    // Initialize search controller listener
    _searchController.addListener(() {
      _filterVerses(_searchController.text);
    });

    // Don't call _loadSurahData() here - we'll call it in didChangeDependencies
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Get route arguments
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final newLanguage = args?['language'] ?? 'english';
    final newSurahNumber = args?['surahNumber'] ?? 1;
    final newIsTafseer = args?['isTafseer'] ?? false;

    // Check if we need to reload data
    if (newLanguage != _language || newSurahNumber != _surahNumber || newIsTafseer != _isTafseer) {
      _language = newLanguage;
      _surahNumber = newSurahNumber;
      _isTafseer = newIsTafseer;
      _loadSurahData();
    } else if (_verses.isEmpty) {
      // Initial load if verses are empty
      _loadSurahData();
    }
  }

  // In surah_detail_page.dart, modify the _loadSurahData method:

  Future<void> _loadSurahData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Determine the correct JSON file to load
      String jsonFile;
      if (_isTafseer) {
        jsonFile = 'assets/data/quran_${_language}_tafseer.json';
      } else {
        jsonFile = 'assets/data/quran_${_language}.json';
      }

      final String jsonString = await rootBundle.loadString(jsonFile);

      // Also load the Arabic Quran data to ensure we always have Arabic text
      final String arabicJsonString = await rootBundle.loadString('assets/data/quran_arabic.json');
      final List<dynamic> arabicJsonData = json.decode(arabicJsonString);
      final arabicSurahData = arabicJsonData.firstWhere(
            (surah) => (surah['id'] as num?)?.toInt() == _surahNumber,
        orElse: () => null,
      );

      final arabicVerses = arabicSurahData?['verses'] as List? ?? [];

      // Handle different JSON structures based on language
      List<dynamic> jsonData;
      Map<String, dynamic>? surahData;

      if (_language == 'arabic') {
        // --- SPECIAL HANDLING FOR ARABIC ---
        // Arabic format: array of surahs with verses array
        jsonData = json.decode(jsonString);
        surahData = jsonData.firstWhere(
              (surah) => (surah['id'] as num?)?.toInt() == _surahNumber,
          orElse: () => null,
        );

        if (surahData != null) {
          final versesList = surahData?['verses'] as List?;
          final rawVerses = versesList?.map((v) => Map<String, dynamic>.from(v)).toList() ?? [];

          // Create a new list of verses with the structure the app expects
          // For Arabic, we copy the 'text' to 'translation' and 'arabic' fields
          // This ensures consistency without needing external files
          final adaptedVerses = rawVerses.map((verse) {
            final arabicText = verse['text'] ?? '';
            return {
              'id': verse['id'],
              'text': arabicText, // Keep original 'text' field
              'arabic': arabicText, // Add 'arabic' field
              'translation': arabicText, // Add 'translation' field with Arabic text
              'transliteration': '', // Add empty transliteration
              'footnotes': '', // Add empty footnotes
              'tafseer': verse['tafseer'] ?? '', // Keep tafseer if it exists
            };
          }).toList();

          setState(() {
            _surahName = surahData?['name'] ?? 'Surah $_surahNumber';
            _verses = adaptedVerses; // Use the adapted list
            _filteredVerses = List<Map<String, dynamic>>.from(_verses);
            _isLoading = false;
          });
        } else {
          throw Exception('Surah $_surahNumber not found in $jsonFile');
        }
      } else if (_language == 'english') {
        // English format: array of verses with sura and aya properties
        jsonData = json.decode(jsonString);

        // Filter verses for the selected surah
        final surahVerses = jsonData.where((verse) => (verse['sura'] as num?)?.toInt() == _surahNumber).toList();

        // Merge English verses with Arabic text
        final mergedVerses = surahVerses.map((verse) {
          final verseNumber = (verse['aya'] as num?)?.toInt() ?? 0;
          final arabicVerse = arabicVerses.firstWhere(
                (v) => (v['id'] as num?)?.toInt() == verseNumber,
            orElse: () => {},
          );

          return {
            ...verse,
            'arabic': arabicVerse['text'] ?? '',
          };
        }).toList();

        setState(() {
          _surahName = 'Surah $_surahNumber'; // We don't have the name in this format
          _verses = List<Map<String, dynamic>>.from(mergedVerses);
          _filteredVerses = List<Map<String, dynamic>>.from(_verses);
          _isLoading = false;
        });
      } else if (_language == 'assamese' || _language == 'hindi') {
        // Assamese and Hindi format: array of verses with sura and aya properties
        jsonData = json.decode(jsonString);

        // Filter verses for the selected surah
        final surahVerses = jsonData.where((verse) => (verse['sura'] as num?)?.toInt() == _surahNumber).toList();

        // Merge language verses with Arabic text
        final mergedVerses = surahVerses.map((verse) {
          final verseNumber = (verse['aya'] as num?)?.toInt() ?? 0;
          final arabicVerse = arabicVerses.firstWhere(
                (v) => (v['id'] as num?)?.toInt() == verseNumber,
            orElse: () => {},
          );

          return {
            ...verse,
            'arabic': arabicVerse['text'] ?? '',
          };
        }).toList();

        setState(() {
          _surahName = 'Surah $_surahNumber'; // We don't have the name in this format
          _verses = List<Map<String, dynamic>>.from(mergedVerses);
          _filteredVerses = List<Map<String, dynamic>>.from(_verses);
          _isLoading = false;
        });
      } else {
        // Default handling for other languages (adjust as needed)
        jsonData = json.decode(jsonString);

        // Try to find surah data first
        if (jsonData.isNotEmpty && jsonData[0] is Map && jsonData[0].containsKey('id')) {
          // Format similar to Arabic
          surahData = jsonData.firstWhere(
                (surah) => (surah['id'] as num?)?.toInt() == _surahNumber,
            orElse: () => null,
          );

          if (surahData != null) {
            final versesList = surahData?['verses'] as List?;
            final rawVerses = versesList?.map((v) => Map<String, dynamic>.from(v)).toList() ?? [];

            // Merge language verses with Arabic text
            final mergedVerses = rawVerses.map((verse) {
              final verseNumber = (verse['id'] as num?)?.toInt() ?? 0;
              final arabicVerse = arabicVerses.firstWhere(
                    (v) => (v['id'] as num?)?.toInt() == verseNumber,
                orElse: () => {},
              );

              return {
                ...verse,
                'arabic': arabicVerse['text'] ?? '',
              };
            }).toList();

            setState(() {
              _surahName = surahData?['name'] ?? 'Surah $_surahNumber';
              _verses = mergedVerses;
              _filteredVerses = List<Map<String, dynamic>>.from(_verses);
              _isLoading = false;
            });
          } else {
            throw Exception('Surah $_surahNumber not found in $jsonFile');
          }
        } else {
          // Format similar to Assamese/Hindi (array of verses)
          final surahVerses = jsonData.where((verse) => (verse['sura'] as num?)?.toInt() == _surahNumber).toList();

          // Merge language verses with Arabic text
          final mergedVerses = surahVerses.map((verse) {
            final verseNumber = (verse['aya'] as num?)?.toInt() ?? 0;
            final arabicVerse = arabicVerses.firstWhere(
                  (v) => (v['id'] as num?)?.toInt() == verseNumber,
              orElse: () => {},
            );

            return {
              ...verse,
              'arabic': arabicVerse['text'] ?? '',
            };
          }).toList();

          setState(() {
            _surahName = 'Surah $_surahNumber';
            _verses = List<Map<String, dynamic>>.from(mergedVerses);
            _filteredVerses = List<Map<String, dynamic>>.from(_verses);
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading surah data: $e');

      // Fallback to hardcoded data if JSON loading fails
      _createFallbackData();
    }
  }

  void _createFallbackData() {
    setState(() {
      _surahName = 'Surah $_surahNumber';
      _verses = List.generate(7, (index) => {
        'id': index + 1,
        'text': 'بِسۡمِ ٱللَّهِ ٱلرَّحۡمَٰنِ ٱلرَّحِيمِ',
        'translation': 'In the name of Allah, the Most Gracious, the Most Merciful.',
        'transliteration': 'Bismillahi r-rahmani r-rahim',
      });
      _filteredVerses = List.from(_verses);
      _isLoading = false;
    });
  }

  void _filterVerses(String query) {
    _debounceTimer?.cancel();

    if (query.isEmpty) {
      setState(() {
        _filteredVerses = _verses;
        _isSearching = false;
      });
      return;
    }

    setState(() {
      _isSearching = true;
    });

    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      final results = _verses.where((verse) {
        // Handle different verse number field names with type coercion, prioritizing 'aya' for assamese/hindi format
        final verseNumber = (verse['aya'] as num?)?.toInt() ??
            (verse['verse_number'] as num?)?.toInt() ??
            (verse['id'] as num?)?.toInt() ?? 0;

        // Handle different text field names
        final text = verse['text']?.toString().toLowerCase() ??
            verse['arabic']?.toString().toLowerCase() ?? '';

        final translation = verse['translation']?.toString().toLowerCase() ?? '';
        final transliteration = verse['transliteration']?.toString().toLowerCase() ?? '';
        final tafseer = verse['tafseer']?.toString().toLowerCase() ?? '';
        final footnotes = verse['footnotes']?.toString().toLowerCase() ?? '';
        final searchQuery = query.toLowerCase().trim();

        // Search by verse number patterns
        if (_isVerseNumberPattern(searchQuery)) {
          return _matchesVerseNumberPattern(verseNumber.toString(), searchQuery);
        }

        // Search in all text fields
        return text.contains(searchQuery) ||
            translation.contains(searchQuery) ||
            transliteration.contains(searchQuery) ||
            tafseer.contains(searchQuery) ||
            footnotes.contains(searchQuery) ||
            verseNumber.toString().contains(searchQuery);
      }).toList();

      if (mounted) {
        setState(() {
          _filteredVerses = results;
          _isSearching = false;
        });
      }
    });
  }

  bool _isVerseNumberPattern(String query) {
    // Check if query matches patterns like: "1", "1:2", "1:2-5", "2-5", "1:2:3" etc.
    final versePattern = RegExp(r'^(\d+)[:-]?(\d+)?[-:]?(\d+)?$');
    return versePattern.hasMatch(query);
  }

  bool _matchesVerseNumberPattern(String verseNumber, String query) {
    try {
      final currentVerse = int.tryParse(verseNumber) ?? 0;

      // Handle single number (e.g., "5")
      if (RegExp(r'^\d+$').hasMatch(query)) {
        final searchNum = int.tryParse(query) ?? 0;
        return currentVerse == searchNum;
      }

      // Handle surah:verse pattern (e.g., "2:255")
      if (query.contains(':')) {
        final parts = query.split(':');
        if (parts.length == 2) {
          final surahPart = int.tryParse(parts[0]) ?? 0;
          final verseStr = parts[1].trim();
          if (verseStr.isEmpty) {
            // If surah: with no verse (e.g., "2:"), match all verses if surah matches current
            return surahPart == _surahNumber;
          }
          final versePart = int.tryParse(verseStr) ?? 0;
          // If surah matches current surah and verse matches
          if (surahPart == _surahNumber && versePart == currentVerse) {
            return true;
          }
        }
      }

      // Handle range pattern (e.g., "5-10")
      if (query.contains('-')) {
        final rangeParts = query.split('-');
        if (rangeParts.length == 2) {
          final start = int.tryParse(rangeParts[0]) ?? 0;
          final end = int.tryParse(rangeParts[1]) ?? 0;
          return currentVerse >= start && currentVerse <= end;
        }
      }

      // Handle combined pattern (e.g., "2:5-10")
      if (query.contains(':') && query.contains('-')) {
        final mainParts = query.split(':');
        if (mainParts.length == 2 && mainParts[0] == _surahNumber.toString()) {
          final rangeParts = mainParts[1].split('-');
          if (rangeParts.length == 2) {
            final start = int.tryParse(rangeParts[0]) ?? 0;
            final end = int.tryParse(rangeParts[1]) ?? 0;
            return currentVerse >= start && currentVerse <= end;
          }
        }
      }
    } catch (e) {
      debugPrint('Error parsing verse number pattern: $e');
    }

    return false;
  }

  void _clearSearch() {
    _searchController.clear();
    _filterVerses('');
    setState(() {
      _showSearchBar = false;
    });
    _searchFocusNode.unfocus();
  }

  void _toggleSearch() {
    setState(() {
      _showSearchBar = !_showSearchBar;
    });

    if (_showSearchBar) {
      // Request focus after the frame is built (TextField is now in the tree)
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _searchFocusNode.requestFocus();
        }
      });
    } else {
      _searchFocusNode.unfocus();
      _clearSearch();
    }
  }

  void _showSettings() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => SurahSettingsDialog(
        language: _language,
        surahNumber: _surahNumber,
        isTafseer: _isTafseer,
      ),
    );
  }

  void _shareVerse(int verseNumber, String text, String translation) {
    final verseText = '$_surahNumber:$verseNumber\n$text\n\n$translation';
    Share.share(verseText);
  }

  void _copyVerse(int verseNumber, String text, String translation) {
    final verseText = '$_surahNumber:$verseNumber\n$text\n\n$translation';
    Clipboard.setData(ClipboardData(text: verseText));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Verse $_surahNumber:$verseNumber copied to clipboard')),
    );
  }

  void _toggleBookmark(int verseNumber, Map<String, dynamic> verseData) {
    final settingsService = Provider.of<SettingsService>(context, listen: false);
    settingsService.toggleBookmark(
      surahNumber: _surahNumber,
      verseNumber: verseNumber,
      verseData: verseData,
      language: _language,
      isTafseer: _isTafseer,
    );

    final isBookmarked = settingsService.isBookmarked(
      _surahNumber,
      verseNumber,
      _language,
      _isTafseer,
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(isBookmarked
            ? 'Verse $_surahNumber:$verseNumber bookmarked'
            : 'Bookmark removed for verse $_surahNumber:$verseNumber'),
      ),
    );
  }

  void _scrollToVerse(int verseNumber) {
    final index = _filteredVerses.indexWhere((verse) {
      // Handle different verse number field names with type coercion, prioritizing 'aya' for assamese/hindi format
      final verseId = (verse['aya'] as num?)?.toInt() ??
          (verse['verse_number'] as num?)?.toInt() ??
          (verse['id'] as num?)?.toInt();
      return verseId == verseNumber;
    });

    if (index != -1) {
      _scrollController.animateTo(
        index * 200.0, // Approximate height per verse card
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    _searchFocusNode.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settingsService = Provider.of<SettingsService>(context);
    final fontScale = settingsService.fontScale;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _surahName,
              style: TextStyle(fontSize: 18 * fontScale),
            ),
            Text(
              'Surah $_surahNumber • ${_verses.length} verses',
              style: TextStyle(fontSize: 12 * fontScale),
            ),
          ],
        ),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        elevation: 4,
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: _toggleSearch,
            tooltip: 'Search verses',
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: _showSettings,
            tooltip: 'Settings',
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          if (_showSearchBar)
            GestureDetector(
              onTap: _clearSearch,
              child: Container(
                color: Colors.transparent,
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16.0),
                      decoration: BoxDecoration(
                        color: theme.cardColor,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          TextField(
                            controller: _searchController,
                            focusNode: _searchFocusNode,
                            decoration: InputDecoration(
                              hintText: 'Search by verse number (1, 2:255, 5-10) or text...',
                              prefixIcon: _isSearching
                                  ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: Padding(
                                  padding: EdgeInsets.all(12.0),
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                ),
                              )
                                  : const Icon(Icons.search),
                              suffixIcon: _searchController.text.isNotEmpty
                                  ? IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: _clearSearch,
                              )
                                  : null,
                              filled: true,
                              fillColor: theme.scaffoldBackgroundColor,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12.0),
                                borderSide: BorderSide.none,
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16.0,
                                vertical: 12.0,
                              ),
                            ),
                          ),
                          if (_searchController.text.isNotEmpty && !_isSearching) ...[
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Text(
                                  '${_filteredVerses.length} verses found',
                                  style: TextStyle(
                                    fontSize: 12 * fontScale,
                                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                                  ),
                                ),
                                const Spacer(),
                                if (_filteredVerses.isNotEmpty)
                                  TextButton(
                                    onPressed: () {
                                      _scrollController.animateTo(
                                        0,
                                        duration: const Duration(milliseconds: 300),
                                        curve: Curves.easeInOut,
                                      );
                                    },
                                    child: Text(
                                      'Scroll to top',
                                      style: TextStyle(
                                        fontSize: 12 * fontScale,
                                        color: theme.colorScheme.primary,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            // Search tips
                            Container(
                              margin: const EdgeInsets.only(top: 8),
                              padding: const EdgeInsets.all(8.0),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primary.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.lightbulb_outline,
                                      size: 16 * fontScale,
                                      color: theme.colorScheme.primary),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Tip: Search with "verse", "surah:verse", or "start-end"',
                                      style: TextStyle(
                                        fontSize: 10 * fontScale,
                                        color: theme.colorScheme.primary,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          // Verses List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : Consumer<SettingsService>(
              builder: (context, settings, child) {
                return Container(
                  color: settings.backgroundColor,
                  child: _filteredVerses.isEmpty && _showSearchBar && _searchController.text.isNotEmpty
                      ? _buildNoResults(theme, fontScale)
                      : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16.0),
                    itemCount: _filteredVerses.length,
                    itemBuilder: (context, index) {
                      final verse = _filteredVerses[index];

                      // Handle different verse number field names with type coercion, prioritizing 'aya' for assamese/hindi format
                      final verseNumber = (verse['aya'] as num?)?.toInt() ??
                          (verse['verse_number'] as num?)?.toInt() ??
                          (verse['id'] as num?)?.toInt() ?? index + 1;

                      // Handle different text field names - For Arabic, use 'text' field
                      final arabic = verse['text'] ?? verse['arabic'] ?? '';
                      final translation = verse['translation'] ?? '';
                      final transliteration = verse['transliteration'] ?? '';
                      final tafseer = verse['tafseer'] ?? '';
                      final footnotes = verse['footnotes'] ?? '';

                      final isBookmarked = settings.isBookmarked(
                          _surahNumber,
                          verseNumber,
                          _language,
                          _isTafseer
                      );

                      return VerseCard(
                        surahNumber: _surahNumber,
                        verseNumber: verseNumber,
                        arabic: arabic,
                        translation: translation,
                        transliteration: transliteration,
                        tafseer: tafseer,
                        footnotes: footnotes,
                        language: _language,
                        isTafseer: _isTafseer,
                        isBookmarked: isBookmarked,
                        onShare: () => _shareVerse(
                            verseNumber,
                            arabic,
                            translation
                        ),
                        onCopy: () => _copyVerse(
                            verseNumber,
                            arabic,
                            translation
                        ),
                        onBookmark: () => _toggleBookmark(verseNumber, verse),
                        fontScale: fontScale,
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoResults(ThemeData theme, double fontScale) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 64 * fontScale,
              color: theme.colorScheme.onSurface.withOpacity(0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'No verses found',
              style: TextStyle(
                fontSize: 18 * fontScale,
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Try searching with different keywords or verse numbers',
              style: TextStyle(
                fontSize: 14 * fontScale,
                color: theme.colorScheme.onSurface.withOpacity(0.6),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            // Search examples
            Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Search Examples:',
                    style: TextStyle(
                      fontSize: 14 * fontScale,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildSearchExample('Verse number', '5', fontScale),
                  _buildSearchExample('Surah:Verse', '2:255', fontScale),
                  _buildSearchExample('Verse range', '5-10', fontScale),
                  _buildSearchExample('Text search', 'mercy', fontScale),
                  _buildSearchExample('Arabic text', 'الرحمن', fontScale),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchExample(String title, String example, double fontScale) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Text(
            '$title: ',
            style: TextStyle(
              fontSize: 12 * fontScale,
              fontWeight: FontWeight.w500,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              example,
              style: TextStyle(
                fontSize: 11 * fontScale,
                fontFamily: 'Monospace',
                color: Colors.blue[700],
              ),
            ),
          ),
        ],
      ),
    );
  }
}