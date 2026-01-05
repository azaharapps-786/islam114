// lib/presentation/pages/surah_list_page.dart
import 'dart:convert';
import 'dart:async';
import 'dart:ui' as ui;
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
  bool _isTafseer = false;
  PageRoute<dynamic>? _savedRoute;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
        parent: _animationController, curve: Curves.easeIn);

    _searchController.addListener(() {
      _filterSurahs(_searchController.text);
    });

    _animationController.forward();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    if (args != null) {
      _language = args['language'] ?? 'english';
      _isTafseer = args['isTafseer'] ?? false;
      _updateTitle();
    }

    final modalRoute = ModalRoute.of(context);
    _savedRoute = modalRoute is PageRoute ? modalRoute : null;
    if (modalRoute is PageRoute) {
      routeObserver.subscribe(this, modalRoute);
    }

    if (!_isInitialized) {
      _isInitialized = true;
      _loadSurahs();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _animationController.dispose();
    _searchController.dispose();
    _scrollController.dispose();
    _debounceTimer?.cancel();
    if (_savedRoute != null) routeObserver.unsubscribe(this);
    super.dispose();
  }

  // --- LOGIC METHODS (FIXES THE "UNDEFINED" ERRORS) ---

  void _updateTitle() {
    String newTitle;
    if (_isTafseer) {
      switch (_language) {
        case 'assamese': newTitle = 'অসমীয়া কোৰআন তাফসীর'; break;
        case 'english': newTitle = 'English Quran Tafseer'; break;
        case 'hindi': newTitle = 'हिन्दी क़ুরআন তਫ਼সির'; break;
        case 'bengali': newTitle = 'বাংলা কোরান তাফসীর'; break;
        default: newTitle = 'Quran Tafseer';
      }
    } else {
      switch (_language) {
        case 'assamese': newTitle = 'অসমীয়া কোৰআন'; break;
        case 'english': newTitle = 'English Quran'; break;
        case 'hindi': newTitle = 'हिन्दी क़ुरআন'; break;
        case 'bengali': newTitle = 'Bengali Quran'; break;
        default: newTitle = 'Quran';
      }
    }
    setState(() => _title = newTitle);
  }

  String _getEmojiForCurrentView() {
    if (_isTafseer) return '📚';
    switch (_language) {
      case 'assamese': return '📗';
      case 'english': return '📕';
      case 'hindi': return '📗';
      case 'bengali': return '📙';
      default: return '📖';
    }
  }

  Future<void> _loadSurahs() async {
    try {
      String jsonFile = _isTafseer
          ? 'assets/data/surah_list_${_language}_tafseer.json'
          : 'assets/data/surah_list_$_language.json';

      final String jsonString = await rootBundle.loadString(jsonFile);
      final List<dynamic> jsonData = json.decode(jsonString);

      if (mounted) {
        setState(() {
          _surahs = List<Map<String, dynamic>>.from(jsonData);
          _filteredSurahs = _surahs;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  void _filterSurahs(String query) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      if (mounted) {
        setState(() {
          _isSearching = query.isNotEmpty;
          _filteredSurahs = _surahs.where((surah) {
            final name = surah['name'].toString().toLowerCase();
            final num = surah['number'].toString();
            return name.contains(query.toLowerCase()) || num.contains(query);
          }).toList();
        });
      }
    });
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() {
      _filteredSurahs = _surahs;
      _isSearching = false;
    });
  }

  // --- UI BUILD METHODS ---

  @override
  Widget build(BuildContext context) {
    final fontScale = Provider.of<SettingsService>(context).fontScale;

    return Scaffold(
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          _buildAmbientBackground(),
          SafeArea(
            child: Column(
              children: [
                _buildCustomHeader(context, fontScale),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: _buildGlassSearchBar(fontScale),
                ),
                _buildSearchIndicators(fontScale),
                Expanded(
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator(color: Colors.greenAccent))
                      : _filteredSurahs.isEmpty
                      ? _buildEmptyState(fontScale)
                      : _buildSurahList(fontScale),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAmbientBackground() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF0A1A12), Color(0xFF143A2C), Color(0xFF0A1A12)],
        ),
      ),
    );
  }

  Widget _buildCustomHeader(BuildContext context, double fontScale) {
    final emoji = _getEmojiForCurrentView();
    final heroTag = 'hero-tag-$_title';

    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 16, 8),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.1),
              ),
              child: const Icon(Icons.arrow_back_ios_new, size: 20, color: Colors.white),
            ),
          ),
          const SizedBox(width: 8),
          Hero(
            tag: heroTag,
            child: Material(
              type: MaterialType.transparency,
              child: Text(emoji, style: TextStyle(fontSize: 28 * fontScale)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _title,
              style: TextStyle(
                fontSize: 20 * fontScale,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGlassSearchBar(double fontScale) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.18),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.2), width: 1.2),
          ),
          child: TextField(
            controller: _searchController,
            style: TextStyle(fontSize: 16 * fontScale, color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Search surah...',
              hintStyle: TextStyle(color: Colors.white54, fontSize: 16 * fontScale),
              prefixIcon: Icon(Icons.search, color: Colors.greenAccent),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                  icon: const Icon(Icons.clear, color: Colors.white70),
                  onPressed: _clearSearch)
                  : null,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchIndicators(double fontScale) {
    if (_searchController.text.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8),
      child: Row(
        children: [
          Text(
            _isSearching ? 'Searching...' : '${_filteredSurahs.length} results found',
            style: TextStyle(color: Colors.white70, fontSize: 13 * fontScale),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(double fontScale) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off, size: 64, color: Colors.white.withOpacity(0.2)),
          const SizedBox(height: 16),
          Text(
            'No surahs found',
            style: TextStyle(fontSize: 18 * fontScale, color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildSurahList(double fontScale) {
    return ListView.builder(
      controller: _scrollController,
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      itemCount: _filteredSurahs.length,
      itemBuilder: (context, index) {
        final surah = _filteredSurahs[index];
        return FadeTransition(
          opacity: _fadeAnimation,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 12.0),
            child: SurahCard(
              key: ValueKey(surah['number']),
              number: surah['number'],
              name: surah['name'],
              language: _language,
              isTafseer: _isTafseer,
              fontScale: fontScale,
            ),
          ),
        );
      },
    );
  }
}