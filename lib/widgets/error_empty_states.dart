import 'dart:io';
import 'package:flutter/material.dart';
import 'package:myfirstflutterapp/services/location_service.dart';

class ErrorState extends StatelessWidget {
  final Object? error;
  final VoidCallback onRetry;

  const ErrorState({
    super.key,
    required this.error,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final isNetworkError = error is SocketException;
    final isLocationPermissionError = error is LocationServiceException &&
        (error as LocationServiceException).type == LocationErrorType.permissionDeniedForever;

    String title;
    String message;
    IconData icon;

    if (isNetworkError) {
      title = "No Internet Connection";
      message = "Please check your network connection and try again.";
      icon = Icons.wifi_off;
    } else if (isLocationPermissionError) {
      title = "Location Access Required";
      message = "To find items near you, please enable location services in your device settings.";
      icon = Icons.location_off;
    } else {
      title = "Something Went Wrong";
      message = "We couldn't load the data right now. Please try again.";
      icon = Icons.cloud_off_rounded;
    }
    
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 72, color: Colors.grey.shade400),
            const SizedBox(height: 24),
            Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text(message, style: TextStyle(fontSize: 16, color: Colors.grey.shade600), textAlign: TextAlign.center),
            const SizedBox(height: 32),
            if (isLocationPermissionError)
              ElevatedButton.icon(
                icon: const Icon(Icons.settings),
                label: const Text("Open Settings"),
                onPressed: () => LocationService.openAppSettings(),
              )
            else
              ElevatedButton.icon(
                icon: const Icon(Icons.refresh),
                label: const Text("Retry"),
                onPressed: onRetry,
              ),
          ],
        ),
      ),
    );
  }
}

class EmptyState extends StatelessWidget {
  const EmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    // Use SliverFillRemaining to center the content within a CustomScrollView
    return const SliverFillRemaining(
      hasScrollBody: false,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inventory_2_outlined, size: 72, color: Colors.grey),
            SizedBox(height: 16),
            Text('No Products Found', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            SizedBox(height: 8),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 32.0),
              child: Text(
                'There are currently no items available to display.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
