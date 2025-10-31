// lib/presentation/widgets/more_option_card.dart
import 'package:flutter/material.dart';

class MoreOptionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final double fontScale;
  final VoidCallback onTap;

  const MoreOptionCard({
    super.key,
    required this.title,
    required this.icon,
    required this.color,
    required this.fontScale,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: theme.colorScheme.surface,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                // Reduced container size
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: color,
                  // Reduced icon size
                  size: (24 * fontScale).clamp(20.0, 28.0),
                ),
              ),
              const SizedBox(height: 12),
              // Use LayoutBuilder to make text adaptive to available space
              LayoutBuilder(
                builder: (context, constraints) {
                  // Calculate appropriate font size based on available width
                  double availableWidth = constraints.maxWidth;

                  // REDUCED BASE FONT SIZE from 16.0 to 14.0
                  double fontSize = 14.0 * fontScale; // Changed from 16.0

                  // Adjust font size based on text length and available width
                  // Also REDUCED these values
                  if (title.length > 10 && availableWidth < 120) {
                    fontSize = 10.0 * fontScale; // Changed from 12.0
                  } else if (title.length > 15 && availableWidth < 150) {
                    fontSize = 9.0 * fontScale; // Changed from 11.0
                  } else if (title.length > 8 && availableWidth < 100) {
                    fontSize = 11.0 * fontScale; // Changed from 13.0
                  }

                  // REDUCED the font size bounds
                  fontSize = fontSize.clamp(8.0, 16.0); // Changed from 10.0, 18.0

                  return FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      title,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onSurface,
                        fontSize: fontSize,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}