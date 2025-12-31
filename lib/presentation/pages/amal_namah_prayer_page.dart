// lib/presentation/pages/amal_namah_prayer_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:haptic_feedback/haptic_feedback.dart';
import 'package:lottie/lottie.dart'; // Add to pubspec.yaml if not already
import '../../core/services/deeds_service.dart';
import '../../core/services/settings_service.dart';

class PrayerPage extends StatefulWidget {
  const PrayerPage({super.key});

  @override
  State<PrayerPage> createState() => _PrayerPageState();
}

class _PrayerPageState extends State<PrayerPage> with TickerProviderStateMixin {
  late DateTime _selectedDate;
  late DailyDeeds _currentDeeds;
  final Map<String, String?> _missedReasons = {};
  late AnimationController _prayerController;
  late Animation<double> _prayerAnimation;

  // --- CORRECTION: Add a boolean flag to track disposal ---
  bool _isDisposed = false;

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();

    _prayerController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _prayerAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _prayerController, curve: Curves.easeInOut),
    );

    _updateDeeds();
  }

  void _updateDeeds() {
    final service = Provider.of<DeedsService>(context, listen: false);
    _currentDeeds = service.getDeedsForDate(_selectedDate);
    setState(() {});

    // --- CORRECTION: Use the flag to check before using the controller ---
    if (!_isDisposed) {
      _prayerController.forward().then((_) {
        if (!_isDisposed) {
          _prayerController.reverse();
        }
      });
    }
  }

  void _save() {
    Provider.of<DeedsService>(context, listen: false).updateDeedsForDate(_selectedDate, _currentDeeds);
    Haptics.vibrate(HapticsType.success);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 8),
            const Text('Prayers recorded!'),
          ],
        ),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  void dispose() {
    // --- CORRECTION: Set the flag to true before disposing ---
    _isDisposed = true;
    _prayerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final fontScale = Provider.of<SettingsService>(context).fontScale;
    final completedPrayers = _currentDeeds.prayers.values.where((p) => p).length;
    final totalPrayers = _currentDeeds.prayers.length;
    final progress = completedPrayers / totalPrayers;

    return Scaffold(
      backgroundColor: Colors.blue[50],
      appBar: AppBar(
        title: Text('Prayer Tracker', style: TextStyle(fontSize: 20 * fontScale, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.blue[700],
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blue[600]!, Colors.blue[800]!],
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Date Selector
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    IconButton(
                      onPressed: () {
                        setState(() => _selectedDate = _selectedDate.subtract(const Duration(days: 1)));
                        _updateDeeds();
                      },
                      icon: const Icon(Icons.chevron_left, size: 32),
                    ),
                    Text(
                      '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                      style: TextStyle(fontSize: 18 * fontScale, fontWeight: FontWeight.bold),
                    ),
                    IconButton(
                      onPressed: _selectedDate.isBefore(DateTime.now())
                          ? () {
                        setState(() => _selectedDate = _selectedDate.add(const Duration(days: 1)));
                        _updateDeeds();
                      }
                          : null,
                      icon: const Icon(Icons.chevron_right, size: 32),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Progress Circle
            Center(
              child: Column(
                children: [
                  AnimatedBuilder(
                    animation: _prayerAnimation,
                    builder: (context, child) {
                      return Stack(
                        alignment: Alignment.center,
                        children: [
                          SizedBox(
                            width: 120,
                            height: 120,
                            child: CircularProgressIndicator(
                              value: progress,
                              strokeWidth: 8,
                              backgroundColor: Colors.grey[300],
                              valueColor: AlwaysStoppedAnimation<Color>(
                                completedPrayers == totalPrayers ? Colors.green : Colors.orange,
                              ),
                            ),
                          ),
                          Text(
                            '$completedPrayers/$totalPrayers',
                            style: TextStyle(fontSize: 20 * fontScale, fontWeight: FontWeight.bold),
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 8),
                  Text(
                    completedPrayers == totalPrayers ? 'Alhamdulillah! Perfect Day' : 'Strive for completion',
                    style: TextStyle(fontSize: 14 * fontScale, color: completedPrayers == totalPrayers ? Colors.green : Colors.orange),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Fard Prayers Section
            Text('Obligatory Prayers', style: TextStyle(fontSize: 20 * fontScale, fontWeight: FontWeight.bold)),
            ..._currentDeeds.prayers.entries.map((entry) {
              final prayer = entry.key;
              final isCompleted = entry.value;
              final reason = _missedReasons[prayer];

              return Card(
                margin: const EdgeInsets.symmetric(vertical: 8),
                child: ExpansionTile(
                  leading: Icon(
                    isCompleted ? Icons.check_circle : Icons.radio_button_unchecked,
                    color: isCompleted ? Colors.green : Colors.grey,
                    size: 32,
                  ),
                  title: Text(prayer, style: TextStyle(fontSize: 16 * fontScale)),
                  subtitle: isCompleted
                      ? const Text('Completed - Alhamdulillah!', style: TextStyle(color: Colors.green))
                      : Text('Missed${reason != null ? ' ($reason)' : ''}'),
                  trailing: Switch(
                    value: isCompleted,
                    onChanged: (value) {
                      setState(() => _currentDeeds.prayers[prayer] = value);
                      if (value) Haptics.vibrate(HapticsType.success);
                      else Haptics.vibrate(HapticsType.error);
                    },
                  ),
                  children: isCompleted
                      ? []
                      : [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          Text('Reason for missing:', style: TextStyle(fontWeight: FontWeight.w500)),
                          ...['Illness', 'Travel', 'Sleep/Forget', 'No Excuse'].map((reasonText) => RadioListTile<String>(
                            title: Text(reasonText),
                            value: reasonText,
                            groupValue: reason,
                            onChanged: (value) {
                              setState(() => _missedReasons[prayer] = value);
                              Haptics.vibrate(HapticsType.light);
                            },
                          )),
                        ],
                      ),
                    ),
                    if (reason == 'No Excuse')
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red[50],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.warning, color: Colors.red, size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'No valid excuse: Voluntary deeds may be invalidated. Repent and make Qada!',
                                style: TextStyle(color: Colors.red[700], fontSize: 12 * fontScale),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              );
            }),

            const SizedBox(height: 24),

            // Qada Section
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Qada (Make-up Prayers)', style: TextStyle(fontSize: 18 * fontScale, fontWeight: FontWeight.bold)),
                    TextField(
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Number performed today',
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.repeat),
                      ),
                      onChanged: (v) => _currentDeeds.qadaCount = int.tryParse(v) ?? 0,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Voluntary Prayers
            Text('Voluntary Prayers', style: TextStyle(fontSize: 20 * fontScale, fontWeight: FontWeight.bold)),
            SwitchListTile(
              title: Text('Tahajjud', style: TextStyle(fontSize: 16 * fontScale)),
              value: _currentDeeds.tahajjud,
              onChanged: (v) {
                setState(() => _currentDeeds.tahajjud = v);
                Haptics.vibrate(v ? HapticsType.success : HapticsType.light);
              },
              secondary: Icon(_currentDeeds.tahajjud ? Icons.nightlight_round : Icons.nights_stay, color: Colors.purple),
            ),
            SwitchListTile(
              title: Text('Witr', style: TextStyle(fontSize: 16 * fontScale)),
              value: _currentDeeds.witr,
              onChanged: (v) => setState(() => _currentDeeds.witr = v),
              secondary: Icon(_currentDeeds.witr ? Icons.check_circle : Icons.circle_outlined, color: Colors.blue),
            ),
            SwitchListTile(
              title: Text('Other Nafl', style: TextStyle(fontSize: 16 * fontScale)),
              value: _currentDeeds.nafl,
              onChanged: (v) => setState(() => _currentDeeds.nafl = v),
              secondary: Icon(_currentDeeds.nafl ? Icons.add_circle : Icons.circle_outlined, color: Colors.orange),
            ),

            const SizedBox(height: 32),

            // Save Button with Animation
            AnimatedBuilder(
              animation: _prayerAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: 1.0 + 0.1 * _prayerAnimation.value,
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _save,
                      icon: const Icon(Icons.save),
                      label: Text('Save Prayers', style: TextStyle(fontSize: 16 * fontScale)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue[700],
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}