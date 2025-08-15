class CategoryModel {
  int id;
  String name;
  String description;
  String icon;

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
