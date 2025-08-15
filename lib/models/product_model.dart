class Product {
  final int id;
  final String name;
  final String description;
  final String image;
  final double price;
  final int categoryId;
  final String? ownerProfileImage;
  final String categoryName;
  final String ownerId;
  final String ownerName;
  final String location;
  final bool availability;
  final String createdAt;
  final String status;
  final int views;

  Product({
    required this.id,
    required this.name,
    required this.description,
    required this.image,
    required this.price,
    required this.categoryId,
    this.ownerProfileImage,
    required this.categoryName,
    required this.ownerId,
    required this.ownerName,
    required this.location,
    required this.availability,
    required this.createdAt,
    required this.status,
    required this.views,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      image: json['image'],
      price: (json['price'] as num).toDouble(),
      categoryId: json['categoryId'],
      ownerProfileImage: json['ownerProfileImage'],
      categoryName: json['categoryName'],
      ownerId: json['ownerId'],
      ownerName: json['ownerName'],
      location: json['location'],
      availability: json['availability'],
      createdAt: json['createdAt'],
      status: json['status'],
      views: json['views'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'image': image,
      'price': price,
      'categoryId': categoryId,
      'ownerProfileImage': ownerProfileImage,
      'categoryName': categoryName,
      'ownerId': ownerId,
      'ownerName': ownerName,
      'location': location,
      'availability': availability,
      'createdAt': createdAt,
      'status': status,
      'views': views,
    };
  }
}
