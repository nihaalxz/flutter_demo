import 'package:flutter/foundation.dart';
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
String? formatJoinedAt(String? joinedAtStr) {
  if (joinedAtStr == null) return null;

  try {
    final date = DateTime.parse(joinedAtStr);
    return DateFormat.yMMMMd().format(date); // e.g., July 9, 2025
  } catch (e) {
    if (kDebugMode) {
      print("Error parsing joinedAt: $e, raw value: $joinedAtStr");
    }
    return joinedAtStr;
  }
}

  return AppUser(
    id: decodedToken['nameid'] ?? '',
    name: decodedToken['unique_name'] ?? '',
    email: decodedToken['email'] ?? '',
    fullName: decodedToken['fullname'] ?? decodedToken['unique_name'] ?? '',
    pictureUrl: decodedToken['picture'],
    phoneNumber: decodedToken['phoneNumber'],
    joinedAt: formatJoinedAt(decodedToken['joinedAt']),
    isKycVerified: decodedToken['iskycverified'] is bool
        ? decodedToken['iskycverified']
        : false,
  );
}
}