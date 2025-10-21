import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../core/services/settings_service.dart';
import '../../core/themes/app_theme.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        elevation: 4,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // --- Appearance Section ---
          _buildSectionHeader(context, 'Appearance', Icons.palette_outlined),
          const SizedBox(height: 8),
          Card(
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
          const SizedBox(height: 24),

          // --- About Section ---
          _buildSectionHeader(context, 'About', Icons.info_outline),
          const SizedBox(height: 8),
          Card(
            child: Column(
              children: [
                _buildAppVersionTile(context), // FIX 1: Created a separate widget for this
                const Divider(height: 1),
                _buildListTile(
                  context,
                  title: 'About Us',
                  subtitle: 'Learn more about Islam114',
                  leading: Icons.info,
                  onTap: () => _showAboutDialog(context), // FIX 2: Pass context here
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // FIX 3: Added context as a required parameter
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
                settingsService.updateThemeMode(newTheme);
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

  // FIX 1: A new widget to handle the app version loading
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

  // FIX 2: The function now requires a BuildContext
  void _showAboutDialog(BuildContext context) {
    showAboutDialog(
      context: context,
      applicationName: 'Islam114',
      applicationVersion: 'Loading...', // We will load this dynamically
      applicationIcon: const FlutterLogo(size: 50),
      children: [
        const Text(
          'A modern, efficient, and user-friendly Islamic application built with Flutter. It aims to provide easy access to essential Islamic knowledge and tools.',
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
      ],
    );
  }
}