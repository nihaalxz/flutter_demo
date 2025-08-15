import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/category_model.dart'; // Import your model
import '../environment/env.dart';     // Import your environment config

class CategoryService {
  // The method is no longer static and now returns the correct type.
  Future<List<CategoryModel>> getCategories() async {
    // Ensure AppConfig.ApibaseUrl is correctly defined in your env.dart file
    final response = await http.get(
      Uri.parse("${AppConfig.ApibaseUrl}/category"),
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      
      // This now maps each JSON object to a CategoryModel object.
      return data.map((json) => CategoryModel.fromJson(json)).toList();
    } else {
      throw Exception("Failed to load categories");
    }
  }
}