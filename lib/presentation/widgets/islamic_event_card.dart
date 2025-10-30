// lib/presentation/widgets/islamic_event_card.dart
import 'package:flutter/material.dart';
import '../../data/models/islamic_event_model.dart';

class IslamicEventCard extends StatelessWidget {
  final IslamicEvent event;
  final double fontScale;

  const IslamicEventCard({
    super.key,
    required this.event,
    required this.fontScale,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    Color eventColor;
    IconData eventIcon;

    switch (event.type) {
      case EventType.eid:
        eventColor = Colors.green;
        eventIcon = Icons.celebration;
        break;
      case EventType.ramadan:
        eventColor = Colors.deepPurple;
        eventIcon = Icons.nights_stay;
        break;
      case EventType.hajj:
        eventColor = Colors.amber;
        eventIcon = Icons.flight_takeoff;
        break;
      case EventType.fasting:
        eventColor = Colors.blue;
        eventIcon = Icons.no_food;
        break;
      case EventType.nightOfPower:
        eventColor = Colors.indigo;
        eventIcon = Icons.star;
        break;
      case EventType.islamicNewYear:
        eventColor = Colors.teal;
        eventIcon = Icons.event;
        break;
      case EventType.ashura:
        eventColor = Colors.red;
        eventIcon = Icons.brightness_low;
        break;
      case EventType.other:
      default:
        eventColor = theme.colorScheme.primary;
        eventIcon = Icons.event_note;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12.0),
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min, // Added to prevent overflow
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8.0),
                  decoration: BoxDecoration(
                    color: eventColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    eventIcon,
                    color: eventColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        event.title,
                        style: TextStyle(
                          fontSize: 16 * fontScale,
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onSurface,
                        ),
                        maxLines: 2, // Added maxLines to prevent overflow
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        event.hijriDate.formattedDate,
                        style: TextStyle(
                          fontSize: 14 * fontScale,
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                ),
                if (event.isImportant)
                  Icon(
                    Icons.star,
                    color: Colors.amber,
                    size: 20,
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              event.description,
              style: TextStyle(
                fontSize: 14 * fontScale,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
              ),
              maxLines: 3, // Added maxLines to prevent overflow
              overflow: TextOverflow.ellipsis,
            ),
            if (event.prayerTimeAdjustment != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  event.prayerTimeAdjustment!,
                  style: TextStyle(
                    fontSize: 12 * fontScale,
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}