import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Shows a red indicator above a verse/hadith that is marked as last read
class LastReadIndicator extends StatelessWidget {
  final String itemName;
  final int itemNumber;
  final int timestamp;
  final double fontScale;
  final String itemTypeLabel;

  const LastReadIndicator({
    super.key,
    required this.itemName,
    required this.itemNumber,
    required this.timestamp,
    required this.fontScale,
    this.itemTypeLabel = 'Verse',
  });

  @override
  Widget build(BuildContext context) {
    final dateTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final dateStr = DateFormat('MMM d, yyyy').format(dateTime);
    final timeStr = DateFormat('h:mm a').format(dateTime);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: 12 * fontScale,
        vertical: 10 * fontScale,
      ),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: Colors.red.shade200,
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.bookmark_rounded,
            color: Colors.red.shade700,
            size: 18 * fontScale,
          ),
          SizedBox(width: 10 * fontScale),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '✓ Last Read',
                  style: TextStyle(
                    fontSize: 11 * fontScale,
                    fontWeight: FontWeight.w700,
                    color: Colors.red.shade800,
                    letterSpacing: 0.5,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  '$itemName • $itemTypeLabel $itemNumber',
                  style: TextStyle(
                    fontSize: 12 * fontScale,
                    color: Colors.red.shade700,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '$dateStr\n$timeStr',
            style: TextStyle(
              fontSize: 10 * fontScale,
              color: Colors.red.shade600,
            ),
            textAlign: TextAlign.right,
          ),
        ],
      ),
    );
  }
}