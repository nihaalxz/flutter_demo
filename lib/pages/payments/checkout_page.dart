import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';

// --- Your models & services ---
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

  OrderResponseDto? _orderResponse;
  late Razorpay _razorpay;

  @override
  void initState() {
    super.initState();
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
  }

  @override
  void dispose() {
    _razorpay.clear();
    super.dispose();
  }

  /// --- Handlers ---
  void _handlePaymentSuccess(PaymentSuccessResponse response) {
    if (kDebugMode) {
      print("Payment Success: ${response.paymentId}");
    }

    // Navigate to status page, which polls backend
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => PaymentSuccessPage(orderId: response.orderId ?? "", paymentService: _paymentService),
      ),
    );
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    if (kDebugMode) {
      print("Payment Failed: ${response.code} - ${response.message}");
    }

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => PaymentFailurePage(orderId: _orderResponse?.razorpayOrderId ?? "", errorMessage: response.message ?? "Payment failed."),
      ),
    );
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    if (kDebugMode) {
      print("External Wallet selected: ${response.walletName}");
    }
  }

  /// --- Start Razorpay Flow ---
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

      // 2. Call backend for Razorpay order
      final response = await _paymentService.startPayment(orderDto);
      setState(() {
        _orderResponse = response;
      });

      // 3. Launch Razorpay checkout
      var options = {
        'key': response.razorpayKeyId,
        'amount': (response.totalAmount * 100).toInt(), // paise
        'name': 'MapleCot',
        'description': 'Payment for your booking',
        'order_id': response.razorpayOrderId,
        'prefill': {
          'name': user.fullName,
          'email': user.email,
          'contact': user.phoneNumber ?? '',
        },
        'theme': {'color': '#3399cc'},
      };

      _razorpay.open(options);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: ${e.toString()}"), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// --- Build Order Summary (unchanged) ---
  Widget _buildOrderSummary() {
    final currencyFormat = NumberFormat.currency(locale: 'en_IN', symbol: '₹');

    if (_orderResponse == null) {
      final basePrice = widget.booking.totalPrice;
      final platformFee = basePrice * 0.05;
      final tds = basePrice * 0.10;
      final totalPayable = basePrice + platformFee + tds;

      return Card(
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("ORDER SUMMARY (ESTIMATE)", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
              const Divider(height: 24),
              _buildPriceRow("Base Rental Price", currencyFormat.format(basePrice)),
              _buildPriceRow("Platform Fee (5%)", currencyFormat.format(platformFee)),
              _buildPriceRow("TDS (10%)", currencyFormat.format(tds)),
              const Divider(height: 24),
              _buildPriceRow("Total Payable Amount", currencyFormat.format(totalPayable), isTotal: true),
            ],
          ),
        ),
      );
    }

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
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.blueGrey)),
            const Divider(height: 30, thickness: 1.2),
            _buildPriceRow("Base Rental Price", currencyFormat.format(order.baseAmount)),
            _buildPriceRow("TDS (10%)", "-${currencyFormat.format(order.tds)}", color: Colors.redAccent),
            _buildPriceRow("Platform Fee (5%)", "+${currencyFormat.format(order.platformFee)}", color: Colors.orange),
            const Divider(),
            _buildPriceRow("Total Payable", currencyFormat.format(order.totalAmount), isTotal: true),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Confirm & Pay")),
      body: SafeArea(
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
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
      children: [Text(label, style: style), Text(amount, style: style)],
    );
  }
}
