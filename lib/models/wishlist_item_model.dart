class WishlistItemModel {
  final int id; // This is the ID of the Wishlist entry itself
  final int itemId; // This is the ID of the Product/Item
  final String itemName;
  final String? itemDescription;
  final String? image;
  final double price;
  final String? categoryName;
  final bool availability;
  final DateTime createdAt;
  final String? locationName;

  WishlistItemModel({
    required this.id,
    required this.itemId,
    required this.itemName,
    this.itemDescription,
    this.image,
    required this.price,
    this.categoryName,
    required this.availability,
    required this.createdAt,
    required this.locationName,
  });

  factory WishlistItemModel.fromJson(Map<String, dynamic> json) {
    return WishlistItemModel(
      id: json['id'],
      itemId: json['itemId'],
      itemName: json['itemName'],
      itemDescription: json['itemDescription'],
      image: json['image'],
      price: (json['price'] as num).toDouble(),
      categoryName: json['categoryName'],
      availability: json['availability'],
      createdAt: DateTime.parse(json['createdAt']),
      locationName: json['locationName'],
    );
  }
}
