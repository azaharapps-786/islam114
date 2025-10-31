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

    _restartAnimation(); // Initialize animations
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        elevation: 4,
      ),
      body: SafeArea(
        child: FadeTransition(
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

              // --- About Section ---
              TweenAnimationBuilder<double>(
                key: ValueKey('about-header-$_animationKey'),
                duration: const Duration(milliseconds: 500),
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
                child: _buildSectionHeader(context, 'About', Icons.info_outline),
              ),
              const SizedBox(height: 8),
              TweenAnimationBuilder<double>(
                key: ValueKey('about-card-$_animationKey'),
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
                child: Card(
                  child: Column(
                    children: [
                      _buildAppVersionTile(context),
                      const Divider(height: 1),
                      _buildAboutListTile(context),
                    ],
                  ),
                ),
              ),
            ],
          ),
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

  Widget _buildListTile(BuildContext context,
      {required String title,
        String? subtitle,
        required IconData leading,
        required VoidCallback onTap}) {
    return ListTile(
      leading: Icon(leading),
      title: Text(title),
      subtitle: subtitle != null ? Text(subtitle!) : null,
      trailing: const Icon(Icons.arrow_forward_ios),
      onTap: onTap,
    );
  }

  Widget _buildAppVersionTile(BuildContext context) {
    return FutureBuilder<PackageInfo>(
      future: PackageInfo.fromPlatform(),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          return _buildListTile(
            context,
            title: 'App Version',
            subtitle: snapshot.data!.version,
            leading: Icons.system_update,
            onTap: () {},
          );
        } else {
          // Show a loading indicator while version is being fetched
          return const ListTile(
            leading: Icon(Icons.system_update),
            title: Text('App Version'),
            subtitle: LinearProgressIndicator(),
          );
        }
      },
    );
  }

  Widget _buildAboutListTile(BuildContext context) {
    return TweenAnimationBuilder<double>(
      key: ValueKey('about-tile-$_animationKey'),
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
      child: _buildListTile(
        context,
        title: 'About Us',
        subtitle: 'Learn more about Islam114',
        leading: Icons.info,
        onTap: () => _showAboutDialog(context),
      ),
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

  void _showAboutDialog(BuildContext context) {
    showAboutDialog(
      context: context,
      applicationName: 'Islam114',
      applicationVersion: 'Loading...', // We will load this dynamically
      applicationIcon: Image.asset(
        'assets/icons/icon.png',
        width: 50,
        height: 50,
      ),
      children: [
        const Text(
          'Islam114 is a comprehensive Islamic application designed to assist Muslim brothers and sisters in their daily spiritual journey. '
              'The app provides easy access to essential Islamic knowledge, including Quranic verses, prayers, Islamic teachings, '
              'and practical tools to help integrate Islamic values into everyday life.',
        ),
        const SizedBox(height: 16),
        // We will load the version here
        FutureBuilder(
          future: PackageInfo.fromPlatform(),
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              return Text('Version: ${snapshot.data!.version}');
            } else {
              return const CircularProgressIndicator();
            }
          },
        ),
        const SizedBox(height: 16),
        const Divider(),
        const SizedBox(height: 8),
        const Text(
          'Developer Information',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        const ListTile(
          leading: Icon(Icons.person),
          title: Text('Developer'),
          subtitle: Text('Azahar Mahmud'),
          dense: true,
          contentPadding: EdgeInsets.zero,
        ),
        const ListTile(
          leading: Icon(Icons.location_on),
          title: Text('Location'),
          subtitle: Text('India, Assam, Golaghat'),
          dense: true,
          contentPadding: EdgeInsets.zero,
        ),
        const ListTile(
          leading: Icon(Icons.email),
          title: Text('Contact'),
          subtitle: Text('azahar.exe@gmail.com'),
          dense: true,
          contentPadding: EdgeInsets.zero,
        ),
        const SizedBox(height: 16),
        const Divider(),
        const SizedBox(height: 8),
        const Center(
          child: Text(
            '© 2025 Azahar Mahmud. All Rights Reserved.',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }
}