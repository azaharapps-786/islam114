import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import 'package:islam114/main.dart';
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
  int _animationKey = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // Performance: 800ms is good, but easeOut is less taxing than easeInOut for hardware
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    );

    _restartAnimation();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<PrayerTimesProvider>().initialize();
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final modalRoute = ModalRoute.of(context);
    if (modalRoute is PageRoute) {
      routeObserver.subscribe(this, modalRoute as PageRoute<dynamic>);
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      _restartAnimation();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _animationController.dispose();
    routeObserver.unsubscribe(this);
    super.dispose();
  }

  void _restartAnimation() {
    if (_animationController.isAnimating) return; // Prevent overlapping
    _animationController.reset();
    _animationController.forward();
    if (mounted) {
      setState(() {
        _animationKey++;
      });
    }
  }

  @override
  void didPopNext() {
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
          if (provider.errorMessage != null) {
            return FadeTransition(
              opacity: _fadeAnimation,
              child: _buildErrorState(provider, fontScale, theme),
            );
          }

          if (provider.isLoading && provider.prayerTimes.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          return FadeTransition(
            opacity: _fadeAnimation,
            child: RefreshIndicator(
              onRefresh: () async => await provider.refreshPrayerTimes(),
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

  Widget _buildErrorState(PrayerTimesProvider provider, double fontScale, ThemeData theme) {
    return Center(
      key: ValueKey('error-$_animationKey'),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Error: ${provider.errorMessage}',
            style: TextStyle(fontSize: 16 * fontScale, color: theme.colorScheme.error),
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
    );
  }

  Widget _buildHeader(BuildContext context, PrayerTimesProvider provider, double fontScale, int animationKey) {
    final theme = Theme.of(context);

    return RepaintBoundary( // Optimizes animation by caching the static content
      child: TweenAnimationBuilder<double>(
        key: ValueKey('header-$animationKey'),
        duration: const Duration(milliseconds: 600),
        tween: Tween(begin: 0.0, end: 1.0),
        curve: Curves.easeOutCubic,
        builder: (context, value, child) {
          return Opacity(
            opacity: value,
            child: Transform.translate(
              offset: Offset(0, 15 * (1 - value)),
              child: child,
            ),
          );
        },
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                children: [
                  _buildNavButton(theme, Icons.chevron_left, () {
                    provider.changeDate(provider.currentDate.subtract(const Duration(days: 1)));
                  }),
                  Expanded(
                    child: Column(
                      children: [
                        Text(
                          DateFormat('EEEE').format(provider.currentDate).toUpperCase(),
                          style: TextStyle(fontSize: 16 * fontScale, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          DateFormat('d MMMM, yyyy').format(provider.currentDate),
                          style: TextStyle(fontSize: 14 * fontScale, color: theme.colorScheme.onSurface.withOpacity(0.7)),
                        ),
                      ],
                    ),
                  ),
                  _buildNavButton(theme, Icons.chevron_right, () {
                    provider.changeDate(provider.currentDate.add(const Duration(days: 1)));
                  }),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.location_on, size: 20 * fontScale),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      provider.locationName.isNotEmpty ? provider.locationName : 'Getting location...',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16 * fontScale),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildActionButton(
                      context: context,
                      icon: Icons.edit_location,
                      label: 'Change Location',
                      onPressed: () => _showLocationDialog(context),
                      theme: theme,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildActionButton(
                      context: context,
                      icon: provider.azanEnabled ? Icons.volume_up : Icons.volume_off,
                      label: 'Azan Settings',
                      onPressed: () => _showAzanSettingsDialog(context),
                      theme: theme,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavButton(ThemeData theme, IconData icon, VoidCallback onPressed) {
    return IconButton(
      onPressed: onPressed,
      icon: Icon(icon),
      style: IconButton.styleFrom(
        backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
        foregroundColor: theme.colorScheme.primary,
      ),
    );
  }

  Widget _buildActionButton({
    required BuildContext context,
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    required ThemeData theme,
  }) {
    return SizedBox(
      height: 48,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 20),
        label: Text(label, style: const TextStyle(fontSize: 13)),
        style: ElevatedButton.styleFrom(
          backgroundColor: theme.colorScheme.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    );
  }

  Widget _buildNextPrayer(BuildContext context, PrayerTimesProvider provider, double fontScale, int animationKey) {
    final theme = Theme.of(context);
    if (provider.nextPrayer == null) return const SizedBox.shrink();

    return RepaintBoundary(
      child: TweenAnimationBuilder<double>(
        key: ValueKey('next-p-$animationKey'),
        duration: const Duration(milliseconds: 600),
        tween: Tween(begin: 0.0, end: 1.0),
        builder: (context, value, child) {
          return Transform.scale(scale: 0.95 + (0.05 * value), child: Opacity(opacity: value, child: child));
        },
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: theme.colorScheme.primary.withOpacity(0.3)),
          ),
          child: Row(
            children: [
              Icon(Icons.access_time, color: theme.colorScheme.primary),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Next Prayer: ${provider.nextPrayer!.name} at ${_formatTime(provider.nextPrayer!.time)}',
                  style: TextStyle(fontSize: 17 * fontScale, fontWeight: FontWeight.bold, color: theme.colorScheme.primary),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPrayerTimesList(BuildContext context, PrayerTimesProvider provider, double fontScale, int animationKey) {
    if (provider.prayerTimes.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Prayer Times', style: TextStyle(fontSize: 18 * fontScale, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          ListView.builder(
            key: ValueKey('list-$animationKey'),
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: provider.prayerTimes.length,
            itemBuilder: (context, index) {
              final prayerTime = provider.prayerTimes[index];
              return RepaintBoundary(
                child: TweenAnimationBuilder<double>(
                  key: ValueKey('item-$index-$animationKey'),
                  duration: Duration(milliseconds: 400 + (index * 60)),
                  tween: Tween(begin: 0.0, end: 1.0),
                  curve: Curves.easeOut,
                  builder: (context, value, child) {
                    return Opacity(
                      opacity: value,
                      child: Transform.translate(offset: Offset(0, 10 * (1 - value)), child: child),
                    );
                  },
                  child: PrayerTimeCard(
                    prayerTime: prayerTime,
                    fontScale: fontScale,
                    azanEnabledForPrayer: provider.prayerAzanEnabled[prayerTime.name] ?? false,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFooter(BuildContext context, PrayerTimesProvider provider, double fontScale, int animationKey) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: _buildFooterButton(
              label: provider.isLoading ? 'Loading...' : 'Refresh Time',
              icon: provider.isLoading ? null : Icons.refresh,
              onPressed: () => provider.refreshPrayerTimes(),
              theme: theme,
              isLoading: provider.isLoading,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildFooterButton(
              label: 'Refresh Region',
              icon: Icons.location_searching,
              onPressed: () => provider.refreshRegion(),
              theme: theme,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooterButton({
    required String label,
    required IconData? icon,
    required VoidCallback onPressed,
    required ThemeData theme,
    bool isLoading = false,
  }) {
    return SizedBox(
      height: 48,
      child: ElevatedButton.icon(
        onPressed: isLoading ? null : onPressed,
        icon: isLoading
            ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
            : Icon(icon, size: 20),
        label: Text(label, style: const TextStyle(fontSize: 13)),
        style: ElevatedButton.styleFrom(
          backgroundColor: theme.colorScheme.primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    );
  }

  void _showLocationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => LocationDialog(
        onLocationSelected: (lat, lon) => context.read<PrayerTimesProvider>().updateLocation(lat, lon),
      ),
    );
  }

  void _showAzanSettingsDialog(BuildContext context) {
    showDialog(context: context, builder: (context) => const AzanSettingsDialog());
  }

  String _formatTime(String time24) {
    try {
      final parts = time24.split(':');
      final hour = int.parse(parts[0]);
      final minute = parts[1];
      final hour12 = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
      final ampm = hour >= 12 ? 'PM' : 'AM';
      return '$hour12:$minute $ampm';
    } catch (_) { return time24; }
  }
}