class OrderResponseDto {
  final String razorpayKeyId;
  final String razorpayOrderId;
  final double baseAmount;
  final double platformFee;
  final double tds;
  final double totalAmount;

  OrderResponseDto({
    required this.razorpayKeyId,
    required this.razorpayOrderId,
    required this.baseAmount,
    required this.platformFee,
    required this.tds,
    required this.totalAmount,
  });

  factory OrderResponseDto.fromJson(Map<String, dynamic> json) {
    return OrderResponseDto(
      razorpayKeyId: json['razorpayKeyId'] ?? '',
      razorpayOrderId: json['razorpayOrderId'] ?? '',
      baseAmount: (json['baseAmount'] as num?)?.toDouble() ?? 0.0,
      platformFee: (json['platformFee'] as num?)?.toDouble() ?? 0.0,
      tds: (json['tds'] as num?)?.toDouble() ?? 0.0,
      totalAmount: (json['totalAmount'] as num?)?.toDouble() ?? 0.0,
    );
  }
}