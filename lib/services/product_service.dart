import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:hive/hive.dart';
import '../environment/env.dart';
import '../models/product_model.dart';

class ProductService {
  final String _baseUrl = AppConfig.ApibaseUrl;

  final Map<String, String> _headers = {
    'Content-Type': 'application/json; charset=UTF-8',
    // 'Authorization': 'Bearer YOUR_AUTH_TOKEN',
  };

  final Box _cacheBox = Hive.box('products'); // Hive box for caching

  /// Fetch all products (cache + API)
  Future<List<Product>> fetchProducts({bool forceRefresh = false}) async {
    // 1️⃣ Load from cache if available
    if (!forceRefresh) {
      final cachedData = _cacheBox.get('list');
      if (cachedData != null) {
        final List<dynamic> jsonList = jsonDecode(cachedData);
        final products = jsonList.map((e) => Product.fromJson(e)).toList();

        // Refresh in background
        _fetchProductsFromApiAndCache();

        return products;
      }
    }

    // 2️⃣ If no cache or force refresh, fetch from API
    return await _fetchProductsFromApiAndCache();
  }

  /// Internal: fetch from API and store in cache
  Future<List<Product>> _fetchProductsFromApiAndCache() async {
    final response = await http.get(Uri.parse('$_baseUrl/item'));

    if (response.statusCode == 200) {
      List<dynamic> body = jsonDecode(response.body);
      List<Product> products = body.map((dynamic item) => Product.fromJson(item)).toList();

      // Save to Hive cache
      _cacheBox.put('list', jsonEncode(products.map((p) => p.toJson()).toList()));

      return products;
    } else {
      throw Exception('Failed to load products. Status code: ${response.statusCode}');
    }
  }

  /// Fetch single product by ID
  Future<Product> fetchProductById(int id) async {
    final response = await http.get(Uri.parse('$_baseUrl/item/$id'));

    if (response.statusCode == 200) {
      return Product.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to load product with ID $id. Status code: ${response.statusCode}');
    }
  }

  

  /// Create new product
  Future<Product> createProduct(Product product) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/item'),
      headers: _headers,
      body: jsonEncode({
        'name': product.name,
        'description': product.description,
        'image': product.image,
        'price': product.price,
        'categoryId': product.categoryId,
        'ownerProfileImage': product.ownerProfileImage,
        'categoryName': product.categoryName,
        'ownerId': product.ownerId,
        'ownerName': product.ownerName,
        'location': product.location,
        'availability': product.availability,
        'status': product.status,
        'views': product.views,
      }),
    );

    if (response.statusCode == 201) {
      // Invalidate cache after creating
      _cacheBox.delete('list');
      return Product.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to create product. Status code: ${response.statusCode}');
    }
  }

  /// Update existing product
  Future<Product> updateProduct(int id, Product product) async {
    final response = await http.put(
      Uri.parse('$_baseUrl/item/$id'),
      headers: _headers,
      body: jsonEncode({
        'id': product.id,
        'name': product.name,
        'description': product.description,
        'image': product.image,
        'price': product.price,
        'categoryId': product.categoryId,
        'ownerProfileImage': product.ownerProfileImage,
        'categoryName': product.categoryName,
        'ownerId': product.ownerId,
        'ownerName': product.ownerName,
        'location': product.location,
        'availability': product.availability,
        'createdAt': product.createdAt,
        'status': product.status,
        'views': product.views,
      }),
    );

    if (response.statusCode == 200) {
      // Invalidate cache after updating
      _cacheBox.delete('list');
      return Product.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to update product with ID $id. Status code: ${response.statusCode}');
    }
  }

  /// Delete a product
  Future<void> deleteProduct(int id) async {
    final response = await http.delete(
      Uri.parse('$_baseUrl/item/$id'),
      headers: _headers,
    );

    if (response.statusCode == 204 || response.statusCode == 200) {
      // Invalidate cache after deletion
      _cacheBox.delete('list');
    } else {
      throw Exception('Failed to delete product with ID $id. Status code: ${response.statusCode}');
    }
  }

  /// Force refresh products from API (useful for pull-to-refresh)
  Future<List<Product>> refreshProducts() async {
    return await _fetchProductsFromApiAndCache();
  }
}
