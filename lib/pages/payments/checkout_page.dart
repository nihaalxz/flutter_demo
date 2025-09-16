import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

void _openCashfreeCheckout(BuildContext context, String paymentSessionId, String orderId) {
  final checkoutUrl = "https://test.cashfree.com/pg/app/orders/$orderId"; // change to prod if needed

  final controller = WebViewController()
    ..setJavaScriptMode(JavaScriptMode.unrestricted)
    ..loadRequest(Uri.parse("$checkoutUrl?paymentSessionId=$paymentSessionId"))
    ..setNavigationDelegate(
      NavigationDelegate(
        onNavigationRequest: (request) {
          if (request.url.contains('payment-success')) {
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Payment Successful!"), backgroundColor: Colors.green),
            );
            // 🔄 TODO: Refresh bookings (call backend / update UI)
            return NavigationDecision.prevent;
          } else if (request.url.contains('payment-failure')) {
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Payment Failed!"), backgroundColor: Colors.red),
            );
            return NavigationDecision.prevent;
          }
          return NavigationDecision.navigate;
        },
      ),
    );

  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => Scaffold(
        appBar: AppBar(title: const Text('Complete Payment')),
        body: WebViewWidget(controller: controller),
      ),
    ),
  );
}
