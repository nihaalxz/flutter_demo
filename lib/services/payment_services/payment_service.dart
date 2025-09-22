import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:razorpay_flutter/razorpay_flutter.dart';

import '../../environment/env.dart';
import '../auth_service.dart';
import '../../models/Order_DTO/OrderResponseDTO.dart';
import '../../models/Order_DTO/order_DTO.dart';
import '../../models/payment_history_DTO.dart';

class PaymentService {
  final String _apiBaseUrl = "${AppConfig.ApibaseUrl}/payment";
  final AuthService _authService = AuthService();
  late Razorpay _razorpay;

  PaymentService() {
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
  }

  void dispose() {
    _razorpay.clear();
  }

  /// --- Get Auth Headers ---
  Future<Map<String, String>> _getAuthHeaders() async {
    final token = await _authService.getToken();
    if (token == null) throw Exception("User is not authenticated.");
    return {
      "Content-Type": "application/json; charset=UTF-8",
      "Authorization": "Bearer $token",
    };
  }

  /// --- Start Payment (create Razorpay order) ---
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
      throw Exception("Failed to create Razorpay order: ${response.statusCode} ${response.body}");
    }
  }

  /// --- Launch Razorpay Checkout ---
  void openCheckout(OrderResponseDto order, String userName, String userEmail, String userPhone) {
    var options = {
      'key': order.razorpayKeyId,
      'amount': (order.totalAmount * 100).toInt(), // in paise
      'name': "MapleCot",
      'description': "Payment for your booking",
      'order_id': order.razorpayOrderId,
      'prefill': {
        'name': userName,
        'email': userEmail,
        'contact': userPhone,
      },
      'theme': {
        'color': '#3399cc',
      },
    };

    try {
      _razorpay.open(options);
    } catch (e) {
      debugPrint("Error opening Razorpay checkout: $e");
    }
  }

  /// --- Razorpay Handlers ---
  void _handlePaymentSuccess(PaymentSuccessResponse response) async {
    debugPrint("Payment Successful: ${response.paymentId}");

    // Send details to backend /verify
    final headers = await _getAuthHeaders();
    final url = Uri.parse("$_apiBaseUrl/verify");

    final payload = {
      'razorpay_order_id': response.orderId,
      'razorpay_payment_id': response.paymentId,
      'razorpay_signature': response.signature
    };

    final res = await http.post(url, headers: headers, body: jsonEncode(payload));
    debugPrint("Verify response: ${res.body}");
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    debugPrint("Payment Failed: ${response.code} - ${response.message}");
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    debugPrint("External Wallet: ${response.walletName}");
  }

  /// --- Get Payment Status ---
  Future<Map<String, dynamic>> verifyPaymentStatus(String orderId) async {
    final headers = await _getAuthHeaders();
    final url = Uri.parse("$_apiBaseUrl/$orderId/status");

    final response = await http.get(url, headers: headers);
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Failed to verify payment: ${response.statusCode} ${response.body}");
    }
  }

  /// --- Get Payment History ---
  Future<List<PaymentHistoryDto>> getPaymentHistory() async {
    final headers = await _getAuthHeaders();
    final url = Uri.parse("$_apiBaseUrl/history");

    final response = await http.get(url, headers: headers);
    if (response.statusCode == 200) {
      final List<dynamic> jsonList = jsonDecode(response.body);
      return jsonList.map((json) => PaymentHistoryDto.fromJson(json)).toList();
    } else {
      throw Exception("Failed to fetch payment history: ${response.statusCode} ${response.body}");
    }
  }
}
