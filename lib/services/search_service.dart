import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:myfirstflutterapp/environment/env.dart';
import 'package:myfirstflutterapp/models/product_model.dart';

class SearchService {
  static const String baseUrl = "${AppConfig.ApibaseUrl}/item";

  /// 🔎 Search items
   Future<List<Product>> searchItems({
    String? query,
    String? location,
    int? categoryId,
  }) async {
    final uri = Uri.parse("$baseUrl/search").replace(
      queryParameters: {
        if (query != null && query.isNotEmpty) 'q': query,
        if (location != null && location.isNotEmpty) 'location': location,
        if (categoryId != null && categoryId != 0)
          'categoryId': categoryId.toString(),
      },
    );

    final response = await http.get(uri);

    if (response.statusCode == 200) {
      final List<dynamic> jsonList = jsonDecode(response.body);
      return jsonList.map((json) => Product.fromJson(json)).toList();
    } else {
      throw Exception("Failed to search items: ${response.body}");
    }
  }

  /// 📍 Get available locations
   Future<List<String>> getLocations() async {
    final uri = Uri.parse("$baseUrl/locations");
    final response = await http.get(uri);

    if (response.statusCode == 200) {
      final List<dynamic> jsonList = jsonDecode(response.body);
      return jsonList.map((loc) => loc.toString()).toList();
    } else {
      throw Exception("Failed to fetch locations");
    }
  }

  /// ✍️ Get autocomplete suggestions
   Future<List<String>> getSuggestions(String term) async {
    final uri = Uri.parse("$baseUrl/autocomplete?term=$term");
    final response = await http.get(uri);

    if (response.statusCode == 200) {
      final List<dynamic> jsonList = jsonDecode(response.body);
      return jsonList.map((s) => s.toString()).toList();
    } else {
      throw Exception("Failed to fetch suggestions");
    }
  }
}
