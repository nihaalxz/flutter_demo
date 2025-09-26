import 'dart:convert';
import 'package:http/http.dart' as http;

// --- Assumed Imports ---
// You will need to replace these with your actual files.
import '../environment/env.dart'; // A file containing your base API URL.
import 'auth_service.dart'; // Your service to get the JWT token.
import '../models/BookingResponseDTO.dart'; // The DTO for booking responses.

class BookingService {
  final String _baseUrl = AppConfig.ApibaseUrl;
  final AuthService _authService = AuthService();

  /// Helper method to get authenticated headers.
  Future<Map<String, String>> _getAuthHeaders() async {
    final token = await _authService.getToken();
    if (token == null) {
      throw Exception('User is not authenticated. Token not found.');
    }
    return {
      'Content-Type': 'application/json; charset=UTF-8',
      'Authorization': 'Bearer $token',
    };
  }

/// Creates a new booking request.
/// Corresponds to: [POST api/booking]
Future<BookingResponseDTO> createBooking({
  required int itemId,
  required DateTime startDate,
  required DateTime endDate,
  required double totalPrice,
  int? offerId, // ✅ optional offerId
}) async {
  final headers = await _getAuthHeaders();
  final url = Uri.parse('$_baseUrl/booking');

  final body = {
    'itemId': itemId,
    'startDate': startDate.toIso8601String(),
    'endDate': endDate.toIso8601String(),
    'totalPrice': totalPrice,
  };

  if (offerId != null) {
    body['offerId'] = offerId; // ✅ include only if booking at offered price
  }

  final response = await http.post(
    url,
    headers: headers,
    body: jsonEncode(body),
  );

  if (response.statusCode == 200 || response.statusCode == 201) {
    return BookingResponseDTO.fromJson(jsonDecode(response.body));
  } else {
    final errorBody = jsonDecode(response.body);
    throw Exception(
      'Failed to create booking: ${errorBody['message'] ?? response.reasonPhrase}',
    );
  }
}

  /// Approves a pending booking.
  /// Corresponds to: [POST api/booking/{id}/approve]
  Future<void> approveBooking(int bookingId) async {
    final headers = await _getAuthHeaders();
    final url = Uri.parse('$_baseUrl/booking/$bookingId/approve');

    final response = await http.post(url, headers: headers);

    if (response.statusCode != 200) {
      throw Exception('Failed to approve booking. Status code: ${response.statusCode}');
    }
  }

  /// Rejects a pending booking.
  /// Corresponds to: [POST api/booking/{id}/reject]
  Future<void> rejectBooking(int bookingId) async {
    final headers = await _getAuthHeaders();
    final url = Uri.parse('$_baseUrl/booking/$bookingId/reject');

    final response = await http.post(url, headers: headers);

    if (response.statusCode != 200) {
      throw Exception('Failed to reject booking. Status code: ${response.statusCode}');
    }
  }

 Future<void> markBookingsAsSeen() async {
    final headers = await _getAuthHeaders();
    final url = Uri.parse('$_baseUrl/booking/mark-as-seen');
    await http.post(url, headers: headers);
  }

Future<int> getUnreadBookingCount() async {
    final headers = await _getAuthHeaders();
    final url = Uri.parse('$_baseUrl/booking/unread-count');
    final response = await http.get(url, headers: headers);
    if (response.statusCode == 200) {
      return json.decode(response.body)['count'] ?? 0;
    }
    return 0;
  }

  /// Cancels a pending booking.
  /// Corresponds to: [PUT api/booking/{id}/cancel]
  Future<void> cancelBooking(int bookingId) async {
    final headers = await _getAuthHeaders();
    final url = Uri.parse('$_baseUrl/booking/$bookingId/cancel');

    final response = await http.put(url, headers: headers);

    if (response.statusCode != 200) {
      throw Exception('Failed to cancel booking. Status code: ${response.statusCode}');
    }
  }

  /// Fetches all bookings (both as a renter and owner) for the logged-in user.
  /// Can be filtered by status (e.g., "Pending", "Approved").
  /// Corresponds to: [GET api/booking/my-bookings]
  Future<List<BookingResponseDTO>> getMyBookings({String? status}) async {
    final headers = await _getAuthHeaders();
    var uri = Uri.parse('$_baseUrl/booking/my-bookings');

    if (status != null && status.isNotEmpty) {
      uri = uri.replace(queryParameters: {'status': status});
    }

    final response = await http.get(uri, headers: headers);

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((item) => BookingResponseDTO.fromJson(item)).toList();
    } else {
      throw Exception('Failed to load bookings. Status code: ${response.statusCode}');
    }
  }

  /// Fetches a single booking by its ID.
  /// Corresponds to: [GET api/booking/{id}]
  Future<BookingResponseDTO> getBookingById(int bookingId) async {
    final headers = await _getAuthHeaders();
    final url = Uri.parse('$_baseUrl/booking/$bookingId');

    final response = await http.get(url, headers: headers);

    if (response.statusCode == 200) {
      return BookingResponseDTO.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to load booking details. Status code: ${response.statusCode}');
    }
  }
}