import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class LocationService {
static Future<Position> getCurrentPosition() async {
  bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
  if (!serviceEnabled) {
    throw Exception('Location services are disabled.');
  }

  LocationPermission permission = await Geolocator.checkPermission();
  if (permission == LocationPermission.denied) {
    permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied) {
      throw Exception('Location permissions are denied');
    }
  }

  if (permission == LocationPermission.deniedForever) {
    // 🚨 User must enable manually from settings
    await Geolocator.openAppSettings();
    throw Exception(
        'Location permissions are permanently denied. Please enable from Settings.');
  }

  return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high);
}


  static Future<String> getCityFromCoordinates(Position position) async {
    List<Placemark> placemarks =
        await placemarkFromCoordinates(position.latitude, position.longitude);

    if (placemarks.isNotEmpty) {
      return placemarks.first.locality ?? "Unknown City";
    }
    return "Unknown City";
  }
}
