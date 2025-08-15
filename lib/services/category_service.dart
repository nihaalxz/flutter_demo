import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/category_model.dart';
import '../environment/env.dart';

class CategoryService {
  Future<List<CategoryModel>> getCategories({bool forceRefresh = false}) async {
    final prefs = await SharedPreferences.getInstance();
    final cachedData = prefs.getString('cached_categories');
    final cachedTimestamp = prefs.getInt('categories_cache_timestamp') ?? 0;
    final currentTime = DateTime.now().millisecondsSinceEpoch;

    // Cache is valid for 10 minutes
    if (!forceRefresh && cachedData != null && (currentTime - cachedTimestamp < 600000)) {
      print("Loading categories from cache...");
      final List<dynamic> data = jsonDecode(cachedData);
      return data.map((json) => CategoryModel.fromJson(json)).toList();
    }

    print("Fetching categories from network...");
    final response = await http.get(Uri.parse("${AppConfig.ApibaseUrl}/category"));
    
    if (response.statusCode == 200) {
      // Save to cache
      await prefs.setString('cached_categories', response.body);
      await prefs.setInt('categories_cache_timestamp', currentTime);

      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => CategoryModel.fromJson(json)).toList();
    } else {
      throw Exception("Failed to load categories");
    }
  }
}
