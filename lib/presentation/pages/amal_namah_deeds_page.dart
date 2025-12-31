// lib/presentation/pages/amal_namah_deeds_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:haptic_feedback/haptic_feedback.dart';
import '../../core/services/deeds_service.dart';
import '../../core/services/settings_service.dart';
import '../../core/utils/spiritual_keywords.dart';

class DeedsPage extends StatefulWidget {
  const DeedsPage({super.key});

  @override
  State<DeedsPage> createState() => _DeedsPageState();
}

class _DeedsPageState extends State<DeedsPage> {
  late DateTime _selectedDate;
  late DailyDeeds _currentDeeds;
  final TextEditingController _goodCtrl = TextEditingController();
  final TextEditingController _badCtrl = TextEditingController();
  String? _goodCategory;
  String? _badCategory;
  int _goodScore = 0;
  int _badScore = 0;
  String? _goodReference;
  String? _badReference;

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
    _updateDeeds();
  }

  void _updateDeeds() {
    final service = Provider.of<DeedsService>(context, listen: false);
    _currentDeeds = service.getDeedsForDate(_selectedDate);
    setState(() {});
  }

  void _save() {
    Provider.of<DeedsService>(context, listen: false).updateDeedsForDate(_selectedDate, _currentDeeds);
    Haptics.vibrate(HapticsType.success);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Deeds saved! May Allah accept.'), backgroundColor: Colors.green),
    );
  }

  void _analyzeAndAddGood() {
    if (_goodCtrl.text.isEmpty) return;
    final result = SpiritualKeywords.analyzeText(_goodCtrl.text);
    setState(() {
      _goodCategory = result['category'];
      _goodScore = result['score'];
      _goodReference = result['reference'];
      _currentDeeds.goodDeeds.add('${_goodCtrl.text.trim()} [${_goodCategory}] (+$_goodScore pts)');
      _goodCtrl.clear();
    });
    Haptics.vibrate(HapticsType.success);
  }

  void _analyzeAndAddBad() {
    if (_badCtrl.text.isEmpty) return;
    final result = SpiritualKeywords.analyzeText(_badCtrl.text);
    setState(() {
      _badCategory = result['category'];
      _badScore = result['score'];
      _badReference = result['reference'];
      _currentDeeds.badDeeds.add('${_badCtrl.text.trim()} [${_badCategory}] (-$_badScore pts)');
      _badCtrl.clear();
    });
    Haptics.vibrate(HapticsType.error);
  }

  // --- ADDED: Method to remove a deed ---
  void _removeDeed(String deed, bool isGood) {
    Haptics.vibrate(HapticsType.light);
    setState(() {
      if (isGood) {
        _currentDeeds.goodDeeds.remove(deed);
      } else {
        _currentDeeds.badDeeds.remove(deed);
      }
    });
    // Optionally auto-save after removal
    Provider.of<DeedsService>(context, listen: false).updateDeedsForDate(_selectedDate, _currentDeeds);
  }

  @override
  Widget build(BuildContext context) {
    final fontScale = Provider.of<SettingsService>(context).fontScale;

    return Scaffold(
      appBar: AppBar(
        title: Text('Deeds & Reflections', style: TextStyle(fontSize: 20 * fontScale)),
        backgroundColor: Colors.purple[700],
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
                      icon: const Icon(Icons.chevron_left),
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
                      icon: const Icon(Icons.chevron_right),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // ... (Keep the rest of your widgets like Tasbeeh, Darood, Quran, etc.) ...
            // Tasbeeh & Darood
            Row(
              children: [
                Expanded(
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          Icon(Icons.repeat, color: Colors.blue, size: 32),
                          Text('Tasbeeh Count', style: TextStyle(fontSize: 16 * fontScale)),
                          TextField(
                            keyboardType: TextInputType.number,
                            onChanged: (v) => _currentDeeds.tasbeehCount = int.tryParse(v) ?? 0,
                            decoration: InputDecoration(
                              border: InputBorder.none,
                              hintText: 'Enter count',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          Icon(Icons.favorite_border, color: Colors.red, size: 32),
                          Text('Darood Count', style: TextStyle(fontSize: 16 * fontScale)),
                          TextField(
                            keyboardType: TextInputType.number,
                            onChanged: (v) => _currentDeeds.daroodCount = int.tryParse(v) ?? 0,
                            decoration: InputDecoration(
                              border: InputBorder.none,
                              hintText: 'Enter count',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Quran Recitation
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Quran Recitation', style: TextStyle(fontSize: 16 * fontScale, fontWeight: FontWeight.bold)),
                    SwitchListTile(
                      title: Text('Recited today?', style: TextStyle(fontSize: 14 * fontScale)),
                      value: _currentDeeds.quranRecited,
                      onChanged: (v) => setState(() => _currentDeeds.quranRecited = v),
                    ),
                    if (_currentDeeds.quranRecited)
                      TextField(
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Pages/Juz',
                          border: const OutlineInputBorder(),
                          prefixIcon: const Icon(Icons.book),
                        ),
                        onChanged: (v) => _currentDeeds.quranPages = int.tryParse(v) ?? 0,
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Good Deeds Section
            Text('Good Deeds', style: TextStyle(fontSize: 20 * fontScale, fontWeight: FontWeight.bold, color: Colors.green)),
            Card(
              color: Colors.green[50],
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    TextField(
                      controller: _goodCtrl,
                      decoration: InputDecoration(
                        labelText: 'Describe good deed...',
                        border: const OutlineInputBorder(),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.psychology, color: Colors.green),
                          onPressed: () {
                            final result = SpiritualKeywords.analyzeText(_goodCtrl.text);
                            setState(() {
                              _goodCategory = result['category'];
                              _goodScore = result['score'];
                              _goodReference = result['reference'];
                            });
                            Haptics.vibrate(HapticsType.light);
                          },
                        ),
                      ),
                    ),
                    if (_goodCategory != null)
                      Padding(
                        padding: const EdgeInsets.all(8),
                        child: Column(
                          children: [
                            Text('Detected: $_goodCategory (+$_goodScore pts)', style: TextStyle(color: Colors.green[700])),
                            Text(_goodReference ?? '', style: TextStyle(fontSize: 12 * fontScale, fontStyle: FontStyle.italic)),
                          ],
                        ),
                      ),
                    ElevatedButton.icon(
                      onPressed: _analyzeAndAddGood,
                      icon: const Icon(Icons.add),
                      label: const Text('Add Good Deed'),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            // --- CORRECTED: Use Dismissible for swipe-to-delete ---
            ..._currentDeeds.goodDeeds.map((deed) {
              final parts = deed.split(' [');
              final title = parts.isNotEmpty ? parts[0] : 'Deed';
              return Dismissible(
                key: Key(deed),
                background: Container(color: Colors.red),
                onDismissed: (direction) => _removeDeed(deed, true),
                child: Card(
                  color: Colors.green[50],
                  child: ListTile(
                    leading: const Icon(Icons.check_circle, color: Colors.green),
                    title: Text(title),
                    subtitle: Text('Category: ${parts.length > 1 ? parts[1].replaceAll(']', '') : 'No category'}'),
                  ),
                ),
              );
            }),

            const SizedBox(height: 24),

            // Bad Deeds Section
            Text('Bad Deeds (Be Honest)', style: TextStyle(fontSize: 20 * fontScale, fontWeight: FontWeight.bold, color: Colors.red)),
            Card(
              color: Colors.red[50],
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.warning, color: Colors.red, size: 24),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Remember: Every small sin accumulates. Repent immediately!',
                            style: TextStyle(color: Colors.red[700], fontWeight: FontWeight.w500),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _badCtrl,
                      decoration: InputDecoration(
                        labelText: 'Describe bad deed...',
                        border: const OutlineInputBorder(),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.psychology_alt, color: Colors.red),
                          onPressed: () {
                            final result = SpiritualKeywords.analyzeText(_badCtrl.text);
                            setState(() {
                              _badCategory = result['category'];
                              _badScore = result['score'];
                              _badReference = result['reference'];
                            });
                            Haptics.vibrate(HapticsType.warning);
                          },
                        ),
                      ),
                    ),
                    if (_badCategory != null)
                      Padding(
                        padding: const EdgeInsets.all(8),
                        child: Column(
                          children: [
                            Text('Detected: $_badCategory (-$_badScore pts)', style: TextStyle(color: Colors.red[700])),
                            Text(_badReference ?? '', style: TextStyle(fontSize: 12 * fontScale, fontStyle: FontStyle.italic, color: Colors.red[600])),
                          ],
                        ),
                      ),
                    ElevatedButton.icon(
                      onPressed: _analyzeAndAddBad,
                      icon: const Icon(Icons.add_alert),
                      label: const Text('Record Bad Deed'),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            // --- CORRECTED: Use Dismissible for swipe-to-delete ---
            ..._currentDeeds.badDeeds.map((deed) {
              final parts = deed.split(' [');
              final title = parts.isNotEmpty ? parts[0] : 'Deed';
              return Dismissible(
                key: Key(deed),
                background: Container(color: Colors.orange),
                onDismissed: (direction) => _removeDeed(deed, false),
                child: Card(
                  color: Colors.red[50],
                  child: ListTile(
                    leading: const Icon(Icons.error, color: Colors.red),
                    title: Text(title),
                    subtitle: Text('Category: ${parts.length > 1 ? parts[1].replaceAll(']', '') : 'No category'}'),
                  ),
                ),
              );
            }),

            const SizedBox(height: 32),

            // Save Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _save,
                icon: const Icon(Icons.save),
                label: Text('Save Reflections', style: TextStyle(fontSize: 16 * fontScale)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple[700],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}