// lib/presentation/pages/bukhari_hadith_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:convert';
import 'dart:async';
import 'package:flutter/services.dart';

import 'package:islam114/main.dart'; // Import for global RouteObserver from main.dart
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
  final ScrollController _scrollController = ScrollController();

  int? _selectedChapterId;
  String _searchQuery = '';
  Map<String, dynamic>? _metadata;
  Map<String, dynamic>? _fullJsonData; // Store the full JSON data

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
    // Subscribe to the global RouteObserver instance.
    final modalRoute = ModalRoute.of(context);
    if (modalRoute is PageRoute) {
      routeObserver.subscribe(this, modalRoute as PageRoute<dynamic>);
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      // Trigger animation restart when app resumes from background.
      _animationController.reset();
      _animationController.forward();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _animationController.dispose();
    _searchController.dispose();
    _scrollController.dispose();
    // Unsubscribe from the global RouteObserver to prevent memory leaks.
    final modalRoute = ModalRoute.of(context);
    if (modalRoute is PageRoute) {
      routeObserver.unsubscribe(this);
    }
    super.dispose();
  }

  @override
  void didPopNext() {
    // Triggered when returning to this route (e.g., popping back from another page).
    _animationController.reset();
    _animationController.forward();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      debugPrint('Attempting to load JSON file...');

      final String jsonString = await rootBundle.loadString('assets/data/sahih_al_bukhari.json');
      debugPrint('JSON file loaded successfully, length: ${jsonString.length}');

      final data = json.decode(jsonString);
      debugPrint('JSON decoded successfully');

      // Store the full JSON data for later use
      _fullJsonData = data;

      if (data['chapters'] != null) {
        setState(() {
          _metadata = data['metadata'];
          _chapters = List<Map<String, dynamic>>.from(data['chapters']);
          _filteredChapters = List<Map<String, dynamic>>.from(_chapters);
          _isLoading = false;
        });
        debugPrint('Loaded ${_chapters.length} chapters');
      } else {
        debugPrint('No chapters found in JSON');
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
    setState(() {
      _isLoading = true;
      _selectedChapterId = chapterId;
    });

    try {
      debugPrint('Loading hadiths for chapter $chapterId...');

      if (_fullJsonData == null) {
        // If full data is not loaded, reload it
        final String jsonString = await rootBundle.loadString('assets/data/sahih_al_bukhari.json');
        _fullJsonData = json.decode(jsonString);
      }

      // Check if hadiths exist in the JSON
      if (_fullJsonData!['hadiths'] != null) {
        final List<Map<String, dynamic>> allHadiths = List<Map<String, dynamic>>.from(_fullJsonData!['hadiths']);

        // Filter hadiths for the selected chapter
        final List<Map<String, dynamic>> chapterHadiths = allHadiths
            .where((hadith) {
          // Fix: Handle the case where chapterId might be null or not an int
          final hadithChapterId = hadith['chapterId'];
          if (hadithChapterId == null) return false;

          // Convert both to int for comparison
          int hadithChapterIdInt;
          if (hadithChapterId is int) {
            hadithChapterIdInt = hadithChapterId;
          } else if (hadithChapterId is String) {
            hadithChapterIdInt = int.tryParse(hadithChapterId) ?? -1;
          } else {
            // Handle other types by converting to string first
            hadithChapterIdInt = int.tryParse(hadithChapterId.toString()) ?? -1;
          }

          return hadithChapterIdInt == chapterId;
        })
            .toList();

        // Log sample hadith structure for debugging
        if (chapterHadiths.isNotEmpty) {
          final sampleHadith = chapterHadiths.first;
          debugPrint('Sample hadith keys: ${sampleHadith.keys.toList()}');
          debugPrint('Sample hadith arabic preview: ${sampleHadith['arabic']?.toString().substring(0, 100) ?? 'N/A'}...');
          debugPrint('Sample hadith english preview: ${sampleHadith['english']?.toString().substring(0, 100) ?? 'N/A'}...');
        }

        debugPrint('Found ${chapterHadiths.length} hadiths for chapter $chapterId');

        setState(() {
          _hadiths = chapterHadiths;
          _filteredHadiths = List<Map<String, dynamic>>.from(_hadiths);
          _isLoading = false;
        });
      } else {
        debugPrint('No hadiths found in JSON');
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

      // Filter chapters
      _filteredChapters = _chapters.where((chapter) {
        final title = chapter['english']?.toString().toLowerCase() ?? '';
        final titleAr = chapter['arabic']?.toString().toLowerCase() ?? '';
        final query = _searchQuery.toLowerCase();

        return title.contains(query) || titleAr.contains(query);
      }).toList();

      // Filter hadiths if a chapter is selected
      if (_selectedChapterId != null) {
        _filteredHadiths = _hadiths.where((hadith) {
          final text = hadith['english']?.toString().toLowerCase() ?? '';
          final textAr = hadith['arabic']?.toString().toLowerCase() ?? '';
          final query = _searchQuery.toLowerCase();

          return text.contains(query) || textAr.contains(query);
        }).toList();
      }
    });
  }

  void _selectChapter(int chapterId) {
    _loadHadiths(chapterId);
    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() {
      _searchQuery = '';
      _filterContent();
    });
  }

  void _backToChapters() {
    setState(() {
      _selectedChapterId = null;
      _hadiths = [];
      _filteredHadiths = [];
    });
  }

  // Handle back navigation
  Future<bool> _onWillPop() async {
    if (_selectedChapterId != null) {
      // If we're viewing hadiths, go back to chapters
      _backToChapters();
      return false; // Prevent the default back action
    }
    // If we're already at chapters, allow the default back action
    return true;
  }

  // Helper method to safely extract int from dynamic value
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
          // Always show the back button, but handle its behavior differently
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
          color: settings.backgroundColor, // Apply background color from settings
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
                          ? 'Search chapters...'
                          : 'Search hadiths...',
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
              'No chapters found',
              style: TextStyle(
                fontSize: 18 * fontScale,
                color: Colors.grey.withOpacity(0.6),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Try searching with different keywords',
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
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      itemCount: _filteredChapters.length,
      itemBuilder: (context, index) {
        final chapter = _filteredChapters[index];
        final chapterId = _extractIntSafely(chapter['id'], index + 1);
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
              'No hadiths found',
              style: TextStyle(
                fontSize: 18 * fontScale,
                color: Colors.grey.withOpacity(0.6),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Try searching with different keywords',
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
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      itemCount: _filteredHadiths.length,
      itemBuilder: (context, index) {
        final hadith = _filteredHadiths[index];

        // Safely extract hadithNumber as int, fallback to (index + 1) if null/invalid
        final int hadithNumber = _extractIntSafely(hadith['number'], index + 1);

        // Use correct JSON keys: 'arabic' and 'english'
        final String textAr = hadith['arabic']?.toString() ?? '';
        final String text = hadith['english']?.toString() ?? '';
        final String? narrator = hadith['narrator']?.toString();

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
            ),
          ),
        );
      },
    );
  }
}