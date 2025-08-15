import 'package:hive/hive.dart';

part 'product_model.g.dart'; // This file will be generated

@HiveType(typeId: 0)
class Product {
  @HiveField(0)
  final int id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final String description;

  @HiveField(3)
  final String image;

  @HiveField(4)
  final double price;

  @HiveField(5)
  final int categoryId;

  @HiveField(6)
  final String? ownerProfileImage;

  @HiveField(7)
  final String categoryName;

  @HiveField(8)
  final String ownerId;

  @HiveField(9)
  final String ownerName;

  @HiveField(10)
  final String location;

  @HiveField(11)
  final bool availability;

  @HiveField(12)
  final String createdAt;

  @HiveField(13)
  final String status;

  @HiveField(14)
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
