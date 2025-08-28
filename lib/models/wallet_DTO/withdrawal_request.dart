class WithdrawalRequest {
  final double amount;
  final String currency;

  WithdrawalRequest({
    required this.amount,
    required this.currency,
  });

  // This factory is for creating an object FROM JSON, which you might not need.
  // factory WithdrawalRequest.fromJson(Map<String, dynamic> json) {
  //   return WithdrawalRequest(
  //     amount: json['amount'] as double,
  //     currency: json['currency'] as String,
  //   );
  // }

  /// ✅ ADD THIS METHOD
  /// Converts the object TO a JSON format to send to the server.
  Map<String, dynamic> toJson() {
    return {
      'amount': amount,
      'currency': currency,
    };
  }
}