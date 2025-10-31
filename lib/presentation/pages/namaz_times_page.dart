// lib/presentation/pages/namaz_times_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import 'package:islam114/main.dart'; // Import for global RouteObserver from main.dart
import '../../core/providers/prayer_times_provider.dart';
import '../../core/services/settings_service.dart';
import '../widgets/prayer_time_card.dart';
import '../widgets/location_dialog.dart';
import '../widgets/azan_settings_dialog.dart';

class NamazTimesPage extends StatefulWidget {
  const NamazTimesPage({super.key});

  @override
  State<NamazTimesPage> createState() => _NamazTimesPageState();
}

class _NamazTimesPageState extends State<NamazTimesPage>
    with TickerProviderStateMixin, RouteAware, WidgetsBindingObserver {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  int _animationKey = 0; // Key to force recreation of animated elements

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _restartAnimation(); // Initialize animations

    // Initialize the provider when the page is created
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PrayerTimesProvider>().initialize();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Subscribe to the global RouteObserver instance.
    final modalRoute = ModalRoute.of(context);
    if (modalRoute is PageRoute) {
      routeObserver.subscribe(this, modalRoute as PageRoute<dynamic>);
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      // Trigger animation restart when app resumes from background.
      _restartAnimation();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _animationController.dispose();
    // Unsubscribe from the global RouteObserver to prevent memory leaks.
    final modalRoute = ModalRoute.of(context);
    if (modalRoute is PageRoute) {
      routeObserver.unsubscribe(this);
    }
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
  void didPopNext() {
    // Triggered when returning to this route (e.g., popping back from another page).
    print('didPopNext called: Restarting NamazTimesPage animation'); // Debug log for verification.
    _restartAnimation();
  }

  @override
  Widget build(BuildContext context) {
    final double fontScale = context.watch<SettingsService>().fontScale;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Namaz Times'),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: Colors.white,
        elevation: 4,
      ),
      body: Consumer<PrayerTimesProvider>(
        builder: (context, provider, child) {
          // Show error message if there is one
          if (provider.errorMessage != null) {
            return FadeTransition(
              opacity: _fadeAnimation,
              child: Center(
                key: ValueKey('error-$_animationKey'), // Key for animation recreation
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Error: ${provider.errorMessage}',
                      style: TextStyle(
                        fontSize: 16 * fontScale,
                        color: theme.colorScheme.error,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        provider.clearError();
                        provider.initialize();
                      },
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            );
          }

          // Show loading indicator
          if (provider.isLoading && provider.prayerTimes.isEmpty) {
            return FadeTransition(
              opacity: _fadeAnimation,
              child: const Center(
                key: ValueKey('loading'), // Static key for loading state
                child: CircularProgressIndicator(),
              ),
            );
          }

          return FadeTransition(
            opacity: _fadeAnimation,
            child: RefreshIndicator(
              key: ValueKey('refresh-$_animationKey'), // Key for animation recreation
              onRefresh: () async {
                await provider.refreshPrayerTimes();
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  children: [
                    _buildHeader(context, provider, fontScale, _animationKey),
                    _buildNextPrayer(context, provider, fontScale, _animationKey),
                    _buildPrayerTimesList(context, provider, fontScale, _animationKey),
                    _buildFooter(context, provider, fontScale, _animationKey),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader(BuildContext context, PrayerTimesProvider provider, double fontScale, int animationKey) {
    final theme = Theme.of(context);

    return TweenAnimationBuilder<double>(
      key: ValueKey('header-$animationKey'), // Unique key for header animation
      duration: const Duration(milliseconds: 600), // Smooth entrance
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
        key: ValueKey('header-content-$animationKey'), // Inner key for content
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Date navigation
            Row(
              children: [
                // Yesterday button
                IconButton(
                  onPressed: () {
                    final yesterday = provider.currentDate.subtract(const Duration(days: 1));
                    provider.changeDate(yesterday);
                  },
                  icon: const Icon(Icons.chevron_left),
                  style: IconButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.1),
                    foregroundColor: theme.colorScheme.primary,
                  ),
                ),

                // Date display
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        DateFormat('EEEE').format(provider.currentDate).toUpperCase(),
                        style: TextStyle(
                          fontSize: 16 * fontScale,
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        DateFormat('d MMMM, yyyy').format(provider.currentDate),
                        style: TextStyle(
                          fontSize: 14 * fontScale,
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                ),

                // Tomorrow button
                IconButton(
                  onPressed: () {
                    final tomorrow = provider.currentDate.add(const Duration(days: 1));
                    provider.changeDate(tomorrow);
                  },
                  icon: const Icon(Icons.chevron_right),
                  style: IconButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.1),
                    foregroundColor: theme.colorScheme.primary,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            // Location display - CENTERED
            Row(
              mainAxisAlignment: MainAxisAlignment.center, // Center the content
              children: [
                Icon(
                  Icons.location_on,
                  color: theme.colorScheme.onSurface,
                  size: 20 * fontScale,
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    provider.locationName.isNotEmpty
                        ? provider.locationName
                        : 'Getting location...',
                    textAlign: TextAlign.center, // Center the text
                    style: TextStyle(
                      fontSize: 16 * fontScale,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                ),
              ],
            ),

            // Show coordinates if location name is not available - CENTERED
            if (provider.currentLocation != null && provider.locationName.contains(',')) ...[
              const SizedBox(height: 4),
              Text(
                'Coordinates: ${provider.currentLocation!.latitude.toStringAsFixed(4)}, ${provider.currentLocation!.longitude.toStringAsFixed(4)}',
                textAlign: TextAlign.center, // Center the text
                style: TextStyle(
                  fontSize: 12 * fontScale,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
            ],

            const SizedBox(height: 16),

            // FIXED: Action buttons row with consistent height
            Row(
              children: [
                // Change location button
                Expanded(
                  child: _buildActionButton(
                    context: context,
                    icon: Icons.edit_location,
                    label: 'Change Location',
                    onPressed: () {
                      _showLocationDialog(context);
                    },
                    theme: theme,
                  ),
                ),

                const SizedBox(width: 8),

                // Azan settings button
                Expanded(
                  child: _buildActionButton(
                    context: context,
                    icon: provider.azanEnabled ? Icons.volume_up : Icons.volume_off,
                    label: 'Azan Settings',
                    onPressed: () {
                      _showAzanSettingsDialog(context);
                    },
                    theme: theme,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // FIXED: Extracted button widget to ensure consistency
  Widget _buildActionButton({
    required BuildContext context,
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    required ThemeData theme,
  }) {
    return SizedBox(
      height: 48, // Fixed height for both buttons
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          backgroundColor: theme.colorScheme.primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8), // Consistent border radius
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12), // Consistent padding
        ),
      ),
    );
  }

  Widget _buildNextPrayer(BuildContext context, PrayerTimesProvider provider, double fontScale, int animationKey) {
    final theme = Theme.of(context);

    if (provider.nextPrayer == null) {
      return const SizedBox.shrink();
    }

    return TweenAnimationBuilder<double>(
      key: ValueKey('next-prayer-$animationKey'), // Unique key for next prayer animation
      duration: const Duration(milliseconds: 600), // Smooth entrance
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
        key: ValueKey('next-prayer-content-$animationKey'), // Inner key for content
        width: double.infinity,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.colorScheme.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: theme.colorScheme.primary.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.access_time,
              color: theme.colorScheme.primary,
              size: 24 * fontScale,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Next Prayer: ${provider.nextPrayer!.name} at ${_formatTime(provider.nextPrayer!.time)}',
                style: TextStyle(
                  fontSize: 18 * fontScale,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPrayerTimesList(BuildContext context, PrayerTimesProvider provider, double fontScale, int animationKey) {
    if (provider.prayerTimes.isEmpty) {
      return TweenAnimationBuilder<double>(
        key: ValueKey('empty-list-$animationKey'), // Unique key for empty state animation
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
          key: ValueKey('empty-content-$animationKey'), // Inner key for content
          height: 200,
          margin: const EdgeInsets.all(16),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.access_time, size: 48),
                const SizedBox(height: 16),
                const Text(
                  'No prayer times available',
                  style: TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 8),
                Text(
                  'Try refreshing or changing your location',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    provider.refreshPrayerTimes();
                  },
                  child: const Text('Refresh'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return TweenAnimationBuilder<double>(
      key: ValueKey('prayer-list-title-$animationKey'), // Key for title animation
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
      child: Container(
        key: ValueKey('prayer-list-container-$animationKey'), // Inner key for container
        margin: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Prayer Times',
              style: TextStyle(
                fontSize: 18 * fontScale,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            ListView.builder(
              key: ValueKey('prayer-list-$_animationKey'), // Unique key on ListView to force full recreation
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: provider.prayerTimes.length,
              itemBuilder: (context, index) {
                final prayerTime = provider.prayerTimes[index];
                return TweenAnimationBuilder<double>(
                  key: ValueKey('prayer$index-$_animationKey'), // Unique key for staggered animation restart
                  duration: Duration(milliseconds: 400 + (index * 80)), // Staggered entrance for smooth reveal
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
                  child: PrayerTimeCard(
                    prayerTime: prayerTime,
                    fontScale: fontScale,
                    azanEnabledForPrayer: provider.prayerAzanEnabled[prayerTime.name] ?? false,
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFooter(BuildContext context, PrayerTimesProvider provider, double fontScale, int animationKey) {
    final theme = Theme.of(context);

    return TweenAnimationBuilder<double>(
      key: ValueKey('footer-$animationKey'), // Unique key for footer animation
      duration: const Duration(milliseconds: 800), // Delayed entrance for footer
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
        key: ValueKey('footer-content-$animationKey'), // Inner key for content
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Fixed height buttons with equal heights
            Expanded(
              child: _buildFooterButton(
                context: context,
                icon: provider.isLoading
                    ? null
                    : Icons.refresh,
                label: provider.isLoading ? 'Loading...' : 'Refresh Time',
                onPressed: () {
                  provider.refreshPrayerTimes();
                },
                theme: theme,
                isLoading: provider.isLoading,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildFooterButton(
                context: context,
                icon: Icons.location_searching,
                label: 'Refresh Region',
                onPressed: () {
                  provider.refreshRegion(); // Use the new refreshRegion method
                },
                theme: theme,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // FIXED: Extracted footer button widget to ensure consistency
  Widget _buildFooterButton({
    required BuildContext context,
    required IconData? icon,
    required String label,
    required VoidCallback onPressed,
    required ThemeData theme,
    bool isLoading = false,
  }) {
    return SizedBox(
      height: 48, // Fixed height for both buttons
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: isLoading
            ? const SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: Colors.white,
          ),
        )
            : Icon(icon),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          backgroundColor: theme.colorScheme.primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8), // Consistent border radius
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12), // Consistent padding
        ),
      ),
    );
  }

  void _showLocationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => LocationDialog(
        onLocationSelected: (latitude, longitude) {
          context.read<PrayerTimesProvider>().updateLocation(latitude, longitude);
        },
      ),
    );
  }

  void _showAzanSettingsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const AzanSettingsDialog(),
    );
  }

  String _formatTime(String time24) {
    try {
      final parts = time24.split(':');
      final hour = int.parse(parts[0]);
      final minute = parts[1];

      final hour12 = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
      final ampm = hour >= 12 ? 'PM' : 'AM';

      return '$hour12:$minute $ampm';
    } catch (e) {
      return time24;
    }
  }
}