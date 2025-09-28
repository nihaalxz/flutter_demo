import 'dart:async';
import 'package:flutter/material.dart';
import 'package:myfirstflutterapp/pages/main_screen.dart';
import 'package:myfirstflutterapp/services/payment_services/payment_service.dart';

// --- Payment Success Screen (Now a StatefulWidget to handle polling) ---
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
  final int _maxPolls = 5; // Poll a maximum of 5 times (15 seconds)

  @override
  void initState() {
    super.initState();
    _startPolling();
  }

  /// Starts a timer that periodically checks the payment status with the backend.
  void _startPolling() {
    _pollingTimer = Timer.periodic(const Duration(seconds: 3), (timer) async {
      _pollCount++;
      try {
        final result =
            await widget.paymentService.verifyPaymentStatus(widget.orderId);
        if (result['status'] == 'Success') {
          // If successful, stop polling and update the UI to show the final success message.
          timer.cancel();
          if (mounted) {
            setState(() => _isVerifying = false);
          }
        } else if (_pollCount >= _maxPolls) {
          // If it's still not successful after max attempts, treat it as a failure.
          timer.cancel();
          _handleVerificationFailure('Verification timed out. Please check your bookings for the final status.');
        }
      } catch (e) {
        timer.cancel();
        _handleVerificationFailure(e.toString());
      }
    });
  }
  
  /// Navigates to the failure page if verification fails or times out.
  void _handleVerificationFailure(String errorMessage) {
      if(mounted) {
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

  @override
  void dispose() {
    _pollingTimer?.cancel(); // Always cancel timers in dispose to prevent memory leaks.
    super.dispose();
  }

  /// Navigates to the MainScreen and tells it to show the Bookings tab (index 3).
  void _goToBookings() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const MainScreen(initialIndex: 3)),
      (Route<dynamic> route) => false,
    );
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
              // Show a loading/verifying UI while polling
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
                  'Please wait a moment while we confirm your transaction.',
                  style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                  textAlign: TextAlign.center,
                ),
              ] else ...[
                // Show the final success UI once verification is complete
                const Icon(Icons.check_circle, color: Colors.green, size: 80),
                const SizedBox(height: 24),
                const Text(
                  'Payment Successful!',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  'Your payment for order #${widget.orderId} has been confirmed.',
                  style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: _goToBookings,
                  child: const Text('View My Bookings'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// --- Payment Failure Screen ---
class PaymentFailurePage extends StatelessWidget {
  final String orderId;
  final String errorMessage;

  const PaymentFailurePage(
      {super.key, required this.orderId, required this.errorMessage});

  void _goToBookings(BuildContext context) {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const MainScreen(initialIndex: 3)),
      (Route<dynamic> route) => false,
    );
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
              const Icon(Icons.error, color: Colors.red, size: 80),
              const SizedBox(height: 24),
              const Text(
                'Payment Failed',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                errorMessage,
                style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () => _goToBookings(context),
                child: const Text('Back to Bookings'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// --- Payment Pending Screen ---
class PaymentPendingPage extends StatelessWidget {
  final String orderId;

  const PaymentPendingPage({super.key, required this.orderId});

  void _goToBookings(BuildContext context) {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const MainScreen(initialIndex: 3)),
      (Route<dynamic> route) => false,
    );
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
              const Icon(Icons.hourglass_top,
                  color: Colors.orange, size: 80),
              const SizedBox(height: 24),
              const Text(
                'Payment Pending',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'Your payment for order #$orderId was not completed. You can try again later from your bookings page.',
                style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () => _goToBookings(context),
                child: const Text('Back to Bookings'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

