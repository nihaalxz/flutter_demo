import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'dart:io' show Platform;
import 'dart:async';

class LocationService {
  // Singleton pattern for consistent service usage
  static final LocationService _instance = LocationService._internal();
  factory LocationService() => _instance;
  LocationService._internal();

  // Stream controller for location updates
  final StreamController<Position> _locationController = StreamController<Position>.broadcast();
  Stream<Position> get locationStream => _locationController.stream;
  
  StreamSubscription<Position>? _positionStreamSubscription;
  Position? _lastKnownPosition;
  
  // Getters
  Position? get lastKnownPosition => _lastKnownPosition;

  /// Determines the current position of the device with comprehensive error handling
  static Future<Position> getCurrentPosition({
    Duration? timeout = const Duration(seconds: 15),
    bool forceRequest = false,
  }) async {
    try {
      if (kDebugMode) {
        print("[LocationService] Starting location request...");
        print("[LocationService] Platform: ${Platform.isIOS ? 'iOS' : 'Android'}");
      }

      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (kDebugMode) {
        print("[LocationService] Location services enabled: $serviceEnabled");
      }
      
      if (!serviceEnabled) {
        // Try to open location settings
        bool opened = await Geolocator.openLocationSettings();
        if (!opened) {
          throw LocationServiceException(
            'Location services are disabled. Please enable them in settings.',
            LocationErrorType.servicesDisabled,
          );
        }
        // Wait a bit for user to enable
        await Future.delayed(const Duration(seconds: 2));
        serviceEnabled = await Geolocator.isLocationServiceEnabled();
        if (!serviceEnabled) {
          throw LocationServiceException(
            'Location services are still disabled.',
            LocationErrorType.servicesDisabled,
          );
        }
      }

      // Check and request permissions
      LocationPermission permission = await _handlePermissions();
      
      if (kDebugMode) {
        print("[LocationService] Final permission status: $permission");
      }

      // Configure platform-specific settings
      final LocationSettings locationSettings = _getPlatformSettings();

      // Get current position with timeout
      Position position;
      if (timeout != null) {
        position = await Geolocator.getCurrentPosition(
          locationSettings: locationSettings,
        ).timeout(
          timeout,
          onTimeout: () {
            throw LocationServiceException(
              'Location request timed out. Please try again.',
              LocationErrorType.timeout,
            );
          },
        );
      } else {
        position = await Geolocator.getCurrentPosition(
          locationSettings: locationSettings,
        );
      }

      if (kDebugMode) {
        print("[LocationService] Position obtained: ${position.latitude}, ${position.longitude}");
        print("[LocationService] Accuracy: ${position.accuracy}m");
      }

      // Cache the position
      LocationService()._lastKnownPosition = position;
      
      return position;
    } catch (e) {
      if (kDebugMode) {
        print("[LocationService] Error getting position: $e");
      }
      if (e is LocationServiceException) {
        rethrow;
      }
      throw LocationServiceException(
        'Failed to get location: ${e.toString()}',
        LocationErrorType.unknown,
      );
    }
  }

  /// Handle location permissions with detailed checks
  static Future<LocationPermission> _handlePermissions() async {
    LocationPermission permission = await Geolocator.checkPermission();
    
    if (kDebugMode) {
      print("[LocationService] Initial permission check: $permission");
    }

    if (permission == LocationPermission.denied) {
      if (kDebugMode) {
        print("[LocationService] Requesting permission...");
      }
      
      permission = await Geolocator.requestPermission();
      
      if (kDebugMode) {
        print("[LocationService] Permission after request: $permission");
      }
      
      if (permission == LocationPermission.denied) {
        throw LocationServiceException(
          'Location permissions are denied. Please grant location access to use this feature.',
          LocationErrorType.permissionDenied,
        );
      }
    }

    if (permission == LocationPermission.deniedForever) {
      // Open app settings for user to manually enable
      bool opened = await Geolocator.openAppSettings();
      if (kDebugMode) {
        print("[LocationService] Opened app settings: $opened");
      }
      
      throw LocationServiceException(
        'Location permissions are permanently denied. Please enable them in app settings.',
        LocationErrorType.permissionDeniedForever,
      );
    }

    // For iOS, also check if precise location is enabled
    if (Platform.isIOS) {
      LocationAccuracyStatus accuracyStatus = await Geolocator.getLocationAccuracy();
      if (kDebugMode) {
        print("[LocationService] iOS accuracy status: $accuracyStatus");
      }
      
      if (accuracyStatus == LocationAccuracyStatus.reduced) {
        // Optionally request full accuracy
        accuracyStatus = await Geolocator.requestTemporaryFullAccuracy(
          purposeKey: "LocationDefaultAccuracyReduced",
        );
        if (kDebugMode) {
          print("[LocationService] iOS accuracy after request: $accuracyStatus");
        }
      }
    }

    return permission;
  }

  /// Get platform-specific location settings
  static LocationSettings _getPlatformSettings() {
    if (Platform.isIOS) {
      return AppleSettings(
        accuracy: LocationAccuracy.high,
        activityType: ActivityType.other,
        distanceFilter: 10, // Update every 10 meters
        pauseLocationUpdatesAutomatically: false,
        showBackgroundLocationIndicator: false,
        allowBackgroundLocationUpdates: false,
      );
    } else if (Platform.isAndroid) {
      return AndroidSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10, // Update every 10 meters
        forceLocationManager: false,
        intervalDuration: const Duration(seconds: 5),
        foregroundNotificationConfig: null, // Add if using background location
      );
    } else {
      // Fallback for other platforms
      return const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10,
      );
    }
  }

  /// Start continuous location updates
  Future<void> startLocationUpdates({
    void Function(Position)? onLocationUpdate,
    void Function(Object)? onError,
  }) async {
    try {
      // Ensure permissions are granted
      await _handlePermissions();
      
      final LocationSettings locationSettings = _getPlatformSettings();
      
      _positionStreamSubscription?.cancel();
      _positionStreamSubscription = Geolocator.getPositionStream(
        locationSettings: locationSettings,
      ).listen(
        (Position position) {
          _lastKnownPosition = position;
          _locationController.add(position);
          onLocationUpdate?.call(position);
          
          if (kDebugMode) {
            print("[LocationService] Location update: ${position.latitude}, ${position.longitude}");
          }
        },
        onError: (error) {
          if (kDebugMode) {
            print("[LocationService] Location stream error: $error");
          }
          onError?.call(error);
        },
      );
    } catch (e) {
      if (kDebugMode) {
        print("[LocationService] Failed to start location updates: $e");
      }
      rethrow;
    }
  }

  /// Stop continuous location updates
  void stopLocationUpdates() {
    _positionStreamSubscription?.cancel();
    _positionStreamSubscription = null;
    if (kDebugMode) {
      print("[LocationService] Location updates stopped");
    }
  }

  /// Get last known position (cached)
  static Future<Position?> getLastKnownPosition() async {
    try {
      Position? position = await Geolocator.getLastKnownPosition();
      if (kDebugMode) {
        print("[LocationService] Last known position: ${position?.latitude}, ${position?.longitude}");
      }
      return position;
    } catch (e) {
      if (kDebugMode) {
        print("[LocationService] Error getting last known position: $e");
      }
      return null;
    }
  }

  /// Calculate distance between two positions in meters
  static double distanceBetween(
    double startLatitude,
    double startLongitude,
    double endLatitude,
    double endLongitude,
  ) {
    return Geolocator.distanceBetween(
      startLatitude,
      startLongitude,
      endLatitude,
      endLongitude,
    );
  }

  /// Calculate bearing between two positions
  static double bearingBetween(
    double startLatitude,
    double startLongitude,
    double endLatitude,
    double endLongitude,
  ) {
    return Geolocator.bearingBetween(
      startLatitude,
      startLongitude,
      endLatitude,
      endLongitude,
    );
  }

  /// Converts GPS coordinates into a human-readable address
  static Future<String> getAddressFromCoordinates(
    Position position, {
    bool detailed = false,
  }) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isEmpty) {
        return "Unknown Location";
      }

      Placemark place = placemarks.first;
      
      if (detailed) {
        // Return detailed address
        List<String> addressParts = [
          if (place.name != null && place.name!.isNotEmpty) place.name!,
          if (place.street != null && place.street!.isNotEmpty) place.street!,
          if (place.subLocality != null && place.subLocality!.isNotEmpty) place.subLocality!,
          if (place.locality != null && place.locality!.isNotEmpty) place.locality!,
          if (place.administrativeArea != null && place.administrativeArea!.isNotEmpty) 
            place.administrativeArea!,
          if (place.postalCode != null && place.postalCode!.isNotEmpty) place.postalCode!,
          if (place.country != null && place.country!.isNotEmpty) place.country!,
        ];
        
        return addressParts.join(', ');
      } else {
        // Return simple city name
        return place.locality ?? 
               place.subLocality ?? 
               place.administrativeArea ?? 
               "Unknown City";
      }
    } catch (e) {
      if (kDebugMode) {
        print("[LocationService] Error getting address: $e");
      }
      return "Could not determine location";
    }
  }

  /// Get city name from coordinates
  static Future<String> getCityFromCoordinates(Position position) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks.first;
        return place.locality ?? 
               place.subLocality ?? 
               place.administrativeArea ?? 
               "Unknown City";
      }
      return "Unknown City";
    } catch (e) {
      if (kDebugMode) {
        print("[LocationService] Error getting city: $e");
      }
      return "Could not determine city";
    }
  }

  /// Get coordinates from address string
  static Future<Position?> getCoordinatesFromAddress(String address) async {
    try {
      List<Location> locations = await locationFromAddress(address);
      
      if (locations.isNotEmpty) {
        Location location = locations.first;
        return Position(
          latitude: location.latitude,
          longitude: location.longitude,
          timestamp: DateTime.now(),
          accuracy: 0,
          altitude: 0,
          altitudeAccuracy: 0,
          heading: 0,
          headingAccuracy: 0,
          speed: 0,
          speedAccuracy: 0,
        );
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        print("[LocationService] Error getting coordinates from address: $e");
      }
      return null;
    }
  }

  /// Check if location services are enabled
  static Future<bool> isLocationServiceEnabled() async {
    return await Geolocator.isLocationServiceEnabled();
  }

  /// Check current permission status
  static Future<LocationPermission> checkPermission() async {
    return await Geolocator.checkPermission();
  }

  /// Open app settings
  static Future<bool> openAppSettings() async {
    return await Geolocator.openAppSettings();
  }

  /// Open location settings
  static Future<bool> openLocationSettings() async {
    return await Geolocator.openLocationSettings();
  }

  /// Dispose of resources
  void dispose() {
    _positionStreamSubscription?.cancel();
    _locationController.close();
  }
}

/// Custom exception for location service errors
class LocationServiceException implements Exception {
  final String message;
  final LocationErrorType type;

  LocationServiceException(this.message, this.type);

  @override
  String toString() => message;
}

/// Types of location errors
enum LocationErrorType {
  servicesDisabled,
  permissionDenied,
  permissionDeniedForever,
  timeout,
  unknown,
}