import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:hive_flutter/hive_flutter.dart';
import 'package:myfirstflutterapp/models/Product_DTO/Product_update_dto.dart';

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

    Future<Product> toggleAvailability(int itemId) async {
    final headers = await _getAuthHeaders();
    final url = Uri.parse('$_baseUrl/item/$itemId/toggle-availability'); // Assuming this endpoint
    final response = await http.patch(url, headers: headers); // Using PATCH is common for partial updates

    if (response.statusCode == 200) {
      return Product.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to update availability.');
    }
  }

   Future<List<Product>> getMyItems() async {
    final headers = await _getAuthHeaders();
    final url = Uri.parse('$_baseUrl/item/my-items'); // Assuming this is your new endpoint
    final response = await http.get(url, headers: headers);

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((item) => Product.fromJson(item)).toList();
    } else {
      throw Exception('Failed to load your items.');
    }
  }

  /// Updates an existing product.
Future<Product> updateItem(int id, ProductUpdateDto dto, {File? imageFile}) async {
  final headers = await _getAuthHeaders();
  final url = Uri.parse('$_baseUrl/item/$id');

  // Use Multipart for form-data
  final request = http.MultipartRequest("PUT", url);
  request.headers.addAll(headers);

  // Add text fields
  request.fields['name'] = dto.name;
    request.fields['description'] = dto.description;
    request.fields['price'] = dto.price.toString();
    request.fields['categoryId'] = dto.categoryId.toString();
    request.fields['location'] = dto.location;
    request.fields['availability'] = dto.availability.toString();

  // Add image file if selected
  if (imageFile != null) {
    request.files.add(await http.MultipartFile.fromPath("image", imageFile.path));
  }

  final streamedResponse = await request.send();
  final response = await http.Response.fromStream(streamedResponse);

  if (response.statusCode == 200) {
    return Product.fromJson(jsonDecode(response.body));
  } else {
    throw Exception('Failed to update product: ${response.body}');
  }
}

  /// Deletes a product by its ID.
  Future<void> deleteItem(int id) async {
    final headers = await _getAuthHeaders();
    final url = Uri.parse('$_baseUrl/item/$id');
    final response = await http.delete(url, headers: headers);
    if (response.statusCode != 204 && response.statusCode != 200) {
      throw Exception('Failed to delete product.');
    }
  }

    Future<void> trackView(int itemId) async {
    final url = Uri.parse("$_baseUrl/Item/$itemId/track-view");

    try {
      final response = await http.post(url);

      if (response.statusCode == 200) {
        if (kDebugMode) {
          print("View tracked successfully");
        }
      } else {
        if (kDebugMode) {
          print("Failed to track view: ${response.statusCode}");
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print("Error tracking view: $e");
      }
    }
  }
}
