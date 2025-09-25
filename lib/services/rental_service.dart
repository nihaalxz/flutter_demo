import 'dart:convert';
import 'package:http/http.dart' as http;
import '../environment/env.dart';
import 'auth_service.dart';

class RentalService {
  final String _baseUrl = AppConfig.ApibaseUrl;
  final AuthService _authService = AuthService();

  Future<Map<String, String>> _getAuthHeaders() async {
    final token = await _authService.getToken();
    if (token == null) throw Exception('User not authenticated.');
    return {
      'Content-Type': 'application/json; charset=UTF-8',
      'Authorization': 'Bearer $token',
    };
  }

  /// Called by the renter to start the rental with the owner's code.
  Future<void> startRental(int bookingId, String startCode) async {
    final headers = await _getAuthHeaders();
    final url = Uri.parse('$_baseUrl/rental/start');
    final body = jsonEncode({
      'bookingId': bookingId,
      'startCode': startCode,
    });

    final response = await http.post(url, headers: headers, body: body);

    if (response.statusCode != 200) {
      throw Exception('Failed to start rental: ${response.body}');
    }
  }

  /// Called by the owner to complete the rental with the renter's code.
  Future<void> completeRental(int bookingId, String returnCode) async {
    final headers = await _getAuthHeaders();
    final url = Uri.parse('$_baseUrl/rental/complete');
    final body = jsonEncode({
      'bookingId': bookingId,
      'returnCode': returnCode,
    });

    final response = await http.post(url, headers: headers, body: body);

    if (response.statusCode != 200) {
      throw Exception('Failed to complete rental: ${response.body}');
    }
  }
}
