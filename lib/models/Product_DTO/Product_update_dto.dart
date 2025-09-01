class ProductUpdateDto {
  final String name;
  final String description;
  final double price;
  final int categoryId;
  final String locationName;
  final bool availability;
  final double latitude;
  final double longitude;


  ProductUpdateDto({
    required this.name,
    required this.description,
    required this.price,
    required this.categoryId,
    required this.locationName,
    required this.availability,
    required this.latitude,
    required this.longitude,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'description': description,
      'price': price,
      'categoryId': categoryId,
      'location': locationName,
      'latitude': latitude,
      'longitude': longitude,
      'availability': availability,
    };
  }
}
