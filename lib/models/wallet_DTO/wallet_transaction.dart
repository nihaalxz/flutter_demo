class WalletTransaction {
  final double amount;
  final String type;
  final DateTime timestamp;
  final int? relatedBookingId; // Can be null

  WalletTransaction({
    required this.amount,
    required this.type,
    required this.timestamp,
    this.relatedBookingId,
  });

  factory WalletTransaction.fromJson(Map<String, dynamic> json) {
    return WalletTransaction(
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      type: json['type'] as String? ?? 'Unknown',
      timestamp: DateTime.parse(json['timestamp'] as String? ?? DateTime.now().toIso8601String()),
      relatedBookingId: json['relatedBookingId'],
    );
  }
}