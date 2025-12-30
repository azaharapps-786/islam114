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
    _searchController.addListener(() {
      _filterVerses(_searchController.text);
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final newLanguage = args?['language'] ?? 'english';
    final newSurahNumber = args?['surahNumber'] ?? 1;
    final newIsTafseer = args?['isTafseer'] ?? false;

    debugPrint('SurahDetailPage args: language=$newLanguage, surah=$newSurahNumber, isTafseer=$newIsTafseer');

    if (newLanguage != _language ||
        newSurahNumber != _surahNumber ||
        newIsTafseer != _isTafseer) {
      _language = newLanguage;
      _surahNumber = newSurahNumber;
      _isTafseer = newIsTafseer;
      _loadSurahData();
    } else if (_verses.isEmpty) {
      _loadSurahData();
    }
  }

  Future<void> _loadSurahData() async {
    setState(() {
      _isLoading = true;
      _surahName = 'সূরা $_surahNumber';
    });

    try {
      String jsonFile;
      if (_isTafseer) {
        jsonFile = 'assets/data/quran_${_language}_tafseer.json';
      } else {
        jsonFile = 'assets/data/quran_${_language}.json';
      }

      debugPrint('=== LOADING SURAH DATA ===');
      debugPrint('Language: $_language');
      debugPrint('Surah: $_surahNumber');
      debugPrint('Is Tafseer: $_isTafseer');
      debugPrint('Attempting to load file: $jsonFile');

      final String jsonString = await rootBundle.loadString(jsonFile);
      debugPrint('File loaded successfully! Size: ${jsonString.length} characters');

      final dynamic rawJson = json.decode(jsonString);
      debugPrint('JSON decoded. Type: ${rawJson.runtimeType}');

      List<Map<String, dynamic>> verses = [];

      if (_isTafseer) {
        debugPrint('Processing as TAFSEER (expecting Map with "1:1" keys)');

        if (rawJson is Map<String, dynamic>) {
          final Map<String, dynamic> tafseerMap = rawJson;
          final List<Map<String, dynamic>> foundVerses = [];

          debugPrint('Tafseer map contains ${tafseerMap.length} total keys');

          for (int verseNum = 1; verseNum <= 286; verseNum++) {
            final String key = '$_surahNumber:$verseNum';
            if (tafseerMap.containsKey(key)) {
              final dynamic value = tafseerMap[key];
              String tafseerText = '';

              if (value is Map && value['text'] is String) {
                tafseerText = value['text'];
              } else if (value is String) {
                tafseerText = value;
              }

              if (tafseerText.isNotEmpty) {
                foundVerses.add({
                  'id': verseNum,
                  'aya': verseNum,
                  'arabic': '',
                  'translation': '',
                  'transliteration': '',
                  'tafseer': tafseerText,
                  'footnotes': '',
                });
              }
            }
          }

          debugPrint('Found ${foundVerses.length} tafseer verses for Surah $_surahNumber');

          if (foundVerses.isEmpty) {
            throw Exception('No tafseer verses found for this surah');
          }

          verses = foundVerses;
        } else {
          throw Exception('Invalid tafseer format - expected Map, got ${rawJson.runtimeType}');
        }
      }
      // Arabic special case
      else if (_language == 'arabic') {
        debugPrint('Processing as ARABIC (special surah-per-object format)');

        if (rawJson is List) {
          final jsonData = rawJson;
          final surahData = jsonData.firstWhere(
                (surah) => (surah['id'] as num?)?.toInt() == _surahNumber,
            orElse: () => null,
          );

          if (surahData != null) {
            _surahName = surahData['name'] ?? 'سورة $_surahNumber';
            final versesList = surahData['verses'] as List?;
            final rawVerses = versesList?.map((v) => Map<String, dynamic>.from(v)).toList() ?? [];

            verses = rawVerses.map((verse) {
              final String arabicText = verse['text'] ?? '';
              return {
                'id': verse['id'],
                'text': arabicText,
                'arabic': arabicText,
                'translation': _isTafseer ? '' : arabicText,
                'transliteration': '',
                'footnotes': '',
                'tafseer': verse['tafseer'] ?? '',
              };
            }).toList();

            debugPrint('Loaded ${verses.length} Arabic verses');
          } else {
            throw Exception('Arabic surah not found');
          }
        } else {
          throw Exception('Arabic JSON expected List, got ${rawJson.runtimeType}');
        }
      }
      // ==================== Other Languages (Support both formats) ====================
      else {
        debugPrint('Processing as NORMAL TRANSLATION');

        List<dynamic> verseList = [];

        if (rawJson is List) {
          // Case 1: Flat list format (Assamese, English, Hindi, etc.)
          if (rawJson.isNotEmpty && (rawJson[0].containsKey('sura') || rawJson[0].containsKey('surah'))) {
            verseList = rawJson.where((verse) {
              final int? suraNum = (verse['sura'] as num?)?.toInt() ??
                  (verse['surah'] as num?)?.toInt();
              return suraNum == _surahNumber;
            }).toList();
            debugPrint('Flat list format detected. Found ${verseList.length} verses');
          }
          // Case 2: Nested surah format (Bengali style)
          else if (rawJson.isNotEmpty && rawJson[0].containsKey('verses')) {
            final surahData = rawJson.firstWhere(
                  (surah) => (surah['id'] as num?)?.toInt() == _surahNumber,
              orElse: () => null,
            );

            if (surahData != null) {
              verseList = surahData['verses'] as List;
              _surahName = surahData['translation'] ?? 'সূরা $_surahNumber';
              debugPrint('Nested Bengali format detected. Found ${verseList.length} verses');
            }
          }
        }

        if (verseList.isEmpty) {
          throw Exception('No verses found for surah $_surahNumber in $_language');
        }

        verses = verseList.map((v) {
          final Map<String, dynamic> verseMap = Map<String, dynamic>.from(v);

          // For Bengali: Force hide Arabic, only show Bengali translation
          if (_language == 'bengali') {
            verseMap['arabic'] = '';  // Hide Arabic
            verseMap['translation'] = verseMap['translation'] ?? '';
          } else {
            // For other languages: normal behavior
            verseMap['arabic'] = verseMap['text'] ?? verseMap['arabic'] ?? '';
            verseMap['translation'] = verseMap['translation'] ?? '';
          }

          verseMap['id'] = verseMap['id'] ?? verseMap['aya'];
          verseMap['transliteration'] = verseMap['transliteration'] ?? '';
          verseMap['tafseer'] = '';
          verseMap['footnotes'] = '';

          return verseMap;
        }).toList();
      }

      setState(() {
        _verses = verses;
        _filteredVerses = List.from(verses);
        _isLoading = false;
      });

      debugPrint('SUCCESS: Loaded ${_verses.length} verses for display');
    } catch (e, stackTrace) {
      debugPrint('=== ERROR LOADING SURAH DATA ===');
      debugPrint('Language: $_language | Surah: $_surahNumber | Tafseer: $_isTafseer');
      debugPrint('Error: $e');
      debugPrint('Stack trace: $stackTrace');
      _createFallbackData();
    }
  }

  void _createFallbackData() {
    setState(() {
      _surahName = _isTafseer ? 'সূরা $_surahNumber (তাফসীর)' : 'Surah $_surahNumber';
      _verses = List.generate(7, (index) => {
        'id': index + 1,
        'aya': index + 1,
        'arabic': 'বিসমিল্লাহির রাহমানির রাহীম',
        'translation': _isTafseer
            ? 'তাফসীর ডাটা লোড হৈছে নাই।'
            : 'In the name of Allah, the Most Gracious, the Most Merciful.',
        'transliteration': 'Bismillahir Rahmanir Rahim',
        'tafseer': _isTafseer ? 'উদাহৰণ তাফসীর টেক্সট।' : '',
      });
      _filteredVerses = List.from(_verses);
      _isLoading = false;
    });
    debugPrint('FALLBACK DATA loaded (7 verses)');
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
    setState(() => _isSearching = true);

    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      final results = _verses.where((verse) {
        final verseNumber = (verse['aya'] as num?)?.toInt() ??
            (verse['id'] as num?)?.toInt() ?? 0;
        final text = (verse['text'] ?? verse['arabic'] ?? '').toString().toLowerCase();
        final translation = (verse['translation'] ?? '').toString().toLowerCase();
        final transliteration = (verse['transliteration'] ?? '').toString().toLowerCase();
        final tafseer = (verse['tafseer'] ?? '').toString().toLowerCase();
        final searchQuery = query.toLowerCase().trim();

        if (_isVerseNumberPattern(searchQuery)) {
          return _matchesVerseNumberPattern(verseNumber.toString(), searchQuery);
        }

        return text.contains(searchQuery) ||
            translation.contains(searchQuery) ||
            transliteration.contains(searchQuery) ||
            tafseer.contains(searchQuery) ||
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

  bool _isVerseNumberPattern(String query) =>
      RegExp(r'^(\d+)[:-]?(\d+)?[-:]?(\d+)?$').hasMatch(query);

  bool _matchesVerseNumberPattern(String verseNumber, String query) {
    try {
      final currentVerse = int.tryParse(verseNumber) ?? 0;
      if (RegExp(r'^\d+$').hasMatch(query)) {
        return currentVerse == (int.tryParse(query) ?? 0);
      }
      if (query.contains(':')) {
        final parts = query.split(':');
        if (parts.length == 2) {
          final surahPart = int.tryParse(parts[0]) ?? 0;
          final versePart = int.tryParse(parts[1].trim()) ?? 0;
          if (parts[1].trim().isEmpty) return surahPart == _surahNumber;
          return surahPart == _surahNumber && versePart == currentVerse;
        }
      }
      if (query.contains('-')) {
        final parts = query.split('-');
        if (parts.length == 2) {
          final start = int.tryParse(parts[0]) ?? 0;
          final end = int.tryParse(parts[1]) ?? 0;
          return currentVerse >= start && currentVerse <= end;
        }
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  void _clearSearch() {
    _searchController.clear();
    _filterVerses('');
    setState(() => _showSearchBar = false);
    _searchFocusNode.unfocus();
  }

  void _toggleSearch() {
    setState(() => _showSearchBar = !_showSearchBar);
    if (_showSearchBar) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _searchFocusNode.requestFocus();
      });
    } else {
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

  void _shareVerse(int verseNumber, String arabic, String translation) {
    final text = _isTafseer
        ? 'সূরা $_surahNumber:$verseNumber\n\n$translation'
        : '$_surahNumber:$verseNumber\n$arabic\n\n$translation';
    Share.share(text);
  }

  void _copyVerse(int verseNumber, String arabic, String translation) {
    final text = _isTafseer
        ? 'সূরা $_surahNumber:$verseNumber\n\n$translation'
        : '$_surahNumber:$verseNumber\n$arabic\n\n$translation';
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('আয়াত কপি কৰা হৈছে')),
    );
  }

  void _toggleBookmark(int verseNumber, Map<String, dynamic> verseData) {
    final settings = Provider.of<SettingsService>(context, listen: false);
    settings.toggleBookmark(
      surahNumber: _surahNumber,
      verseNumber: verseNumber,
      verseData: verseData,
      language: _language,
      isTafseer: _isTafseer,
    );
    final isBookmarked = settings.isBookmarked(_surahNumber, verseNumber, _language, _isTafseer);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(isBookmarked ? 'বুকমাৰ্ক কৰা হৈছে' : 'বুকমাৰ্ক আঁতৰোৱা হৈছে')),
    );
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
            Text(_surahName, style: TextStyle(fontSize: 18 * fontScale)),
            Text('সূরা $_surahNumber • ${_verses.length} আয়াত',
                style: TextStyle(fontSize: 12 * fontScale)),
          ],
        ),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: Colors.white,
        elevation: 4,
        actions: [
          IconButton(icon: const Icon(Icons.search), onPressed: _toggleSearch),
          IconButton(icon: const Icon(Icons.settings), onPressed: _showSettings),
        ],
      ),
      body: Column(
        children: [
          if (_showSearchBar)
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
                          ? IconButton(icon: const Icon(Icons.clear), onPressed: _clearSearch)
                          : null,
                      filled: true,
                      fillColor: theme.scaffoldBackgroundColor,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.0),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                    ),
                  ),
                  if (_searchController.text.isNotEmpty && !_isSearching) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Text('${_filteredVerses.length} verses found',
                            style: TextStyle(fontSize: 12 * fontScale, color: theme.colorScheme.onSurface.withOpacity(0.6))),
                        const Spacer(),
                        if (_filteredVerses.isNotEmpty)
                          TextButton(
                            onPressed: () => _scrollController.animateTo(0, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut),
                            child: Text('Scroll to top', style: TextStyle(fontSize: 12 * fontScale, color: theme.colorScheme.primary)),
                          ),
                      ],
                    ),
                    Container(
                      margin: const EdgeInsets.only(top: 8),
                      padding: const EdgeInsets.all(8.0),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.lightbulb_outline, size: 16 * fontScale, color: theme.colorScheme.primary),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text('Tip: Search with "verse", "surah:verse", or "start-end"',
                                style: TextStyle(fontSize: 10 * fontScale, color: theme.colorScheme.primary)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),

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
                      final verseNumber = (verse['aya'] as num?)?.toInt() ??
                          (verse['id'] as num?)?.toInt() ??
                          index + 1;

                      final arabic = verse['arabic'] ?? verse['text'] ?? '';
                      final translation = verse['translation'] ?? '';
                      final transliteration = verse['transliteration'] ?? '';
                      final tafseer = verse['tafseer'] ?? '';
                      final footnotes = verse['footnotes'] ?? '';

                      final isBookmarked = settings.isBookmarked(
                          _surahNumber, verseNumber, _language, _isTafseer);

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
                        onShare: () => _shareVerse(verseNumber, arabic, translation),
                        onCopy: () => _copyVerse(verseNumber, arabic, translation),
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
            Icon(Icons.search_off, size: 64 * fontScale, color: theme.colorScheme.onSurface.withOpacity(0.3)),
            const SizedBox(height: 16),
            Text('No verses found',
                style: TextStyle(fontSize: 18 * fontScale, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface.withOpacity(0.6))),
            const SizedBox(height: 8),
            Text('Try searching with different keywords or verse numbers',
                style: TextStyle(fontSize: 14 * fontScale, color: theme.colorScheme.onSurface.withOpacity(0.6)),
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}