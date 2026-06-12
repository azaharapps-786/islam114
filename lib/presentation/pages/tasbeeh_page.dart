import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'dart:ui' as ui;

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

  // FIXED: Limit history to 1 year to prevent unbounded growth
  static const int _maxHistoryDays = 365;

  // Reliable & fast sound system
  final List<AudioPlayer> _audioPlayers = [];
  int _currentPlayerIndex = 0;
  static const int _playerPoolSize = 5;

  Timer? _tapRateTimer;
  Timer? _midnightCheckTimer; // NEW: Check for day change
  int _recentTaps = 0;
  double _currentSpeed = 1.0;

  // Animation Controllers
  late AnimationController _tapAnimationController;
  late Animation<double> _tapScaleAnimation;

  late AnimationController _pageAnimationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _today = _dateFormat.format(DateTime.now());

    _initializePageAnimations();
    _initializeTapAnimation();
    _initializeAudioPlayers();
    _initializeTapRateMonitor();
    _startMidnightCheck(); // NEW: Start checking for day change
    _loadData();
  }

  void _initializePageAnimations() {
    _pageAnimationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _pageAnimationController, curve: Curves.easeOut),
    );
    _scaleAnimation = Tween<double>(begin: 0.95, end: 1.0).animate(
      CurvedAnimation(parent: _pageAnimationController, curve: Curves.elasticOut),
    );
    _pageAnimationController.forward();
  }

  void _initializeTapAnimation() {
    _tapAnimationController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _tapScaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _tapAnimationController, curve: Curves.easeOut),
    );
  }

  void _initializeAudioPlayers() {
    for (int i = 0; i < _playerPoolSize; i++) {
      final player = AudioPlayer();
      player.setPlayerMode(PlayerMode.lowLatency);
      _audioPlayers.add(player);
    }
  }

  void _initializeTapRateMonitor() {
    _tapRateTimer = Timer.periodic(const Duration(milliseconds: 350), (timer) {
      if (_recentTaps >= 6) {
        _currentSpeed = 2.4;
      } else if (_recentTaps >= 4) {
        _currentSpeed = 1.8;
      } else if (_recentTaps <= 1) {
        _currentSpeed = 1.0;
      }
      _recentTaps = 0;
    });
  }

  // NEW: Check every minute if the day has changed
  void _startMidnightCheck() {
    _midnightCheckTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
      final newToday = _dateFormat.format(DateTime.now());
      if (newToday != _today) {
        debugPrint('Day changed from $_today to $newToday');
        _handleDayChange(newToday);
      }
    });
  }

  // NEW: Handle when midnight passes
  void _handleDayChange(String newDay) {
    // Save the old day's final count to history
    _history[_today] = _counter;
    _saveHistoryToDisk(); // Save old history before switching

    setState(() {
      _today = newDay;
      _counter = 0; // Reset counter for new day
    });
    _saveTodayCount(); // Save new day (0)
  }

  @override
  void dispose() {
    _tapRateTimer?.cancel();
    _midnightCheckTimer?.cancel(); // NEW
    for (final player in _audioPlayers) {
      player.stop();
      player.dispose();
    }
    _tapAnimationController.dispose();
    _pageAnimationController.dispose();

    // NEW: Save history one last time when leaving the page
    _saveHistoryToDisk();

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
      if (mounted) setState(() => _isLoading = false);
    }
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final Map<String, int> newHistory = {};
      final now = DateTime.now();

      final keys = prefs.getKeys().where((key) => key.startsWith('count_')).toList();
      for (final key in keys) {
        final dateStr = key.substring(6);

        // FIXED: Parse date and skip entries older than _maxHistoryDays
        try {
          final date = DateTime.parse(dateStr);
          final difference = now.difference(date).inDays;

          if (difference <= _maxHistoryDays) {
            newHistory[dateStr] = prefs.getInt(key) ?? 0;
          } else {
            // OLD: Clean up expired entries from disk to free space
            prefs.remove(key);
          }
        } catch (e) {
          // Invalid date format, skip or remove
          prefs.remove(key);
        }
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

  // FIXED: Split save into separate methods for performance

  /// Saves ONLY today's count (called on every tap - FAST)
  Future<void> _saveTodayCount() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('count_$_today', _counter);

      // Update local map without disk write
      if (mounted) {
        setState(() {
          _history[_today] = _counter;
        });
      }
    } catch (e) {
      debugPrint('Save count error: $e');
    }
  }

  /// Saves ONLY settings (called when settings change - FAST)
  Future<void> _saveSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('target', _target);
      await prefs.setBool('sound_enabled', _soundEnabled);
      await prefs.setBool('haptic_enabled', _hapticEnabled);
    } catch (e) {
      debugPrint('Save settings error: $e');
    }
  }

  /// Saves FULL history to disk (called only on dispose/day change - SLOW BUT RARE)
  Future<void> _saveHistoryToDisk() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      for (final entry in _history.entries) {
        await prefs.setInt('count_${entry.key}', entry.value);
      }
    } catch (e) {
      debugPrint('Save history error: $e');
    }
  }

  void _playSound() async {
    if (!_soundEnabled) return;
    try {
      final player = _audioPlayers[_currentPlayerIndex];
      _currentPlayerIndex = (_currentPlayerIndex + 1) % _playerPoolSize;
      await player.stop();
      await player.setPlaybackRate(_currentSpeed);
      await player.play(AssetSource('sounds/tap_sound.mp3'));
    } catch (e) {
      debugPrint('Audio play error: $e');
    }
  }

  void _onTapDown(TapDownDetails details) => _tapAnimationController.forward();
  void _onTapUp(TapUpDetails details) => _tapAnimationController.reverse();
  void _onTapCancel() => _tapAnimationController.reverse();

  void _incrementCounter() {
    setState(() => _counter++);
    _recentTaps++;
    _playSound();
    if (_hapticEnabled) HapticFeedback.lightImpact();
    _saveTodayCount(); // FIXED: Only saves today's count (1 disk write instead of 180+)
  }

  void _decrementCounter() {
    if (_counter > 0) {
      setState(() => _counter--);
      _playSound();
      _saveTodayCount(); // FIXED: Only saves today's count
    }
  }

  void _resetCounter() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Reset Counter'),
        content: const Text('Are you sure you want to reset today\'s count?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              setState(() => _counter = 0);
              _saveTodayCount(); // FIXED
              Navigator.pop(context);
            },
            child: const Text('Reset', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _setTarget() {
    final controller = TextEditingController(text: _target.toString());
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Set Target'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Target Count', border: OutlineInputBorder()),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              final newTarget = int.tryParse(controller.text);
              if (newTarget != null && newTarget > 0) {
                setState(() => _target = newTarget);
                _saveSettings(); // FIXED: Only saves settings
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

    double fontScale = 1.0;
    try {
      fontScale = Provider.of<SettingsService>(context, listen: false).fontScale;
    } catch (e) {
      debugPrint('SettingsService not found');
    }

    final Border containerBorder = Border.all(
      color: theme.colorScheme.primary.withOpacity(0.6),
      width: 2,
    );

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
              setState(() => _soundEnabled = !_soundEnabled);
              _saveSettings(); // FIXED: Only saves settings
            },
          ),
          IconButton(
            icon: Icon(_hapticEnabled ? Icons.vibration : Icons.phone_android),
            onPressed: () {
              setState(() => _hapticEnabled = !_hapticEnabled);
              _saveSettings(); // FIXED: Only saves settings
            },
          ),
        ],
      ),
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : Container(
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
              child: Column(
                children: [
                  // Counter Section
                  Container(
                    margin: const EdgeInsets.all(16),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(16),
                      border: containerBorder,
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 10, offset: const Offset(0, 4))],
                    ),
                    child: Column(
                      children: [
                        Text('$_counter', style: TextStyle(fontSize: 42 * fontScale, fontWeight: FontWeight.bold, color: theme.colorScheme.primary)),
                        const SizedBox(height: 8),
                        Text('Progress: $_counter / $_target', style: TextStyle(fontSize: 15 * fontScale, color: theme.colorScheme.onSurface.withOpacity(0.8))),
                        const SizedBox(height: 12),
                        LinearProgressIndicator(
                          value: _target > 0 ? _counter / _target : 0.0,
                          minHeight: 7,
                          borderRadius: BorderRadius.circular(4),
                          backgroundColor: theme.colorScheme.primary.withOpacity(0.2),
                          valueColor: AlwaysStoppedAnimation(theme.colorScheme.primary),
                        ),
                      ],
                    ),
                  ),

                  // COUNT HERE Area
                  Expanded(
                    flex: 5,
                    child: GestureDetector(
                      onTapDown: _onTapDown,
                      onTapUp: _onTapUp,
                      onTapCancel: _onTapCancel,
                      onTap: _incrementCounter,
                      child: AnimatedBuilder(
                        animation: _tapAnimationController,
                        builder: (context, child) {
                          return Transform.scale(
                            scale: _tapScaleAnimation.value,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(16),
                                child: BackdropFilter(
                                  filter: ui.ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: theme.colorScheme.surface.withOpacity(0.9),
                                      borderRadius: BorderRadius.circular(16),
                                      border: containerBorder,
                                      boxShadow: [
                                        BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, 10)),
                                      ],
                                    ),
                                    child: child,
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.touch_app, size: 72 * fontScale, color: theme.colorScheme.primary.withOpacity(0.45)),
                              const SizedBox(height: 32),
                              Text(
                                'COUNT HERE',
                                style: TextStyle(
                                  fontSize: 34 * fontScale,
                                  fontWeight: FontWeight.w600,
                                  color: theme.colorScheme.primary.withOpacity(0.5),
                                  letterSpacing: 3.0,
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
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Wrap(
                      alignment: WrapAlignment.spaceEvenly,
                      spacing: 12,
                      runSpacing: 10,
                      children: [
                        ElevatedButton.icon(
                          onPressed: _setTarget,
                          icon: const Icon(Icons.flag, size: 18),
                          label: const Text('Target', style: TextStyle(fontSize: 13)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: theme.colorScheme.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            minimumSize: const Size(110, 42),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: _decrementCounter,
                          icon: const Icon(Icons.undo, size: 18),
                          label: const Text('Undo', style: TextStyle(fontSize: 13)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: theme.colorScheme.secondary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            minimumSize: const Size(110, 42),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: _resetCounter,
                          icon: const Icon(Icons.refresh, size: 18),
                          label: const Text('Reset', style: TextStyle(fontSize: 13)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            minimumSize: const Size(110, 42),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // History Section
                  Container(
                    margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(16),
                      border: containerBorder,
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 10, offset: const Offset(0, 4))],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('History', style: TextStyle(fontSize: 16 * fontScale, fontWeight: FontWeight.bold, color: theme.colorScheme.primary)),
                            Text('Last $_maxHistoryDays days', style: TextStyle(fontSize: 11 * fontScale, color: Colors.grey)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          height: 80,
                          child: _history.isEmpty
                              ? Center(child: Text('No history yet', style: TextStyle(color: Colors.grey[600], fontSize: 13)))
                              : ListView.builder(
                            itemCount: _history.length > 5 ? 5 : _history.length,
                            itemBuilder: (context, index) {
                              final sorted = _history.entries.toList()..sort((a, b) => b.key.compareTo(a.key));
                              final entry = sorted[index];
                              final date = DateTime.parse(entry.key);
                              final isToday = entry.key == _today;
                              return Padding(
                                padding: const EdgeInsets.symmetric(vertical: 2),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          isToday ? 'Today' : DateFormat('MMM dd').format(date),
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                                            color: isToday ? theme.colorScheme.primary : null,
                                          ),
                                        ),
                                        if (!isToday) ...[
                                          const SizedBox(width: 4),
                                          Text(
                                            DateFormat('yyyy').format(date),
                                            style: const TextStyle(fontSize: 10, color: Colors.grey),
                                          ),
                                        ],
                                      ],
                                    ),
                                    Text('${entry.value} taps',
                                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: theme.colorScheme.primary)),
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
    );
  }
}