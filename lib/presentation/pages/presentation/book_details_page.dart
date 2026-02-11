import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../core/services/settings_service.dart';

class BookDetailsPage extends StatefulWidget {
  final String? chapterId;      // "5", "14", "intro", "conclusion", etc.

  const BookDetailsPage({
    super.key,
    this.chapterId,
  });

  @override
  State<BookDetailsPage> createState() => _BookDetailsPageState();
}

class _BookDetailsPageState extends State<BookDetailsPage> {
  Map<String, dynamic>? fullContent;
  Map<String, dynamic>? displayedContent;
  bool isLoading = true;
  String? errorMessage;
  String displayTitle = 'Introduction';

  @override
  void initState() {
    super.initState();
    _loadContent();
  }

  Future<void> _loadContent() async {
    const String path = 'assets/books/quran_and_science/book_content.json';

    try {
      final String jsonString = await rootBundle.loadString(path);
      final data = json.decode(jsonString);

      if (!mounted) return;

      setState(() {
        fullContent = data;
        isLoading = false;
      });

      _selectContent();
    } catch (e) {
      if (!mounted) return;

      setState(() {
        errorMessage = e.toString().contains('Unable to load asset')
            ? 'Cannot load book content:\n$path\n\nFix:\n1. File exists\n2. pubspec.yaml → assets:\n   - assets/books/\n\nRun: flutter clean && flutter pub get'
            : e.toString();
        isLoading = false;
      });
    }
  }

  void _selectContent() {
    if (fullContent == null) return;

    String newTitle = 'Introduction';
    Map<String, dynamic>? selected;

    final requestedId = widget.chapterId?.trim();

    if (requestedId != null && requestedId.isNotEmpty) {
      final requestedNum = int.tryParse(requestedId);

      // 1. Match chapters by numeric ID
      final parts = fullContent!['parts'] as List<dynamic>? ?? [];
      bool found = false;
      for (final part in parts) {
        final chapters = (part as Map<String, dynamic>)['chapters'] as List<dynamic>? ?? [];
        for (final chapter in chapters) {
          final chapterMap = chapter as Map<String, dynamic>;
          final chapterId = chapterMap['id'];
          if (chapterId == requestedNum || chapterId?.toString() == requestedId) {
            selected = chapterMap;
            newTitle = chapterMap['title'] ?? 'Chapter $requestedId';
            found = true;
            break;
          }
        }
        if (found) break;
      }

      // 2. Special sections by string ID
      if (!found) {
        switch (requestedId) {
          case 'intro':
            selected = fullContent!['introduction'];
            newTitle = selected?['title'] ?? 'Introduction';
            break;
          case 'conclusion':
            selected = fullContent!['conclusion'];
            newTitle = selected?['title'] ?? 'Conclusion';
            break;
          case 'glossary':
            selected = fullContent!['backMatter']?['glossary'];
            newTitle = 'Glossary';
            break;
          case 'bibliography':
            selected = fullContent!['backMatter']?['bibliography'];
            newTitle = 'Bibliography';
            break;
          case 'about':
            selected = fullContent!['backMatter']?['aboutTheAuthor'];
            newTitle = 'About the Author';
            break;
        }
      }
    }

    // Fallback: introduction
    if (selected == null) {
      selected = fullContent!['introduction'] as Map<String, dynamic>?;
      newTitle = selected?['title'] ?? 'Introduction';
    }

    if (mounted) {
      setState(() {
        displayedContent = selected;
        displayTitle = newTitle;
      });
    }
  }

  Widget _buildSection(Map<String, dynamic> section) {
    final title = section['title'] as String?;
    final contentText = section['content'] as String?;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (title != null && title.trim().isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 28, bottom: 12),
            child: Text(
              title.trim(),
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0A4D4D),
              ),
            ),
          ),
        if (contentText != null && contentText.trim().isNotEmpty)
          Text(
            contentText.trim(),
            style: const TextStyle(
              fontSize: 17,
              height: 1.65,
              color: Colors.black87,
            ),
          ),
        const SizedBox(height: 20),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsService>(context);
    final double fontScale = settings.fontScale;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FCFB),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFF0A4D4D),
        title: Text(
          displayTitle,
          style: TextStyle(
            fontSize: (20 * fontScale).clamp(18, 24),
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : errorMessage != null
          ? Center(child: Text('Error: $errorMessage'))
          : displayedContent == null
          ? const Center(child: Text('No content available'))
          : SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (displayedContent!['title'] != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 20),
                child: Text(
                  displayedContent!['title'],
                  style: TextStyle(
                    fontSize: (24 * fontScale).clamp(20, 28),
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF0A4D4D),
                  ),
                ),
              ),
            ...(displayedContent!['sections'] as List<dynamic>? ?? [])
                .map((s) => _buildSection(s as Map<String, dynamic>))
                .toList(),
            const SizedBox(height: 60),
          ],
        ),
      ),
    );
  }
}