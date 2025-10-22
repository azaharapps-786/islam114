// lib/core/services/location_service.dart
import 'package:flutter/foundation.dart'; // Add this import
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:permission_handler/permission_handler.dart';

class LocationService {
  static final LocationService _instance = LocationService._internal();
  factory LocationService() => _instance;
  LocationService._internal();

  Future<bool> hasPermission() async {
    final permission = await Geolocator.checkPermission();
    return permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse;
  }

  Future<bool> requestPermission() async {
    final permission = await Geolocator.requestPermission();
    return permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse;
  }

  Future<Position?> getCurrentPosition() async {
    try {
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
    } catch (e) {
      debugPrint('Error getting position: $e');
      return null;
    }
  }

  Future<String> getLocationName(double latitude, double longitude) async {
    try {
      debugPrint('Getting location name for: $latitude, $longitude');
      final placemarks = await placemarkFromCoordinates(latitude, longitude);
      debugPrint('Found ${placemarks.length} placemarks');

      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        debugPrint('Placemark: $place');

        // Try to get the most specific location name
        if (place.locality != null && place.locality!.isNotEmpty) {
          if (place.administrativeArea != null && place.administrativeArea!.isNotEmpty) {
            return "${place.locality}, ${place.administrativeArea}";
          }
          return place.locality!;
        } else if (place.subAdministrativeArea != null && place.subAdministrativeArea!.isNotEmpty) {
          if (place.administrativeArea != null && place.administrativeArea!.isNotEmpty) {
            return "${place.subAdministrativeArea}, ${place.administrativeArea}";
          }
          return place.subAdministrativeArea!;
        } else if (place.administrativeArea != null && place.administrativeArea!.isNotEmpty) {
          return place.administrativeArea!;
        } else if (place.country != null && place.country!.isNotEmpty) {
          return place.country!;
        }
      }

      // If we couldn't get a proper name, return coordinates
      return "$latitude, $longitude";
    } catch (e) {
      debugPrint('Error getting location name: $e');
      return "$latitude, $longitude";
    }
  }
}