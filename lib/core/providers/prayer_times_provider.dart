import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../data/models/prayer_times_model.dart';
import '../services/location_service.dart';
import '../services/prayer_times_service.dart';
import '../services/azan_settings_service.dart';
import '../services/azan_player_service.dart';

class PrayerTimesProvider extends ChangeNotifier {
  final PrayerTimesService _prayerTimesService = PrayerTimesService();
  final LocationService _locationService = LocationService();
  final AzanSettingsService _azanSettingsService = AzanSettingsService();
  final AzanPlayerService _azanPlayerService = AzanPlayerService();

  List<PrayerTime> _prayerTimes = [];
  List<PrayerTime> get prayerTimes => _prayerTimes;

  PrayerTime? _nextPrayer;
  PrayerTime? get nextPrayer => _nextPrayer;

  DateTime _currentDate = DateTime.now();
  DateTime get currentDate => _currentDate;

  String _locationName = '';
  String get locationName => _locationName;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  LocationData? _currentLocation;
  LocationData? get currentLocation => _currentLocation;

  // Store the user's actual location separately
  LocationData? _userActualLocation;
  String _userActualLocationName = '';

  // Add getters for Azan settings
  bool get azanEnabled => _azanSettingsService.azanEnabled;
  Map<String, bool> get prayerAzanEnabled => _azanSettingsService.prayerAzanEnabled;

  Future<void> initialize() async {
    debugPrint('Initializing PrayerTimesProvider');
    _setLoading(true);
    _errorMessage = null;

    try {
      // Check if we have cached location
      final cachedLocation = await _prayerTimesService.getCachedLocation();
      if (cachedLocation != null) {
        debugPrint('Using cached location: ${cachedLocation.latitude}, ${cachedLocation.longitude}');
        _currentLocation = cachedLocation;
        _userActualLocation = cachedLocation; // Store as user's actual location
        _locationName = await _locationService.getLocationName(
          cachedLocation.latitude,
          cachedLocation.longitude,
        );
        _userActualLocationName = _locationName; // Store the name
        debugPrint('Location name: $_locationName');
        await _loadPrayerTimes();
      } else {
        debugPrint('No cached location, getting current location');
        // Get current location
        final hasPermission = await _locationService.hasPermission();
        if (!hasPermission) {
          debugPrint('Requesting location permission');
          final granted = await _locationService.requestPermission();
          if (!granted) {
            _errorMessage = 'Location permission is required to show prayer times';
            _setLoading(false);
            return;
          }
        }

        final position = await _locationService.getCurrentPosition();
        if (position != null) {
          debugPrint('Got current position: ${position.latitude}, ${position.longitude}');
          _currentLocation = LocationData(
            latitude: position.latitude,
            longitude: position.longitude,
          );
          _userActualLocation = _currentLocation; // Store as user's actual location
          _locationName = await _locationService.getLocationName(
            position.latitude,
            position.longitude,
          );
          _userActualLocationName = _locationName; // Store the name
          debugPrint('Location name: $_locationName');
          await _loadPrayerTimes();
        } else {
          debugPrint('Could not get current position');
          _errorMessage = 'Could not get your location';
        }
      }
    } catch (e) {
      debugPrint('Error initializing prayer times: $e');
      _errorMessage = 'Error initializing prayer times: ${e.toString()}';
    } finally {
      _setLoading(false);
    }
  }

  Future<void> _loadPrayerTimes({bool forceRefresh = false}) async {
    if (_currentLocation == null) {
      debugPrint('No location available, cannot load prayer times');
      return;
    }

    debugPrint('Loading prayer times for ${_currentLocation!.latitude}, ${_currentLocation!.longitude} for date ${_currentDate}');
    _setLoading(true);
    _errorMessage = null;

    try {
      PrayerTimesResponse? prayerTimesData;

      // Always fetch from API when date changes
      if (forceRefresh || !_isSameDay(_currentDate, DateTime.now())) {
        debugPrint('Fetching prayer times from API for date ${_currentDate}');
        prayerTimesData = await _prayerTimesService.getPrayerTimesByCoordinates(
          _currentLocation!.latitude,
          _currentLocation!.longitude,
          date: _currentDate,
        );
      } else {
        // Try to use cached data if not forcing refresh
        if (await _prayerTimesService.isCacheValid()) {
          debugPrint('Using cached prayer times');
          prayerTimesData = await _prayerTimesService.getCachedPrayerTimes();
        } else {
          debugPrint('Fetching prayer times from API');
          prayerTimesData = await _prayerTimesService.getPrayerTimesByCoordinates(
            _currentLocation!.latitude,
            _currentLocation!.longitude,
            date: _currentDate,
          );
        }
      }

      if (prayerTimesData != null) {
        debugPrint('Got prayer times data');
        _processPrayerTimesData(prayerTimesData);
      } else {
        debugPrint('Could not load prayer times');
        _errorMessage = 'Could not load prayer times';
      }
    } catch (e) {
      debugPrint('Error loading prayer times: $e');
      _errorMessage = 'Error loading prayer times: ${e.toString()}';
    } finally {
      _setLoading(false);
    }
  }

  void _processPrayerTimesData(PrayerTimesResponse data) {
    final timings = data.data.timings;

    // Create prayer times list
    final List<PrayerTime> prayerTimesList = [
      PrayerTime(name: 'Fajr', time: timings.fajr),
      PrayerTime(name: 'Sunrise', time: timings.sunrise),
      PrayerTime(name: 'Dhuhr', time: timings.dhuhr),
      PrayerTime(name: 'Asr', time: timings.asr),
      PrayerTime(name: 'Maghrib', time: timings.maghrib),
      PrayerTime(name: 'Isha', time: timings.isha),
    ];

    // Calculate and add Tahajjud time
    final updatedList = _calculateAndAddTahajjudTime(prayerTimesList);

    // Find next prayer (only for today)
    if (_isSameDay(_currentDate, DateTime.now())) {
      _nextPrayer = _findNextPrayer(updatedList);

      // Mark the next prayer in the list
      _prayerTimes = updatedList.map((prayer) {
        return PrayerTime(
          name: prayer.name,
          time: prayer.time,
          isNext: prayer.name == _nextPrayer?.name,
        );
      }).toList();

      // Check if we should play Azan
      _checkAndPlayAzan();
    } else {
      _nextPrayer = null;
      _prayerTimes = updatedList;
    }

    notifyListeners();
  }

  List<PrayerTime> _calculateAndAddTahajjudTime(List<PrayerTime> prayerTimesList) {
    final fajrTimeStr = prayerTimesList.firstWhere(
          (p) => p.name.toLowerCase() == 'fajr',
      orElse: () => PrayerTime(name: '', time: ''),
    ).time;

    final ishaTimeStr = prayerTimesList.firstWhere(
          (p) => p.name.toLowerCase() == 'isha',
      orElse: () => PrayerTime(name: '', time: ''),
    ).time;

    if (fajrTimeStr.isNotEmpty && ishaTimeStr.isNotEmpty) {
      try {
        final fajrTime = _parseTime(fajrTimeStr);
        final ishaTime = _parseTime(ishaTimeStr);

        // Create DateTime objects for the current date's Isha and next day's Fajr
        final currentDate = DateTime(_currentDate.year, _currentDate.month, _currentDate.day);

        final ishaDateTime = currentDate.add(Duration(hours: ishaTime.hour, minutes: ishaTime.minute));
        final fajrDateTime = currentDate.add(Duration(days: 1, hours: fajrTime.hour, minutes: fajrTime.minute));

        // Calculate the duration between Isha and Fajr
        final nightDuration = fajrDateTime.difference(ishaDateTime);

        // Calculate Tahajjud time (2/3 of the night has passed)
        final tahajjudDuration = Duration(
          milliseconds: (nightDuration.inMilliseconds * 2 / 3).round(),
        );

        final tahajjudDateTime = ishaDateTime.add(tahajjudDuration);

        // Format back to HH:mm
        final tahajjudTimeStr = DateFormat('HH:mm').format(tahajjudDateTime);

        // Find the index of Isha to insert Tahajjud right after it
        final ishaIndex = prayerTimesList.indexWhere(
              (p) => p.name.toLowerCase() == 'isha',
        );

        final newList = List<PrayerTime>.from(prayerTimesList);
        final tahajjudPrayer = PrayerTime(
          name: 'Tahajjud',
          time: tahajjudTimeStr,
          isNext: _nextPrayer?.name == 'Tahajjud',
        );

        if (ishaIndex != -1) {
          newList.insert(ishaIndex + 1, tahajjudPrayer);
        } else {
          newList.add(tahajjudPrayer);
        }

        return newList;
      } catch (e) {
        debugPrint('Error calculating Tahajjud time: $e');
        // If there's an error calculating Tahajjud, return the original list
        return prayerTimesList;
      }
    }

    return prayerTimesList;
  }

  TimeOfDay _parseTime(String timeStr) {
    final parts = timeStr.split(':');
    return TimeOfDay(
      hour: int.parse(parts[0]),
      minute: int.parse(parts[1]),
    );
  }

  PrayerTime? _findNextPrayer(List<PrayerTime> prayerTimes) {
    final now = TimeOfDay.now();
    final nowInMinutes = now.hour * 60 + now.minute;

    for (final prayer in prayerTimes) {
      final parts = prayer.time.split(':');
      final prayerInMinutes = int.parse(parts[0]) * 60 + int.parse(parts[1]);

      if (prayerInMinutes > nowInMinutes) {
        return prayer;
      }
    }

    // If all prayers have passed, return the first prayer of the next day
    return prayerTimes.isNotEmpty ? prayerTimes.first : null;
  }

  // Add this method to check and play Azan
  void _checkAndPlayAzan() {
    if (_nextPrayer == null) return;

    final now = DateTime.now();
    final prayerTime = _parseTime(_nextPrayer!.time);
    final prayerDateTime = DateTime(
        now.year, now.month, now.day,
        prayerTime.hour, prayerTime.minute
    );

    // Calculate difference in seconds
    final difference = prayerDateTime.difference(now).inSeconds;

    // If it's time for the next prayer (within 1 minute)
    if (difference >= 0 && difference <= 60) {
      final prayerName = _nextPrayer!.name;
      if (_azanSettingsService.isAzanEnabledForPrayer(prayerName)) {
        _azanPlayerService.playAzan(prayerName: prayerName);
      }
    }
  }

  Future<void> refreshPrayerTimes() async {
    // Reset to today's date when refreshing
    debugPrint('Resetting date to today and refreshing prayer times');
    _currentDate = DateTime.now();
    await _loadPrayerTimes(forceRefresh: true);
  }

  Future<void> refreshRegion() async {
    debugPrint('Refreshing region - getting current device location');
    _setLoading(true);
    _errorMessage = null;

    try {
      // Check if we have location permission
      final hasPermission = await _locationService.hasPermission();
      if (!hasPermission) {
        debugPrint('Requesting location permission');
        final granted = await _locationService.requestPermission();
        if (!granted) {
          _errorMessage = 'Location permission is required to show prayer times';
          _setLoading(false);
          return;
        }
      }

      // Get fresh current position
      final position = await _locationService.getCurrentPosition();
      if (position != null) {
        debugPrint('Got current position: ${position.latitude}, ${position.longitude}');

        // Update both current location and user's actual location
        _currentLocation = LocationData(
          latitude: position.latitude,
          longitude: position.longitude,
        );
        _userActualLocation = _currentLocation;

        // Get location name
        _locationName = await _locationService.getLocationName(
          position.latitude,
          position.longitude,
        );
        _userActualLocationName = _locationName;

        debugPrint('Location name: $_locationName');

        // Load prayer times for the new location
        await _loadPrayerTimes(forceRefresh: true);
      } else {
        debugPrint('Could not get current position');
        _errorMessage = 'Could not get your location';
      }
    } catch (e) {
      debugPrint('Error refreshing region: $e');
      _errorMessage = 'Error refreshing region: ${e.toString()}';
    } finally {
      _setLoading(false);
    }
  }

  Future<void> changeDate(DateTime newDate) async {
    // Limit to 7 days before and after today
    final today = DateTime.now();
    final minDate = today.subtract(const Duration(days: 7));
    final maxDate = today.add(const Duration(days: 7));

    if (newDate.isBefore(minDate) || newDate.isAfter(maxDate)) {
      _errorMessage = 'Date is outside the allowed range (7 days before/after today)';
      notifyListeners();
      return;
    }

    debugPrint('Changing date from $_currentDate to $newDate');
    _currentDate = newDate;

    // Always fetch new data when date changes
    await _loadPrayerTimes(forceRefresh: true);
  }

  Future<void> updateLocation(double latitude, double longitude) async {
    debugPrint('Updating location to: $latitude, $longitude');
    _currentLocation = LocationData(latitude: latitude, longitude: longitude);
    _locationName = await _locationService.getLocationName(latitude, longitude);
    debugPrint('New location name: $_locationName');
    await _loadPrayerTimes(forceRefresh: true);
  }

  Future<void> setAzanEnabled(bool enabled) async {
    await _azanSettingsService.setAzanEnabled(enabled);
    notifyListeners();
  }

  Future<void> setPrayerAzanEnabled(String prayer, bool enabled) async {
    await _azanSettingsService.setPrayerAzanEnabled(prayer, enabled);
    notifyListeners();
  }

  Future<void> playTestAzan({String prayerName = ''}) async {
    debugPrint('Playing test Azan for prayer: $prayerName');
    try {
      await _azanPlayerService.playAzan(prayerName: prayerName);
      notifyListeners();
    } catch (e) {
      debugPrint('Error in playTestAzan: $e');
    }
  }

  Future<void> pauseTestAzan() async {
    debugPrint('Pausing test Azan');
    try {
      await _azanPlayerService.pauseAzan();
      notifyListeners();
    } catch (e) {
      debugPrint('Error in pauseTestAzan: $e');
    }
  }

  Future<void> stopTestAzan() async {
    debugPrint('Stopping test Azan');
    try {
      await _azanPlayerService.stopAzan();
      notifyListeners();
    } catch (e) {
      debugPrint('Error in stopTestAzan: $e');
    }
  }

  Future<bool> doesAzanFileExist() async {
    return await _azanPlayerService.doesAzanFileExist();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }
}