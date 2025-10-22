// lib/presentation/widgets/azan_settings_dialog.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/providers/prayer_times_provider.dart';

class AzanSettingsDialog extends StatefulWidget {
  const AzanSettingsDialog({super.key});

  @override
  State<AzanSettingsDialog> createState() => _AzanSettingsDialogState();
}

class _AzanSettingsDialogState extends State<AzanSettingsDialog> {
  bool _checkingFile = true;
  bool _fileExists = false;
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();
    _checkAudioFile();
  }

  @override
  void dispose() {
    // Stop Azan when dialog is closed
    _stopAzan();
    super.dispose();
  }

  Future<void> _checkAudioFile() async {
    final provider = Provider.of<PrayerTimesProvider>(context, listen: false);
    final exists = await provider.doesAzanFileExist();
    if (mounted) {
      setState(() {
        _checkingFile = false;
        _fileExists = exists;
      });
    }
  }

  Future<void> _toggleTestAzan() async {
    if (!_fileExists) return;

    final provider = Provider.of<PrayerTimesProvider>(context, listen: false);

    if (_isPlaying) {
      await provider.pauseTestAzan();
    } else {
      await provider.playTestAzan(prayerName: 'Fajr');
    }

    if (mounted) {
      setState(() {
        _isPlaying = !_isPlaying;
      });
    }
  }

  Future<void> _stopAzan() async {
    if (_isPlaying) {
      final provider = Provider.of<PrayerTimesProvider>(context, listen: false);
      await provider.stopTestAzan();

      if (mounted) {
        setState(() {
          _isPlaying = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<PrayerTimesProvider>(
      builder: (context, provider, child) {
        return AlertDialog(
          title: const Text('Azan Settings'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Prayer-specific Azan toggles
                const Text(
                  'Enable Azan for specific prayers:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),

                const SizedBox(height: 8),

                ...provider.prayerAzanEnabled.entries.map((entry) {
                  return SwitchListTile(
                    title: Text(entry.key),
                    value: entry.value,
                    onChanged: (value) {
                      provider.setPrayerAzanEnabled(entry.key, value);
                    },
                    secondary: const Icon(Icons.mosque),
                  );
                }).toList(),

                const SizedBox(height: 16),

                // Show file checking status
                if (_checkingFile)
                  const Row(
                    children: [
                      SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      SizedBox(width: 8),
                      Text('Checking audio file...'),
                    ],
                  )
                else if (!_fileExists)
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.red.shade100,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.error, color: Colors.red),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Azan audio file not found. Please make sure "assets/audio/azan.mp3" exists.',
                            style: TextStyle(color: Colors.red),
                          ),
                        ),
                      ],
                    ),
                  ),

                const SizedBox(height: 16),

                // Test Azan button with play/pause functionality
                ElevatedButton.icon(
                  onPressed: _fileExists ? _toggleTestAzan : null,
                  icon: Icon(_isPlaying ? Icons.pause : Icons.play_arrow),
                  label: Text(_isPlaying ? 'Pause Azan Sound' : 'Test Azan Sound'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                // Stop Azan before closing
                _stopAzan();
                Navigator.of(context).pop();
              },
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }
}