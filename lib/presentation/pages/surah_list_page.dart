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
  int _animationKey = 0; // Key to force recreation of animated elements

  @override
  void initState() {
    super.initState();
    // We load the data here, it doesn't depend on context
    _allSurahs = SurahDataService.getAllSurahs();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );

    _restartAnimation(); // Initialize animations
  }

  // This is the correct place for logic that depends on InheritedWidgets (like ModalRoute)
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Get the language passed from the home screen
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is String) {
      _languageCode = args;
    } else {
      _languageCode = 'english'; // Default fallback
    }
    // We call setState here to rebuild the UI with the correct language
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  // Restart the page animations and trigger a rebuild for list items.
  void _restartAnimation() {
    _animationController.reset();
    _animationController.forward();
    _animationKey++;
    // Force a rebuild to replay list animations via key changes.
    if (mounted) {
      setState(() {});
    }
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
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Column(
            children: [
              // Search Bar
              TweenAnimationBuilder<double>(
                key: ValueKey('search-bar-$_animationKey'),
                duration: const Duration(milliseconds: 400),
                tween: Tween(begin: 0.0, end: 1.0),
                curve: Curves.easeOut,
                builder: (context, value, child) {
                  return Transform.translate(
                    offset: Offset(0, 20 * (1 - value)),
                    child: Transform.scale(
                      scale: value,
                      child: Opacity(
                        opacity: value,
                        child: child,
                      ),
                    ),
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (value) {
                      setState(() {
                        _animationKey++; // Trigger rebuild with new key for filtered list animation
                      });
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
              ),
              // Surah List
              Expanded(
                child: _buildSurahList(fontScale),
              ),
            ],
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
      return TweenAnimationBuilder<double>(
        key: ValueKey('empty-list-$_animationKey'),
        duration: const Duration(milliseconds: 500),
        tween: Tween(begin: 0.0, end: 1.0),
        curve: Curves.easeOut,
        builder: (context, value, child) {
          return Transform.translate(
            offset: Offset(0, 20 * (1 - value)),
            child: Transform.scale(
              scale: value,
              child: Opacity(
                opacity: value,
                child: child,
              ),
            ),
          );
        },
        child: const Center(child: Text('No results found.')),
      );
    }

    return ListView.builder(
      key: ValueKey('surah-list-$_animationKey'), // Key for list recreation on search or animation restart
      itemCount: filteredSurahs.length,
      itemBuilder: (context, index) {
        final surah = filteredSurahs[index];
        return TweenAnimationBuilder<double>(
          key: ValueKey('surah-item-$index-$_animationKey'), // Staggered key
          duration: Duration(milliseconds: 300 + (index * 50)),
          tween: Tween(begin: 0.0, end: 1.0),
          curve: Curves.easeOut,
          builder: (context, itemValue, child) {
            return Transform.translate(
              offset: Offset(0, 20 * (1 - itemValue)),
              child: Transform.scale(
                scale: itemValue,
                child: Opacity(
                  opacity: itemValue,
                  child: child,
                ),
              ),
            );
          },
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