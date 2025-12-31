// lib/presentation/pages/amal_namah_stats_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../core/services/deeds_service.dart';
import '../../core/services/settings_service.dart';
import '../../core/utils/spiritual_keywords.dart';

class StatsPage extends StatelessWidget {
  const StatsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final deedsService = Provider.of<DeedsService>(context);
    final settings = Provider.of<SettingsService>(context);
    final fontScale = settings.fontScale;

    // Get today's deeds to display in the list
    final todayDeeds = deedsService.getDeedsForDate(DateTime.now());

    final totalGood = deedsService.getTotalGoodDeeds();
    final totalBad = deedsService.getTotalBadDeeds();
    final diff = totalGood - totalBad;
    final status = deedsService.getUserStatus();
    final analysis = deedsService.analyzeDeeds();
    final projection = deedsService.projectYearly(diff);
    final isPositive = diff >= 0;

    return Scaffold(
      backgroundColor: isPositive ? Colors.green[50] : Colors.red[50],
      appBar: AppBar(
        title: Text('Your Scale of Deeds', style: TextStyle(fontSize: 20 * fontScale, fontWeight: FontWeight.bold)),
        backgroundColor: isPositive ? Colors.green[700] : Colors.red[700],
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status Header with Static Icon
            Card(
              elevation: 8,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 24.0, bottom: 16.0),
                    child: Icon(
                      isPositive ? Icons.nights_stay : Icons.warning_amber,
                      size: 100,
                      color: isPositive ? Colors.green[600] : Colors.red[600],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Text(
                          status,
                          style: TextStyle(
                            fontSize: 22 * fontScale,
                            fontWeight: FontWeight.bold,
                            color: isPositive ? Colors.green[800] : Colors.red[800],
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          isPositive
                              ? 'Alhamdulillah! Your good deeds are weighing heavy. Jannah is closer.'
                              : 'Danger! The scale tips toward regret. Repent and turn back to Allah now!',
                          style: TextStyle(fontSize: 14 * fontScale, color: isPositive ? Colors.green[600] : Colors.red[600]),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Balance Chart
            Text('Deeds Balance', style: TextStyle(fontSize: 20 * fontScale, fontWeight: FontWeight.bold)),
            Container(
              height: 200,
              padding: const EdgeInsets.all(16),
              child: PieChart(
                PieChartData(
                  sections: [
                    PieChartSectionData(
                      color: Colors.green,
                      value: totalGood.toDouble(),
                      title: '$totalGood',
                      radius: 60,
                      titleStyle: TextStyle(fontSize: 16 * fontScale, color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                    PieChartSectionData(
                      color: Colors.red,
                      value: totalBad.toDouble(),
                      title: '$totalBad',
                      radius: 60,
                      titleStyle: TextStyle(fontSize: 16 * fontScale, color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ],
                  centerSpaceRadius: 40,
                  sectionsSpace: 2,
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Net Balance
            Card(
              color: isPositive ? Colors.green[100] : Colors.red[100],
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Column(
                      children: [
                        Icon(Icons.trending_up, size: 40, color: Colors.green),
                        Text('Good: $totalGood', style: TextStyle(fontSize: 16 * fontScale, color: Colors.green)),
                      ],
                    ),
                    Column(
                      children: [
                        Icon(Icons.trending_down, size: 40, color: Colors.red),
                        Text('Bad: $totalBad', style: TextStyle(fontSize: 16 * fontScale, color: Colors.red)),
                      ],
                    ),
                    Column(
                      children: [
                        Icon(Icons.balance, size: 40, color: diff >= 0 ? Colors.green : Colors.red),
                        Text('Net: $diff', style: TextStyle(fontSize: 18 * fontScale, fontWeight: FontWeight.bold, color: diff >= 0 ? Colors.green : Colors.red)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Today's Deeds Section
            Text("Today's Reflections", style: TextStyle(fontSize: 20 * fontScale, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),

            // Good Deeds List
            if (todayDeeds.goodDeeds.isNotEmpty) ...[
              Text("Good Deeds", style: TextStyle(fontSize: 16 * fontScale, color: Colors.green)),
              ...todayDeeds.goodDeeds.map((deed) {
                // --- SAFETY CHECK FOR RANGE ERROR ---
                final parts = deed.split(' [');
                final title = parts.isNotEmpty ? parts[0] : 'Deed';
                final subtitle = parts.length > 1 ? parts[1].replaceAll(']', '') : 'No category';
                return Card(
                  color: Colors.green[50],
                  child: ListTile(
                    leading: const Icon(Icons.check_circle, color: Colors.green),
                    title: Text(title),
                    subtitle: Text('Category: $subtitle'),
                  ),
                );
              }),
              const SizedBox(height: 16),
            ],

            // Bad Deeds List
            if (todayDeeds.badDeeds.isNotEmpty) ...[
              Text("Bad Deeds (Repent for these)", style: TextStyle(fontSize: 16 * fontScale, color: Colors.red)),
              ...todayDeeds.badDeeds.map((deed) {
                // --- SAFETY CHECK FOR RANGE ERROR ---
                final parts = deed.split(' [');
                final title = parts.isNotEmpty ? parts[0] : 'Deed';
                final subtitle = parts.length > 1 ? parts[1].replaceAll(']', '') : 'No category';
                return Card(
                  color: Colors.red[50],
                  child: ListTile(
                    leading: const Icon(Icons.error, color: Colors.red),
                    title: Text(title),
                    subtitle: Text('Category: $subtitle'),
                  ),
                );
              }),
              const SizedBox(height: 24),
            ],

            // Deep Analysis
            Text('Deep Analysis', style: TextStyle(fontSize: 20 * fontScale, fontWeight: FontWeight.bold)),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: SingleChildScrollView(
                  child: Text(
                    analysis,
                    style: TextStyle(fontSize: 14 * fontScale),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Projection Card - Scary/Motivating
            Text('One-Year Projection', style: TextStyle(fontSize: 20 * fontScale, fontWeight: FontWeight.bold)),
            Card(
              color: isPositive ? Colors.green[100] : Colors.red[100],
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Icon(
                      isPositive ? Icons.card_giftcard : Icons.local_fire_department,
                      size: 80,
                      color: isPositive ? Colors.green[600] : Colors.red[600],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      projection,
                      style: TextStyle(
                        fontSize: 16 * fontScale,
                        fontWeight: FontWeight.bold,
                        color: isPositive ? Colors.green[800] : Colors.red[800],
                      ),
                      textAlign: TextAlign.center,
                    ),
                    if (!isPositive)
                      const Padding(
                        padding: EdgeInsets.only(top: 8),
                        child: Text(
                          'The time is now! Every moment counts.',
                          style: TextStyle(fontSize: 14, color: Colors.red, fontStyle: FontStyle.italic),
                          textAlign: TextAlign.center,
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Reminder Verse
            Card(
              color: Colors.blue[50],
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    const Icon(Icons.book, size: 32, color: Colors.blue),
                    const SizedBox(height: 8),
                    Text(
                      '"And whoever does an atom\'s weight of good will see it, And whoever does an atom\'s weight of evil will see it." (Quran 99:7-8)',
                      style: TextStyle(fontSize: 14 * fontScale, fontStyle: FontStyle.italic, fontWeight: FontWeight.w500),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}