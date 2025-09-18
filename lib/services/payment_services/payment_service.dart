import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:myfirstflutterapp/models/Order_DTO/OrderResponseDTO.dart';

import '../../environment/env.dart';
import '../auth_service.dart';
import '../../models/Order_DTO/order_DTO.dart';
import '../../models/payment_history_DTO.dart';

class PaymentService {
  final String _apiBaseUrl = "${AppConfig.ApibaseUrl}/payment";
  final AuthService _authService = AuthService();

  /// --- Get Auth Headers ---
  Future<Map<String, String>> _getAuthHeaders() async {
    final token = await _authService.getToken();
    if (token == null) {
      throw Exception("User is not authenticated. Token not found.");
    }
    return {
      "Content-Type": "application/json; charset=UTF-8",
      "Authorization": "Bearer $token",
    };
  }

  /// --- Start Payment (create Cashfree order) ---
  /// Returns `paymentSessionId` and `orderId` from backend
Future<OrderResponseDto> startPayment(OrderDto order) async {
  final headers = await _getAuthHeaders();
  final url = Uri.parse("$_apiBaseUrl/create-order");

  final response = await http.post(
    url,
    headers: headers,
    body: jsonEncode(order.toJson()),
  );

  if (response.statusCode == 200) {
    final responseBody = jsonDecode(response.body);
    return OrderResponseDto.fromJson(responseBody);
  } else {
    throw Exception(
      "Failed to create payment order: ${response.statusCode} ${response.body}",
    );
  }
}

  /// --- Get Payment Status ---
  /// Returns backend response for an orderId
  Future<Map<String, dynamic>> verifyPaymentStatus(String orderId) async {
    final headers = await _getAuthHeaders();
    final url = Uri.parse("$_apiBaseUrl/$orderId/status");

    final response = await http.get(url, headers: headers);

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception(
          "Failed to verify payment status: ${response.statusCode} ${response.body}");
    }
  }

  /// --- Get Payment History ---
  Future<List<PaymentHistoryDto>> getPaymentHistory() async {
    final headers = await _getAuthHeaders();
    final url = Uri.parse("$_apiBaseUrl/history");

    final response = await http.get(url, headers: headers);

    if (response.statusCode == 200) {
      final List<dynamic> jsonList = jsonDecode(response.body);
      return jsonList
          .map((json) => PaymentHistoryDto.fromJson(json))
          .toList();
    } else {
      throw Exception(
          "Failed to fetch payment history: ${response.statusCode} ${response.body}");
    }
  }
}
