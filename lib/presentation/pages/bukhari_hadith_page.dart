// lib/presentation/pages/bukhari_hadith_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:convert';
import 'dart:async';
import 'package:flutter/services.dart';

import 'package:islam114/main.dart';
import '../../core/services/settings_service.dart';
import '../widgets/hadith_card.dart';
import '../widgets/hadith_chapter_list_item.dart';

class BukhariHadithPage extends StatefulWidget {
  const BukhariHadithPage({super.key});

  @override
  State<BukhariHadithPage> createState() => _BukhariHadithPageState();
}

class _BukhariHadithPageState extends State<BukhariHadithPage>
    with TickerProviderStateMixin, RouteAware, WidgetsBindingObserver {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  List<Map<String, dynamic>> _chapters = [];
  List<Map<String, dynamic>> _filteredChapters = [];
  List<Map<String, dynamic>> _hadiths = [];
  List<Map<String, dynamic>> _filteredHadiths = [];
  bool _isLoading = true;
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();

  final ScrollController _chaptersScrollController = ScrollController();
  final ScrollController _hadithsScrollController = ScrollController();

  double _chaptersScrollPosition = 0.0;
  double _hadithsScrollPosition = 0.0;

  int? _selectedChapterId;
  String _searchQuery = '';
  Map<String, dynamic>? _metadata;
  Map<String, dynamic>? _fullJsonData;

  static const String _bookKey = 'bukhari';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.forward();

    _chaptersScrollController.addListener(() {
      if (_chaptersScrollController.hasClients) {
        _chaptersScrollPosition = _chaptersScrollController.offset;
      }
    });
    _hadithsScrollController.addListener(() {
      if (_hadithsScrollController.hasClients) {
        _hadithsScrollPosition = _hadithsScrollController.offset;
      }
    });

    _loadData();

    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text;
        _filterContent();
      });
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final modalRoute = ModalRoute.of(context);
    if (modalRoute is PageRoute) {
      routeObserver.subscribe(this, modalRoute as PageRoute<dynamic>);
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      _animationController.reset();
      _animationController.forward();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _animationController.dispose();
    _searchController.dispose();
    _chaptersScrollController.dispose();
    _hadithsScrollController.dispose();
    final modalRoute = ModalRoute.of(context);
    if (modalRoute is PageRoute) {
      routeObserver.unsubscribe(this);
    }
    super.dispose();
  }

  @override
  void didPopNext() {
    _animationController.reset();
    _animationController.forward();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final String jsonString = await rootBundle.loadString('assets/data/sahih_al_bukhari.json');
      final data = json.decode(jsonString);
      _fullJsonData = data;

      if (data['chapters'] != null) {
        setState(() {
          _metadata = data['metadata'];
          _chapters = List<Map<String, dynamic>>.from(data['chapters']);
          _filteredChapters = List<Map<String, dynamic>>.from(_chapters);
          _isLoading = false;
        });
      } else {
        throw Exception('No chapters found in JSON');
      }
    } catch (e) {
      debugPrint('Error loading data: $e');
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading data: $e')),
        );
      }
    }
  }

  Future<void> _loadHadiths(int chapterId) async {
    if (_chaptersScrollController.hasClients) {
      _chaptersScrollPosition = _chaptersScrollController.offset;
    }

    setState(() {
      _isLoading = true;
      _selectedChapterId = chapterId;
    });

    try {
      if (_fullJsonData == null) {
        final String jsonString = await rootBundle.loadString('assets/data/sahih_al_bukhari.json');
        _fullJsonData = json.decode(jsonString);
      }

      if (_fullJsonData!['hadiths'] != null) {
        final List<Map<String, dynamic>> allHadiths = List<Map<String, dynamic>>.from(_fullJsonData!['hadiths']);

        final List<Map<String, dynamic>> chapterHadiths = allHadiths.where((hadith) {
          final hadithChapterId = hadith['chapterId'];
          if (hadithChapterId == null) return false;

          int hadithChapterIdInt;
          if (hadithChapterId is int) {
            hadithChapterIdInt = hadithChapterId;
          } else if (hadithChapterId is String) {
            hadithChapterIdInt = int.tryParse(hadithChapterId) ?? -1;
          } else {
            hadithChapterIdInt = int.tryParse(hadithChapterId.toString()) ?? -1;
          }

          return hadithChapterIdInt == chapterId;
        }).toList();

        setState(() {
          _hadiths = chapterHadiths;
          _filteredHadiths = List<Map<String, dynamic>>.from(_hadiths);
          _isLoading = false;
        });

        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_hadithsScrollController.hasClients && _hadithsScrollPosition > 0) {
            _hadithsScrollController.jumpTo(_hadithsScrollPosition);
          }
        });
      } else {
        throw Exception('No hadiths found in JSON');
      }
    } catch (e) {
      debugPrint('Error loading hadiths: $e');
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading hadiths: $e')),
        );
      }
    }
  }

  void _filterContent() {
    if (_searchQuery.isEmpty) {
      setState(() {
        _filteredChapters = List<Map<String, dynamic>>.from(_chapters);
        _filteredHadiths = List<Map<String, dynamic>>.from(_hadiths);
        _isSearching = false;
      });
      return;
    }

    setState(() {
      _isSearching = true;
      final query = _searchQuery.toLowerCase();

      _filteredChapters = _chapters.where((chapter) {
        final title = chapter['english']?.toString().toLowerCase() ?? '';
        final titleAr = chapter['arabic']?.toString().toLowerCase() ?? '';
        final chapterNum = chapter['id']?.toString().toLowerCase() ??
            chapter['chapterNumber']?.toString().toLowerCase() ??
            chapter['number']?.toString().toLowerCase() ?? '';

        return title.contains(query) ||
            titleAr.contains(query) ||
            chapterNum.contains(query);
      }).toList();

      if (_selectedChapterId != null) {
        _filteredHadiths = _hadiths.where((hadith) {
          final text = hadith['english']?.toString().toLowerCase() ?? '';
          final textAr = hadith['arabic']?.toString().toLowerCase() ?? '';
          final hadithNum = hadith['number']?.toString().toLowerCase() ??
              hadith['hadithNumber']?.toString().toLowerCase() ??
              hadith['id']?.toString().toLowerCase() ?? '';
          final narrator = hadith['narrator']?.toString().toLowerCase() ?? '';

          return text.contains(query) ||
              textAr.contains(query) ||
              hadithNum.contains(query) ||
              narrator.contains(query);
        }).toList();
      }
    });
  }

  void _selectChapter(int chapterId) {
    _hadithsScrollPosition = 0.0;
    _loadHadiths(chapterId);
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() {
      _searchQuery = '';
      _filterContent();
    });
  }

  void _backToChapters() {
    if (_hadithsScrollController.hasClients) {
      _hadithsScrollPosition = _hadithsScrollController.offset;
    }

    setState(() {
      _selectedChapterId = null;
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_chaptersScrollController.hasClients) {
        _chaptersScrollController.jumpTo(_chaptersScrollPosition);
      }
    });
  }

  Future<bool> _onWillPop() async {
    if (_selectedChapterId != null) {
      _backToChapters();
      return false;
    }
    return true;
  }

  int _extractIntSafely(dynamic value, int fallback) {
    if (value == null) return fallback;
    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? fallback;
    return int.tryParse(value.toString()) ?? fallback;
  }

  void _showArabicSettingsDialog(BuildContext context) {
    final settings = Provider.of<SettingsService>(context, listen: false);
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Arabic Text Settings'),
              content: SwitchListTile(
                title: const Text('Show Arabic Text'),
                subtitle: const Text('Enable/disable Arabic hadith text'),
                value: settings.showArabic,
                onChanged: (value) {
                  setDialogState(() {});
                  settings.setShowArabic(value);
                },
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Close'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final double fontScale = Provider.of<SettingsService>(context).fontScale;
    final settings = Provider.of<SettingsService>(context);
    final theme = Theme.of(context);

    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            _metadata != null
                ? '${_metadata!['english']['title']}'
                : 'Sahih al-Bukhari',
            style: TextStyle(fontSize: 18 * fontScale),
          ),
          backgroundColor: theme.colorScheme.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          automaticallyImplyLeading: true,
          leading: Navigator.canPop(context)
              ? IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              if (_selectedChapterId != null) {
                _backToChapters();
              } else {
                Navigator.of(context).pop();
              }
            },
            tooltip: _selectedChapterId != null
                ? 'Back to Chapters'
                : 'Back to Home',
          )
              : null,
          actions: [
            IconButton(
              icon: const Icon(Icons.settings),
              onPressed: () => _showArabicSettingsDialog(context),
              tooltip: 'Settings',
            ),
          ],
        ),
        body: Container(
          color: settings.backgroundColor,
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Column(
              children: [
                // Search Bar
                Container(
                  padding: const EdgeInsets.all(16.0),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: _selectedChapterId == null
                          ? 'Search chapters (e.g., 40, prayer, fasting)...'
                          : 'Search hadiths (e.g., 100, prophet, narrated)...',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: _clearSearch,
                      )
                          : null,
                      filled: true,
                      fillColor: theme.cardColor,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.0),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                // Main Content
                Expanded(
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : _selectedChapterId == null
                      ? _buildChaptersList(fontScale, theme)
                      : _buildHadithsList(fontScale, theme, settings.showArabic),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildChaptersList(double fontScale, ThemeData theme) {
    if (_filteredChapters.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.menu_book,
              size: 64 * fontScale,
              color: Colors.grey.withOpacity(0.3),
            ),
            const SizedBox(height: 16),
            Text(
              _searchQuery.isNotEmpty ? 'No chapters found for "$_searchQuery"' : 'No chapters found',
              style: TextStyle(
                fontSize: 18 * fontScale,
                color: Colors.grey.withOpacity(0.6),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Try searching with chapter number or keywords',
              style: TextStyle(
                fontSize: 14 * fontScale,
                color: Colors.grey.withOpacity(0.6),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      key: const PageStorageKey<String>('chapters_list'),
      controller: _chaptersScrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      itemCount: _filteredChapters.length,
      itemBuilder: (context, index) {
        final chapter = _filteredChapters[index];
        final chapterId = _extractIntSafely(
            chapter['id'] ?? chapter['chapterNumber'] ?? chapter['number'],
            index + 1
        );
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          child: HadithChapterListItem(
            chapterId: chapterId,
            titleAr: chapter['arabic']?.toString() ?? '',
            titleEn: chapter['english']?.toString() ?? '',
            fontScale: fontScale,
            onTap: () => _selectChapter(chapterId),
          ),
        );
      },
    );
  }

  Widget _buildHadithsList(double fontScale, ThemeData theme, bool showArabic) {
    if (_filteredHadiths.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.format_quote,
              size: 64 * fontScale,
              color: Colors.grey.withOpacity(0.3),
            ),
            const SizedBox(height: 16),
            Text(
              _searchQuery.isNotEmpty ? 'No hadiths found for "$_searchQuery"' : 'No hadiths found',
              style: TextStyle(
                fontSize: 18 * fontScale,
                color: Colors.grey.withOpacity(0.6),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Try searching with hadith number or keywords',
              style: TextStyle(
                fontSize: 14 * fontScale,
                color: Colors.grey.withOpacity(0.6),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      key: PageStorageKey<String>('hadiths_list_${_selectedChapterId}'),
      controller: _hadithsScrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      itemCount: _filteredHadiths.length,
      itemBuilder: (context, index) {
        final hadith = _filteredHadiths[index];

        final int hadithNumber = _extractIntSafely(
            hadith['number'] ?? hadith['hadithNumber'] ?? hadith['id'],
            index + 1
        );

        final String textAr = hadith['arabic']?.toString() ?? '';
        final String text = hadith['english']?.toString() ?? '';
        final String? narrator = hadith['narrator']?.toString();

        final chapterName = _chapters.isNotEmpty
            ? _chapters.firstWhere(
              (c) => _extractIntSafely(c['id'] ?? c['chapterNumber'] ?? c['number'], 0) == _selectedChapterId,
          orElse: () => {'english': 'Chapter $_selectedChapterId'},
        )['english']?.toString() ?? 'Chapter $_selectedChapterId'
            : 'Chapter $_selectedChapterId';

        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 16.0),
            child: HadithCard(
              hadithNumber: hadithNumber,
              textAr: textAr,
              text: text,
              narrator: narrator,
              fontScale: fontScale,
              showArabic: showArabic,
              chapterId: _selectedChapterId ?? 0,
              chapterName: chapterName,
              bookKey: _bookKey,
              surahOrChapterNumber: _selectedChapterId ?? 0,
            ),
          ),
        );
      },
    );
  }
}