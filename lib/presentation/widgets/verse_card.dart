import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'dart:convert';

import '../../core/services/settings_service.dart';

class VerseCard extends StatefulWidget {
  final int surahNumber;
  final int verseNumber;
  final String arabic;
  final String translation;
  final String transliteration;
  final String tafseer;
  final String footnotes;
  final String language;
  final bool isTafseer;
  final bool isBookmarked;
  final double fontScale;
  final VoidCallback onShare;
  final VoidCallback onCopy;
  final VoidCallback onBookmark;

  const VerseCard({
    super.key,
    required this.surahNumber,
    required this.verseNumber,
    required this.arabic,
    required this.translation,
    required this.transliteration,
    required this.tafseer,
    this.footnotes = '',
    required this.language,
    required this.isTafseer,
    required this.isBookmarked,
    required this.fontScale,
    required this.onShare,
    required this.onCopy,
    required this.onBookmark,
  });

  @override
  State<VerseCard> createState() => _VerseCardState();
}

class _VerseCardState extends State<VerseCard> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _isExpanded = false;
  bool _showFootnotes = false;
  bool _isHighlighted = false;

  Map<String, String> _additionalTranslations = {};

  static const Color _highlightColor = Color(0xFFFFF9C4); // Light Yellow (Material Yellow 100)
  static const Color _highlightBorderColor = Color(0xFFFBC02D); // Deep Yellow (Material Yellow 700)

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.98).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadAdditionalTranslations();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _loadAdditionalTranslations() async {
    final settingsService = Provider.of<SettingsService>(context, listen: false);
    // Correctly calls the method we added to SettingsService
    final displaySettings = settingsService.getSurahDisplaySettings(widget.language, widget.isTafseer);

    final Map<String, String> newTranslations = {};

    for (final entry in displaySettings.additionalTranslations.entries) {
      if (!entry.value) continue;

      final String lang = entry.key;
      try {
        final String jsonString = await rootBundle.loadString('assets/data/quran_$lang.json');
        final dynamic rawJson = json.decode(jsonString);

        String? verseText;

        if (rawJson is List) {
          if (rawJson.isNotEmpty && (rawJson[0].containsKey('sura') || rawJson[0].containsKey('surah'))) {
            final verseData = rawJson.firstWhere(
                  (v) => ((v['sura'] ?? v['surah']) as num?)?.toInt() == widget.surahNumber &&
                  (v['aya'] as num?)?.toInt() == widget.verseNumber,
              orElse: () => null,
            );
            verseText = verseData?['translation'] ?? '';
          } else if (rawJson.isNotEmpty && rawJson[0].containsKey('verses')) {
            final surahData = rawJson.firstWhere(
                  (s) => (s['id'] as num?)?.toInt() == widget.surahNumber,
              orElse: () => null,
            );
            if (surahData != null) {
              final versesList = surahData['verses'] as List?;
              final verseData = versesList?.firstWhere(
                    (v) => (v['aya'] as num?)?.toInt() == widget.verseNumber,
                orElse: () => null,
              );
              verseText = verseData?['translation'] ?? verseData?['text'] ?? '';
            }
          }
        }

        if (verseText != null && verseText.isNotEmpty) {
          newTranslations[lang] = verseText;
        }
      } catch (e) {
        debugPrint('Failed to load additional $lang translation: $e');
      }
    }

    if (mounted) {
      setState(() => _additionalTranslations = newTranslations);
    }
  }

  void _onTapDown(TapDownDetails details) => _controller.forward();
  void _onTapUp(TapUpDetails details) => _controller.reverse();
  void _onTapCancel() => _controller.reverse();

  void _toggleHighlight() {
    HapticFeedback.lightImpact();
    setState(() {
      _isHighlighted = !_isHighlighted;
    });
  }

  String _capitalize(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final settings = Provider.of<SettingsService>(context);
    final displaySettings = settings.getSurahDisplaySettings(widget.language, widget.isTafseer);

    final bool tafseerExpanded = widget.isTafseer ? true : _isExpanded;

    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: GestureDetector(
            onLongPress: _toggleHighlight,
            child: Card(
              margin: const EdgeInsets.only(bottom: 16.0),
              elevation: _isHighlighted ? 8 : 2,
              color: _isHighlighted ? _highlightColor : theme.cardColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.0),
                side: _isHighlighted
                    ? const BorderSide(color: _highlightBorderColor, width: 2.0)
                    : BorderSide.none,
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: _isHighlighted
                                ? _highlightBorderColor.withOpacity(0.3)
                                : theme.colorScheme.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                          child: Text(
                            '${widget.surahNumber}:${widget.verseNumber}',
                            style: TextStyle(
                              fontSize: 14 * widget.fontScale,
                              fontWeight: FontWeight.bold,
                              color: _isHighlighted ? _highlightBorderColor : theme.colorScheme.primary,
                            ),
                          ),
                        ),
                        const Spacer(),
                        if (_isHighlighted)
                          Padding(
                            padding: const EdgeInsets.only(right: 8.0),
                            child: Text(
                              'Highlighted',
                              style: TextStyle(
                                fontSize: 12 * widget.fontScale,
                                color: _highlightBorderColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        IconButton(
                          icon: Icon(
                            widget.isBookmarked ? Icons.star : Icons.star_border,
                            color: widget.isBookmarked
                                ? Colors.amber
                                : theme.colorScheme.onSurface.withOpacity(0.6),
                          ),
                          onPressed: widget.onBookmark,
                        ),
                        PopupMenuButton<String>(
                          icon: Icon(Icons.more_vert, color: theme.colorScheme.onSurface.withOpacity(0.6)),
                          onSelected: (value) {
                            if (value == 'share') widget.onShare();
                            if (value == 'copy') widget.onCopy();
                          },
                          itemBuilder: (context) => [
                            const PopupMenuItem(value: 'share', child: Row(children: [Icon(Icons.share, size: 20), SizedBox(width: 8), Text('Share')])),
                            const PopupMenuItem(value: 'copy', child: Row(children: [Icon(Icons.copy, size: 20), SizedBox(width: 8), Text('Copy')])),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    if (!widget.isTafseer) ...[
                      if (displaySettings.showArabic && widget.arabic.isNotEmpty) ...[
                        Text(
                          widget.arabic,
                          style: TextStyle(
                            fontSize: 20 * widget.fontScale,
                            fontFamily: 'Uthmanic',
                            height: 1.5,
                            color: theme.colorScheme.onSurface,
                          ),
                          textAlign: TextAlign.right,
                          textDirection: TextDirection.rtl,
                        ),
                        const SizedBox(height: 12),
                      ],

                      if (displaySettings.showTransliteration && widget.transliteration.isNotEmpty) ...[
                        Text(
                          widget.transliteration,
                          style: TextStyle(
                            fontSize: 14 * widget.fontScale,
                            fontStyle: FontStyle.italic,
                            color: theme.colorScheme.onSurface.withOpacity(0.8),
                          ),
                        ),
                        const SizedBox(height: 8),
                      ],

                      if (displaySettings.showTranslation && widget.translation.isNotEmpty) ...[
                        Text(
                          widget.translation,
                          style: TextStyle(fontSize: 16 * widget.fontScale, color: theme.colorScheme.onSurface),
                        ),
                        const SizedBox(height: 12),
                      ],
                    ],

                    if (!widget.isTafseer)
                      ..._additionalTranslations.entries.map((entry) {
                        return Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${_capitalize(entry.key)} Translation',
                                style: TextStyle(
                                  fontSize: 12 * widget.fontScale,
                                  fontWeight: FontWeight.bold,
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                entry.value,
                                style: TextStyle(
                                  fontSize: 15 * widget.fontScale,
                                  color: theme.colorScheme.onSurface.withOpacity(0.85),
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),

                    if (widget.footnotes.isNotEmpty) ...[
                      GestureDetector(
                        onTap: () => setState(() => _showFootnotes = !_showFootnotes),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          margin: const EdgeInsets.only(bottom: 8),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.secondary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.info_outline, size: 16, color: theme.colorScheme.secondary),
                              const SizedBox(width: 8),
                              Text('Footnotes', style: TextStyle(fontSize: 12 * widget.fontScale, color: theme.colorScheme.secondary)),
                              const Spacer(),
                              Icon(_showFootnotes ? Icons.expand_less : Icons.expand_more, size: 16, color: theme.colorScheme.secondary),
                            ],
                          ),
                        ),
                      ),
                      if (_showFootnotes)
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.secondary.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: theme.colorScheme.secondary.withOpacity(0.2)),
                          ),
                          child: Text(
                            widget.footnotes,
                            style: TextStyle(fontSize: 12 * widget.fontScale, color: theme.colorScheme.onSurface.withOpacity(0.8)),
                          ),
                        ),
                    ],

                    if (widget.tafseer.isNotEmpty && (widget.isTafseer || displaySettings.showTafseer)) ...[
                      GestureDetector(
                        onTap: widget.isTafseer ? null : () => setState(() => _isExpanded = !_isExpanded),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: _isHighlighted
                                ? _highlightBorderColor.withOpacity(0.15)
                                : theme.colorScheme.primary.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: _isHighlighted
                                  ? _highlightBorderColor.withOpacity(0.5)
                                  : theme.colorScheme.primary.withOpacity(0.2),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    'Tafseer',
                                    style: TextStyle(
                                      fontSize: 16 * widget.fontScale,
                                      fontWeight: FontWeight.bold,
                                      color: _isHighlighted ? _highlightBorderColor : theme.colorScheme.primary,
                                    ),
                                  ),
                                  const Spacer(),
                                  if (!widget.isTafseer)
                                    Icon(
                                      _isExpanded ? Icons.expand_less : Icons.expand_more,
                                      color: _isHighlighted ? _highlightBorderColor : theme.colorScheme.primary,
                                    ),
                                ],
                              ),
                              if (tafseerExpanded) ...[
                                const SizedBox(height: 12),
                                Text(
                                  widget.tafseer,
                                  style: TextStyle(
                                    fontSize: 15 * widget.fontScale,
                                    color: theme.colorScheme.onSurface,
                                    height: 1.6,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}