import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class HomeFeatureCard extends StatelessWidget {
  final String title;
  final String? iconPath;
  final VoidCallback onTap;
  final String emojiIcon;

  const HomeFeatureCard({
    super.key,
    required this.title,
    this.iconPath,
    required this.onTap,
    required this.emojiIcon,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(
                child: _buildIcon(context), // Use a helper method for the icon
              ),
              const SizedBox(height: 8),
              Text(
                title,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Helper widget to decide which icon to show
  // Helper widget to decide which icon to show
  Widget _buildIcon(BuildContext context) {
    // FIX: Now we check if the iconPath is not null and not empty
    if (iconPath != null && iconPath!.isNotEmpty) {
      return SvgPicture.asset(
        iconPath!,
        width: 40,
        height: 40,
        // FIX: REMOVED the colorFilter to show the original SVG colors
      );
    }

    // Fallback to a simple Text Icon (Emoji) if SVG is not found
    return Text(
      emojiIcon,
      style: TextStyle(
        fontSize: 40,
        color: Theme.of(context).colorScheme.primary,
      ),
    );
  }
}