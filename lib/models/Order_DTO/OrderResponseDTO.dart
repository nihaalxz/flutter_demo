class OrderResponseDto {
  final String paymentSessionId;
  final String orderId;
  final double originalAmount;
  final double tds;
  final double platformFee;
  final double finalPayable;

  OrderResponseDto({
    required this.paymentSessionId,
    required this.orderId,
    required this.originalAmount,
    required this.tds,
    required this.platformFee,
    required this.finalPayable,
  });

  factory OrderResponseDto.fromJson(Map<String, dynamic> json) {
    return OrderResponseDto(
      paymentSessionId: json['paymentSessionId'],
      orderId: json['orderId'],
      originalAmount: (json['originalAmount'] as num).toDouble(),
      tds: (json['tds'] as num).toDouble(),
      platformFee: (json['platformFee'] as num).toDouble(),
      finalPayable: (json['finalPayable'] as num).toDouble(),
    );
  }
}
