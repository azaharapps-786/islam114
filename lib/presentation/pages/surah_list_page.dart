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

class _SurahListPageState extends State<SurahListPage> {
  late List<Surah> _allSurahs;
  late String _languageCode;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // We load the data here, it doesn't depend on context
    _allSurahs = SurahDataService.getAllSurahs();
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
      body: Column(
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
        return SurahListItem(
          surah: surah,
          surahName: _getSurahName(surah),
          fontScale: fontScale,
          onTap: () {
            // HapticFeedback.light(HapticFeedbackType.selection); //
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Tapped on ${_getSurahName(surah)}'),
                duration: const Duration(seconds: 1),
              ),
            );
          },
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