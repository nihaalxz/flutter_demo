import 'package:url_launcher/url_launcher.dart';

class MapLauncherService {
  /// Opens the default map application on the device to the given coordinates.
  static Future<void> openMap(double latitude, double longitude) async {
    final uri = Uri.parse('https://www.google.com/maps/search/?api=1&query=$latitude,$longitude');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      throw 'Could not open the map.';
    }
  }
}
