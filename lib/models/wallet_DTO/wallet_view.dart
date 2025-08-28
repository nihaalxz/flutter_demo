import 'wallet_transaction.dart';

class WalletView {
  final double withdrawableBalance;
  final double pendingBalance;
  final List<WalletTransaction> recentTransactions;

  WalletView({
    required this.withdrawableBalance,
    required this.pendingBalance,
    required this.recentTransactions,
  });

  factory WalletView.fromJson(Map<String, dynamic> json) {
    // Safely parse the list of transactions from within the main object
    var transactionsList = json['recentTransactions'] as List? ?? [];
    List<WalletTransaction> transactions = transactionsList
        .map((i) => WalletTransaction.fromJson(i))
        .toList();

    return WalletView(
      withdrawableBalance: (json['withdrawableBalance'] as num?)?.toDouble() ?? 0.0,
      pendingBalance: (json['pendingBalance'] as num?)?.toDouble() ?? 0.0,
      recentTransactions: transactions,
    );
  }
}