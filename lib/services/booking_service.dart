import 'dart:convert';
import 'package:http/http.dart' as http;

// --- Assumed Imports ---
import '../environment/env.dart';
import 'auth_service.dart';
import '../models/BookingResponseDTO.dart';

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
  Future<BookingResponseDTO> createBooking({
    required int itemId,
    required DateTime startDate,
    required DateTime endDate,
    required double totalPrice,
    int? offerId,
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
      body['offerId'] = offerId;
    }

    final response = await http.post(
      url,
      headers: headers,
      body: jsonEncode(body),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return BookingResponseDTO.fromJson(jsonDecode(response.body));
    } else if (response.statusCode == 409) {
      // Handle date conflict specifically
      final errorBody = jsonDecode(response.body);
      throw Exception('Date conflict: ${errorBody['message'] ?? 'Selected dates are not available'}');
    } else {
      final errorBody = jsonDecode(response.body);
      throw Exception(
        'Failed to create booking: ${errorBody['message'] ?? response.reasonPhrase}',
      );
    }
  }

  /// Checks availability for dates before booking
  Future<Map<String, dynamic>> checkAvailability({
    required int itemId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final headers = await _getAuthHeaders();
    
    final params = {
      'itemId': itemId.toString(),
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
    };
    
    final url = Uri.parse('$_baseUrl/booking/check-availability').replace(queryParameters: params);
    final response = await http.get(url, headers: headers);

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to check availability. Status code: ${response.statusCode}');
    }
  }

  /// Approves a pending booking.
  Future<void> approveBooking(int bookingId) async {
    final headers = await _getAuthHeaders();
    final url = Uri.parse('$_baseUrl/booking/$bookingId/approve');

    final response = await http.post(url, headers: headers);

    if (response.statusCode != 200) {
      throw Exception('Failed to approve booking. Status code: ${response.statusCode}');
    }
  }

  /// Rejects a pending booking.
  Future<void> rejectBooking(int bookingId) async {
    final headers = await _getAuthHeaders();
    final url = Uri.parse('$_baseUrl/booking/$bookingId/reject');

    final response = await http.post(url, headers: headers);

    if (response.statusCode != 200) {
      throw Exception('Failed to reject booking. Status code: ${response.statusCode}');
    }
  }

  /// Marks bookings as seen (for notification counts)
  Future<void> markBookingsAsSeen() async {
    final headers = await _getAuthHeaders();
    final url = Uri.parse('$_baseUrl/booking/mark-as-seen');
    await http.post(url, headers: headers);
  }

  /// Gets unread booking count for notifications
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
  Future<void> cancelBooking(int bookingId) async {
    final headers = await _getAuthHeaders();
    final url = Uri.parse('$_baseUrl/booking/$bookingId/cancel');

    final response = await http.put(url, headers: headers);

    if (response.statusCode != 200) {
      throw Exception('Failed to cancel booking. Status code: ${response.statusCode}');
    }
  }

  /// Fetches all bookings for the logged-in user with optional filtering
  Future<List<BookingResponseDTO>> getMyBookings({String? status, bool? asOwner}) async {
    final headers = await _getAuthHeaders();
    final params = <String, String>{};
    
    if (status != null && status.isNotEmpty) {
      params['status'] = status;
    }
    if (asOwner != null) {
      params['asOwner'] = asOwner.toString();
    }
    
    final uri = Uri.parse('$_baseUrl/booking/my-bookings').replace(queryParameters: params);
    final response = await http.get(uri, headers: headers);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      // Handle both response formats - array or object with bookings property
      if (data is Map && data.containsKey('bookings')) {
        final List<dynamic> bookingsData = data['bookings'];
        return bookingsData.map((item) => BookingResponseDTO.fromJson(item)).toList();
      } else if (data is List) {
        return data.map((item) => BookingResponseDTO.fromJson(item)).toList();
      } else {
        throw Exception('Unexpected response format');
      }
    } else {
      throw Exception('Failed to load bookings. Status code: ${response.statusCode}');
    }
  }

  /// Gets booking summary (counts by status)
  Future<Map<String, dynamic>> getBookingSummary() async {
    final headers = await _getAuthHeaders();
    final url = Uri.parse('$_baseUrl/booking/my-bookings/summary');

    final response = await http.get(url, headers: headers);

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load booking summary. Status code: ${response.statusCode}');
    }
  }

  /// Fetches a single booking by its ID.
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

  /// Enhanced method to get user bookings with better error handling
  Future<List<BookingResponseDTO>> getUserBookings() async {
    try {
      return await getMyBookings();
    } catch (e) {
      print('Error fetching user bookings: $e');
      return [];
    }
  }

  /// Check if a specific product is already booked by the user
  Future<bool> isProductBooked(int productId) async {
  try {
    final bookings = await getUserBookings();
    return bookings.any((booking) => 
        booking.itemid == productId && 
        (booking.status == 'Pending' || booking.status == 'Approved' || booking.status == 'Active'));
  } catch (e) {
    print('Error checking if product is booked: $e');
    return false;
  }
}
}