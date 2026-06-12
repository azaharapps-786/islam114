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

  void _updateTitle() {
    String newTitle;
    if (_isTafseer) {
      switch (_language) {
        case 'assamese': newTitle = 'অসমীয়া কোৰআন তাফসীর'; break;
        case 'english': newTitle = 'English Quran Tafseer'; break;
        case 'hindi': newTitle = 'हिन्दी क़ुरआन तफ़सीर'; break;
        case 'bengali': newTitle = 'বাংলা কোরান তাফসীর'; break;
        default: newTitle = 'Quran Tafseer';
      }
    } else {
      switch (_language) {
        case 'assamese': newTitle = 'অসমীয়া কোৰআন'; break;
        case 'english': newTitle = 'English Quran'; break;
        case 'hindi': newTitle = 'हिन्दी क़ुरआन'; break;
        case 'bengali': newTitle = 'বাংলা কোরান'; break;
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

  @override
  Widget build(BuildContext context) {
    final fontScale = Provider.of<SettingsService>(context).fontScale;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFE8F5E9),
              Color(0xFFC8E6C9),
              Color(0xFFA5D6A7),
              Color(0xFFDCEDC8),
            ],
            stops: [0.0, 0.4, 0.8, 1.0],
          ),
        ),
        child: Column(
          children: [
            _buildAppBar(fontScale),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
              child: _buildSearchBar(fontScale),
            ),
            _buildSearchIndicators(fontScale),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: Color(0xFF2E7D32)))
                  : _filteredSurahs.isEmpty
                  ? _buildEmptyState(fontScale)
                  : _buildSurahList(fontScale),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar(double fontScale) {
    return PreferredSize(
      preferredSize: const Size.fromHeight(kToolbarHeight + 24),
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF2E7D32), Color(0xFF388E3C)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          title: Row(
            children: [
              Text(
                _getEmojiForCurrentView(),
                style: TextStyle(fontSize: 30 * fontScale),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _title,
                  style: TextStyle(
                    fontSize: 21 * fontScale,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar(double fontScale) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade400.withOpacity(0.5),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        style: TextStyle(fontSize: 16.5 * fontScale, color: Colors.grey.shade900),
        decoration: InputDecoration(
          hintText: 'Search surah by name or number...',
          hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 16 * fontScale),
          prefixIcon: Icon(Icons.search, color: const Color(0xFF2E7D32), size: 26),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
            icon: Icon(Icons.clear, color: Colors.grey.shade600),
            onPressed: _clearSearch,
          )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        ),
      ),
    );
  }

  Widget _buildSearchIndicators(double fontScale) {
    if (_searchController.text.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28.0, vertical: 6),
      child: Row(
        children: [
          Text(
            _isSearching ? 'Searching...' : '${_filteredSurahs.length} surahs found',
            style: TextStyle(
              color: Colors.grey.shade700,
              fontSize: 13.5 * fontScale,
              fontWeight: FontWeight.w500,
            ),
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
          Icon(Icons.search_off, size: 88, color: Colors.grey.shade500),
          const SizedBox(height: 24),
          Text(
            'No surahs found',
            style: TextStyle(
              fontSize: 22 * fontScale,
              color: Colors.grey.shade800,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try a different search term',
            style: TextStyle(fontSize: 15 * fontScale, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  Widget _buildSurahList(double fontScale) {
    return ListView.separated(
      controller: _scrollController,
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
      itemCount: _filteredSurahs.length,
      separatorBuilder: (context, index) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final surah = _filteredSurahs[index];
        return FadeTransition(
          opacity: _fadeAnimation,
          child: SurahCard(
            key: ValueKey(surah['number']),
            number: surah['number'],
            name: surah['name'],
            language: _language,
            isTafseer: _isTafseer,
            fontScale: fontScale,
          ),
        );
      },
    );
  }
}