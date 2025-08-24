class ProductUpdateDto {
  final String name;
  final String description;
  final double price;
  final int categoryId;
  final String location;
  final bool availability;

  ProductUpdateDto({
    required this.name,
    required this.description,
    required this.price,
    required this.categoryId,
    required this.location,
    required this.availability,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'description': description,
      'price': price,
      'categoryId': categoryId,
      'location': location,
      'availability': availability,
    };
  }
}
