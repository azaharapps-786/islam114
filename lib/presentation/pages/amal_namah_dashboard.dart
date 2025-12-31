// lib/presentation/pages/amal_namah_dashboard.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:haptic_feedback/haptic_feedback.dart'; // <-- FIX 1: Add this import
import '../../core/services/deeds_service.dart';
import '../../core/services/settings_service.dart';
import '../../core/utils/spiritual_keywords.dart';
import 'amal_namah_prayer_page.dart';
import 'amal_namah_deeds_page.dart';
import 'amal_namah_stats_page.dart';

class AmalNamahDashboard extends StatefulWidget {
  final String language;
  final String title;

  const AmalNamahDashboard({
    super.key,
    required this.language,
    required this.title,
  });

  @override
  State<AmalNamahDashboard> createState() => _AmalNamahDashboardState();
}

class _AmalNamahDashboardState extends State<AmalNamahDashboard> with TickerProviderStateMixin {
  late AnimationController _statusController;
  late Animation<double> _statusAnimation;

  @override
  void initState() {
    super.initState();
    _statusController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    _statusAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _statusController, curve: Curves.elasticOut),
    );
    _statusController.forward();
  }

  @override
  void dispose() {
    _statusController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final deedsService = Provider.of<DeedsService>(context);
    final settings = Provider.of<SettingsService>(context);
    final fontScale = settings.fontScale;
    final theme = Theme.of(context);

    final totalGood = deedsService.getTotalGoodDeeds();
    final totalBad = deedsService.getTotalBadDeeds();
    final diff = totalGood - totalBad;
    final status = deedsService.getUserStatus();
    final isPositive = diff >= 0;

    return Scaffold(
      backgroundColor: isPositive ? Colors.green[50] : Colors.red[50],
      appBar: AppBar(
        title: Text(
          widget.title,
          style: TextStyle(fontSize: 20 * fontScale, color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: isPositive ? Colors.green[700] : Colors.red[700],
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isPositive ? [Colors.green[600]!, Colors.green[800]!] : [Colors.red[600]!, Colors.red[800]!],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Status Card with Animation
            AnimatedBuilder(
              animation: _statusAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: _statusAnimation.value,
                  child: Card(
                    elevation: 8,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    color: isPositive ? Colors.green[100] : Colors.red[100],
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          Icon(
                            deedsService.getStatusIcon(),
                            size: 60,
                            color: isPositive ? Colors.green[700] : Colors.red[700],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            status,
                            style: TextStyle(
                              fontSize: 18 * fontScale,
                              fontWeight: FontWeight.bold,
                              color: isPositive ? Colors.green[800] : Colors.red[800],
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            isPositive ? 'Alhamdulillah! Keep striving for Jannah.' : 'Repent now! The scale is tipping dangerously.',
                            style: TextStyle(fontSize: 14 * fontScale, color: isPositive ? Colors.green[600] : Colors.red[600]),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 24),

            // Lifetime Balance Card
            Card(
              elevation: 6,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Text(
                      'Your Scale Today',
                      style: TextStyle(fontSize: 20 * fontScale, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Column(
                          children: [
                            Icon(Icons.favorite, size: 40, color: Colors.green),
                            Text('Good: $totalGood', style: TextStyle(fontSize: 16 * fontScale, color: Colors.green)),
                          ],
                        ),
                        Column(
                          children: [
                            Icon(Icons.warning, size: 40, color: Colors.red),
                            Text('Bad: $totalBad', style: TextStyle(fontSize: 16 * fontScale, color: Colors.red)),
                          ],
                        ),
                        Column(
                          children: [
                            Icon(Icons.balance, size: 40, color: diff >= 0 ? Colors.green : Colors.red),
                            Text('Net: $diff', style: TextStyle(fontSize: 16 * fontScale, fontWeight: FontWeight.bold, color: diff >= 0 ? Colors.green : Colors.red)),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Navigation Buttons with Haptic Feedback
            _buildNavButton(
              'Prayer Tracker',
              Icons.mosque_outlined,
              Colors.blue,
                  () => _navigateWithHaptic(context, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PrayerPage()))), // <-- FIX 2: Corrected class name
            ),
            _buildNavButton(
              'Deeds & Reflections',
              Icons.edit_note_outlined,
              Colors.green,
                  () => _navigateWithHaptic(context, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DeedsPage()))), // <-- FIX 3: Corrected class name
            ),
            _buildNavButton(
              'Scale Analysis',
              Icons.bar_chart,
              Colors.orange,
                  () => _navigateWithHaptic(context, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const StatsPage()))), // <-- FIX 4: Corrected class name
            ),

            // Motivational Verse at Bottom
            const SizedBox(height: 24),
            Card(
              color: isPositive ? Colors.green[100] : Colors.red[100],
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Icon(
                      isPositive ? Icons.lightbulb : Icons.warning,
                      size: 32,
                      color: isPositive ? Colors.green : Colors.red,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      isPositive
                          ? '"And the Hereafter is better for you than the first [life]. And your Lord is going to give you, and you will be satisfied." (Quran 93:4-5)'
                          : '"O you who have believed, fear Allah and let every soul look to what it has put forth for tomorrow." (Quran 59:18)',
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

  Widget _buildNavButton(String title, IconData icon, Color color, VoidCallback onTap) {
    final fontScale = Provider.of<SettingsService>(context, listen: false).fontScale;
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 28, color: color),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: TextStyle(fontSize: 16 * fontScale, fontWeight: FontWeight.w600)),
                    Text(
                      'Track your daily actions',
                      style: TextStyle(fontSize: 12 * fontScale, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios, size: 16),
            ],
          ),
        ),
      ),
    );
  }

  void _navigateWithHaptic(BuildContext context, VoidCallback navigate) {
    Haptics.vibrate(HapticsType.light); // <-- This will now work
    navigate();
  }
}