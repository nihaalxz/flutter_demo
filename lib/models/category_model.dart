import 'package:hive/hive.dart';

part 'category_model.g.dart'; // This file will be generated

@HiveType(typeId: 1)
class CategoryModel {
  @HiveField(0)
  final int id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final String description;

  @HiveField(3)
  final String icon;

  CategoryModel({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      icon: json['icon'],
    );
  }
}
