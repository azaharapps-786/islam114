// lib/presentation/widgets/verse_card.dart
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
  bool _isExpanded = false;        // For collapsible tafseer in normal mode
  bool _showFootnotes = false;

  Map<String, String> _additionalTranslations = {};

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
    final displaySettings = settingsService.surahDisplaySettings[widget.language];

    if (displaySettings == null) return;

    final newTranslations = <String, String>{};
    final enabledLanguages = displaySettings.additionalTranslations;

    for (final entry in enabledLanguages.entries) {
      if (entry.value) {
        final lang = entry.key;
        try {
          final String jsonString = await rootBundle.loadString('assets/data/quran_$lang.json');
          final List<dynamic> jsonData = json.decode(jsonString);

          final verseData = jsonData.firstWhere(
                (v) => (v['sura'] as num?)?.toInt() == widget.surahNumber &&
                (v['aya'] as num?)?.toInt() == widget.verseNumber,
            orElse: () => null,
          );

          if (verseData != null) {
            newTranslations[lang] = verseData['translation'] ?? '';
          }
        } catch (e) {
          debugPrint('Error loading translation for $lang: $e');
        }
      }
    }

    if (mounted) {
      setState(() {
        _additionalTranslations = newTranslations;
      });
    }
  }

  void _onTapDown(TapDownDetails details) => _controller.forward();
  void _onTapUp(TapUpDetails details) => _controller.reverse();
  void _onTapCancel() => _controller.reverse();

  String _capitalize(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final settings = Provider.of<SettingsService>(context);
    final displaySettings = settings.surahDisplaySettings[widget.language] ??
        SurahDisplaySettings.defaultFor(widget.language);

    // In pure Tafseer mode, force expand tafseer
    final bool tafseerExpanded = widget.isTafseer ? true : _isExpanded;

    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Card(
            margin: const EdgeInsets.only(bottom: 16.0),
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Verse header
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                        child: Text(
                          '${widget.surahNumber}:${widget.verseNumber}',
                          style: TextStyle(
                            fontSize: 14 * widget.fontScale,
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: Icon(
                          widget.isBookmarked ? Icons.star : Icons.star_border,
                          color: widget.isBookmarked ? Colors.amber : theme.colorScheme.onSurface.withOpacity(0.6),
                        ),
                        onPressed: widget.onBookmark,
                        tooltip: widget.isBookmarked ? 'Remove bookmark' : 'Add bookmark',
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

                  // === Hide Arabic, Transliteration, Translation in pure Tafseer mode ===
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

                  // Additional Translations (only in normal mode)
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

                  // Footnotes
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

                  // === TAFSEER SECTION - ALWAYS VISIBLE IN PURE TAFSEER MODE ===
                  if (widget.tafseer.isNotEmpty &&
                      (widget.isTafseer || displaySettings.showTafseer)) ...[
                    GestureDetector(
                      onTap: widget.isTafseer ? null : () => setState(() => _isExpanded = !_isExpanded),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: theme.colorScheme.primary.withOpacity(0.2)),
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
                                    color: theme.colorScheme.primary,
                                  ),
                                ),
                                const Spacer(),
                                if (!widget.isTafseer) // Only show arrow in normal mode
                                  Icon(
                                    _isExpanded ? Icons.expand_less : Icons.expand_more,
                                    color: theme.colorScheme.primary,
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
        );
      },
    );
  }
}