import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

// --- Imports ---
import '../../models/payment_history_DTO.dart';
import '../../services/payment_services/payment_service.dart';

/// A page that displays a list of the user's past payment transactions.
class PaymentHistoryPage extends StatefulWidget {
  const PaymentHistoryPage({super.key});

  @override
  State<PaymentHistoryPage> createState() => _PaymentHistoryPageState();
}

class _PaymentHistoryPageState extends State<PaymentHistoryPage> {
  final PaymentService _paymentService = PaymentService();
  late Future<List<PaymentHistoryDto>> _historyFuture; // Corrected type

  @override
  void initState() {
    super.initState();
    _historyFuture = _paymentService.getPaymentHistory();
  }
  
  /// Refreshes the payment history data.
  void _refreshHistory() {
    setState(() {
      _historyFuture = _paymentService.getPaymentHistory();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Payment History')),
      body: SafeArea( // ✅ Added SafeArea
        child: FutureBuilder<List<PaymentHistoryDto>>(
          future: _historyFuture,
          builder: (context, snapshot) {
            // --- Loading State ---
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            // --- Error State ---
            if (snapshot.hasError) {
              return _buildErrorState(snapshot.error.toString());
            }

            final history = snapshot.data ?? [];

            // --- Empty State ---
            if (history.isEmpty) {
              return _buildEmptyState();
            }

            // --- Success State ---
            return RefreshIndicator(
              onRefresh: () async => _refreshHistory(),
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                itemCount: history.length,
                itemBuilder: (context, index) {
                  return _buildHistoryCard(history[index]);
                },
              ),
            );
          },
        ),
      ),
    );
  }

  /// Builds a single card for a payment transaction.
  Widget _buildHistoryCard(PaymentHistoryDto item) {
    final bool isSuccess =
        item.status.toLowerCase() == 'paid' ||
        item.status.toLowerCase() == 'success';
    final DateFormat dateFormat = DateFormat('MMM d, yyyy \'at\' h:mm a');
    final NumberFormat currencyFormat = NumberFormat.currency(
      locale: 'en_IN',
      symbol: '₹',
    );

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isSuccess
              ? Colors.green.shade100
              : Colors.red.shade100,
          child: Icon(
            isSuccess ? Icons.check_circle_outline : Icons.cancel_outlined,
            color: isSuccess ? Colors.green.shade700 : Colors.red.shade700,
          ),
        ),
        title: Text(
          item.itemName,
          style: const TextStyle(fontWeight: FontWeight.bold),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(dateFormat.format(item.createdAt)),
        trailing: Text(
          currencyFormat.format(item.amount),
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: isSuccess ? Colors.green.shade800 : Colors.grey.shade600,
          ),
        ),
      ),
    );
  }

  /// A widget to display when the list is empty.
  Widget _buildEmptyState() {
    return RefreshIndicator(
      onRefresh: () async => _refreshHistory(),
      child: ListView(
        // Wrap in ListView to enable pull-to-refresh
        children: [
          SizedBox(height: MediaQuery.of(context).size.height * 0.25),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.receipt_long, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                const Text(
                  'No Payment History',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                Text(
                  'Your past transactions will appear here.',
                  style: TextStyle(color: Colors.grey[600]),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// A widget to display when an error occurs.
  Widget _buildErrorState(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.cloud_off_rounded, size: 60, color: Colors.grey),
            const SizedBox(height: 16),
            const Text(
              "Something Went Wrong",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              style: TextStyle(color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _refreshHistory,
              child: const Text("Retry"),
            ),
          ],
        ),
      ),
    );
  }
}
