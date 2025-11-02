import 'dart:convert';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:islam114/main.dart';
import '../../core/services/settings_service.dart';
import '../../data/models/quran_dictionary_model.dart';
import '../../data/services/quran_dictionary_service.dart';
import '../widgets/dictionary_settings_dialog.dart';
import '../widgets/dictionary_item_card.dart';

class QuranDictionaryPage extends StatefulWidget {
  const QuranDictionaryPage({super.key});

  @override
  State<QuranDictionaryPage> createState() => _QuranDictionaryPageState();
}

class _QuranDictionaryPageState extends State<QuranDictionaryPage> with TickerProviderStateMixin, RouteAware, WidgetsBindingObserver {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  List<QuranDictionaryItem> _dictionaryItems = [];
  List<QuranDictionaryItem> _filteredItems = [];
  bool _isLoading = true;
  bool _isSearching = false;
  String _selectedLanguage = 'english';
  double _fontScale = 1.0;
  bool _isDarkMode = false;
  String _readingMode = 'standard';
  String _errorMessage = '';
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.7, curve: Curves.easeInOut),
      ),
    );
    _scaleAnimation = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOutBack,
      ),
    );

    _animationController.forward();

    _loadSettings();
    _loadDictionaryData();
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
    _scrollController.dispose();
    _debounceTimer?.cancel();
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

  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final fontScale = prefs.getDouble('dictionary_font_scale') ?? 1.0;
      final isDarkMode = prefs.getBool('dictionary_dark_mode') ?? false;
      final readingMode = prefs.getString('dictionary_reading_mode') ?? 'standard';
      final selectedLanguage = prefs.getString('dictionary_language') ?? 'english';

      setState(() {
        _fontScale = fontScale;
        _isDarkMode = isDarkMode;
        _readingMode = readingMode;
        _selectedLanguage = selectedLanguage;
      });
    } catch (e) {
      print('Error loading settings: $e');
    }
  }

  Future<void> _saveSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble('dictionary_font_scale', _fontScale);
      await prefs.setBool('dictionary_dark_mode', _isDarkMode);
      await prefs.setString('dictionary_reading_mode', _readingMode);
      await prefs.setString('dictionary_language', _selectedLanguage);
    } catch (e) {
      print('Error saving settings: $e');
    }
  }

  Future<void> _loadDictionaryData() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });

      final String jsonString = await rootBundle.loadString('assets/dictionaries/quran_dictionary_$_selectedLanguage.json');
      print('JSON loaded successfully, length: ${jsonString.length}');

      final dynamic jsonData = json.decode(jsonString);
      print('JSON parsed successfully, type: ${jsonData.runtimeType}');

      if (jsonData is List) {
        print('JSON is a list with ${jsonData.length} items');
        if (jsonData.isNotEmpty) {
          print('First item type: ${jsonData[0].runtimeType}');
          print('First item keys: ${jsonData[0].keys.toList()}');
          print('First item empty key value: ${jsonData[0][""]}');
        }
      }

      final items = await QuranDictionaryService.loadDictionary(_selectedLanguage);
      print('Dictionary loaded with ${items.length} items');

      if (items.isNotEmpty) {
        print('First item ID: ${items.first.id}');
        print('First item title: ${items.first.title}');
        print('First item location: ${items.first.location}');
      }

      setState(() {
        _dictionaryItems = items;
        _filteredItems = items;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading dictionary: $e');
      setState(() {
        _isLoading = false;
        _errorMessage = 'Error loading dictionary: $e';
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading dictionary: $e')),
        );
      }
    }
  }

  void _filterDictionary(String query) {
    _debounceTimer?.cancel();

    if (query.isEmpty) {
      setState(() {
        _filteredItems = _dictionaryItems;
        _isSearching = false;
      });
      return;
    }

    setState(() {
      _isSearching = true;
    });

    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      compute(_performSearch, {'items': _dictionaryItems, 'query': query})
          .then((results) {
        if (mounted) {
          setState(() {
            _filteredItems = results;
            _isSearching = false;
          });
        }
      }).catchError((error) {
        if (mounted) {
          setState(() {
            _isSearching = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Search error: $error')),
          );
        }
      });
    });
  }

  static List<QuranDictionaryItem> _performSearch(Map<String, dynamic> params) {
    final List<QuranDictionaryItem> items = params['items'];
    final String query = params['query'];
    return QuranDictionaryService.searchDictionary(items, query);
  }

  void _changeLanguage(String language) {
    setState(() {
      _selectedLanguage = language;
      _isLoading = true;
    });
    _saveSettings();
    _loadDictionaryData();
  }

  void _openSettings() {
    showDialog(
      context: context,
      builder: (context) => DictionarySettingsDialog(
        fontScale: _fontScale,
        isDarkMode: _isDarkMode,
        readingMode: _readingMode,
        selectedLanguage: _selectedLanguage,
        onFontScaleChanged: (value) {
          setState(() {
            _fontScale = value;
          });
          _saveSettings();
        },
        onDarkModeChanged: (value) {
          setState(() {
            _isDarkMode = value;
          });
          _saveSettings();
        },
        onReadingModeChanged: (value) {
          setState(() {
            _readingMode = value;
          });
          _saveSettings();
        },
        onLanguageChanged: (value) {
          _changeLanguage(value);
        },
        onResetLanguageDialog: () {},
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final baseTheme = Theme.of(context);
    final theme = _isDarkMode ? ThemeData.dark().copyWith(
      primaryColor: baseTheme.colorScheme.primary,
      appBarTheme: AppBarTheme(
        backgroundColor: baseTheme.colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      cardColor: Colors.grey[800],
      scaffoldBackgroundColor: Colors.grey[900],
    ) : baseTheme;

    final settingsFontScale = Provider.of<SettingsService>(context).fontScale;

    return Theme(
      data: theme,
      child: Scaffold(
        appBar: AppBar(
          title: Text('Quran Dictionary (${_selectedLanguage.toUpperCase()})'),
          backgroundColor: theme.colorScheme.primary,
          foregroundColor: Colors.white,
          actions: [
            IconButton(
              icon: const Icon(Icons.settings),
              onPressed: _openSettings,
            ),
          ],
        ),
        body: ScaleTransition(
          scale: _scaleAnimation,
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Column(
              children: [
                // Search bar
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: TextField(
                    controller: _searchController,
                    onChanged: _filterDictionary,
                    decoration: InputDecoration(
                      hintText: 'Search for words, verses, or locations (e.g., 4:33:2)...',
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
                        onPressed: () {
                          _searchController.clear();
                          _filterDictionary('');
                        },
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

                // Searching indicator
                if (_isSearching)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              theme.colorScheme.primary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Searching...',
                          style: TextStyle(
                            color: theme.colorScheme.onSurface.withOpacity(0.6),
                            fontSize: 14 * settingsFontScale * _fontScale,
                          ),
                        ),
                      ],
                    ),
                  ),

                // Results count
                if (_searchController.text.isNotEmpty && !_isSearching)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Row(
                      children: [
                        Text(
                          '${_filteredItems.length} results found',
                          style: TextStyle(
                            color: theme.colorScheme.onSurface.withOpacity(0.6),
                            fontSize: 14 * settingsFontScale * _fontScale,
                          ),
                        ),
                        const Spacer(),
                        if (_filteredItems.isNotEmpty)
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
                                color: theme.colorScheme.primary,
                                fontSize: 12 * settingsFontScale * _fontScale,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),

                // Error message
                if (_errorMessage.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.red.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.error, color: Colors.red.shade700),
                              const SizedBox(width: 8),
                              Text(
                                'Error',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.red.shade700,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(_errorMessage),
                          const SizedBox(height: 8),
                          ElevatedButton(
                            onPressed: _loadDictionaryData,
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    ),
                  ),

                // Dictionary list
                Expanded(
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : _filteredItems.isEmpty
                      ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.search_off,
                          size: 64 * settingsFontScale * _fontScale,
                          color: theme.colorScheme.onSurface.withOpacity(0.3),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No results found',
                          style: TextStyle(
                            fontSize: 18 * settingsFontScale * _fontScale,
                            color: theme.colorScheme.onSurface.withOpacity(0.6),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Try searching with different keywords',
                          style: TextStyle(
                            fontSize: 14 * settingsFontScale * _fontScale,
                            color: theme.colorScheme.onSurface.withOpacity(0.6),
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  )
                      : ListView.builder(
                    controller: _scrollController,
                    physics: const BouncingScrollPhysics(
                      parent: AlwaysScrollableScrollPhysics(),
                    ),
                    cacheExtent: 500.0,
                    padding: const EdgeInsets.all(16.0),
                    itemCount: _filteredItems.length,
                    itemBuilder: (context, index) {
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        curve: Curves.easeOut,
                        child: DictionaryItemCard(
                          key: ValueKey(_filteredItems[index].id),
                          item: _filteredItems[index],
                          fontScale: settingsFontScale * _fontScale,
                          readingMode: _readingMode,
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}