import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';
import 'dart:async';

import '../../core/services/settings_service.dart';

class TasbeehPage extends StatefulWidget {
  const TasbeehPage({super.key});

  @override
  State<TasbeehPage> createState() => _TasbeehPageState();
}

class _TasbeehPageState extends State<TasbeehPage> with TickerProviderStateMixin {
  int _counter = 0;
  int _target = 33;
  bool _soundEnabled = true;
  bool _hapticEnabled = true;
  final Map<String, int> _history = {};
  final DateFormat _dateFormat = DateFormat('yyyy-MM-dd');
  late String _today;
  bool _isLoading = true;

  // ROBUST ADAPTIVE SOUND STRATEGY
  final List<AudioPlayer> _audioPlayers = []; // Pool of players for rapid taps
  final List<bool> _playerInUse = []; // Track which players are in use
  static const int _playerPoolSize = 5; // Number of players in pool
  Timer? _tapRateTimer; // Timer to calculate tap rate
  int _recentTaps = 0; // Count of recent taps
  double _currentSpeed = 1.0; // Current playback speed
  bool _isRapidTapping = false; // Flag for rapid tapping mode

  // Animation setup
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _today = _dateFormat.format(DateTime.now());
    _initializeAnimations();
    _initializeAudioPlayers();
    _initializeTapRateMonitor();
    _loadData();
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOut,
      ),
    );
    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.elasticOut,
      ),
    );
    _animationController.forward();
  }

  // Initialize pool of audio players
  void _initializeAudioPlayers() {
    for (int i = 0; i < _playerPoolSize; i++) {
      final player = AudioPlayer();
      _audioPlayers.add(player);
      _playerInUse.add(false);

      // Set up completion listener to mark player as available
      player.onPlayerComplete.listen((_) {
        if (mounted && i < _playerInUse.length) {
          _playerInUse[i] = false;
        }
      });
    }
  }

  // Initialize tap rate monitoring
  void _initializeTapRateMonitor() {
    _tapRateTimer = Timer.periodic(const Duration(milliseconds: 500), (timer) {
      if (_recentTaps >= 3) {
        // Rapid tapping detected
        if (!_isRapidTapping) {
          setState(() {
            _isRapidTapping = true;
            _currentSpeed = 2.5; // Fast speed for rapid tapping
          });
          debugPrint('Rapid tapping detected, speed: $_currentSpeed');
        }
      } else if (_recentTaps == 0) {
        // No tapping recently
        if (_isRapidTapping) {
          setState(() {
            _isRapidTapping = false;
            _currentSpeed = 1.0; // Normal speed
          });
          debugPrint('Tapping stopped, speed reset to: $_currentSpeed');
        }
      } else if (_recentTaps == 1) {
        // Single tap
        if (_isRapidTapping) {
          setState(() {
            _isRapidTapping = false;
            _currentSpeed = 1.0; // Normal speed
          });
          debugPrint('Single tap, speed reset to: $_currentSpeed');
        }
      } else if (_recentTaps == 2) {
        // Double tap
        if (!_isRapidTapping) {
          setState(() {
            _currentSpeed = 1.5; // Medium speed for double tap
          });
          debugPrint('Double tap detected, speed: $_currentSpeed');
        }
      }

      // Reset tap count for next interval
      _recentTaps = 0;
    });
  }

  @override
  void dispose() {
    _tapRateTimer?.cancel();

    // Dispose all audio players
    for (final player in _audioPlayers) {
      player.dispose();
    }

    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (mounted) {
        setState(() {
          _counter = prefs.getInt('count_$_today') ?? 0;
          _target = prefs.getInt('target') ?? 33;
          _soundEnabled = prefs.getBool('sound_enabled') ?? true;
          _hapticEnabled = prefs.getBool('haptic_enabled') ?? true;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('SharedPreferences load error: $e');
      if (mounted) {
        setState(() { _isLoading = false; });
      }
    }
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final Map<String, int> newHistory = {};

      final keys = prefs.getKeys().where((key) => key.startsWith('count_')).toList();
      for (final key in keys) {
        final date = key.substring(6);
        newHistory[date] = prefs.getInt(key) ?? 0;
      }

      if (mounted) {
        setState(() {
          _history.clear();
          _history.addAll(newHistory);
        });
      }
    } catch (e) {
      debugPrint('History load error: $e');
    }
  }

  Future<void> _saveData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('count_$_today', _counter);
      await prefs.setInt('target', _target);
      await prefs.setBool('sound_enabled', _soundEnabled);
      await prefs.setBool('haptic_enabled', _hapticEnabled);

      _history[_today] = _counter;
      if (mounted) setState(() {});
    } catch (e) {
      debugPrint('Save data error: $e');
    }
  }

  // ROBUST SOUND PLAYING STRATEGY
  void _playSound() async {
    if (!_soundEnabled) return;

    try {
      // Find an available player
      int? availablePlayerIndex;
      for (int i = 0; i < _playerInUse.length; i++) {
        if (!_playerInUse[i]) {
          availablePlayerIndex = i;
          break;
        }
      }

      // If no player is available, use the first one
      if (availablePlayerIndex == null) {
        availablePlayerIndex = 0;
        debugPrint('All players busy, using player 0');
      }

      // Mark player as in use
      _playerInUse[availablePlayerIndex] = true;

      // Get the player and set its speed
      final player = _audioPlayers[availablePlayerIndex];
      await player.setPlaybackRate(_currentSpeed);

      // Play the sound
      await player.play(AssetSource('sounds/tap_sound.mp3'));

      debugPrint('Playing sound at speed: $_currentSpeed');
    } catch (e) {
      debugPrint('Error playing sound: $e');
    }
  }

  void _incrementCounter() {
    setState(() {
      _counter++;
    });

    // Increment tap count for rate monitoring
    _recentTaps++;

    // Play sound
    _playSound();

    // Haptic feedback
    if (_hapticEnabled) {
      HapticFeedback.lightImpact();
    }

    // Save data
    _saveData();
  }

  void _decrementCounter() {
    if (_counter > 0) {
      setState(() {
        _counter--;
      });
      _playSound();
      _saveData();
    }
  }

  void _resetCounter() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Counter'),
        content: const Text('Are you sure you want to reset the counter for today?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _counter = 0;
              });
              _saveData();
              Navigator.pop(context);
            },
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }

  void _setTarget() {
    final controller = TextEditingController(text: _target.toString());

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Set Target'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Target Count',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final newTarget = int.tryParse(controller.text);
              if (newTarget != null && newTarget > 0) {
                setState(() {
                  _target = newTarget;
                });
                _saveData();
              }
              Navigator.pop(context);
            },
            child: const Text('Set'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenHeight = MediaQuery.of(context).size.height;

    // Robust fontScale retrieval with fallback
    double fontScale = 1.0;
    try {
      fontScale = Provider.of<SettingsService>(context).fontScale;
    } catch (e) {
      debugPrint('SettingsService not found; using default fontScale: 1.0. Ensure provider is wrapped in ancestors.');
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tasbeeh Counter'),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: Colors.white,
        elevation: 4,
        actions: [
          IconButton(
            icon: Icon(_soundEnabled ? Icons.volume_up : Icons.volume_off),
            onPressed: () {
              setState(() {
                _soundEnabled = !_soundEnabled;
              });
              _saveData();
            },
          ),
          IconButton(
            icon: Icon(_hapticEnabled ? Icons.vibration : Icons.phone_android),
            onPressed: () {
              setState(() {
                _hapticEnabled = !_hapticEnabled;
              });
              _saveData();
            },
          ),
        ],
      ),
      body: SafeArea(
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : Container(
              width: double.infinity,
              height: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    theme.colorScheme.primary.withOpacity(0.1),
                    theme.colorScheme.surface,
                  ],
                ),
              ),
              child: SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: screenHeight - kToolbarHeight - MediaQuery.of(context).padding.top,
                  ),
                  child: IntrinsicHeight(
                    child: Column(
                      children: [
                        // Counter Display
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                          margin: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                '$_counter',
                                style: TextStyle(
                                  fontSize: 48 * fontScale,
                                  fontWeight: FontWeight.bold,
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Progress: $_counter / $_target',
                                style: TextStyle(
                                  fontSize: 16 * fontScale,
                                  color: theme.colorScheme.onSurface.withOpacity(0.7),
                                ),
                              ),
                              const SizedBox(height: 16),
                              LinearProgressIndicator(
                                value: _target > 0 ? _counter / _target : 0.0,
                                minHeight: 8,
                                borderRadius: BorderRadius.circular(4),
                                backgroundColor: theme.colorScheme.surface,
                                valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.primary),
                              ),
                            ],
                          ),
                        ),

                        // Tap Area
                        Expanded(
                          flex: 2,
                          child: GestureDetector(
                            onTap: _incrementCounter,
                            child: Container(
                              margin: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primary.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: theme.colorScheme.primary.withOpacity(0.3),
                                  width: 2,
                                ),
                              ),
                              child: Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.touch_app,
                                      size: 56 * fontScale,
                                      color: theme.colorScheme.primary.withOpacity(0.5),
                                    ),
                                    const SizedBox(height: 20),
                                    Text(
                                      'TAP HERE',
                                      style: TextStyle(
                                        fontSize: 26 * fontScale,
                                        fontWeight: FontWeight.bold,
                                        color: theme.colorScheme.primary.withOpacity(0.5),
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    Text(
                                      'Speed: ${_currentSpeed.toStringAsFixed(1)}x',
                                      style: TextStyle(
                                        fontSize: 14 * fontScale,
                                        color: theme.colorScheme.primary.withOpacity(0.7),
                                      ),
                                    ),
                                    const SizedBox(height: 5),
                                    Text(
                                      _isRapidTapping ? '🔥 Rapid Tapping!' : '',
                                      style: TextStyle(
                                        fontSize: 12 * fontScale,
                                        color: Colors.orange,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),

                        // Control Buttons
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Wrap(
                            alignment: WrapAlignment.spaceEvenly,
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              SizedBox(
                                width: 100,
                                child: ElevatedButton.icon(
                                  onPressed: _setTarget,
                                  icon: const Icon(Icons.flag),
                                  label: const Text('Target'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: theme.colorScheme.primary,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(vertical: 8),
                                  ),
                                ),
                              ),
                              SizedBox(
                                width: 100,
                                child: ElevatedButton.icon(
                                  onPressed: _decrementCounter,
                                  icon: const Icon(Icons.undo),
                                  label: const Text('Undo'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: theme.colorScheme.secondary,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(vertical: 8),
                                  ),
                                ),
                              ),
                              SizedBox(
                                width: 100,
                                child: ElevatedButton.icon(
                                  onPressed: _resetCounter,
                                  icon: const Icon(Icons.refresh),
                                  label: const Text('Reset'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(vertical: 8),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        // History Section
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          margin: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'History',
                                style: TextStyle(
                                  fontSize: 18 * fontScale,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Container(
                                height: 120,
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.surface,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: theme.colorScheme.outline.withOpacity(0.3),
                                  ),
                                ),
                                child: _history.isEmpty
                                    ? const Center(child: Text('No history yet'))
                                    : ListView.builder(
                                  padding: const EdgeInsets.all(8),
                                  itemCount: _history.length,
                                  itemBuilder: (context, index) {
                                    final sortedEntries = _history.entries.toList()
                                      ..sort((a, b) => b.key.compareTo(a.key));
                                    final entry = sortedEntries[index];
                                    final date = DateTime.parse(entry.key);
                                    final formattedDate = DateFormat('MMM dd, yyyy').format(date);

                                    return Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 2),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Expanded(
                                            child: Text(formattedDate),
                                          ),
                                          Text(
                                            '${entry.value} taps',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: theme.colorScheme.primary,
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}