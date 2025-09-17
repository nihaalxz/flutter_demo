import 'package:flutter/material.dart';
import 'package:flutter_cashfree_pg_sdk/api/cferrorresponse/cferrorresponse.dart';
import 'package:flutter_cashfree_pg_sdk/api/cfpayment/cfwebcheckoutpayment.dart';
import 'package:flutter_cashfree_pg_sdk/api/cfpaymentgateway/cfpaymentgatewayservice.dart';
import 'package:flutter_cashfree_pg_sdk/api/cfsession/cfsession.dart';// Corrected import path
import 'package:flutter_cashfree_pg_sdk/utils/cfenums.dart';

// --- Assumed Imports ---
import 'package:myfirstflutterapp/models/BookingResponseDTO.dart';
import 'package:myfirstflutterapp/models/order_DTO.dart';
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

  // This is the entry point for the Cashfree SDK
  final CFPaymentGatewayService _cfPaymentGatewayService = CFPaymentGatewayService();

  @override
  void initState() {
    super.initState();
    // Step 2 (Part 3): Setup callback handlers
    _cfPaymentGatewayService.setCallback(onVerify, onError);
  }

  /// This callback is triggered when the payment is successful
  /// and Cashfree's servers have verified it.
  void onVerify(String orderId) {
    print("Payment Verified for orderId: $orderId");
    // Navigate to a success screen
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => PaymentSuccessPage(orderId: orderId),
      ),
    );
  }

  /// This callback is triggered when the payment fails or is cancelled.
  void onError(CFErrorResponse errorResponse, String orderId) {
    print("Payment Error: ${errorResponse.getMessage()} for orderId: $orderId");
    // Navigate to a failure screen
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => PaymentFailurePage(
          orderId: orderId,
          errorMessage: errorResponse.getMessage() ?? "Payment failed or was cancelled.",
        ),
      ),
    );
  }

  /// The main function to start the payment process.
  Future<void> _startPayment() async {
    setState(() => _isLoading = true);

    try {
      // 1. Get user details to create the order
      final user = await _authService.getUserProfile();
      if (user == null) {
        throw Exception("User not logged in.");
      }

      final orderDto = OrderDto(
        userId: user.id,
        email: user.email,
        phone: user.phoneNumber ?? '',
        amount: widget.booking.totalPrice,
        bookingId: widget.booking.id,
        itemName: widget.booking.itemName,
        itemImage: widget.booking.itemImage,
      );

      // 2. Call your backend to get the paymentSessionId and orderId
      final paymentData = await _paymentService.startPayment(orderDto);
      final sessionId = paymentData['paymentSessionId'];
      final orderId = paymentData['orderId'];

      if (sessionId == null || orderId == null) {
        throw Exception("Could not retrieve payment session.");
      }

      // 3. Step 2 (Part 1): Create a CFSession object
      final session = CFSessionBuilder()
          .setEnvironment(CFEnvironment.SANDBOX) // Use SANDBOX for testing
          .setPaymentSessionId(sessionId)
          .setOrderId(orderId)
          .build();

      // 4. Step 2 (Part 2): Create a Web Checkout Payment object
      final cfWebCheckout = CFWebCheckoutPaymentBuilder()
          .setSession(session)
          .build();
          
      // 5. Step 2 (Part 4): Initiate the payment
      await _cfPaymentGatewayService.doPayment(cfWebCheckout);

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error: ${e.toString().replaceAll("Exception: ", "")}"),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Confirm & Pay")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("ORDER SUMMARY", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                    const Divider(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(child: Text(widget.booking.itemName, style: const TextStyle(fontSize: 16), overflow: TextOverflow.ellipsis)),
                        Text("₹${widget.booking.totalPrice.toStringAsFixed(2)}", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Divider(),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("Total Payable", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        Text("₹${widget.booking.totalPrice.toStringAsFixed(2)}", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const Spacer(),
            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else
              ElevatedButton(
                onPressed: _startPayment,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text("Proceed to Pay"),
              ),
          ],
        ),
      ),
    );
  }
}
