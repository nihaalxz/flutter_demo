import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:hive_flutter/hive_flutter.dart';
import '../models/product_model.dart';
import '../environment/env.dart';

class ProductService {
  final String _baseUrl = AppConfig.ApibaseUrl;
  final Box _cacheBox = Hive.box('p2p_cache');

  Future<List<Product>> fetchProducts({bool forceRefresh = false}) async {
    final cachedData = _cacheBox.get('cached_products');
    final cachedTimestamp = _cacheBox.get('products_cache_timestamp') ?? 0;
    final currentTime = DateTime.now().millisecondsSinceEpoch;

    // Cache is valid for 10 minutes
    if (!forceRefresh && cachedData != null && (currentTime - cachedTimestamp < 600000)) {
      print("Loading products from Hive cache...");
      return List<Product>.from(cachedData);
    }

    print("Fetching products from network...");
    final response = await http.get(Uri.parse('$_baseUrl/item'));

    if (response.statusCode == 200) {
      final List<dynamic> body = jsonDecode(response.body);
      final products = body.map((dynamic item) => Product.fromJson(item)).toList();
      
      // Save to Hive cache
      await _cacheBox.put('cached_products', products);
      await _cacheBox.put('products_cache_timestamp', currentTime);
      
      return products;
    } else {
      throw Exception('Failed to load products. Status code: ${response.statusCode}');
    }
  }
  
  // --- Other methods for single product actions ---
  
  final Map<String, String> _headers = {
    'Content-Type': 'application/json; charset=UTF-8',
  };

  Future<Product> fetchProductById(int id) async {
    final response = await http.get(Uri.parse('$_baseUrl/item/$id'));
    if (response.statusCode == 200) {
      return Product.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to load product with ID $id. Status code: ${response.statusCode}');
    }
  }

  Future<Product> createProduct(Product product) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/item'),
      headers: _headers,
      body: jsonEncode(product.toJson()),
    );
    if (response.statusCode == 201) {
      return Product.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to create product. Status code: ${response.statusCode}');
    }
  }

  Future<Product> updateProduct(int id, Product product) async {
    final response = await http.put(
      Uri.parse('$_baseUrl/item/$id'),
      headers: _headers,
      body: jsonEncode(product.toJson()),
    );
    if (response.statusCode == 200) {
      return Product.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to update product with ID $id. Status code: ${response.statusCode}');
    }
  }

  Future<void> deleteProduct(int id) async {
    final response = await http.delete(Uri.parse('$_baseUrl/item/$id'));
    if (response.statusCode != 204 && response.statusCode != 200) {
      throw Exception('Failed to delete product with ID $id. Status code: ${response.statusCode}');
    }
  }
}
