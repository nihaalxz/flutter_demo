import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:myfirstflutterapp/services/payment_services/wallet_service.dart';
import 'package:shimmer/shimmer.dart';

// --- Assumed Imports ---
import '../models/wallet_DTO/wallet_view.dart';
import '../models/wallet_DTO/wallet_transaction.dart';
import '../models/wallet_DTO/withdrawal_request.dart';

/// A page that displays the user's wallet balance and transaction history.
class WalletPage extends StatefulWidget {
  const WalletPage({super.key});

  @override
  State<WalletPage> createState() => _WalletPageState();
}

class _WalletPageState extends State<WalletPage> {
  final WalletService _walletService = WalletService();
  late Future<WalletView> _walletDataFuture;
  @override
  void initState() {
    super.initState();
   _walletDataFuture = _walletService.getWallet();
  }

  /// Fetches both wallet details and transactions concurrently.
  Future<Map<String, dynamic>> _fetchWalletData() async {
    try {
      final results = await Future.wait([
        _walletService.getWallet(),
      ]);
      return {
        'details': results[0],
        'transactions': results[1] as List<WalletTransaction>,
      };
    } catch (e) {
      // Re-throw the error to be caught by the FutureBuilder
      rethrow;
    }
  }

  void _refreshWalletData() {
    setState(() {
     _walletDataFuture = _walletService.getWallet();
    });
  }

  /// ✅ NEW: Shows a dialog to handle withdrawal requests.
  void _showWithdrawalDialog(WalletView walletDetails) {
    final amountController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Request Withdrawal'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Withdrawable Balance: ${NumberFormat.currency(locale: 'en_IN', symbol: '₹').format(walletDetails.withdrawableBalance)}'),
                const SizedBox(height: 16),
                TextFormField(
                  controller: amountController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Amount',
                    prefixText: '₹ ',
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter an amount';
                    }
                    final amount = double.tryParse(value);
                    if (amount == null) {
                      return 'Please enter a valid number';
                    }
                    if (amount > walletDetails.withdrawableBalance) {
                      return 'Amount exceeds withdrawable balance';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (formKey.currentState!.validate()) {
                  final request = WithdrawalRequest(
                    amount: double.parse(amountController.text),
                    currency: 'INR',
                  );
                  try {
                    await _walletService.requestWithdrawal(request);
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Withdrawal request submitted!'), backgroundColor: Colors.green),
                    );
                  } catch (e) {
                     ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
                    );
                  }
                }
              },
              child: const Text('Submit'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Wallet'),
      ),
      body: FutureBuilder<WalletView>(
        future: _walletDataFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return _buildShimmerLoader();
          }

          if (snapshot.hasError) {
            return _buildErrorState(snapshot.error.toString());
          }

          final walletDetails = snapshot.data!;
          final transactions = walletDetails.recentTransactions;

          return RefreshIndicator(
            onRefresh: () async => _refreshWalletData(),
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: _buildBalanceCard(walletDetails),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      'Wallet History',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                ),
                if (transactions.isEmpty)
                  const SliverFillRemaining(
                    child: Center(child: Text('No transactions yet.')),
                  )
                else
                  _buildTransactionList(transactions),
              ],
            ),
          );
        },
      ),
    );
  }

  /// The main card displaying the user's current balance and withdrawal button.
  Widget _buildBalanceCard(WalletView walletDetails) {
    return Card(
      margin: const EdgeInsets.all(16.0),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Withdrawable Balance',
              style: TextStyle(fontSize: 16, color: Color.fromARGB(255, 79, 79, 79)),
            ),
            const SizedBox(height: 8),
            // ✅ FIX: Use `withdrawableBalance` from the model
            Text(
              NumberFormat.currency(locale: 'en_IN', symbol: '₹').format(walletDetails.withdrawableBalance),
              style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Pending Balance: ${NumberFormat.currency(locale: 'en_IN', symbol: '₹').format(walletDetails.pendingBalance)}',
              style: const TextStyle(fontSize: 20, color: Color.fromARGB(255, 48, 48, 48)),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              icon: const Icon(Icons.send_to_mobile),
              label: const Text('Request Withdrawal',style: TextStyle(fontSize: 20),),
              onPressed: () => _showWithdrawalDialog(walletDetails),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// A SliverList to display the transaction history.
  Widget _buildTransactionList(List<WalletTransaction> transactions) {
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final transaction = transactions[index];
          final isCredit = transaction.type.toLowerCase() == 'credit';
          return ListTile(
            leading: CircleAvatar(
              backgroundColor: isCredit ? Colors.green[100] : Colors.red[100],
              child: Icon(
                isCredit ? Icons.arrow_downward : Icons.arrow_upward,
                color: isCredit ? Colors.green[800] : Colors.red[800],
              ),
            ),
            // ✅ FIX: Use a placeholder for description as it's not in the model
            title: Text("Booking ID: ${transaction.relatedBookingId}", style: const TextStyle(fontWeight: FontWeight.w500)),
            // ✅ FIX: Use `timestamp` instead of `date`
            subtitle: Text(DateFormat.yMMMd().add_jm().format(transaction.timestamp.toLocal())),
            trailing: Text(
              '${isCredit ? '+' : '-'} ${NumberFormat.currency(locale: 'en_IN', symbol: '₹').format(transaction.amount)}',
              style: TextStyle(
                color: isCredit ? Colors.green : Colors.red,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          );
        },
        childCount: transactions.length,
      ),
    );
  }

  /// A shimmer loading placeholder.
  Widget _buildShimmerLoader() {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      child: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          Container(height: 180, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16))),
          const SizedBox(height: 24),
          Container(height: 24, width: 200, color: Colors.white),
          const SizedBox(height: 16),
          Container(height: 60, color: Colors.white),
          const SizedBox(height: 12),
          Container(height: 60, color: Colors.white),
        ],
      ),
    );
  }

  /// The view to show when an error occurs.
  Widget _buildErrorState(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.redAccent, size: 48),
            const SizedBox(height: 16),
            Text(
              "Something went wrong",
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              error,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _refreshWalletData,
              child: const Text("Retry"),
            ),
          ],
        ),
      ),
    );
  }
}
