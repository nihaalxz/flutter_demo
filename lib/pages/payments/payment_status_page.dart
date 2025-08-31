import 'package:flutter/material.dart';

// --- Assumed Imports ---
import 'package:myfirstflutterapp/pages/bookings_page.dart';
import 'package:myfirstflutterapp/pages/main_screen.dart';


/// A page shown to the user after a successful payment.
class PaymentSuccessPage extends StatelessWidget {
  final String orderId;
  const PaymentSuccessPage({super.key, required this.orderId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.check_circle_outline, color: Colors.green, size: 80),
              const SizedBox(height: 24),
              const Text(
                'Payment Successful!',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Your booking has been confirmed. You can view its status on the bookings page.',
                style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () {
                  // Navigate to the main screen, specifically to the bookings tab
                   Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (context) => const BookingsPage()), // Assuming Bookings is at index 2
                    (Route<dynamic> route) => false,
                  );
                },
                child: const Text('View My Bookings'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A page shown to the user after a failed or cancelled payment.
class PaymentFailedPage extends StatelessWidget {
  final String orderId;
  const PaymentFailedPage({super.key, required this.orderId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.cancel_outlined, color: Colors.red, size: 80),
              const SizedBox(height: 24),
              const Text(
                'Payment Failed',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Something went wrong with your payment. Please try again.',
                style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () {
                  // Go back to the previous screen (e.g., the product details page)
                  Navigator.of(context).pop();
                },
                child: const Text('Try Again'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
