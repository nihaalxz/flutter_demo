import 'dart:convert';
import 'package:http/http.dart' as http;

// --- Assumed Imports ---
import '../../environment/env.dart';
import '../auth_service.dart';
import '../../models/order_DTO.dart';
import '../../models/Payment_History_DTO.dart';

class PaymentService {
  final String _apiBaseUrl = "${AppConfig.ApibaseUrl}/payment";
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

  /// Creates a payment order on the backend and returns the necessary IDs
  /// to launch the Cashfree checkout WebView.
  Future<Map<String, String>> startPayment(OrderDto order) async {
    final headers = await _getAuthHeaders();
    final url = Uri.parse('$_apiBaseUrl/create-order');

    final response = await http.post(
      url,
      headers: headers,
      body: jsonEncode(order.toJson()),
    );

    if (response.statusCode == 200) {
      final responseBody = jsonDecode(response.body);
      final paymentSessionId = responseBody['paymentSessionId'] ?? responseBody['payment_session_id'];
      final orderId = responseBody['orderId'] ?? responseBody['order_id'];

      if (paymentSessionId == null || orderId == null) {
        throw Exception('Payment session details are missing from the server response.');
      }

      return {
        'paymentSessionId': paymentSessionId,
        'orderId': orderId,
      };
    } else {
      throw Exception('Failed to create payment order: ${response.body}');
    }
  }

  /// Fetches the status of a specific payment order from the backend.
  Future<Map<String, dynamic>> getPaymentStatus(String orderId) async {
    final headers = await _getAuthHeaders();
    final url = Uri.parse('$_apiBaseUrl/$orderId/status');

    final response = await http.get(url, headers: headers);

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to get payment status: ${response.body}');
    }
  }

  /// Fetches the user's entire payment history.
  Future<List<PaymentHistoryDto>> getPaymentHistory() async {
    final headers = await _getAuthHeaders();
    final url = Uri.parse('$_apiBaseUrl/history');

    final response = await http.get(url, headers: headers);

    if (response.statusCode == 200) {
      final List<dynamic> jsonList = jsonDecode(response.body);
      return jsonList.map((json) => PaymentHistoryDto.fromJson(json)).toList();
    } else {
      throw Exception("Failed to fetch payment history: ${response.body}");
    }
  }
}
