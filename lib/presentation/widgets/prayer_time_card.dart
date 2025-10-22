import 'package:flutter/material.dart';
import '../../data/models/prayer_times_model.dart';

class PrayerTimeCard extends StatelessWidget {
  final PrayerTime prayerTime;
  final double fontScale;
  final bool azanEnabledForPrayer;

  const PrayerTimeCard({
    super.key,
    required this.prayerTime,
    required this.fontScale,
    this.azanEnabledForPrayer = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: prayerTime.isNext
            ? theme.colorScheme.primary.withValues(alpha: 0.1)
            : theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: prayerTime.isNext
              ? theme.colorScheme.primary.withValues(alpha: 0.3)
              : theme.colorScheme.outline.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Prayer name
            Expanded(
              flex: 2,
              child: Row(
                children: [
                  Text(
                    prayerTime.name,
                    style: TextStyle(
                      fontSize: 16 * fontScale,
                      fontWeight: prayerTime.isNext ? FontWeight.bold : FontWeight.normal,
                      color: prayerTime.isNext
                          ? theme.colorScheme.primary
                          : theme.colorScheme.onSurface,
                    ),
                  ),
                  if (azanEnabledForPrayer) ...[
                    const SizedBox(width: 8),
                    Icon(
                      Icons.volume_up,
                      size: 16 * fontScale,
                      color: theme.colorScheme.primary,
                    ),
                  ],
                ],
              ),
            ),

            // Prayer time
            Expanded(
              child: Text(
                _formatTime(prayerTime.time),
                textAlign: TextAlign.right,
                style: TextStyle(
                  fontSize: 16 * fontScale,
                  fontWeight: prayerTime.isNext ? FontWeight.bold : FontWeight.normal,
                  color: prayerTime.isNext
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurface,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(String time24) {
    try {
      final parts = time24.split(':');
      final hour = int.parse(parts[0]);
      final minute = parts[1];

      final hour12 = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
      final ampm = hour >= 12 ? 'PM' : 'AM';

      return '$hour12:$minute $ampm';
    } catch (e) {
      return time24;
    }
  }
}