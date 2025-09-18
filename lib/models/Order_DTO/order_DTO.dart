class OrderDto {
  final String userId;
  final String email;
  final String phone;
  final double amount;
  final int bookingId;
  final String itemName;
  final String? itemImage;

  OrderDto({
    required this.userId,
    required this.email,
    required this.phone,
    required this.amount,
    required this.bookingId,
    required this.itemName,
    this.itemImage,
  });

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'email': email,
      'phone': phone,
      'amount': amount,
      'bookingId': bookingId,
      'itemName': itemName,
      'itemImage': itemImage,
    };
  }
}