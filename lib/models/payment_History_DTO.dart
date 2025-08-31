class PaymentHistoryDto {
  final String orderId;
  final int bookingId;
  final double amount;
  final String currency;
  final String status;
  final String paymentMethod;
  final DateTime createdAt;
  final String itemName;
  final String ownerName;

  PaymentHistoryDto({
    required this.orderId,
    required this.bookingId,
    required this.amount,
    required this.currency,
    required this.status,
    required this.paymentMethod,
    required this.createdAt,
    required this.itemName,
    required this.ownerName,
  });

  factory PaymentHistoryDto.fromJson(Map<String, dynamic> json) {
    return PaymentHistoryDto(
      orderId: json['orderId'],
      bookingId: json['bookingId'],
      amount: json['amount'],
      currency: json['currency'],
      status: json['status'],
      paymentMethod: json['paymentMethod'],
      createdAt: DateTime.parse(json['createdAt']),
      itemName: json['itemName'],
      ownerName: json['ownerName'],

    );
  }
}
