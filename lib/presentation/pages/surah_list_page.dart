import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:haptic_feedback/haptic_feedback.dart';

import '../../core/services/settings_service.dart';
import '../../data/models/surah_model.dart';
import '../../data/services/surah_data_service.dart';
import '../widgets/surah_list_item.dart';

class SurahListPage extends StatefulWidget {
  const SurahListPage({super.key});

  @override
  State<SurahListPage> createState() => _SurahListPageState();
}

class _SurahListPageState extends State<SurahListPage> with TickerProviderStateMixin {
  late List<Surah> _allSurahs;
  late String _languageCode;
  final TextEditingController _searchController = TextEditingController();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _allSurahs = SurahDataService.getAllSurahs();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOut,
      ),
    );
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.elasticOut,
      ),
    );

    _animationController.forward();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is String) {
      _languageCode = args;
    } else {
      _languageCode = 'english';
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double fontScale = Provider.of<SettingsService>(context).fontScale;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          '114 Surah List (${_languageCode.toUpperCase()})',
          style: TextStyle(fontSize: 18 * fontScale),
        ),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        elevation: 4,
      ),
      body: SafeArea(
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Column(
              children: [
                // Search Bar
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (value) {
                      setState(() {});
                    },
                    decoration: InputDecoration(
                      hintText: 'Search by name or number...',
                      prefixIcon: const Icon(Icons.search),
                      filled: true,
                      fillColor: Theme.of(context).cardColor,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.0),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                // Surah List
                Expanded(
                  child: _buildSurahList(fontScale),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSurahList(double fontScale) {
    final filteredSurahs = _allSurahs.where((surah) {
      final query = _searchController.text.toLowerCase();
      final surahName = _getSurahName(surah).toLowerCase();
      final surahNumber = surah.id.toString();
      return surahName.contains(query) || surahNumber.contains(query);
    }).toList();

    if (filteredSurahs.isEmpty) {
      return const Center(child: Text('No results found.'));
    }

    return ListView.builder(
      itemCount: filteredSurahs.length,
      itemBuilder: (context, index) {
        final surah = filteredSurahs[index];
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          child: SurahListItem(
            surah: surah,
            surahName: _getSurahName(surah),
            fontScale: fontScale,
            onTap: () {
              //  HapticFeedback.light(HapticFeedbackType.selection);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Tapped on ${_getSurahName(surah)}'),
                  duration: const Duration(seconds: 1),
                ),
              );
            },
          ),
        );
      },
    );
  }

  String _getSurahName(Surah surah) {
    switch (_languageCode.toLowerCase()) {
      case 'arabic':
        return surah.name;
      case 'assamese':
        return surah.assameseName;
      case 'hindi':
        return surah.hindiName;
      case 'english':
      default:
        return surah.transliteration;
    }
  }
}