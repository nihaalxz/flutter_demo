import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geocoding/geocoding.dart';
import 'package:myfirstflutterapp/services/location_service.dart'; // Using the robust service

class MapPickerPage extends StatefulWidget {
  const MapPickerPage({super.key});

  @override
  State<MapPickerPage> createState() => _MapPickerPageState();
}

class _MapPickerPageState extends State<MapPickerPage> {
  // Default to a central location, will be updated to user's location
  static const _initialCameraPosition = CameraPosition(
    target: LatLng(20.5937, 78.9629), // Center of India
    zoom: 4,
  );

  GoogleMapController? _mapController;
  LatLng _selectedPosition = _initialCameraPosition.target;
  String _selectedAddress = "Move the map to select a location";
  bool _isLoadingAddress = true;

  @override
  void initState() {
    super.initState();
    _moveToCurrentUserLocation();
  }

  /// Tries to get the user's current location and move the map camera to it.
  Future<void> _moveToCurrentUserLocation() async {
    try {
      // Use our robust LocationService to handle permissions and get position
      final position = await LocationService.getCurrentPosition();
      _mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(
          LatLng(position.latitude, position.longitude),
          15, // Zoom in closer for a better user experience
        ),
      );
    } catch (e) {
      // Handle location errors gracefully
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }

  /// Called when the map camera stops moving to update the selected address.
  void _onCameraIdle() async {
    // Prevent errors if the controller isn't ready
    if (_mapController == null) return;

    // Use try-catch for safety, as getLatLng can sometimes fail
    try {
      final latLng = await _mapController!.getLatLng(
        ScreenCoordinate(
          x: MediaQuery.of(context).size.width ~/ 2,
          y: (MediaQuery.of(context).size.height - kToolbarHeight) ~/ 2,
        ),
      );

      setState(() {
        _selectedPosition = latLng;
        _isLoadingAddress = true; // Show loading indicator while geocoding
      });

      // Convert coordinates to a readable address
      final placemarks = await placemarkFromCoordinates(
        latLng.latitude,
        latLng.longitude,
      );

      if (mounted && placemarks.isNotEmpty) {
        final p = placemarks.first;
        setState(() {
          _selectedAddress = _formatPlacemark(p);
          _isLoadingAddress = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _selectedAddress = "Could not determine address";
          _isLoadingAddress = false;
        });
      }
    }
  }

  /// ✅ Formats a Placemark object into a detailed, human-readable address string,
  /// filtering out confusing "plus codes" and providing a clean structure.
  String _formatPlacemark(Placemark p) {
    // Helper function to check for and exclude plus codes.
    // Plus codes are useful but not user-friendly in a readable address.
    bool isPlusCode(String? s) => (s?.contains('+') ?? false) && (s?.length ?? 0) < 15;

    // Build the address from the most specific parts to the most general.
    // This creates a more natural address format.
    final components = [
      p.name,
      p.thoroughfare, // Street name and number
      p.subLocality,  // Neighborhood or smaller area
      p.locality,     // City or town
      p.administrativeArea, // State or province
      p.postalCode,
      p.country,
    ];

    // Filter out any null, empty, or plus code components.
    // The 'where' clause ensures we don't have empty commas.
    return components
        .where((s) => s != null && s.isNotEmpty && !isPlusCode(s))
        .toSet() // Use toSet() to remove duplicate parts (e.g., if locality and subLocality are the same)
        .join(', ');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: _initialCameraPosition,
            onMapCreated: (controller) => _mapController = controller,
            onCameraIdle: _onCameraIdle,
            myLocationButtonEnabled: true,
            myLocationEnabled: true,
            zoomControlsEnabled: false, // Cleaner UI
          ),
          // Center marker icon
          const Center(
            child: Icon(
              Icons.location_pin,
              color: Colors.red,
              size: 50,
            ),
          ),
          // Top address bar and confirmation button
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.15),
                      blurRadius: 10,
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('Selected Location:',
                              style: TextStyle(color: Colors.grey)),
                          const SizedBox(height: 4),
                          if (_isLoadingAddress)
                            const LinearProgressIndicator()
                          else
                            Text(
                              _selectedAddress,
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold),
                              maxLines: 2, // Allow for longer addresses
                              overflow: TextOverflow.ellipsis,
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: _isLoadingAddress
                          ? null // Disable button while fetching address
                          : () {
                              // Return a map containing both the address and coordinates.
                              Navigator.of(context).pop({
                                'address': _selectedAddress,
                                'coordinates': _selectedPosition,
                              });
                            },
                      child: const Text('Select'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

