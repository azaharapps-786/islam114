// lib/presentation/pages/surah_list_page.dart
import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:islam114/main.dart';
import '../../core/services/settings_service.dart';
import '../widgets/surah_card.dart';

class SurahListPage extends StatefulWidget {
  const SurahListPage({super.key});

  @override
  State<SurahListPage> createState() => _SurahListPageState();
}

class _SurahListPageState extends State<SurahListPage>
    with TickerProviderStateMixin, RouteAware, WidgetsBindingObserver {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  List<Map<String, dynamic>> _surahs = [];
  List<Map<String, dynamic>> _filteredSurahs = [];
  bool _isLoading = true;
  bool _isSearching = false;
  String _language = 'english';
  String _title = 'English Quran';
  Timer? _debounceTimer;
  bool _isInitialized = false;
  bool _isTafseer = false; // Add a new variable to track if this is a tafseer view

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

    // Initialize search controller listener
    _searchController.addListener(() {
      _filterSurahs(_searchController.text);
    });

    // Start animation
    _animationController.forward();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Get language from arguments
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    if (args != null) {
      _language = args['language'] ?? 'english';
      _isTafseer = args['isTafseer'] ?? false;
      _updateTitle();
    }

    // Subscribe to the global RouteObserver instance.
    final modalRoute = ModalRoute.of(context);
    if (modalRoute is PageRoute) {
      routeObserver.subscribe(this, modalRoute as PageRoute<dynamic>);
    }

    // Initialize data only once
    if (!_isInitialized) {
      _isInitialized = true;
      // Use a post-frame callback to ensure the widget is fully built
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _loadSurahs();
        }
      });
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

  // Update the _updateTitle method:
  void _updateTitle() {
    String newTitle;

    if (_isTafseer) {
      switch (_language) {
        case 'assamese':
          newTitle = 'অসমীয়া কোৰআন তাফসীর';
          break;
        case 'english':
          newTitle = 'English Quran Tafseer';
          break;
        case 'hindi':
          newTitle = 'हिन्दी क़ुरआन तफ़सीर';
          break;
        case 'arabic':
          newTitle = 'تفسير القرآن باللغة العربية';
          break;
        case 'bengali':
          newTitle = 'বাংলা কোরান তাফসীর';
          break;
        default:
          newTitle = 'Quran Tafseer';
      }
    } else {
      switch (_language) {
        case 'assamese':
          newTitle = 'অসমীয়া কোৰআন';
          break;
        case 'english':
          newTitle = 'English Quran';
          break;
        case 'hindi':
          newTitle = 'हिन्दी क़ुरआन';
          break;
        case 'arabic':
          newTitle = 'Arabic Quran';
          break;
        case 'bengali':
          newTitle = 'Bengali Quran';
          break;
        default:
          newTitle = 'Quran';
      }
    }

    // Update the state to trigger a UI rebuild
    if (mounted && _title != newTitle) {
      setState(() {
        _title = newTitle;
      });
    }
  }

  // Update the _loadSurahs method:
  Future<void> _loadSurahs() async {
    try {
      setState(() {
        _isLoading = true;
      });

      // Determine the correct JSON file to load
      String jsonFile;
      if (_isTafseer) {
        jsonFile = 'assets/data/surah_list_${_language}_tafseer.json';
      } else {
        jsonFile = 'assets/data/surah_list_$_language.json';
      }

      final String jsonString = await rootBundle.loadString(jsonFile);
      final List<dynamic> jsonData = json.decode(jsonString);

      setState(() {
        _surahs = List<Map<String, dynamic>>.from(jsonData);
        _filteredSurahs = List<Map<String, dynamic>>.from(_surahs);
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading surahs: $e');
      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading surahs: $e')),
        );
      }
    }
  }

  void _filterSurahs(String query) {
    _debounceTimer?.cancel();

    if (query.isEmpty) {
      setState(() {
        _filteredSurahs = _surahs;
        _isSearching = false;
      });
      return;
    }

    setState(() {
      _isSearching = true;
    });

    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      final results = _surahs.where((surah) {
        final number = surah['number']?.toString() ?? '';
        final name = surah['name']?.toString().toLowerCase() ?? '';
        final searchQuery = query.toLowerCase();

        return number.contains(searchQuery) || name.contains(searchQuery);
      }).toList();

      if (mounted) {
        setState(() {
          _filteredSurahs = results;
          _isSearching = false;
        });
      }
    });
  }

  void _clearSearch() {
    _searchController.clear();
    _filterSurahs('');
  }

  @override
  Widget build(BuildContext context) {
    // Get fontScale from provider in build method
    final fontScale = Provider.of<SettingsService>(context, listen: true).fontScale;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(_title),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: Colors.white,
        elevation: 4,
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
                  decoration: InputDecoration(
                    hintText: 'Search by surah number or name...',
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
                          fontSize: 14 * fontScale,
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
                        '${_filteredSurahs.length} results found',
                        style: TextStyle(
                          color: theme.colorScheme.onSurface.withOpacity(0.6),
                          fontSize: 14 * fontScale,
                        ),
                      ),
                      const Spacer(),
                      if (_filteredSurahs.isNotEmpty)
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
                              fontSize: 12 * fontScale,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),

              // Surah list
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _filteredSurahs.isEmpty
                    ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.menu_book,
                        size: 64 * fontScale,
                        color: theme.colorScheme.onSurface.withOpacity(0.3),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No surahs found',
                        style: TextStyle(
                          fontSize: 18 * fontScale,
                          color: theme.colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Try searching with different keywords',
                        style: TextStyle(
                          fontSize: 14 * fontScale,
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
                  itemCount: _filteredSurahs.length,
                  itemBuilder: (context, index) {
                    final surah = _filteredSurahs[index];
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeOut,
                      child: SurahCard(
                        key: ValueKey(surah['number']),
                        number: surah['number'],
                        name: surah['name'],
                        language: _language,
                        fontScale: fontScale,
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}