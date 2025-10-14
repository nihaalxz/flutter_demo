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
  String? _currentCity;
  String? _errorMessage;

  // Cache duration for popular locations
  static const _cacheKey = 'popular_locations_cache';
  static const _cacheTimestampKey = 'popular_locations_timestamp';
  static const _cacheDuration = Duration(minutes: 30);

  @override
  void initState() {
    super.initState();
    _loadPopularLocations();
    _loadSavedCurrentCity();
  }

  Future<void> _loadPopularLocations() async {
    setState(() {
      _isLoadingLocations = true;
      _errorMessage = null;
    });

    try {
      // Try loading from cache first
      final cachedLocations = await _getCachedLocations();
      if (cachedLocations != null) {
        setState(() {
          _popularLocations = cachedLocations;
          _isLoadingLocations = false;
        });
        return;
      }

      // Fetch from network
      final locations = await widget.productService.getPopularLocations();
      
      // Remove duplicates and filter empty locations
      final uniqueLocations = <String, Map<String, dynamic>>{};
      for (var loc in locations) {
        final name = (loc['locationName'] as String).trim();
        if (name.isNotEmpty && !uniqueLocations.containsKey(name)) {
          uniqueLocations[name] = loc;
        }
      }

      final locationsList = uniqueLocations.values.toList();
      
      // Cache the result
      await _cacheLocations(locationsList);
      
      if (mounted) {
        setState(() {
          _popularLocations = locationsList;
        });
      }
    } catch (e) {
      debugPrint('Failed to load popular locations: $e');
      if (mounted) {
        setState(() {
          _errorMessage = 'Could not load locations';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingLocations = false;
        });
      }
    }
  }

  Future<List<Map<String, dynamic>>?> _getCachedLocations() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final timestamp = prefs.getInt(_cacheTimestampKey);
      
      if (timestamp != null) {
        final cacheAge = DateTime.now().millisecondsSinceEpoch - timestamp;
        if (cacheAge < _cacheDuration.inMilliseconds) {
          final cached = prefs.getStringList(_cacheKey);
          if (cached != null) {
            return cached.map((json) {
              final parts = json.split('|');
              return {
                'locationName': parts[0],
                'itemCount': int.parse(parts[1]),
              };
            }).toList();
          }
        }
      }
    } catch (e) {
      debugPrint('Error loading cached locations: $e');
    }
    return null;
  }

  Future<void> _cacheLocations(List<Map<String, dynamic>> locations) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheData = locations.map((loc) {
        return '${loc['locationName']}|${loc['itemCount']}';
      }).toList();
      
      await prefs.setStringList(_cacheKey, cacheData);
      await prefs.setInt(_cacheTimestampKey, DateTime.now().millisecondsSinceEpoch);
    } catch (e) {
      debugPrint('Error caching locations: $e');
    }
  }

  Future<void> _loadSavedCurrentCity() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final city = prefs.getString('saved_current_city');
      if (mounted && city != null && city.isNotEmpty) {
        setState(() {
          _currentCity = city;
        });
      }
    } catch (e) {
      debugPrint('Error loading saved city: $e');
    }
  }

  Future<void> _saveSelectedLocation(String? location) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (location == null) {
        await prefs.remove('saved_location');
      } else {
        await prefs.setString('saved_location', location);
      }
    } catch (e) {
      debugPrint('Error saving location: $e');
    }
  }

  Future<void> _saveCurrentCity(String city) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('saved_current_city', city);
    } catch (e) {
      debugPrint('Error saving current city: $e');
    }
  }

  Future<void> _getCurrentLocation() async {
    if (_isGettingCurrentLocation) return;

    setState(() => _isGettingCurrentLocation = true);

    try {
      final position = await LocationService.getCurrentPosition();
      final city = await LocationService.getCityFromCoordinates(position);

      if (mounted) {
        widget.onLocationChanged(city);
        await _saveSelectedLocation(city);
        await _saveCurrentCity(city);
        
        setState(() {
          _currentCity = city;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Location set to $city',
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.green.shade600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } on LocationServiceException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline_rounded, color: Colors.white, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    e.message,
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.red.shade600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline_rounded, color: Colors.white, size: 20),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Failed to get location',
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.red.shade600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isGettingCurrentLocation = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: isDark 
            ? theme.colorScheme.surface.withOpacity(0.5)
            : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.primary.withOpacity(0.2),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: widget.selectedLocation,
          icon: _isGettingCurrentLocation
              ? SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: theme.colorScheme.primary,
                  ),
                )
              : Icon(
                  Icons.keyboard_arrow_down_rounded,
                  size: 24,
                  color: theme.colorScheme.primary,
                ),
          isExpanded: true,
          borderRadius: BorderRadius.circular(16),
          dropdownColor: theme.colorScheme.surface,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
          hint: Row(
            children: [
              Icon(
                Icons.public_rounded,
                size: 20,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 10),
              Text(
                'All Kerala',
                style: TextStyle(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          items: _buildDropdownItems(theme),
          onChanged: _handleLocationChange,
        ),
      ),
    );
  }

  List<DropdownMenuItem<String>> _buildDropdownItems(ThemeData theme) {
    return [
      // All Kerala option
      DropdownMenuItem(
        value: null,
        child: _buildMenuItem(
          icon: Icons.public_rounded,
          label: 'All Kerala',
          theme: theme,
          isDefault: true,
        ),
      ),
      
      // Current location option
      DropdownMenuItem(
        value: 'current_location',
        child: _buildMenuItem(
          icon: Icons.my_location_rounded,
          label: _currentCity ?? 'Use Current Location',
          theme: theme,
          isSpecial: _currentCity != null,
        ),
      ),
      
      // Modern divider
      DropdownMenuItem(
        value: 'divider',
        enabled: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  theme.dividerColor.withOpacity(0.5),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
      ),
      
      // Loading state
      if (_isLoadingLocations)
        DropdownMenuItem(
          value: 'loading',
          enabled: false,
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Loading locations...',
                    style: TextStyle(
                      color: theme.textTheme.bodySmall?.color,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ),
        )
      // Error state
      else if (_errorMessage != null)
        DropdownMenuItem(
          value: 'error',
          enabled: false,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Icon(
                  Icons.error_outline_rounded,
                  size: 18,
                  color: Colors.red.shade400,
                ),
                const SizedBox(width: 8),
                Text(
                  _errorMessage!,
                  style: TextStyle(
                    color: Colors.red.shade600,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        )
      // Popular locations - clean list without counters
      else
        ..._popularLocations.map((location) {
          final name = location['locationName'] as String;
          
          return DropdownMenuItem(
            value: name,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.location_city_rounded,
                      size: 16,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Flexible(
                    child: Text(
                      name,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
    ];
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String label,
    required ThemeData theme,
    bool isSpecial = false,
    bool isDefault = false,
  }) {
    final color = isSpecial || isDefault 
        ? theme.colorScheme.primary 
        : theme.textTheme.bodyMedium?.color;
        
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: (isSpecial || isDefault)
                  ? theme.colorScheme.primary.withOpacity(0.15)
                  : theme.colorScheme.surfaceVariant.withOpacity(0.5),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              size: 18,
              color: color,
            ),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: color,
                fontWeight: (isSpecial || isDefault) 
                    ? FontWeight.w600 
                    : FontWeight.w500,
              ),
            ),
          ),
          if (isSpecial)
            Container(
              margin: const EdgeInsets.only(left: 8),
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    theme.colorScheme.primary,
                    theme.colorScheme.primary.withOpacity(0.7),
                  ],
                ),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Text(
                'Current',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _handleLocationChange(String? newValue) async {
    if (newValue == 'current_location') {
      await _getCurrentLocation();
    } else if (newValue != 'divider' && 
               newValue != 'loading' && 
               newValue != 'error') {
      widget.onLocationChanged(newValue);
      await _saveSelectedLocation(newValue);
    }
  }
}