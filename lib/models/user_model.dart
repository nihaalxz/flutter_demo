import 'package:intl/intl.dart';

class AppUser {
  final String id;
  final String name;
  final String email;
  final String? pictureUrl;
  final String? joinedAt; // This will now be a formatted string like "August 20, 2025"
  final String fullName;
  final bool isKycVerified;
  final String? phoneNumber;

  AppUser({
    required this.id,
    required this.name,
    required this.email,
    this.pictureUrl,
    this.joinedAt,
    required this.fullName,
    required this.isKycVerified,
    this.phoneNumber,
  });

  factory AppUser.fromToken(Map<String, dynamic> decodedToken) {
    // Helper function to safely convert the numeric timestamp to a formatted date string
    String? formatJoinedAt(dynamic timestamp) {
      if (timestamp is int) {
        try {
          // JWT timestamps are in seconds, so multiply by 1000 for milliseconds
          final date = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
          return DateFormat.yMMMMd().format(date);
        } catch (e) {
          return null; // Return null if parsing fails
        }
      }
      return null;
    }

    return AppUser(
      // Provide fallback empty strings for required fields to prevent null errors
      id: decodedToken['nameid'] ?? '',
      name: decodedToken['unique_name'] ?? '',
      email: decodedToken['email'] ?? '',
      fullName: decodedToken['fullname'] ?? decodedToken['unique_name'] ?? '', // Fallback to name if fullname is null

      // These fields are already nullable, so direct assignment is fine
      pictureUrl: decodedToken['picture'],
      phoneNumber: decodedToken['phoneNumber'],

      // Safely parse the boolean, defaulting to false if null or invalid
      isKycVerified: decodedToken['iskycverified'] is bool ? decodedToken['iskycverified'] : false,
      
      // Use the helper to correctly parse the date
      joinedAt: formatJoinedAt(decodedToken['nbf']),
    );
  }
}