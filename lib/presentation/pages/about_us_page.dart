// lib/presentation/pages/about_us_page.dart
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class AboutUsPage extends StatelessWidget {
  const AboutUsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      // 1. STATIC STANDARD APP BAR
      appBar: AppBar(
        title: const Text(
          'About Us',
          style: TextStyle(
            fontSize: 18, // Standard professional size
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: theme.colorScheme.surface,
        foregroundColor: theme.colorScheme.onSurface,
        surfaceTintColor: Colors.transparent,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Divider(
            height: 1,
            color: theme.colorScheme.outlineVariant.withOpacity(0.5),
          ),
        ),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          children: [
            const SizedBox(height: 32),

            // 2. SMALLER & REFINED BRANDING
            Center(
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: theme.colorScheme.primary.withOpacity(0.1),
                      ),
                    ),
                    child: Image.asset(
                      'assets/icons/icon.png',
                      width: 50, // Reduced from 80/60
                      height: 50,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Islam114',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 20, // More professional than headlineMedium
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  FutureBuilder<PackageInfo>(
                    future: PackageInfo.fromPlatform(),
                    builder: (context, snapshot) {
                      return Text(
                        'Version ${snapshot.data?.version ?? "1.0.0"}',
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          letterSpacing: 0.5,
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 3. ABOUT SECTION
                  _buildSectionHeader(theme, 'ABOUT THE PROJECT'),
                  const SizedBox(height: 12),
                  Text(
                    'Islam114 is a comprehensive Islamic application designed to assist Muslim brothers and sisters in their daily spiritual journey. Built on a 12th gen i3 system with 8GB RAM, this app is optimized for high performance and smooth user experience across all devices.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      height: 1.6,
                      fontSize: 14, // Standard body size
                      color: theme.colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // 4. PROFESSIONAL INFO CARD
                  _buildSectionHeader(theme, 'DEVELOPER INFORMATION'),
                  const SizedBox(height: 12),
                  Container(
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: theme.colorScheme.outlineVariant.withOpacity(0.5),
                      ),
                    ),
                    child: Column(
                      children: [
                        _buildListTile(
                          theme,
                          Icons.person_outline_rounded,
                          'Developer',
                          'Azahar Mahmud',
                          null,
                        ),
                        _divider(theme),
                        _buildListTile(
                          theme,
                          Icons.map_outlined,
                          'Location',
                          'Assam, India',
                          null,
                        ),
                        _divider(theme),
                        _buildListTile(
                          theme,
                          Icons.mail_outline_rounded,
                          'Inquiries',
                          'azaharapps@gmail.com',
                              () => _launchEmail('azaharapps@gmail.com'),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 48),

                  // 5. STANDARD FOOTER
                  Center(
                    child: Column(
                      children: [
                        Text(
                          '© 2026 AzaharApps',
                          style: theme.textTheme.labelLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        Text(
                          'All Rights Reserved',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant.withOpacity(0.8),
                            fontWeight: FontWeight.w500,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Designed and developed with precision.',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant.withOpacity(0.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(ThemeData theme, String title) {
    return Text(
      title,
      style: theme.textTheme.labelSmall?.copyWith(
        fontWeight: FontWeight.w800,
        color: theme.colorScheme.primary,
        letterSpacing: 1.2,
      ),
    );
  }

  Widget _buildListTile(ThemeData theme, IconData icon, String title, String value, VoidCallback? onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(icon, size: 22, color: theme.colorScheme.primary.withOpacity(0.8)),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontSize: 11,
                    ),
                  ),
                  Text(
                    value,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            if (onTap != null)
              Icon(Icons.open_in_new_rounded, size: 14, color: theme.colorScheme.outline),
          ],
        ),
      ),
    );
  }

  Widget _divider(ThemeData theme) => Divider(
    height: 1,
    indent: 50,
    endIndent: 16,
    color: theme.colorScheme.outlineVariant.withOpacity(0.4),
  );

  void _launchEmail(String email) async {
    final Uri params = Uri(scheme: 'mailto', path: email);
    if (await canLaunchUrl(params)) {
      await launchUrl(params);
    }
  }
}