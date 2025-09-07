import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'dart:io' show Platform;

/// Custom exception for location service errors for better handling in the UI.
class LocationServiceException implements Exception {
  final String message;
  final LocationErrorType type;

  LocationServiceException(this.message, this.type);

  @override
  String toString() => message;
}

/// Enum to categorize location errors.
enum LocationErrorType {
  servicesDisabled,
  permissionDenied,
  permissionDeniedForever,
  timeout,
  lowAccuracy,
  unknown,
}

class LocationService {
  /// Determines the current position of the device.
  static Future<Position> getCurrentPosition({Duration? timeout}) async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw LocationServiceException(
        'Location services are disabled. Please enable them in your device settings.',
        LocationErrorType.servicesDisabled,
      );
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw LocationServiceException(
          'Location permissions are denied.',
          LocationErrorType.permissionDenied,
        );
      }
    }

    if (permission == LocationPermission.deniedForever) {
      await Geolocator.openAppSettings();
      throw LocationServiceException(
        'Location permissions are permanently denied. Please enable them in your app settings.',
        LocationErrorType.permissionDeniedForever,
      );
    }

    final position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    ).timeout(timeout ?? const Duration(seconds: 15), onTimeout: () {
      throw LocationServiceException(
        'Location request timed out. Please check your connection and try again.',
        LocationErrorType.timeout,
      );
    });

    // DEBUG LOGGING FOR ACCURACY
    if (kDebugMode) {
      print(
          "[LocationService] Position obtained with accuracy: ${position.accuracy} meters");
    }

    // An accuracy > 1000m often indicates an approximate location on iOS.
    if (position.accuracy > 1000) {
      throw LocationServiceException(
        'Precise location is turned off. Please enable it in your location settings for this app to get accurate results.',
        LocationErrorType.lowAccuracy,
      );
    }

    return position;
  }

  /// Converts GPS coordinates into a human-readable city name.
  static Future<String> getCityFromCoordinates(Position position) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        return placemarks.first.locality ?? "Unknown City";
      }
      return "Unknown City";
    } catch (e) {
      if (kDebugMode) {
        print("[LocationService] Error getting city: $e");
      }
      return "Could not determine city";
    }
  }

  // ✅ --- ADDED MISSING HELPER METHODS ---

  /// Opens the app's settings page for the user to manually change permissions.
  static Future<bool> openAppSettings() async {
    return await Geolocator.openAppSettings();
  }

  /// Opens the device's main location settings page.
  static Future<bool> openLocationSettings() async {
    return await Geolocator.openLocationSettings();
  }
}