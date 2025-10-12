class WishlistItemModel {
  final int wishListId; // Wishlist entry ID
  final int itemId; // Actual Item ID
  final String name;
  final String? description;
  final String? image;
  final double price;
  final int categoryId;
  final String? categoryName;
  final String ownerId;
  final String? ownerName;
  final String? ownerProfileImage;
  final double latitude;
  final double longitude;
  final String locationName;
  final bool availability;
  final DateTime createdAt;
  final String status;
  final int views;
  final bool isWishlisted;

  WishlistItemModel({
    required this.wishListId,
    required this.itemId,
    required this.name,
    this.description,
    this.image,
    required this.price,
    required this.categoryId,
    this.categoryName,
    required this.ownerId,
    this.ownerName,
    this.ownerProfileImage,
    required this.latitude,
    required this.longitude,
    required this.locationName,
    required this.availability,
    required this.createdAt,
    required this.status,
    required this.views,
    this.isWishlisted = true, // default true for wishlist items
  });

  factory WishlistItemModel.fromJson(Map<String, dynamic> json) {
    final item = json['item']; // because API returns { wishListId, item: {...} }

    return WishlistItemModel(
      wishListId: json['wishListId'],
      itemId: item['id'],
      name: item['name'],
      description: item['description'],
      image: item['image'],
      price: (item['price'] as num).toDouble(),
      categoryId: item['categoryId'],
      categoryName: item['categoryName'],
      ownerId: item['ownerId'],
      ownerName: item['ownerName'],
      ownerProfileImage: item['ownerProfileImage'],
      latitude: (item['latitude'] as num).toDouble(),
      longitude: (item['longitude'] as num).toDouble(),
      locationName: item['locationName'],
      availability: item['availability'],
      createdAt: DateTime.parse(item['createdAt']),
      status: item['status'],
      views: item['views'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'wishListId': wishListId,
      'item': {
        'id': itemId,
        'name': name,
        'description': description,
        'image': image,
        'price': price,
        'categoryId': categoryId,
        'categoryName': categoryName,
        'ownerId': ownerId,
        'ownerName': ownerName,
        'ownerProfileImage': ownerProfileImage,
        'latitude': latitude,
        'longitude': longitude,
        'locationName': locationName,
        'availability': availability,
        'createdAt': createdAt.toIso8601String(),
        'status': status,
        'views': views,
      }
    };
  }
}
