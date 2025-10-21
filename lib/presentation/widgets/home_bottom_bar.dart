import 'package:flutter/material.dart';

class HomeBottomBar extends StatelessWidget {
  const HomeBottomBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Settings Button
          TextButton.icon(
            onPressed: () {
              Navigator.pushNamed(context, '/settings');
            },
            icon: const Icon(Icons.settings_outlined),
            label: const Text('Settings'),
          ),
          // About Us Button
          TextButton.icon(
            onPressed: () {
              // Show a simple dialog or navigate to an about page
              showAboutDialog(
                context: context,
                applicationName: 'Islam114',
                applicationVersion: '2.0.0',
                applicationIcon: const FlutterLogo(),
                children: [
                  const Text('A modern and efficient Islamic app built with Flutter.'),
                ],
              );
            },
            icon: const Icon(Icons.info_outline),
            label: const Text('About Us'),
          ),
        ],
      ),
    );
  }
}