import 'package:myfirstflutterapp/models/product_model.dart';

class OfferResponseDTO {
  final int id;
  final int itemId;
  final String itemName;
  final String renterId;
  final String renterName;
  final double offeredPrice;
  final double originalPrice;
  final String status;
  final DateTime createdAt;
  final DateTime? respondedAt;
  final bool canBook;
  
  // Added for UI convenience
  final Product? item; 

  OfferResponseDTO({
    required this.id,
    required this.itemId,
    required this.itemName,
    required this.renterId,
    required this.renterName,
    required this.offeredPrice,
    required this.originalPrice,
    required this.status,
    required this.createdAt,
    this.respondedAt,
    required this.canBook,
    this.item,
  });

  factory OfferResponseDTO.fromJson(Map<String, dynamic> json) {
    return OfferResponseDTO(
      id: json['id'],
      itemId: json['itemId'],
      itemName: json['itemName'],
      renterId: json['renterId'],
      renterName: json['renterName'],
      offeredPrice: (json['offeredPrice'] as num).toDouble(),
      originalPrice: (json['originalPrice'] as num).toDouble(),
      status: json['status'],
      createdAt: DateTime.parse(json['createdAt']),
      respondedAt: json['respondedAt'] != null ? DateTime.parse(json['respondedAt']) : null,
      canBook: json['canBook'],
      item: json['item'] != null ? Product.fromJson(json['item']) : null,
    );
  }
}
