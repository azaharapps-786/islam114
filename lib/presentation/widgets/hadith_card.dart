import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/services/settings_service.dart';
import 'last_read_indicator.dart';

class HadithCard extends StatefulWidget {
  final int hadithNumber;
  final String textAr;
  final String text;
  final String? narrator;
  final double fontScale;
  final bool showArabic;
  final int chapterId;
  final String chapterName;
  final String bookKey;
  final int surahOrChapterNumber; // For share/copy text

  const HadithCard({
    super.key,
    required this.hadithNumber,
    required this.textAr,
    required this.text,
    this.narrator,
    required this.fontScale,
    this.showArabic = true,
    this.chapterId = 0,
    this.chapterName = '',
    this.bookKey = 'bukhari',
    this.surahOrChapterNumber = 0,
  });

  @override
  State<HadithCard> createState() => _HadithCardState();
}

class _HadithCardState extends State<HadithCard> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _isHighlighted = false;

  static const Color _highlightColor = Color(0xFFFFF9C4);
  static const Color _highlightBorderColor = Color(0xFFFBC02D);

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
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) => _controller.forward();
  void _onTapUp(TapUpDetails details) => _controller.reverse();
  void _onTapCancel() => _controller.reverse();

  void _toggleHighlight() {
    HapticFeedback.lightImpact();
    setState(() => _isHighlighted = !_isHighlighted);
  }

  void _shareHadith() {
    final prefix = 'Hadith ${widget.hadithNumber} (Chapter ${widget.surahOrChapterNumber})';
    final text = widget.showArabic
        ? '$prefix\n\n${widget.textAr}\n\n${widget.text}'
        : '$prefix\n\n${widget.text}';
    Clipboard.setData(ClipboardData(text: text)); // Using clipboard as fallback
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Hadith text copied to clipboard (Share not available)'),
        duration: Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _copyHadith() {
    final prefix = 'Hadith ${widget.hadithNumber} (Chapter ${widget.surahOrChapterNumber})';
    final text = widget.showArabic
        ? '$prefix\n\n${widget.textAr}\n\n${widget.text}'
        : '$prefix\n\n${widget.text}';
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Hadith copied'),
        duration: Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _toggleMarkAsLastRead() {
    final settings = Provider.of<SettingsService>(context, listen: false);

    // Check if currently marked
    final isCurrentlyMarked = settings.isHadithLastRead(
      widget.bookKey,
      widget.chapterId,
      widget.hadithNumber,
    );

    if (isCurrentlyMarked) {
      // UNMARK: Remove the last read mark for this chapter
      settings.clearLastReadHadith(widget.bookKey, widget.chapterId);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Last read mark removed'),
          duration: Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      // MARK: Set as last read
      settings.markHadithLastRead(
        bookKey: widget.bookKey,
        chapterId: widget.chapterId,
        hadithNumber: widget.hadithNumber,
        chapterName: widget.chapterName.isNotEmpty ? widget.chapterName : 'Chapter ${widget.chapterId}',
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Marked hadith ${widget.hadithNumber} as last read'),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Consumer<SettingsService>(
      builder: (context, settingsService, child) {
        // Check if this hadith is marked as last read
        final bool isLastRead = settingsService.isHadithLastRead(
          widget.bookKey,
          widget.chapterId,
          widget.hadithNumber,
        );
        final lastReadData = isLastRead
            ? settingsService.getLastReadHadith(widget.bookKey, widget.chapterId)
            : null;

        return AnimatedBuilder(
          animation: _scaleAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: _scaleAnimation.value,
              child: GestureDetector(
                onTapDown: _onTapDown,
                onTapUp: _onTapUp,
                onTapCancel: _onTapCancel,
                onLongPress: _toggleHighlight, // LONG PRESS HIGHLIGHT
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Last Read Indicator (only shows if marked)
                      if (isLastRead && lastReadData != null)
                        Padding(
                          padding: const EdgeInsets.only(left: 16, right: 16, top: 16),
                          child: LastReadIndicator(
                            itemName: lastReadData['itemName'] ?? widget.chapterName,
                            itemNumber: widget.hadithNumber,
                            timestamp: lastReadData['timestamp'] ?? 0,
                            fontScale: widget.fontScale,
                            itemTypeLabel: 'Hadith',
                          ),
                        ),

                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: _isHighlighted
                                        ? _highlightBorderColor.withOpacity(0.3)
                                        : theme.colorScheme.primary.withOpacity(0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Text(
                                    '${widget.hadithNumber}',
                                    style: TextStyle(
                                      fontSize: 12 * widget.fontScale,
                                      fontWeight: FontWeight.bold,
                                      color: _isHighlighted ? _highlightBorderColor : theme.colorScheme.primary,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                if (widget.narrator != null && widget.narrator!.isNotEmpty)
                                  Expanded(
                                    child: Text(
                                      'Narrated by: ${widget.narrator}',
                                      style: TextStyle(
                                        fontSize: 12 * widget.fontScale,
                                        fontStyle: FontStyle.italic,
                                        color: theme.colorScheme.onSurface.withOpacity(0.7),
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                const Spacer(),
                                // Show AzaharApps when highlighted
                                if (_isHighlighted)
                                  Padding(
                                    padding: const EdgeInsets.only(right: 8.0),
                                    child: Text(
                                      'AzaharApps',
                                      style: TextStyle(
                                        fontSize: 12 * widget.fontScale,
                                        color: _highlightBorderColor,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                // 3-dot menu
                                PopupMenuButton<String>(
                                  icon: Icon(
                                    Icons.more_vert,
                                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                                  ),
                                  onSelected: (value) {
                                    if (value == 'share') _shareHadith();
                                    if (value == 'copy') _copyHadith();
                                    if (value == 'mark_last_read') _toggleMarkAsLastRead();
                                  },
                                  itemBuilder: (context) => [
                                    const PopupMenuItem(
                                      value: 'share',
                                      child: Row(
                                        children: [
                                          Icon(Icons.share, size: 20),
                                          SizedBox(width: 8),
                                          Text('Share'),
                                        ],
                                      ),
                                    ),
                                    const PopupMenuItem(
                                      value: 'copy',
                                      child: Row(
                                        children: [
                                          Icon(Icons.copy, size: 20),
                                          SizedBox(width: 8),
                                          Text('Copy'),
                                        ],
                                      ),
                                    ),
                                    const PopupMenuDivider(),
                                    PopupMenuItem(
                                      value: 'mark_last_read',
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.bookmark_add_rounded,
                                            size: 20,
                                            color: isLastRead ? Colors.red : Colors.blue,
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            isLastRead ? 'Unmark as Last Read' : 'Mark as Last Read',
                                            style: TextStyle(
                                              color: isLastRead ? Colors.red : null,
                                              fontWeight: isLastRead ? FontWeight.w600 : null,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),

                            // Arabic Text
                            if (widget.showArabic && widget.textAr.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 8.0),
                                child: Text(
                                  widget.textAr,
                                  style: TextStyle(
                                    fontSize: 18 * widget.fontScale,
                                    fontWeight: FontWeight.w500,
                                    color: theme.colorScheme.onSurface,
                                    height: 1.5,
                                  ),
                                  textAlign: TextAlign.right,
                                ),
                              ),

                            // English Text
                            if (widget.text.isNotEmpty)
                              Text(
                                widget.text,
                                style: TextStyle(
                                  fontSize: 14 * widget.fontScale,
                                  color: theme.colorScheme.onSurface.withOpacity(0.8),
                                  height: 1.5,
                                ),
                              ),

                            // Empty state
                            if (widget.textAr.isEmpty && widget.text.isEmpty)
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Text(
                                  'No text available for this hadith.',
                                  style: TextStyle(
                                    fontSize: 14 * widget.fontScale,
                                    color: theme.colorScheme.onSurface.withOpacity(0.5),
                                    fontStyle: FontStyle.italic,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}