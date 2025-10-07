import 'package:flutter/material.dart';
import 'package:myfirstflutterapp/services/location_service.dart';
import 'package:myfirstflutterapp/services/product_service.dart';

class LocationDropdown extends StatefulWidget {
  final String? selectedLocation;
  final ValueChanged<String?> onLocationChanged;
  final ProductService productService;

  const LocationDropdown({
    super.key,
    required this.selectedLocation,
    required this.onLocationChanged,
    required this.productService,
  });

  @override
  State<LocationDropdown> createState() => _LocationDropdownState();
}

class _LocationDropdownState extends State<LocationDropdown> {
  List<Map<String, dynamic>> _popularLocations = [];
  bool _isLoadingLocations = false;
  bool _isGettingCurrentLocation = false;

  @override
  void initState() {
    super.initState();
    _loadPopularLocations();
  }

Future<void> _loadPopularLocations() async {
  setState(() {
    _isLoadingLocations = true;
  });

  try {
    final locations = await widget.productService.getPopularLocations();

    // ✅ Remove duplicates by location name
    final uniqueLocations = <String, Map<String, dynamic>>{};

    for (var loc in locations) {
      final name = (loc['locationName'] as String).trim();
      if (!uniqueLocations.containsKey(name)) {
        uniqueLocations[name] = loc;
      }
    }

    setState(() {
      _popularLocations = uniqueLocations.values.toList();
    });
  } catch (e) {
    debugPrint('Failed to load popular locations: $e');
  } finally {
    setState(() {
      _isLoadingLocations = false;
    });
  }
}


  Future<void> _getCurrentLocation() async {
    setState(() {
      _isGettingCurrentLocation = true;
    });

    try {
      final position = await LocationService.getCurrentPosition();
      final city = await LocationService.getCityFromCoordinates(position);
      
      if (mounted) {
        widget.onLocationChanged(city);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Location set to $city')),
        );
      }
    } on LocationServiceException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Location error: ${e.message}')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to get location: $e')),
        );
      }
    } finally {
      setState(() {
        _isGettingCurrentLocation = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return DropdownButtonHideUnderline(
      child: DropdownButton<String>(
        value: widget.selectedLocation,
        icon: _isGettingCurrentLocation 
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.arrow_drop_down, size: 20),
        borderRadius: BorderRadius.circular(12),
        dropdownColor: Theme.of(context).cardColor,
        style: Theme.of(context).textTheme.bodyMedium,
        hint: const Text('All Locations'),
        items: [
          // All locations option
          const DropdownMenuItem(
            value: null,
            child: Row(
              children: [
                Icon(Icons.public, size: 18),
                SizedBox(width: 8),
                Text('All Locations'),
              ],
            ),
          ),
          // Current location option
          DropdownMenuItem(
            value: 'current_location',
            child: Row(
              children: [
                Icon(Icons.my_location, size: 18),
                const SizedBox(width: 8),
                const Text('Use Current Location'),
              ],
            ),
          ),
          const DropdownMenuItem(
            value: 'divider',
            enabled: false,
            child: Divider(),
          ),
          // Popular locations
          if (_isLoadingLocations)
            const DropdownMenuItem(
              value: 'loading',
              enabled: false,
              child: Center(
                child: SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            )
          else
            ..._popularLocations.map((location) {
              final locationName = location['locationName'] as String;
              final itemCount = location['itemCount'] as int;
              
              return DropdownMenuItem(
                value: locationName,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        locationName,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '($itemCount)',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
              );
            }),
        ],
        onChanged: (String? newValue) async {
          if (newValue == 'current_location') {
            await _getCurrentLocation();
          } else if (newValue != 'divider' && newValue != 'loading') {
            widget.onLocationChanged(newValue);
          }
        },
      ),
    );
  }
}