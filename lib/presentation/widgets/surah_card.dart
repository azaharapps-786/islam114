// lib/presentation/widgets/surah_card.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class SurahCard extends StatefulWidget {
  final int number;
  final String name;
  final String language;
  final double fontScale;

  const SurahCard({
    super.key,
    required this.number,
    required this.name,
    required this.language,
    required this.fontScale,
  });

  @override
  State<SurahCard> createState() => _SurahCardState();
}

class _SurahCardState extends State<SurahCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    _controller.forward();
    HapticFeedback.lightImpact();
  }

  void _onTapUp(TapUpDetails details) {
    _controller.reverse();
    Navigator.pushNamed(
      context,
      '/surahDetail',
      arguments: {
        'surahNumber': widget.number,
        'language': widget.language,
        'isTafseer': false, // Set to true for tafseer pages
      },
    );
  }

  void _onTapCancel() {
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Card(
              margin: const EdgeInsets.only(bottom: 12.0),
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.0),
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.all(16.0),
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  child: Center(
                    child: Text(
                      '${widget.number}',
                      style: TextStyle(
                        fontSize: 16 * widget.fontScale,
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ),
                ),
                title: Text(
                  widget.name,
                  style: TextStyle(
                    fontSize: 16 * widget.fontScale,
                    fontWeight: FontWeight.w500,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                trailing: Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                ),
                onTap: () {
                  Navigator.pushNamed(
                    context,
                    '/surahDetail',
                    arguments: {
                      'surahNumber': widget.number,
                      'language': widget.language,
                      'isTafseer': false, // Set to true for tafseer pages
                    },
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }
}