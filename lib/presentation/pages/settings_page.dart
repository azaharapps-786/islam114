import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../core/services/settings_service.dart';
import '../../core/themes/app_theme.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  int _animationKey = 0; // Key to force recreation of animated elements
  bool _isInitialized = false; // Add this flag to track initialization

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );

    _animationController.forward();

    // Mark as initialized
    setState(() {
      _isInitialized = true;
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  // Restart the page animations and trigger a rebuild for list items.
  void _restartAnimation() {
    _animationController.reset();
    _animationController.forward();
    _animationKey++;
    // Force a rebuild to replay list animations via key changes.
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    // Don't build until animations are initialized
    if (!_isInitialized) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Settings'),
          backgroundColor: Theme.of(context).colorScheme.primary,
          foregroundColor: Colors.white,
          elevation: 4,
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        elevation: 4,
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: ListView(
          key: ValueKey('settings-list-$_animationKey'),
          padding: const EdgeInsets.all(16.0),
          children: [
            // --- Appearance Section ---
            TweenAnimationBuilder<double>(
              key: ValueKey('appearance-header-$_animationKey'),
              duration: const Duration(milliseconds: 300),
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
              child: _buildSectionHeader(context, 'Appearance', Icons.palette_outlined),
            ),
            const SizedBox(height: 8),
            TweenAnimationBuilder<double>(
              key: ValueKey('appearance-card-$_animationKey'),
              duration: const Duration(milliseconds: 400),
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
              child: Card(
                child: Column(
                  children: [
                    // Theme Selector
                    _buildThemeSelector(context),
                    const Divider(height: 1),
                    // Font Size Slider
                    _buildFontSlider(context),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 8),
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
      ],
    );
  }

  Widget _buildThemeSelector(BuildContext context) {
    return Consumer<SettingsService>(
      builder: (context, settingsService, child) {
        return ListTile(
          leading: const Icon(Icons.brightness_6_outlined),
          title: const Text('Theme'),
          subtitle: Text(_getThemeDisplayName(settingsService.themeMode)),
          trailing: DropdownButton<ThemeMode>(
            value: settingsService.themeMode,
            onChanged: (ThemeMode? newTheme) {
              if (newTheme != null) {
                if (newTheme == ThemeMode.light) {
                  settingsService.updateThemeMode(newTheme);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Feature Coming Soon!'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                }
              }
            },
            items: const [
              DropdownMenuItem(value: ThemeMode.system, child: Text('System Default')),
              DropdownMenuItem(value: ThemeMode.light, child: Text('Light')),
              DropdownMenuItem(value: ThemeMode.dark, child: Text('Dark')),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFontSlider(BuildContext context) {
    return Consumer<SettingsService>(
      builder: (context, settingsService, child) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Font Size'),
                  Text(
                    '${(settingsService.fontScale * 100).round()}%',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
              Row(
                children: [
                  const Icon(Icons.text_fields, size: 20),
                  Expanded(
                    child: Slider(
                      value: settingsService.fontScale,
                      min: 0.8,
                      max: 1.4,
                      divisions: 6,
                      onChanged: (double value) {
                        settingsService.updateFontScale(value);
                      },
                    ),
                  ),
                  const Icon(Icons.text_fields, size: 28),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  String _getThemeDisplayName(ThemeMode themeMode) {
    switch (themeMode) {
      case ThemeMode.light:
        return 'Light';
      case ThemeMode.dark:
        return 'Dark';
      case ThemeMode.system:
      default:
        return 'System Default';
    }
  }
}