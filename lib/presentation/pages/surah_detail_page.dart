import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/services/settings_service.dart';
import '../widgets/verse_card.dart';
import '../widgets/surah_settings_dialog.dart';
import 'tafseer_settings_dialog.dart';

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

  // Cache for additional data to avoid repeated loading
  Map<String, dynamic> _cachedData = {};

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

    if (newLanguage != _language ||
        newSurahNumber != _surahNumber ||
        newIsTafseer != _isTafseer) {
      _language = newLanguage;
      _surahNumber = newSurahNumber;
      _isTafseer = newIsTafseer;
      _cachedData.clear(); // Clear cache when changing surah or language
      _loadSurahData();
    } else if (_verses.isEmpty) {
      _loadSurahData();
    }
  }

  Future<void> _loadSurahData() async {
    setState(() {
      _isLoading = true;
      _surahName = 'Surah $_surahNumber';
    });

    try {
      // Load the main language data
      String jsonFile;
      if (_isTafseer) {
        jsonFile = 'assets/data/quran_${_language}_tafseer.json';
      } else {
        jsonFile = 'assets/data/quran_${_language}.json';
      }

      final String jsonString = await rootBundle.loadString(jsonFile);
      final dynamic rawJson = json.decode(jsonString);

      // Load Arabic data separately (for all languages except Arabic)
      List<Map<String, dynamic>> arabicVerses = [];
      if (_language != 'arabic') {
        try {
          if (!_cachedData.containsKey('arabic')) {
            final String arabicJsonString = await rootBundle.loadString('assets/data/quran_arabic.json');
            final List<dynamic> arabicRaw = json.decode(arabicJsonString);
            _cachedData['arabic'] = arabicRaw;
          }

          final List<dynamic> arabicRaw = _cachedData['arabic'];
          final surahData = arabicRaw.firstWhere(
                (s) => (s['id'] as num?)?.toInt() == _surahNumber,
            orElse: () => null,
          );

          if (surahData != null) {
            final versesList = surahData['verses'] as List?;
            arabicVerses = (versesList ?? []).map((v) => {
              'id': v['id'],
              'aya': v['id'],
              'arabic': v['text'],
            }).toList();
          }
        } catch (e) {
          debugPrint('Failed to load Arabic data: $e');
        }
      }

      // Load English transliteration data for all languages (not just English)
      List<Map<String, dynamic>> transliterationVerses = [];
      try {
        if (!_cachedData.containsKey('transliteration')) {
          final String transJsonString = await rootBundle.loadString(
            'assets/data/quran_english_transliteration.json',
          );
          final List<dynamic> transRaw = json.decode(transJsonString);
          _cachedData['transliteration'] = transRaw;
        }

        final List<dynamic> transRaw = _cachedData['transliteration'];
        transliterationVerses = transRaw
            .where((v) => (v['surah_no'] as num?)?.toInt() == _surahNumber)
            .map((v) => {
          'aya': v['verse_no'],
          'transliteration': v['verse_text'] ?? '',
        })
            .toList();
      } catch (e) {
        debugPrint('Failed to load English transliteration: $e');
      }

      // FINAL FIX: Load the primary translation text for Tafseer mode using robust logic
      Map<int, String> primaryTranslations = {};
      if (_isTafseer && _language != 'arabic') {
        try {
          final String primaryJsonString = await rootBundle.loadString('assets/data/quran_${_language}.json');
          final dynamic primaryRaw = json.decode(primaryJsonString);
          List<dynamic> verseList = [];

          // Apply the same robust logic as the regular Quran view
          if (primaryRaw is List && primaryRaw.isNotEmpty) {
            // Check if this is a flat structure with sura/surah field
            if (primaryRaw[0].containsKey('sura') || primaryRaw[0].containsKey('surah')) {
              verseList = primaryRaw.where((v) {
                final num? n = v['sura'] ?? v['surah'];
                return n?.toInt() == _surahNumber;
              }).toList();
            }
            // Check if this is a nested structure with verses field
            else if (primaryRaw[0].containsKey('verses')) {
              final surahData = primaryRaw.firstWhere(
                    (s) => (s['id'] as num?)?.toInt() == _surahNumber,
                orElse: () => null,
              );
              if (surahData != null) {
                verseList = surahData['verses'] as List;
              }
            }
          }

          // Sort the verses to ensure correct mapping
          if (verseList.isNotEmpty && (verseList[0].containsKey('aya') || verseList[0].containsKey('id'))) {
            verseList.sort((a, b) {
              final aVerse = (a['aya'] ?? a['id']) as num?;
              final bVerse = (b['aya'] ?? b['id']) as num?;
              return aVerse?.toInt().compareTo(bVerse?.toInt() ?? 0) ?? 0;
            });
          }

          for(final v in verseList) {
            final id = (v['id'] as num?)?.toInt() ?? (v['aya'] as num?)?.toInt() ?? 0;
            String text = '';
            if (_language == 'bengali') {
              text = v['bengali'] ?? v['translation'] ?? v['text'] ?? '';
            } else if (_language == 'hindi') {
              text = v['hindi'] ?? v['translation'] ?? v['text'] ?? '';
            } else if (_language == 'assamese') {
              text = v['assamese'] ?? v['translation'] ?? v['text'] ?? '';
            } else {
              text = v['translation'] ?? v['text'] ?? '';
            }
            if(id > 0) primaryTranslations[id] = text;
          }
        } catch (e) {
          debugPrint('Failed to load primary translation for Tafseer: $e');
        }
      }

      List<Map<String, dynamic>> verses = [];

      if (_isTafseer) {
        // CORRECTED Tafseer handling
        if (rawJson is Map<String, dynamic>) {
          final tafseerMap = rawJson as Map<String, dynamic>;
          final foundVerses = <Map<String, dynamic>>[];

          for (int v = 1; v <= 286; v++) {
            final key = '$_surahNumber:$v';
            if (tafseerMap.containsKey(key)) {
              final value = tafseerMap[key];
              final text = value is Map ? value['text'] : value.toString();
              if (text.isNotEmpty) {
                // CORRECTED: Find corresponding data instead of using empty strings
                String arabicText = '';
                String translationText = '';
                String transliterationText = '';

                // Get Arabic text
                if (_language != 'arabic') {
                  final arabicMatch = arabicVerses.firstWhere((a) => a['id'] == v, orElse: () => {'arabic': ''});
                  arabicText = arabicMatch['arabic'] as String;
                }

                // Get Translation text from our new robust map
                translationText = primaryTranslations[v] ?? '';

                // Get Transliteration text
                final transMatch = transliterationVerses.firstWhere((t) => t['aya'] == v, orElse: () => {'transliteration': ''});
                transliterationText = transMatch['transliteration'] as String;

                foundVerses.add({
                  'id': v,
                  'aya': v,
                  'arabic': arabicText,
                  'translation': translationText,
                  'transliteration': transliterationText,
                  'tafseer': text,
                  'footnotes': '',
                });
              }
            }
          }
          verses = foundVerses;
        }
      } else if (_language == 'arabic') {
        // Arabic handling (unchanged)
        if (rawJson is List) {
          final surahData = rawJson.firstWhere(
                (s) => (s['id'] as num?)?.toInt() == _surahNumber,
            orElse: () => null,
          );
          if (surahData != null) {
            _surahName = surahData['name'] ?? 'سورة $_surahNumber';
            final versesList = surahData['verses'] as List?;
            verses = (versesList ?? []).map((v) {
              final arabicText = v['text'] ?? '';
              return {
                'id': v['id'],
                'aya': v['id'],
                'arabic': arabicText,
                'translation': arabicText,
                'transliteration': '',
                'tafseer': v['tafseer'] ?? '',
              };
            }).toList();
          }
        }
      } else {
        // All other languages (including English, Bengali, Hindi, Assamese)
        List<dynamic> verseList = [];

        // Handle different JSON structures
        if (rawJson is List) {
          if (rawJson.isNotEmpty) {
            // Check if this is a flat structure with sura/surah field
            if (rawJson[0].containsKey('sura') || rawJson[0].containsKey('surah')) {
              verseList = rawJson.where((v) {
                final num? n = v['sura'] ?? v['surah'];
                return n?.toInt() == _surahNumber;
              }).toList();
            }
            // Check if this is a nested structure with verses field
            else if (rawJson[0].containsKey('verses')) {
              final surahData = rawJson.firstWhere(
                    (s) => (s['id'] as num?)?.toInt() == _surahNumber,
                orElse: () => null,
              );
              if (surahData != null) {
                verseList = surahData['verses'] as List;
                _surahName = surahData['translation'] ??
                    surahData['name'] ??
                    surahData['bengali'] ??
                    surahData['hindi'] ??
                    surahData['assamese'] ??
                    'Surah $_surahNumber';
              }
            }
            // Handle the case where it's a direct list of surahs
            else {
              final surahData = rawJson.firstWhere(
                    (s) => (s['id'] as num?)?.toInt() == _surahNumber,
                orElse: () => null,
              );
              if (surahData != null) {
                verseList = surahData['verses'] as List;
                _surahName = surahData['translation'] ??
                    surahData['name'] ??
                    surahData['bengali'] ??
                    surahData['hindi'] ??
                    surahData['assamese'] ??
                    'Surah $_surahNumber';
              }
            }
          }
        }

        if (verseList.isEmpty) throw Exception('No verses found');

        // FIXED: Sort verses by their actual verse number, not by their position in the list
        if (verseList.isNotEmpty && (verseList[0].containsKey('aya') || verseList[0].containsKey('id'))) {
          verseList.sort((a, b) {
            final aVerse = (a['aya'] ?? a['id']) as num?;
            final bVerse = (b['aya'] ?? b['id']) as num?;
            return aVerse?.toInt().compareTo(bVerse?.toInt() ?? 0) ?? 0;
          });
        }

        verses = verseList.asMap().entries.map((entry) {
          final index = entry.key;
          final v = entry.value;
          final map = Map<String, dynamic>.from(v);

          // FIXED: Get verse ID and ensure it's correct for the current surah
          // For English, Assamese, and Hindi, we need to use the actual verse number from the data
          // not the index position
          int verseId;
          if (map.containsKey('aya') && map['aya'] != null) {
            verseId = (map['aya'] as num?)?.toInt() ?? 0;
          } else if (map.containsKey('id') && map['id'] != null) {
            verseId = (map['id'] as num?)?.toInt() ?? 0;
          } else {
            // If no verse number is found, use index + 1 as fallback
            verseId = index + 1;
          }

          // Set Arabic from separate Arabic data (not from Bengali JSON)
          String arabicText = '';
          if (arabicVerses.isNotEmpty) {
            final arabicMatch = arabicVerses.firstWhere(
                  (a) => a['id'] == verseId,
              orElse: () => {'arabic': ''},
            );
            arabicText = arabicMatch['arabic'] as String;
          }
          map['arabic'] = arabicText;

          // Translation (special handling for Bengali, Hindi, Assamese)
          if (_language == 'bengali') {
            map['translation'] = map['bengali'] ?? map['translation'] ?? map['text'] ?? '';
          } else if (_language == 'hindi') {
            map['translation'] = map['hindi'] ?? map['translation'] ?? map['text'] ?? '';
          } else if (_language == 'assamese') {
            map['translation'] = map['assamese'] ?? map['translation'] ?? map['text'] ?? '';
          } else {
            map['translation'] = map['translation'] ?? '';
          }

          // FIXED: Ensure ID and aya are correctly set to the verse number
          map['id'] = verseId;
          map['aya'] = verseId;

          // Transliteration (from English transliteration data)
          if (transliterationVerses.isNotEmpty) {
            final match = transliterationVerses.firstWhere(
                  (t) => t['aya'] == verseId,
              orElse: () => {'transliteration': ''},
            );
            map['transliteration'] = match['transliteration'] as String;
          } else {
            map['transliteration'] = '';
          }

          map['tafseer'] = '';
          map['footnotes'] = '';

          return map;
        }).toList();
      }

      setState(() {
        _verses = verses;
        _filteredVerses = List.from(verses);
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading surah: $e');
      _createFallbackData();
    }
  }

  void _createFallbackData() {
    setState(() {
      _surahName = _isTafseer ? 'Surah $_surahNumber (Tafseer)' : 'Surah $_surahNumber';
      _verses = List.generate(7, (i) => {
        'id': i + 1,
        'aya': i + 1,
        'arabic': 'بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ',
        'translation': _isTafseer
            ? 'Tafseer data could not be loaded.'
            : 'In the name of Allah, the Most Gracious, the Most Merciful.',
        'transliteration': 'Bismillahir Rahmanir Rahim',
        'tafseer': _isTafseer ? 'Example tafseer text.' : '',
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
    setState(() => _isSearching = true);

    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      final results = _verses.where((verse) {
        final verseNumber = (verse['aya'] as num?)?.toInt() ??
            (verse['id'] as num?)?.toInt() ?? 0;
        final text = (verse['text'] ?? verse['arabic'] ?? '').toString().toLowerCase();
        final translation = (verse['translation'] ?? '').toString().toLowerCase();
        final transliteration = (verse['transliteration'] ?? '').toString().toLowerCase();
        final tafseer = (verse['tafseer'] ?? '').toString().toLowerCase();
        final q = query.toLowerCase().trim();

        if (_isVerseNumberPattern(q)) return _matchesVerseNumberPattern(verseNumber.toString(), q);

        return text.contains(q) ||
            translation.contains(q) ||
            transliteration.contains(q) ||
            tafseer.contains(q) ||
            verseNumber.toString().contains(q);
      }).toList();

      if (mounted) {
        setState(() {
          _filteredVerses = results;
          _isSearching = false;
        });
      }
    });
  }

  bool _isVerseNumberPattern(String q) => RegExp(r'^(\d+)[:-]?(\d+)?[-:]?(\d+)?$').hasMatch(q);

  bool _matchesVerseNumberPattern(String v, String q) {
    try {
      final cv = int.tryParse(v) ?? 0;
      if (RegExp(r'^\d+$').hasMatch(q)) return cv == (int.tryParse(q) ?? 0);
      if (q.contains(':')) {
        final p = q.split(':');
        if (p.length == 2) {
          final sp = int.tryParse(p[0]) ?? 0;
          final vp = int.tryParse(p[1].trim()) ?? 0;
          if (p[1].trim().isEmpty) return sp == _surahNumber;
          return sp == _surahNumber && vp == cv;
        }
      }
      if (q.contains('-')) {
        final p = q.split('-');
        if (p.length == 2) {
          final s = int.tryParse(p[0]) ?? 0;
          final e = int.tryParse(p[1]) ?? 0;
          return cv >= s && cv <= e;
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
      WidgetsBinding.instance.addPostFrameCallback((_) => _searchFocusNode.requestFocus());
    } else {
      _clearSearch();
    }
  }

  void _showSettings() {
    // Use different dialog based on whether we're in Tafseer mode
    if (_isTafseer) {
      showGeneralDialog(
        context: context,
        barrierLabel: 'Tafseer Settings',
        barrierDismissible: true,
        barrierColor: Colors.black.withOpacity(0.5),
        transitionDuration: const Duration(milliseconds: 400),
        // CORRECTED: Wrap the dialog in a Consumer to provide the SettingsService
        pageBuilder: (context, animation, secondaryAnimation) {
          return Consumer<SettingsService>(
            builder: (context, settingsService, child) {
              return TafseerSettingsDialog(
                language: _language,
              );
            },
          );
        },
        transitionBuilder: (context, animation, secondaryAnimation, child) {
          // Elastic scale animation
          final scaleAnimation = Tween<double>(
            begin: 0.5,
            end: 1.0,
          ).animate(
            CurvedAnimation(
              parent: animation,
              curve: Curves.elasticOut,
            ),
          );

          // Fade animation
          final fadeAnimation = Tween<double>(
            begin: 0.0,
            end: 1.0,
          ).animate(
            CurvedAnimation(
              parent: animation,
              curve: const Interval(0.3, 1.0, curve: Curves.easeOut),
            ),
          );

          return FadeTransition(
            opacity: fadeAnimation,
            child: ScaleTransition(
              scale: scaleAnimation,
              child: child,
            ),
          );
        },
      );
    } else {
      showGeneralDialog(
        context: context,
        barrierLabel: 'Settings',
        barrierDismissible: true,
        barrierColor: Colors.black.withOpacity(0.5),
        transitionDuration: const Duration(milliseconds: 400),
        pageBuilder: (context, animation, secondaryAnimation) {
          return SurahSettingsDialog(
            language: _language,
            isTafseerMode: _isTafseer,
          );
        },
        transitionBuilder: (context, animation, secondaryAnimation, child) {
          // Elastic scale animation
          final scaleAnimation = Tween<double>(
            begin: 0.5,
            end: 1.0,
          ).animate(
            CurvedAnimation(
              parent: animation,
              curve: Curves.elasticOut,
            ),
          );

          // Fade animation
          final fadeAnimation = Tween<double>(
            begin: 0.0,
            end: 1.0,
          ).animate(
            CurvedAnimation(
              parent: animation,
              curve: const Interval(0.3, 1.0, curve: Curves.easeOut),
            ),
          );

          return FadeTransition(
            opacity: fadeAnimation,
            child: ScaleTransition(
              scale: scaleAnimation,
              child: child,
            ),
          );
        },
      );
    }
  }

  void _shareVerse(int verseNumber, String arabic, String translation) {
    final prefix = 'Surah $_surahNumber:$verseNumber';
    final text = _isTafseer ? '$prefix\n\n$translation' : '$prefix\n$arabic\n\n$translation';
    Share.share(text);
  }

  void _copyVerse(int verseNumber, String arabic, String translation) {
    final prefix = 'Surah $_surahNumber:$verseNumber';
    final text = _isTafseer ? '$prefix\n\n$translation' : '$prefix\n$arabic\n\n$translation';
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Verse copied')));
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
    final bool booked = settings.isBookmarked(_surahNumber, verseNumber, _language, _isTafseer);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(booked ? 'Bookmarked' : 'Bookmark removed')),
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
    final settings = Provider.of<SettingsService>(context);
    final fontScale = settings.fontScale;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_surahName, style: TextStyle(fontSize: 18 * fontScale)),
            Text('Surah $_surahNumber • ${_verses.length} verses',
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
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: theme.cardColor, boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4, offset: const Offset(0, 2))
              ]),
              child: TextField(
                controller: _searchController,
                focusNode: _searchFocusNode,
                decoration: InputDecoration(
                  hintText: 'Search by verse number (1, 2:255, 5-10) or text...',
                  prefixIcon: _isSearching
                      ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.search),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(icon: const Icon(Icons.clear), onPressed: _clearSearch)
                      : null,
                  filled: true,
                  fillColor: theme.scaffoldBackgroundColor,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
              ),
            ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : Consumer<SettingsService>(builder: (context, settings, child) {
              return Container(
                color: settings.backgroundColor,
                child: _filteredVerses.isEmpty && _showSearchBar && _searchController.text.isNotEmpty
                    ? _buildNoResults(theme, fontScale)
                    : ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: _filteredVerses.length,
                  itemBuilder: (context, i) {
                    final verse = _filteredVerses[i];
                    final vn = (verse['aya'] as num?)?.toInt() ?? (verse['id'] as num?)?.toInt() ?? i + 1;
                    final arabic = verse['arabic'] ?? verse['text'] ?? '';
                    final translation = verse['translation'] ?? '';
                    final transliteration = verse['transliteration'] ?? '';
                    final tafseer = verse['tafseer'] ?? '';
                    final footnotes = verse['footnotes'] ?? '';

                    final booked = settings.isBookmarked(_surahNumber, vn, _language, _isTafseer);

                    return VerseCard(
                      surahNumber: _surahNumber,
                      verseNumber: vn,
                      arabic: arabic,
                      translation: translation,
                      transliteration: transliteration,
                      tafseer: tafseer,
                      footnotes: footnotes,
                      language: _language,
                      isTafseer: _isTafseer,
                      isBookmarked: booked,
                      onShare: () => _shareVerse(vn, arabic, translation),
                      onCopy: () => _copyVerse(vn, arabic, translation),
                      onBookmark: () => _toggleBookmark(vn, verse),
                      fontScale: fontScale,
                      // Pass cached data to avoid repeated loading
                      cachedData: _cachedData,
                    );
                  },
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildNoResults(ThemeData theme, double fontScale) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 64 * fontScale, color: theme.colorScheme.onSurface.withOpacity(0.3)),
            const SizedBox(height: 16),
            Text('No verses found',
                style: TextStyle(fontSize: 18 * fontScale, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('Try searching with different keywords or verse numbers',
                style: TextStyle(fontSize: 14 * fontScale), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}