import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

/// A page that displays a Google Map, allowing the user to select a location.
/// It returns a map containing the selected address string and LatLng coordinates.
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
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _moveToCurrentUserLocation();
  }

  /// Tries to get the user's current location and move the map camera to it.
  Future<void> _moveToCurrentUserLocation() async {
    try {
      final position = await Geolocator.getCurrentPosition();
      _mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(
          LatLng(position.latitude, position.longitude),
          14,
        ),
      );
    } catch (e) {
      print("Could not get user location: $e");
    }
  }

  /// Called when the map camera stops moving.
  void _onCameraIdle() async {
    if (_mapController == null) return;

    // Get the coordinates of the center of the map
    final latLng = await _mapController!.getLatLng(
      ScreenCoordinate(
        x: MediaQuery.of(context).size.width ~/ 2,
        y: MediaQuery.of(context).size.height ~/ 2,
      ),
    );

    setState(() {
      _selectedPosition = latLng;
      _isLoading = true;
    });

    // Convert coordinates to a readable address
    try {
      final placemarks = await placemarkFromCoordinates(
        latLng.latitude,
        latLng.longitude,
      );
      if (placemarks.isNotEmpty) {
        final p = placemarks.first;
        // Construct a clean address string
        setState(() {
          _selectedAddress =
              "${p.locality}, ${p.administrativeArea}, ${p.country}";
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _selectedAddress = "Could not determine address";
        _isLoading = false;
      });
    }
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
                          const Text('Selected Location:', style: TextStyle(color: Colors.grey)),
                          _isLoading
                              ? const LinearProgressIndicator()
                              : Text(
                                  _selectedAddress,
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: _isLoading
                          ? null
                          : () {
                              // ✅ FIX: Return a map containing both the address and coordinates.
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
