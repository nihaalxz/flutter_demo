import 'dart:async';
import 'package:flutter/material.dart';
import 'package:myfirstflutterapp/pages/main_screen.dart';
import 'package:myfirstflutterapp/services/payment_services/payment_service.dart';

/// --- Payment Success Screen (Polls backend to confirm Razorpay payment) ---
class PaymentSuccessPage extends StatefulWidget {
  final String orderId;
  final PaymentService paymentService;

  const PaymentSuccessPage({
    super.key,
    required this.orderId,
    required this.paymentService,
  });

  @override
  State<PaymentSuccessPage> createState() => _PaymentSuccessPageState();
}

class _PaymentSuccessPageState extends State<PaymentSuccessPage> {
  bool _isVerifying = true;
  Timer? _pollingTimer;
  int _pollCount = 0;
  final int _maxPolls = 6; // Poll for 18 seconds max (6x every 3s)

  @override
  void initState() {
    super.initState();
    _startPolling();
  }

  /// Polls backend to confirm Razorpay payment
  void _startPolling() {
    _pollingTimer = Timer.periodic(const Duration(seconds: 3), (timer) async {
      _pollCount++;
      try {
        final result =
            await widget.paymentService.verifyPaymentStatus(widget.orderId);

        final status = result['status']?.toString().toLowerCase() ?? '';
        debugPrint("Polling attempt $_pollCount: Status = $status");

        if (status == 'success') {
          timer.cancel();
          if (mounted) setState(() => _isVerifying = false);
        } else if (status == 'failed') {
          timer.cancel();
          _handleVerificationFailure(
              'Payment failed. Please try again with another method.');
        } else if (status == 'pending' && _pollCount >= _maxPolls) {
          timer.cancel();
          _handlePendingPayment(
              'Payment is still pending. Please check your bookings page.');
        } else if (status == 'cancelled' || status == 'user_cancelled') {
          timer.cancel();
          _handlePendingPayment(
              'Payment was cancelled. You can retry from your bookings page.');
        } else if (_pollCount >= _maxPolls) {
          timer.cancel();
          _handleVerificationFailure(
              'Verification timed out. Please check your bookings later.');
        }
      } catch (e) {
        debugPrint("Error during polling: $e");
        timer.cancel();
        _handleVerificationFailure(
            'Unable to verify payment status: ${e.toString()}');
      }
    });
  }

  void _handleVerificationFailure(String errorMessage) {
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => PaymentFailurePage(
            orderId: widget.orderId,
            errorMessage: errorMessage,
          ),
        ),
      );
    }
  }

  void _handlePendingPayment(String message) {
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => PaymentPendingPage(
            orderId: widget.orderId,
            message: message,
          ),
        ),
      );
    }
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (_isVerifying) ...[
                const CircularProgressIndicator(),
                const SizedBox(height: 24),
                const Text(
                  'Verifying your payment...',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  'Please wait while we confirm your Razorpay transaction.',
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                Text(
                  'Attempt $_pollCount of $_maxPolls',
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
              ] else ...[
                const Icon(Icons.check_circle, color: Colors.green, size: 80),
                const SizedBox(height: 24),
                const Text(
                  'Payment Successful 🎉',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Text(
                  'Your payment for order #${widget.orderId} has been confirmed.',
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(
                          builder: (context) => const MainScreen()),
                      (Route<dynamic> route) => false,
                    );
                  },
                  child: const Text('Back to Home'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// --- Payment Failure Screen ---
class PaymentFailurePage extends StatelessWidget {
  final String orderId;
  final String errorMessage;

  const PaymentFailurePage({
    super.key,
    required this.orderId,
    required this.errorMessage,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error, color: Colors.red, size: 80),
              const SizedBox(height: 24),
              const Text(
                'Payment Failed ❌',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Text(
                errorMessage,
                style: const TextStyle(fontSize: 16, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (context) => const MainScreen()),
                    (Route<dynamic> route) => false,
                  );
                },
                child: const Text('Back to Home'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// --- Payment Pending Screen ---
class PaymentPendingPage extends StatelessWidget {
  final String orderId;
  final String? message;

  const PaymentPendingPage({
    super.key,
    required this.orderId,
    this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.hourglass_top,
                  color: Colors.orangeAccent, size: 80),
              const SizedBox(height: 24),
              const Text(
                'Payment Pending ⏳',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Text(
                message ??
                    'Your payment for order #$orderId was not completed. You can retry from your bookings page.',
                style: const TextStyle(fontSize: 16, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (context) => const MainScreen()),
                    (Route<dynamic> route) => false,
                  );
                },
                child: const Text('Back to Home'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
