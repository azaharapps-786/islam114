import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'; // For debugPrint
import 'package:provider/provider.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart'; // Import for haptic feedback

import '../../core/services/settings_service.dart';

class TasbeehPage extends StatefulWidget {
  const TasbeehPage({super.key});

  @override
  State<TasbeehPage> createState() => _TasbeehPageState();
}

class _TasbeehPageState extends State<TasbeehPage> with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  late AnimationController _pageAnimationController;
  late Animation<double> _fadeAnimation;
  int _animationKey = 0; // Key to force recreation of animated elements

  int _counter = 0;
  int _target = 33; // Default target
  bool _soundEnabled = true;
  bool _hapticEnabled = true;
  final Map<String, int> _history = {};
  final DateFormat _dateFormat = DateFormat('yyyy-MM-dd');
  late String _today;
  bool _isLoading = true;

  // ENHANCED: Larger pool with better management
  final List<AudioPlayer> _audioPlayerPool = [];
  final List<bool> _playerAvailability = []; // Track which players are free
  final int _poolSize = 8; // Increased to 8 players

  // Audio source cache
  late AudioPlayer _preloadPlayer; // For preloading audio
  bool _audioPreloaded = false;

  @override
  void initState() {
    super.initState();
    _today = _dateFormat.format(DateTime.now());

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(begin: 1.0, end: 0.9).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _pageAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _pageAnimationController, curve: Curves.easeInOut),
    );

    _restartAnimation(); // Initialize animations

    // Initialize audio player pool
    _initializeAudioPlayerPool();

    _loadData();
  }

  // Restart the page animations and trigger a rebuild for list items.
  void _restartAnimation() {
    _pageAnimationController.reset();
    _pageAnimationController.forward();
    _animationKey++;
    // Force a rebuild to replay list animations via key changes.
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _initializeAudioPlayerPool() async {
    // Create preload player
    _preloadPlayer = AudioPlayer();
    await _preloadPlayer.setPlayerMode(PlayerMode.lowLatency);

    // Try to preload the audio
    try {
      await _preloadPlayer.setSource(AssetSource('sounds/tap_sound.mp3'));
      _audioPreloaded = true;
      debugPrint('Audio preloaded successfully');
    } catch (e) {
      debugPrint('Could not preload audio: $e');
    }

    // Create player pool
    for (int i = 0; i < _poolSize; i++) {
      final player = AudioPlayer();
      await player.setPlayerMode(PlayerMode.lowLatency);
      await player.setReleaseMode(ReleaseMode.stop);

      // Set up completion listener to mark player as available
      player.onPlayerComplete.listen((_) {
        if (mounted && i < _playerAvailability.length) {
          _playerAvailability[i] = true;
        }
      });

      _audioPlayerPool.add(player);
      _playerAvailability.add(true); // Initially all players are available
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _pageAnimationController.dispose();
    _preloadPlayer.dispose();

    // Dispose all audio players in the pool
    for (final player in _audioPlayerPool) {
      player.dispose();
    }

    super.dispose();
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _counter = prefs.getInt('count_$_today') ?? 0;
      _target = prefs.getInt('target') ?? 33;
      _soundEnabled = prefs.getBool('sound_enabled') ?? true;
      _hapticEnabled = prefs.getBool('haptic_enabled') ?? true;
      _isLoading = false;
    });

    // Load history separately to avoid blocking UI
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final Map<String, int> newHistory = {};

    final keys = prefs.getKeys().where((key) => key.startsWith('count_')).toList();
    for (final key in keys) {
      final date = key.substring(6); // Remove 'count_' prefix
      newHistory[date] = prefs.getInt(key) ?? 0;
    }

    if (mounted) {
      setState(() {
        _history.clear();
        _history.addAll(newHistory);
      });
    }
  }

  Future<void> _saveData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('count_$_today', _counter);
    await prefs.setInt('target', _target);
    await prefs.setBool('sound_enabled', _soundEnabled);
    await prefs.setBool('haptic_enabled', _hapticEnabled);

    // Update history after saving
    _history[_today] = _counter;
    if (mounted) setState(() {});
  }

  void _playSound() {
    if (_soundEnabled) {
      try {
        // Find first available player
        int playerIndex = -1;
        for (int i = 0; i < _poolSize; i++) {
          if (_playerAvailability[i]) {
            playerIndex = i;
            break;
          }
        }

        // If no player is available, force use the first one
        if (playerIndex == -1) {
          playerIndex = 0;
          debugPrint('No available player, forcing use of player 0');
        }

        // Mark player as busy
        _playerAvailability[playerIndex] = false;

        final player = _audioPlayerPool[playerIndex];

        // Stop any currently playing sound on this player
        player.stop().then((_) {
          // Play the sound
          player.play(AssetSource('sounds/tap_sound.mp3'), volume: 1.0).catchError((error) {
            debugPrint('Error playing sound: $error');
            // Mark as available again even on error
            if (mounted && playerIndex < _playerAvailability.length) {
              _playerAvailability[playerIndex] = true;
            }
          });
        }).catchError((error) {
          debugPrint('Error stopping player: $error');
          // Try to play anyway
          player.play(AssetSource('sounds/tap_sound.mp3'), volume: 1.0).catchError((e) {
            debugPrint('Error playing after stop error: $e');
          });
        });

        // Set a fallback timer to mark player as available after 200ms
        // This ensures we don't get stuck with all players marked as busy
        Future.delayed(const Duration(milliseconds: 200), () {
          if (mounted && playerIndex < _playerAvailability.length) {
            _playerAvailability[playerIndex] = true;
          }
        });

      } catch (e) {
        debugPrint('Could not play sound: $e');
      }
    }

    if (_hapticEnabled) {
      // Use Flutter's built-in haptic feedback
      HapticFeedback.lightImpact();
    }
  }

  void _incrementCounter() {
    setState(() {
      _counter++;
      _pulseController.forward().then((_) => _pulseController.reverse());
    });

    // Play sound IMMEDIATELY without waiting
    _playSound();

    // Save data asynchronously without blocking
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
    final double fontScale = Provider.of<SettingsService>(context).fontScale;
    final theme = Theme.of(context);
    final screenHeight = MediaQuery.of(context).size.height;

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
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : FadeTransition(
        opacity: _fadeAnimation,
        child: SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: screenHeight - AppBar().preferredSize.height - MediaQuery.of(context).padding.top,
            ),
            child: IntrinsicHeight(
              child: Column(
                children: [
                  // Counter Display - Reduced padding
                  TweenAnimationBuilder<double>(
                    key: ValueKey('counter-$_animationKey'),
                    duration: const Duration(milliseconds: 600),
                    tween: Tween(begin: 0.0, end: 1.0),
                    curve: Curves.easeOut,
                    builder: (context, value, child) {
                      return Transform.translate(
                        offset: Offset(0, 20 * (1 - value)),
                        child: Transform.scale(
                          scale: value,
                          child: Opacity(
                            opacity: value,
                            child: child,
                          ),
                        ),
                      );
                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12), // Reduced from 16
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          AnimatedBuilder(
                            animation: _pulseAnimation,
                            builder: (context, child) {
                              return Transform.scale(
                                scale: _pulseAnimation.value,
                                child: Text(
                                  '$_counter',
                                  style: TextStyle(
                                    fontSize: 48 * fontScale, // Reduced from 60
                                    fontWeight: FontWeight.bold,
                                    color: theme.colorScheme.primary,
                                  ),
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 8), // Reduced from 12
                          Text(
                            'Progress: $_counter / $_target',
                            style: TextStyle(
                              fontSize: 16 * fontScale, // Reduced from 18
                              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                            ),
                          ),
                          const SizedBox(height: 8),
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
                  ),

                  // Tap Area
                  TweenAnimationBuilder<double>(
                    key: ValueKey('tap-area-$_animationKey'),
                    duration: const Duration(milliseconds: 600),
                    tween: Tween(begin: 0.0, end: 1.0),
                    curve: Curves.easeOut,
                    builder: (context, value, child) {
                      return Transform.translate(
                        offset: Offset(0, 20 * (1 - value)),
                        child: Transform.scale(
                          scale: value,
                          child: Opacity(
                            opacity: value,
                            child: child,
                          ),
                        ),
                      );
                    },
                    child: Expanded(
                      flex: 3,
                      child: GestureDetector(
                        onTap: _incrementCounter,
                        child: Container(
                          margin: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: theme.colorScheme.primary.withValues(alpha: 0.3),
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
                                  color: theme.colorScheme.primary.withValues(alpha: 0.5),
                                ),
                                const SizedBox(height: 200),
                                Text(
                                  'TAP HERE',
                                  style: TextStyle(
                                    fontSize: 26 * fontScale,
                                    fontWeight: FontWeight.bold,
                                    color: theme.colorScheme.primary.withValues(alpha: 0.5),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Control Buttons
                  TweenAnimationBuilder<double>(
                    key: ValueKey('controls-$_animationKey'),
                    duration: const Duration(milliseconds: 700),
                    tween: Tween(begin: 0.0, end: 1.0),
                    curve: Curves.easeOut,
                    builder: (context, value, child) {
                      return Transform.translate(
                        offset: Offset(0, 20 * (1 - value)),
                        child: Transform.scale(
                          scale: value,
                          child: Opacity(
                            opacity: value,
                            child: child,
                          ),
                        ),
                      );
                    },
                    child: Padding(
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
                  ),

                  // History Section
                  TweenAnimationBuilder<double>(
                    key: ValueKey('history-$_animationKey'),
                    duration: const Duration(milliseconds: 800),
                    tween: Tween(begin: 0.0, end: 1.0),
                    curve: Curves.easeOut,
                    builder: (context, value, child) {
                      return Transform.translate(
                        offset: Offset(0, 20 * (1 - value)),
                        child: Transform.scale(
                          scale: value,
                          child: Opacity(
                            opacity: value,
                            child: child,
                          ),
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.all(16),
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
                          const SizedBox(height: 22),
                          Container(
                            height: 100,
                            decoration: BoxDecoration(
                              color: theme.colorScheme.surface,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: theme.colorScheme.outline.withValues(alpha: 0.3),
                              ),
                            ),
                            child: _history.isEmpty
                                ? const Center(child: Text('No history yet'))
                                : ListView.builder(
                              key: ValueKey('history-list-$_animationKey'), // Unique key for history list
                              padding: const EdgeInsets.all(8),
                              itemCount: _history.length,
                              itemBuilder: (context, index) {
                                final sortedEntries = _history.entries.toList()
                                  ..sort((a, b) => b.key.compareTo(a.key));
                                final entry = sortedEntries[index];
                                final date = DateTime.parse(entry.key);
                                final formattedDate = DateFormat('MMM dd, yyyy').format(date);

                                return TweenAnimationBuilder<double>(
                                  key: ValueKey('history-item-$index-$_animationKey'), // Staggered key
                                  duration: Duration(milliseconds: 400 + (index * 80)),
                                  tween: Tween(begin: 0.0, end: 1.0),
                                  curve: Curves.easeOut,
                                  builder: (context, itemValue, child) {
                                    return Transform.translate(
                                      offset: Offset(0, 10 * (1 - itemValue)),
                                      child: Transform.scale(
                                        scale: itemValue,
                                        child: Opacity(
                                          opacity: itemValue,
                                          child: child,
                                        ),
                                      ),
                                    );
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 2),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(formattedDate),
                                        Text(
                                          '${entry.value} taps',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: theme.colorScheme.primary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}