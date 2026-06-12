import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:islam114/main.dart';

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

  bool _isJumping = false;

  Map<String, dynamic> _cachedData = {};

  static final Map<String, double> _scrollPositions = {};

  final Map<int, GlobalKey> _verseKeys = {};

  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();

    _scrollController.addListener(() {
      if (_scrollController.hasClients && _surahNumber > 0) {
        if (!_isJumping) {
          _scrollPositions['$_surahNumber$_language$_isTafseer'] =
              _scrollController.offset;
        }
      }
    });

    _searchController.addListener(() {
      _filterVerses(_searchController.text);
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final args =
    ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final newLanguage = args?['language'] ?? 'english';
    final newSurahNumber = args?['surahNumber'] ?? 1;
    final newIsTafseer = args?['isTafseer'] ?? false;

    if (newLanguage != _language || newIsTafseer != _isTafseer) {
      _language = newLanguage;
      _isTafseer = newIsTafseer;
      _cachedData.clear();
      _verseKeys.clear();

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          Provider.of<SettingsService>(context, listen: false)
              .refreshDisplaySettings();
        }
      });

      _loadSurahData();
    } else if (newSurahNumber != _surahNumber) {
      _surahNumber = newSurahNumber;
      _verseKeys.clear();
      _loadSurahData();
    } else if (_verses.isEmpty) {
      _loadSurahData();
    }
  }

  Future<void> _loadSurahData() async {
    setState(() {
      _surahName = 'Surah $_surahNumber';
    });

    try {
      final mainKey = QuranDataCache.key(_language, _isTafseer);
      dynamic rawJson = QuranDataCache.jsonCache[mainKey];

      if (rawJson == null) {
        final jsonFile = _isTafseer
            ? 'assets/data/quran_${_language}_tafseer.json'
            : 'assets/data/quran_${_language}.json';
        final String jsonString = await rootBundle.loadString(jsonFile);
        rawJson = json.decode(jsonString);
        QuranDataCache.jsonCache[mainKey] = rawJson;
      }

      List<Map<String, dynamic>> arabicVerses = [];
      if (_language != 'arabic') {
        try {
          dynamic arabicRaw = QuranDataCache.jsonCache['arabic'];
          if (arabicRaw == null) {
            final String arabicJsonString =
            await rootBundle.loadString('assets/data/quran_arabic.json');
            arabicRaw = json.decode(arabicJsonString);
            QuranDataCache.jsonCache['arabic'] = arabicRaw;
          }
          _cachedData['arabic'] = arabicRaw;

          final List<dynamic> arabicList = arabicRaw as List<dynamic>;
          final surahData = arabicList.firstWhere(
                (s) => (s['id'] as num?)?.toInt() == _surahNumber,
            orElse: () => null,
          );

          if (surahData != null) {
            final versesList = surahData['verses'] as List?;
            arabicVerses = (versesList ?? [])
                .map((v) => {
              'id': v['id'],
              'aya': v['id'],
              'arabic': v['text'],
            })
                .toList();
          }
        } catch (e) {
          debugPrint('Failed to load Arabic data: $e');
        }
      }

      List<Map<String, dynamic>> transliterationVerses = [];
      try {
        dynamic transRaw = QuranDataCache.jsonCache['transliteration'];
        if (transRaw == null) {
          final String transJsonString = await rootBundle.loadString(
            'assets/data/quran_english_transliteration.json',
          );
          transRaw = json.decode(transJsonString);
          QuranDataCache.jsonCache['transliteration'] = transRaw;
        }
        _cachedData['transliteration'] = transRaw;

        final List<dynamic> transList = transRaw as List<dynamic>;
        transliterationVerses = transList
            .where((v) => (v['surah_no'] as num?)?.toInt() == _surahNumber)
            .map((v) => {
          'aya': v['verse_no'],
          'transliteration': v['verse_text'] ?? '',
        })
            .toList();
      } catch (e) {
        debugPrint('Failed to load English transliteration: $e');
      }

      Map<int, String> primaryTranslations = {};
      if (_isTafseer && _language != 'arabic') {
        try {
          final primaryCacheKey = QuranDataCache.key(_language, false);
          dynamic primaryRaw = QuranDataCache.jsonCache[primaryCacheKey];

          if (primaryRaw == null) {
            final String primaryJsonFile =
                'assets/data/quran_${_language}.json';
            final String primaryJsonString =
            await rootBundle.loadString(primaryJsonFile);
            primaryRaw = json.decode(primaryJsonString);
            QuranDataCache.jsonCache[primaryCacheKey] = primaryRaw;
          }

          List<dynamic> verseList = [];

          if (primaryRaw is List && primaryRaw.isNotEmpty) {
            if (primaryRaw[0].containsKey('sura') ||
                primaryRaw[0].containsKey('surah')) {
              verseList = primaryRaw.where((v) {
                final num? n = v['sura'] ?? v['surah'];
                return n?.toInt() == _surahNumber;
              }).toList();
            } else if (primaryRaw[0].containsKey('verses')) {
              final surahData = primaryRaw.firstWhere(
                    (s) => (s['id'] as num?)?.toInt() == _surahNumber,
                orElse: () => null,
              );
              if (surahData != null) {
                verseList = surahData['verses'] as List;
              }
            }
          }

          if (verseList.isNotEmpty &&
              (verseList[0].containsKey('aya') ||
                  verseList[0].containsKey('id'))) {
            verseList.sort((a, b) {
              final aVerse = (a['aya'] ?? a['id']) as num?;
              final bVerse = (b['aya'] ?? b['id']) as num?;
              return aVerse?.toInt().compareTo(bVerse?.toInt() ?? 0) ?? 0;
            });
          }

          for (final v in verseList) {
            final id = (v['id'] as num?)?.toInt() ??
                (v['aya'] as num?)?.toInt() ??
                0;
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
            if (id > 0) primaryTranslations[id] = text;
          }
        } catch (e) {
          debugPrint('Failed to load primary translation for Tafseer: $e');
        }
      }

      List<Map<String, dynamic>> verses = [];

      if (_isTafseer) {
        if (rawJson is Map<String, dynamic>) {
          final tafseerMap = rawJson;
          final foundVerses = <Map<String, dynamic>>[];

          for (int v = 1; v <= 286; v++) {
            final key = '$_surahNumber:$v';
            if (tafseerMap.containsKey(key)) {
              final value = tafseerMap[key];
              final text =
              value is Map ? value['text'] : value.toString();
              if (text.isNotEmpty) {
                String arabicText = '';
                String translationText = '';
                String transliterationText = '';

                if (_language != 'arabic') {
                  final arabicMatch = arabicVerses.firstWhere(
                          (a) => a['id'] == v,
                      orElse: () => {'arabic': ''});
                  arabicText = arabicMatch['arabic'] as String;
                }

                translationText = primaryTranslations[v] ?? '';

                final transMatch = transliterationVerses.firstWhere(
                        (t) => t['aya'] == v,
                    orElse: () => {'transliteration': ''});
                transliterationText =
                transMatch['transliteration'] as String;

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
        List<dynamic> verseList = [];

        if (rawJson is List) {
          if (rawJson.isNotEmpty) {
            if (rawJson[0].containsKey('sura') ||
                rawJson[0].containsKey('surah')) {
              verseList = rawJson.where((v) {
                final num? n = v['sura'] ?? v['surah'];
                return n?.toInt() == _surahNumber;
              }).toList();
            } else if (rawJson[0].containsKey('verses')) {
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
            } else {
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

        if (verseList.isNotEmpty &&
            (verseList[0].containsKey('aya') ||
                verseList[0].containsKey('id'))) {
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

          int verseId;
          if (map.containsKey('aya') && map['aya'] != null) {
            verseId = (map['aya'] as num?)?.toInt() ?? 0;
          } else if (map.containsKey('id') && map['id'] != null) {
            verseId = (map['id'] as num?)?.toInt() ?? 0;
          } else {
            verseId = index + 1;
          }

          String arabicText = '';
          if (arabicVerses.isNotEmpty) {
            final arabicMatch = arabicVerses.firstWhere(
                  (a) => a['id'] == verseId,
              orElse: () => {'arabic': ''},
            );
            arabicText = arabicMatch['arabic'] as String;
          }
          map['arabic'] = arabicText;

          if (_language == 'bengali') {
            map['translation'] =
                map['bengali'] ?? map['translation'] ?? map['text'] ?? '';
          } else if (_language == 'hindi') {
            map['translation'] =
                map['hindi'] ?? map['translation'] ?? map['text'] ?? '';
          } else if (_language == 'assamese') {
            map['translation'] =
                map['assamese'] ?? map['translation'] ?? map['text'] ?? '';
          } else {
            map['translation'] = map['translation'] ?? '';
          }

          map['id'] = verseId;
          map['aya'] = verseId;

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

      final posKey = '$_surahNumber$_language$_isTafseer';
      if (!_showSearchBar &&
          _scrollPositions.containsKey(posKey) &&
          _scrollPositions[posKey]! > 0) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_scrollController.hasClients) {
            final maxScroll = _scrollController.position.maxScrollExtent;
            final targetOffset =
            _scrollPositions[posKey]!.clamp(0.0, maxScroll);
            _scrollController.jumpTo(targetOffset);
          }
        });
      }
    } catch (e) {
      debugPrint('Error loading surah: $e');
      _createFallbackData();
    }
  }

  void _createFallbackData() {
    setState(() {
      _surahName =
      _isTafseer ? 'Surah $_surahNumber (Tafseer)' : 'Surah $_surahNumber';
      _verses = List.generate(
          7,
              (i) => {
            'id': i + 1,
            'aya': i + 1,
            'arabic': 'بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ',
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

  // ─────────────────────────────────────────────────────────────────────────
  // PRECISE VERSE JUMP  –  interpolation-based, converges in 2-3 frames
  // ─────────────────────────────────────────────────────────────────────────

  /// Returns the scroll offset (pixels from top) needed to place this item
  /// at the very top of the viewport. Returns null if the item is not yet
  /// rendered in the widget tree.
  double? _getScrollOffsetForKey(GlobalKey key) {
    try {
      final ctx = key.currentContext;
      if (ctx == null) return null;
      final RenderBox? box = ctx.findRenderObject() as RenderBox?;
      if (box == null || !box.hasSize) return null;
      // RenderAbstractViewport.of() finds the enclosing scroll viewport and
      // getOffsetToReveal returns exactly how many pixels we need to scroll
      // so that this box sits at the given alignment (0.0 = top).
      final viewport = RenderAbstractViewport.of(box);
      return viewport.getOffsetToReveal(box, 0.0).offset;
    } catch (_) {
      return null;
    }
  }

  void _jumpToVerse(int targetVerse) {
    // Restore the full list so the user can keep scrolling after the jump.
    if (_filteredVerses.length != _verses.length) {
      setState(() {
        _filteredVerses = List.from(_verses);
      });
    }

    final targetIndex = _verses.indexWhere((v) {
      final vn =
          (v['aya'] as num?)?.toInt() ?? (v['id'] as num?)?.toInt() ?? 0;
      return vn == targetVerse;
    });

    if (targetIndex == -1) {
      // Verse doesn't exist in this surah → show "no results"
      setState(() {
        _filteredVerses = [];
      });
      return;
    }

    // Show the loading spinner overlay immediately.
    setState(() => _isJumping = true);

    // Begin the background jump on the very next frame (after rebuild).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _performPreciseJump(targetVerse, targetIndex, 0);
    });
  }

  /// Called recursively until the target verse's GlobalKey has a live
  /// RenderObject we can snap to.
  ///
  /// On each attempt we:
  ///   1. Check if the target is already rendered → snap and done.
  ///   2. Otherwise, gather the actual scroll offsets of *all* currently
  ///      rendered verses (via RenderAbstractViewport), find the closest
  ///      neighbours above and below the target, then interpolate between
  ///      them to get a much more accurate estimate than pure index-fraction
  ///      maths. This handles variable-height tafseer cards correctly.
  ///   3. Jump to (estimate − 400 px) so the target lands inside the
  ///      ListView's cacheExtent and gets built on the next frame.
  ///   4. Schedule another attempt.
  void _performPreciseJump(int targetVerse, int targetIndex, int attempts) {
    if (!mounted || !_scrollController.hasClients) {
      if (mounted) setState(() => _isJumping = false);
      return;
    }

    // ── SUCCESS: target verse is built → snap exactly to it ──────────────
    final targetKey = _verseKeys[targetVerse];
    final targetOffset =
    targetKey != null ? _getScrollOffsetForKey(targetKey) : null;

    if (targetOffset != null) {
      _scrollController.jumpTo(
        targetOffset.clamp(0.0, _scrollController.position.maxScrollExtent),
      );
      // Hide the spinner one frame later so the snap is applied first.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _isJumping = false);
      });
      return;
    }

    // ── GIVE UP after enough attempts (should never reach this) ──────────
    if (attempts > 20) {
      if (mounted) setState(() => _isJumping = false);
      return;
    }

    final double maxExtent = _scrollController.position.maxScrollExtent;
    final int totalItems = _verses.length;

    if (totalItems <= 1) {
      _scrollController.jumpTo(0);
      WidgetsBinding.instance.addPostFrameCallback(
              (_) => _performPreciseJump(targetVerse, targetIndex, attempts + 1));
      return;
    }

    // ── INTERPOLATE using real rendered positions ─────────────────────────
    //
    // Walk every key in _verseKeys. For each that currently has a live
    // RenderObject, read its exact scroll position via getOffsetToReveal.
    // Track the nearest rendered verse *above* (index < target) and the
    // nearest rendered verse *below* (index > target).
    //
    // Then interpolate linearly between those two anchors to estimate where
    // the target verse actually lives in pixel-space.

    int bestAboveIndex = -1;
    double bestAboveScrollOffset = 0.0;
    int bestBelowIndex = totalItems; // sentinel: "not found"
    double bestBelowScrollOffset = maxExtent;

    for (final entry in _verseKeys.entries) {
      final verseNum = entry.key;
      final scrollOff = _getScrollOffsetForKey(entry.value);
      if (scrollOff == null) continue; // not rendered yet

      // Find which list index this verse number corresponds to.
      final vIndex = _verses.indexWhere((v) {
        final vn =
            (v['aya'] as num?)?.toInt() ?? (v['id'] as num?)?.toInt() ?? 0;
        return vn == verseNum;
      });
      if (vIndex == -1) continue;

      if (vIndex < targetIndex && vIndex > bestAboveIndex) {
        bestAboveIndex = vIndex;
        bestAboveScrollOffset = scrollOff;
      }
      if (vIndex > targetIndex && vIndex < bestBelowIndex) {
        bestBelowIndex = vIndex;
        bestBelowScrollOffset = scrollOff;
      }
    }

    double estimatedOffset;

    if (bestAboveIndex >= 0 && bestBelowIndex < totalItems) {
      // ── Best case: interpolate between two real anchors ────────────────
      // Linear interpolation: position = above + (target−above)/(below−above)
      //                                          × (belowOffset−aboveOffset)
      final indexRange = bestBelowIndex - bestAboveIndex;
      final fraction = (targetIndex - bestAboveIndex) / indexRange;
      estimatedOffset =
          bestAboveScrollOffset + fraction * (bestBelowScrollOffset - bestAboveScrollOffset);
    } else if (bestAboveIndex >= 0) {
      // ── Only have an anchor above: extrapolate forward ─────────────────
      // avgHeight = total scroll used by items 0..bestAboveIndex
      final avgHeight = bestAboveIndex > 0
          ? bestAboveScrollOffset / bestAboveIndex
          : 300.0;
      estimatedOffset =
          bestAboveScrollOffset + (targetIndex - bestAboveIndex) * avgHeight;
    } else if (bestBelowIndex < totalItems) {
      // ── Only have an anchor below: extrapolate backward ────────────────
      final itemsBelow = totalItems - bestBelowIndex;
      final avgHeight = itemsBelow > 0
          ? (maxExtent - bestBelowScrollOffset) / itemsBelow
          : 300.0;
      estimatedOffset =
          bestBelowScrollOffset - (bestBelowIndex - targetIndex) * avgHeight;
    } else {
      // ── Fallback: no rendered anchors at all (first attempt, list just
      //    rebuilt) – use index fraction as initial coarse estimate ────────
      estimatedOffset = maxExtent * targetIndex / (totalItems - 1);
    }

    // Jump slightly *before* the estimate so the target verse lands inside
    // the cacheExtent window and gets built by the framework on the next frame.
    final jumpOffset = (estimatedOffset - 400).clamp(0.0, maxExtent);
    _scrollController.jumpTo(jumpOffset);

    WidgetsBinding.instance.addPostFrameCallback(
            (_) => _performPreciseJump(targetVerse, targetIndex, attempts + 1));
  }

  // ─────────────────────────────────────────────────────────────────────────

  void _filterVerses(String query) {
    _debounceTimer?.cancel();
    if (query.isEmpty) {
      setState(() {
        _filteredVerses = List.from(_verses);
        _isSearching = false;
      });
      return;
    }

    final trimmedQuery = query.trim();

    // Jump to Verse: ":100" or "100"
    if (RegExp(r'^:?\d+$').hasMatch(trimmedQuery)) {
      final targetVerse =
          int.tryParse(trimmedQuery.replaceAll(':', '')) ?? 0;
      _isSearching = false;
      _jumpToVerse(targetVerse);
      return;
    }

    // Jump to Verse: "3:100"
    if (RegExp(r'^\d+:\d+$').hasMatch(trimmedQuery)) {
      final parts = trimmedQuery.split(':');
      final qSurah = int.tryParse(parts[0]) ?? 0;
      final qVerse = int.tryParse(parts[1]) ?? 0;

      if (qSurah == _surahNumber) {
        _isSearching = false;
        _jumpToVerse(qVerse);
        return;
      }
    }

    // Standard text / range filtering
    setState(() => _isSearching = true);

    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      final results = _verses.where((verse) {
        final verseNumber = (verse['aya'] as num?)?.toInt() ??
            (verse['id'] as num?)?.toInt() ??
            0;
        final text =
        (verse['text'] ?? verse['arabic'] ?? '').toString().toLowerCase();
        final translation =
        (verse['translation'] ?? '').toString().toLowerCase();
        final transliteration =
        (verse['transliteration'] ?? '').toString().toLowerCase();
        final tafseer = (verse['tafseer'] ?? '').toString().toLowerCase();
        final q = trimmedQuery.toLowerCase();

        if (_isVerseNumberPattern(q)) {
          return _matchesVerseNumberPattern(verseNumber.toString(), q);
        }

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

  bool _isVerseNumberPattern(String q) =>
      RegExp(r'^(\d+)[:-]?(\d+)?[-:]?(\d+)?$').hasMatch(q);

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
      WidgetsBinding.instance
          .addPostFrameCallback((_) => _searchFocusNode.requestFocus());
    } else {
      _clearSearch();
    }
  }

  void _showSettings() {
    if (_isTafseer) {
      showGeneralDialog(
        context: context,
        barrierLabel: 'Tafseer Settings',
        barrierDismissible: true,
        barrierColor: Colors.black.withOpacity(0.5),
        transitionDuration: const Duration(milliseconds: 400),
        pageBuilder: (context, animation, secondaryAnimation) {
          return Consumer<SettingsService>(
            builder: (context, settingsService, child) {
              return TafseerSettingsDialog(language: _language);
            },
          );
        },
        transitionBuilder: (context, animation, secondaryAnimation, child) {
          final scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
            CurvedAnimation(
                parent: animation, curve: Curves.elasticOut),
          );
          final fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
            CurvedAnimation(
                parent: animation,
                curve:
                const Interval(0.3, 1.0, curve: Curves.easeOut)),
          );
          return FadeTransition(
            opacity: fadeAnimation,
            child: ScaleTransition(scale: scaleAnimation, child: child),
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
              language: _language, isTafseerMode: _isTafseer);
        },
        transitionBuilder: (context, animation, secondaryAnimation, child) {
          final scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
            CurvedAnimation(
                parent: animation, curve: Curves.elasticOut),
          );
          final fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
            CurvedAnimation(
                parent: animation,
                curve:
                const Interval(0.3, 1.0, curve: Curves.easeOut)),
          );
          return FadeTransition(
            opacity: fadeAnimation,
            child: ScaleTransition(scale: scaleAnimation, child: child),
          );
        },
      );
    }
  }

  void _shareVerse(
      int verseNumber, String arabic, String translation) {
    final prefix = 'Surah $_surahNumber:$verseNumber';
    final text = _isTafseer
        ? '$prefix\n\n$translation'
        : '$prefix\n$arabic\n\n$translation';
    Share.share(text);
  }

  void _copyVerse(
      int verseNumber, String arabic, String translation) {
    final prefix = 'Surah $_surahNumber:$verseNumber';
    final text = _isTafseer
        ? '$prefix\n\n$translation'
        : '$prefix\n$arabic\n\n$translation';
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Verse copied')));
  }

  void _toggleBookmark(
      int verseNumber, Map<String, dynamic> verseData) {
    final settings =
    Provider.of<SettingsService>(context, listen: false);
    settings.toggleBookmark(
      surahNumber: _surahNumber,
      verseNumber: verseNumber,
      verseData: verseData,
      language: _language,
      isTafseer: _isTafseer,
    );
    final bool booked = settings.isBookmarked(
        _surahNumber, verseNumber, _language, _isTafseer);
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
    _verseKeys.clear();
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
            Text(_surahName,
                style: TextStyle(fontSize: 18 * fontScale)),
            Text('Surah $_surahNumber • ${_verses.length} verses',
                style: TextStyle(fontSize: 12 * fontScale)),
          ],
        ),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: Colors.white,
        elevation: 4,
        actions: [
          IconButton(
              icon: const Icon(Icons.search),
              onPressed: _toggleSearch),
          IconButton(
              icon: const Icon(Icons.settings),
              onPressed: _showSettings),
        ],
      ),
      body: Column(
        children: [
          if (_showSearchBar)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                  color: theme.cardColor,
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 4,
                        offset: const Offset(0, 2))
                  ]),
              child: TextField(
                controller: _searchController,
                focusNode: _searchFocusNode,
                decoration: InputDecoration(
                  hintText:
                  'Type 50, 3:50, or :50 to jump instantly...',
                  prefixIcon: _isSearching
                      ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                          strokeWidth: 2))
                      : const Icon(Icons.search),
                  suffixIcon:
                  _searchController.text.isNotEmpty
                      ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: _clearSearch)
                      : null,
                  filled: true,
                  fillColor: theme.scaffoldBackgroundColor,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none),
                ),
              ),
            ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : Stack(
              children: [
                // ── Scrollable verse list ──────────────────────────
                Container(
                  color: settings.backgroundColor,
                  child: Consumer<SettingsService>(
                      builder: (context, settings, child) {
                        return _filteredVerses.isEmpty &&
                            _showSearchBar &&
                            _searchController.text.isNotEmpty
                            ? _buildNoResults(theme, fontScale)
                            : ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.all(16),
                          // ── KEY CHANGE ──────────────────────────
                          // Pre-build items within 4000 px of the
                          // viewport so that once our interpolated
                          // estimate lands nearby, the target verse
                          // is guaranteed to be built in the very
                          // next frame.
                          cacheExtent: 4000,
                          itemCount: _filteredVerses.length,
                          itemBuilder: (context, i) {
                            final verse = _filteredVerses[i];
                            final vn = (verse['aya'] as num?)
                                ?.toInt() ??
                                (verse['id'] as num?)
                                    ?.toInt() ??
                                i + 1;

                            _verseKeys[vn] ??= GlobalKey();

                            final arabic = verse['arabic'] ??
                                verse['text'] ??
                                '';
                            final translation =
                                verse['translation'] ?? '';
                            final transliteration =
                                verse['transliteration'] ?? '';
                            final tafseer =
                                verse['tafseer'] ?? '';
                            final footnotes =
                                verse['footnotes'] ?? '';

                            final booked =
                            settings.isBookmarked(
                                _surahNumber,
                                vn,
                                _language,
                                _isTafseer);

                            return VerseCard(
                              key: _verseKeys[vn],
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
                              onShare: () => _shareVerse(
                                  vn, arabic, translation),
                              onCopy: () => _copyVerse(
                                  vn, arabic, translation),
                              onBookmark: () =>
                                  _toggleBookmark(vn, verse),
                              fontScale: fontScale,
                              cachedData: _cachedData,
                              surahName: _surahName,
                            );
                          },
                        );
                      }),
                ),

                // ── Loading overlay while jumping ──────────────────
                if (_isJumping)
                  Container(
                    color: settings.backgroundColor
                        .withOpacity(0.85),
                    child: const Center(
                      child: CircularProgressIndicator(),
                    ),
                  ),
              ],
            ),
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
            Icon(Icons.search_off,
                size: 64 * fontScale,
                color: theme.colorScheme.onSurface.withOpacity(0.3)),
            const SizedBox(height: 16),
            Text('No verses found',
                style: TextStyle(
                    fontSize: 18 * fontScale,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(
                'Verse number might not exist in this Surah',
                style: TextStyle(fontSize: 14 * fontScale),
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}