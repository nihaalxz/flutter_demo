import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cashfree_pg_sdk/api/cferrorresponse/cferrorresponse.dart';
import 'package:flutter_cashfree_pg_sdk/api/cfpayment/cfwebcheckoutpayment.dart';
import 'package:flutter_cashfree_pg_sdk/api/cfpaymentgateway/cfpaymentgatewayservice.dart';
import 'package:flutter_cashfree_pg_sdk/api/cfsession/cfsession.dart';
import 'package:flutter_cashfree_pg_sdk/utils/cfenums.dart';
import 'package:intl/intl.dart';

// --- Assumed Imports ---
import 'package:myfirstflutterapp/models/BookingResponseDTO.dart';
import 'package:myfirstflutterapp/models/Order_DTO/order_DTO.dart';
import 'package:myfirstflutterapp/models/Order_DTO/OrderResponseDTO.dart';
import 'package:myfirstflutterapp/services/auth_service.dart';
import 'package:myfirstflutterapp/services/payment_services/payment_service.dart';
import 'package:myfirstflutterapp/pages/payments/payment_status_page.dart';

class CheckoutPage extends StatefulWidget {
  final BookingResponseDTO booking;

  const CheckoutPage({Key? key, required this.booking}) : super(key: key);

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  final PaymentService _paymentService = PaymentService();
  final AuthService _authService = AuthService();
  bool _isLoading = false;

  // State to hold the authoritative order details from the backend
  OrderResponseDto? _orderResponse;

  // Cashfree SDK entry point
  final CFPaymentGatewayService _cfPaymentGatewayService =
      CFPaymentGatewayService();

  @override
  void initState() {
    super.initState();
    _cfPaymentGatewayService.setCallback(onVerify, onError);
  }

  void onVerify(String orderId) {
    if (kDebugMode) {
      print("SDK Verification successful for orderId: $orderId. Starting backend polling...");
    }
    // Navigate to success page which will handle verification polling
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => PaymentSuccessPage(
          orderId: orderId,
          paymentService: _paymentService,
        ),
      ),
    );
  }

  void onError(CFErrorResponse errorResponse, String orderId) {
    if (kDebugMode) {
      print("Payment Error: ${errorResponse.getMessage()} for orderId: $orderId");
      print("Error Type: ${errorResponse.getType()}");
      print("Error Code: ${errorResponse.getCode()}");
    }

    // Handle different error types more appropriately
    final errorMessage = errorResponse.getMessage() ?? "Unknown error occurred";
    final errorType = errorResponse.getType();
    final errorCode = errorResponse.getCode();

    // Check if this is a user cancellation
    if (_isUserCancellation(errorMessage, errorType, errorCode)) {
      if (kDebugMode) {
        print("User cancelled payment, navigating to pending page");
      }
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => PaymentPendingPage(orderId: orderId),
        ),
      );
    } else {
      // For actual failures, still go to failure page
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => PaymentFailurePage(
            orderId: orderId,
            errorMessage: errorMessage,
          ),
        ),
      );
    }
  }

  /// Helper method to determine if the error is due to user cancellation
  bool _isUserCancellation(String? errorMessage, String? errorType, String? errorCode) {
    if (errorMessage == null) return false;
    
    final message = errorMessage.toLowerCase();
    
    // Common patterns for user cancellation
    final cancellationPatterns = [
      'user cancelled',
      'user canceled',
      'payment cancelled',
      'payment canceled',
      'transaction cancelled',
      'transaction canceled',
      'user dropped',
      'user exited',
      'payment aborted',
      'back button',
      'cancelled by user',
      'canceled by user',
    ];

    return cancellationPatterns.any((pattern) => message.contains(pattern));
  }

  /// Start Payment Process
  Future<void> _startPayment() async {
    setState(() => _isLoading = true);

    try {
      // 1. Get user details
      final user = await _authService.getUserProfile();
      if (user == null) throw Exception("User not logged in.");

      final orderDto = OrderDto(
        userId: user.id,
        email: user.email,
        phone: user.phoneNumber ?? '',
        amount: widget.booking.totalPrice,
        bookingId: widget.booking.id,
        itemName: widget.booking.itemName,
        itemImage: widget.booking.itemImage,
      );

      // 2. Call backend for session + authoritative order details
      final response = await _paymentService.startPayment(orderDto);
      
      // Store the server's response in the state
      setState(() {
        _orderResponse = response;
      });

      final sessionId = response.paymentSessionId;
      final orderId = response.orderId;

      // 3. Create Cashfree Session
      final session = CFSessionBuilder()
          .setEnvironment(CFEnvironment.SANDBOX) // ⚠️ change to PROD later
          .setPaymentSessionId(sessionId)
          .setOrderId(orderId)
          .build();

      // 4. Create Web Checkout Payment
      final cfWebCheckout =
          CFWebCheckoutPaymentBuilder().setSession(session).build();

      // 5. Initiate Payment
      await _cfPaymentGatewayService.doPayment(cfWebCheckout);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text("Error: ${e.toString().replaceAll("Exception: ", "")}"),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// Build order summary based on current state
  Widget _buildOrderSummary() {
    final currencyFormat = NumberFormat.currency(locale: 'en_IN', symbol: '₹');

    // Before backend call, show client-side estimate
    if (_orderResponse == null) {
      final basePrice = widget.booking.totalPrice;
      final platformFee = basePrice * 0.05;
      final tds = basePrice * 0.10;
      final totalPayable = basePrice + platformFee + tds;

      return Card(
        elevation: 3,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("ORDER SUMMARY (ESTIMATE)",
                  style: TextStyle(
                      fontWeight: FontWeight.bold, color: Colors.grey)),
              const Divider(height: 24),
              _buildPriceRow("Base Rental Price", currencyFormat.format(basePrice)),
              const SizedBox(height: 12),
              _buildPriceRow("Platform Fee (5%)", currencyFormat.format(platformFee)),
              const SizedBox(height: 12),
              _buildPriceRow("TDS (10%)", currencyFormat.format(tds)),
              const Divider(height: 24),
              _buildPriceRow(
                "Total Payable Amount",
                currencyFormat.format(totalPayable),
                isTotal: true,
              ),
            ],
          ),
        ),
      );
    }

    // After backend call, show authoritative breakdown
    final order = _orderResponse!;
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("FINAL ORDER SUMMARY",
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: Colors.blueGrey)),
            const Divider(height: 30, thickness: 1.2),
            _buildPriceRow("Base Rental Price", currencyFormat.format(order.originalAmount)),
            const SizedBox(height: 12),
            _buildPriceRow("TDS (10%)", "-${currencyFormat.format(order.tds)}", color: Colors.redAccent),
            const SizedBox(height: 8),
            _buildPriceRow("Platform Fee (5%)", "+${currencyFormat.format(order.platformFee)}", color: Colors.orange),
            const Divider(),
            _buildPriceRow(
              "Total Payable",
              currencyFormat.format(order.finalPayable),
              isTotal: true,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Confirm & Pay")),
      body: SafeArea( // ✅ SafeArea added here
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildOrderSummary(),
              const Spacer(),
              if (_isLoading)
                const Center(child: CircularProgressIndicator())
              else
                ElevatedButton(
                  onPressed: _startPayment,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text("Proceed to Pay"),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPriceRow(String label, String amount, {bool isTotal = false, Color? color}) {
    final style = TextStyle(
      fontSize: isTotal ? 18 : 16,
      fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
      color: color,
    );
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: style),
        Text(amount, style: style),
      ],
    );
  }
}
