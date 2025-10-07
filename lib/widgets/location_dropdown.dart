import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
  String? _currentCity; // ✅ stores GPS-detected city name

  @override
  void initState() {
    super.initState();
    _loadPopularLocations();
    _loadSavedCurrentCity();
  }

  Future<void> _loadPopularLocations() async {
    setState(() => _isLoadingLocations = true);

    try {
      final locations = await widget.productService.getPopularLocations();
      final uniqueLocations = <String, Map<String, dynamic>>{};
      for (var loc in locations) {
        final name = (loc['locationName'] as String).trim();
        if (!uniqueLocations.containsKey(name)) {
          uniqueLocations[name] = loc;
        }
      }
      setState(() => _popularLocations = uniqueLocations.values.toList());
    } catch (e) {
      debugPrint('Failed to load popular locations: $e');
    } finally {
      setState(() => _isLoadingLocations = false);
    }
  }

  Future<void> _loadSavedCurrentCity() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _currentCity = prefs.getString('saved_current_city');
    });
  }

  Future<void> _saveSelectedLocation(String? location) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('saved_location', location ?? 'all_kerala');
  }

  Future<void> _saveCurrentCity(String? city) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('saved_current_city', city ?? '');
  }

  Future<void> _getCurrentLocation() async {
    setState(() => _isGettingCurrentLocation = true);

    try {
      final position = await LocationService.getCurrentPosition();
      final city = await LocationService.getCityFromCoordinates(position);

      if (mounted) {
        widget.onLocationChanged(city);
        await _saveSelectedLocation(city);
        await _saveCurrentCity(city);
        setState(() {
          _currentCity = city; // ✅ Update visible label
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('📍 Location set to $city')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('⚠️ Failed to get location: $e')),
        );
      }
    } finally {
      setState(() => _isGettingCurrentLocation = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // ✅ Build effective label
    String? effectiveValue = widget.selectedLocation;
    if (effectiveValue == 'current_location' && _currentCity != null) {
      effectiveValue = _currentCity;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Theme.of(context).dividerColor.withOpacity(0.3)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: effectiveValue,
          icon: _isGettingCurrentLocation
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.arrow_drop_down, size: 20),
          isExpanded: true,
          borderRadius: BorderRadius.circular(14),
          dropdownColor: Theme.of(context).colorScheme.surface,
          style: Theme.of(context).textTheme.bodyMedium,
          hint: const Text('🌦️ All Kerala'),
          items: [
            DropdownMenuItem(
              value: 'all_kerala',
              child: _buildItem(Icons.public, 'All Kerala'),
            ),
            DropdownMenuItem(
              value: 'current_location',
              child: _buildItem(Icons.my_location, _currentCity ?? 'Use Current Location'),
            ),
            const DropdownMenuItem(
              value: 'divider',
              enabled: false,
              child: Divider(height: 1),
            ),
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
                final name = location['locationName'] as String;
                final count = location['itemCount'] as int;
                return DropdownMenuItem(
                  value: name,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const SizedBox(width: 8),
                          Text(name, overflow: TextOverflow.ellipsis),
                        ],
                      ),
                      Text(
                        '($count)',
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: Colors.grey),
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
              await _saveSelectedLocation(newValue);
              if (newValue != null) await _saveCurrentCity(newValue);
              setState(() {
                _currentCity = newValue;
              });
            }
          },
        ),
      ),
    );
  }

  /// Small helper for menu item styling
  Widget _buildItem(IconData icon, String label) {
    return Row(
      children: [
        Icon(icon, size: 18),
        const SizedBox(width: 8),
        Text(label, overflow: TextOverflow.ellipsis),
      ],
    );
  }
}
