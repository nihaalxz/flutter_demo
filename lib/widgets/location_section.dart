import 'dart:io';
import 'package:flutter/material.dart';
import 'package:myfirstflutterapp/services/location_service.dart';

class LocationSection extends StatelessWidget {
  final String currentCity;
  final bool locationPermissionDenied;
  final bool isLoadingLocation;
  final VoidCallback onRetryLocation;

  const LocationSection({
    super.key,
    required this.currentCity,
    required this.locationPermissionDenied,
    required this.isLoadingLocation,
    required this.onRetryLocation,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(
                Icons.location_on_outlined,
                size: 20,
                color: locationPermissionDenied
                    ? Colors.orange.shade700
                    : Theme.of(context).textTheme.bodySmall?.color,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _buildLocationTitle(),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (isLoadingLocation)
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else if (locationPermissionDenied)
                IconButton(
                  icon: Icon(Icons.refresh, color: Colors.orange.shade800),
                  onPressed: onRetryLocation,
                  tooltip: 'Retry location',
                ),
            ],
          ),
          if (locationPermissionDenied) _buildPermissionWarning(context),
        ],
      ),
    );
  }

  /// Determines the correct title to display based on the location state.
  String _buildLocationTitle() {
    if (isLoadingLocation || currentCity == "Loading...") {
      return "Getting your location...";
    }
    if (locationPermissionDenied) {
      return "Location Access Denied";
    }
    if (currentCity == "Unable to determine location") {
       return "Could not get location";
    }
    return "Items near $currentCity";
  }

  /// Builds the warning message and settings button for when permission is denied.
  Widget _buildPermissionWarning(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8.0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.orange.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.orange.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Icon(
              Icons.info_outline,
              size: 20,
              color: Colors.orange.shade800,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Enable location to see items near you.',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.orange.shade900,
                ),
              ),
            ),
            TextButton(
              onPressed: () async {
                // Use the service to open the app's settings page
                await LocationService.openAppSettings();
              },
              child: const Text(
                'Settings',
                style: TextStyle(fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
