import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:hive_flutter/hive_flutter.dart';

// --- Assumed Imports ---
import '../models/product_model.dart';
import '../environment/env.dart';
import 'auth_service.dart';

class ProductService {
  final String _baseUrl = AppConfig.ApibaseUrl;
  final AuthService _authService = AuthService();
  // ✅ FIX: Removed the direct Hive.box() call from here to prevent race conditions.

  /// Helper method to get authenticated headers.
  Future<Map<String, String>> _getAuthHeaders() async {
    final token = await _authService.getToken();
    if (token == null) {
      throw Exception('User is not authenticated. Token not found.');
    }
    return {
      'Content-Type': 'application/json; charset=UTF-8',
      'Authorization': 'Bearer $token',
    };
  }

  /// Fetches a list of all products, with caching.
  Future<List<Product>> fetchProducts({bool forceRefresh = false}) async {
    final cacheBox = Hive.box('p2p_cache');
    
    final cachedData = cacheBox.get('cached_products');
    final cachedTimestamp = cacheBox.get('products_cache_timestamp') ?? 0;
    final currentTime = DateTime.now().millisecondsSinceEpoch;

    // Cache is valid for 10 minutes (600000 milliseconds)
    if (!forceRefresh && cachedData != null && (currentTime - cachedTimestamp < 600000)) {
      print("Loading products from Hive cache...");
      
      // ✅ FIX: Safely convert the cached map to the correct type before parsing.
      return (cachedData as List).map((item) {
        final map = Map<String, dynamic>.from(item as Map);
        return Product.fromJson(map);
      }).toList();
    }

    print("Fetching products from network...");
    final headers = await _getAuthHeaders();
    final url = Uri.parse('$_baseUrl/item');
    final response = await http.get(url, headers: headers);

    if (response.statusCode == 200) {
      final List<dynamic> body = jsonDecode(response.body);
      final products = body.map((dynamic item) => Product.fromJson(item)).toList();
      
      // Save raw JSON data to Hive cache for easier deserialization later
      final List<Map<String, dynamic>> productsJson = body.cast<Map<String, dynamic>>();
      await cacheBox.put('cached_products', productsJson);
      await cacheBox.put('products_cache_timestamp', currentTime);
      
      return products;
    } else {
      throw Exception('Failed to load products.');
    }
  }

  /// Fetches a single product by its unique ID.
  Future<Product> getProductById(int productId) async {
    final headers = await _getAuthHeaders();
    final url = Uri.parse('$_baseUrl/item/$productId');
    final response = await http.get(url, headers: headers);

    if (response.statusCode == 200) {
      return Product.fromJson(json.decode(response.body));
    } else {
      // Try to parse a more specific error message from the backend
      try {
        final errorBody = json.decode(response.body);
        final errorMessage = errorBody['message'] ?? 'Failed to load product details.';
        throw Exception(errorMessage);
      } catch (_) {
        // Fallback if the response body isn't valid JSON
        if (response.statusCode == 404) {
          throw Exception('Product not found.');
        }
        throw Exception('Failed to load product details. Status code: ${response.statusCode}');
      }
    }
  }

  /// Fetches a list of products similar to the given product ID.
  Future<List<Product>> getSimilarProducts(int productId) async {
    final headers = await _getAuthHeaders();
    final url = Uri.parse('$_baseUrl/item/$productId/similar');
    final response = await http.get(url, headers: headers);

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((item) => Product.fromJson(item)).toList();
    } else {
      // Try to parse a more specific error message from the backend
      try {
        final errorBody = json.decode(response.body);
        final errorMessage = errorBody['message'] ?? 'Failed to load similar products.';
        throw Exception(errorMessage);
      } catch (_) {
        // Fallback if the response body isn't valid JSON
        throw Exception('Failed to load similar products. Status code: ${response.statusCode}');
      }
    }
  }

  /// Creates a new product.
  Future<Product> createProduct(Product product) async {
    final headers = await _getAuthHeaders();
    final url = Uri.parse('$_baseUrl/item');
    final response = await http.post(
      url,
      headers: headers,
      body: jsonEncode(product.toJson()),
    );
    if (response.statusCode == 201) {
      return Product.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to create product.');
    }
  }

  /// Updates an existing product.
  Future<Product> updateProduct(int id, Product product) async {
    final headers = await _getAuthHeaders();
    final url = Uri.parse('$_baseUrl/item/$id');
    final response = await http.put(
      url,
      headers: headers,
      body: jsonEncode(product.toJson()),
    );
    if (response.statusCode == 200) {
      return Product.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to update product.');
    }
  }

  /// Deletes a product by its ID.
  Future<void> deleteProduct(int id) async {
    final headers = await _getAuthHeaders();
    final url = Uri.parse('$_baseUrl/item/$id');
    final response = await http.delete(url, headers: headers);
    if (response.statusCode != 204 && response.statusCode != 200) {
      throw Exception('Failed to delete product.');
    }
  }
}
