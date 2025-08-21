import 'dart:convert';
import 'package:http/http.dart' as http;

// --- Assumed Imports ---
import '../models/wishlist_item_model.dart'; // The new model
import '../environment/env.dart';    // For your base API URL
import 'auth_service.dart';   // For getting the auth token

class WishlistService {
  final String _baseUrl = AppConfig.ApibaseUrl;
  final AuthService _authService = AuthService();

  /// Fetches all items in the current user's wishlist.
  /// Corresponds to: [GET] /api/WishList
  Future<List<WishlistItemModel>> getWishlist() async {
    final token = await _authService.getToken();
    if (token == null) throw Exception('User not authenticated.');

    final uri = Uri.parse('$_baseUrl/WishList');
    final response = await http.get(uri, headers: {
      'Authorization': 'Bearer $token',
    });

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((item) => WishlistItemModel.fromJson(item)).toList();
    } else {
      throw Exception('Failed to load wishlist.');
    }
  }

  /// Adds an item to the user's wishlist.
  /// Corresponds to: [POST] /api/WishList
  Future<void> addToWishlist(int itemId) async {
    final token = await _authService.getToken();
    if (token == null) throw Exception('User not authenticated.');

    final uri = Uri.parse('$_baseUrl/WishList');
    
    final response = await http.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: json.encode({'itemId': itemId}),
    );

    if (response.statusCode == 200) return; // Success
    
    if (response.statusCode == 400) {
      throw Exception('Item is already in your wishlist.');
    } else {
      throw Exception('Failed to add item to wishlist.');
    }
  }

  /// Removes an item from the user's wishlist by its Item ID.
  /// Corresponds to: [DELETE] /api/WishList/{itemId}
  Future<void> removeFromWishlist(int itemId) async {
    final token = await _authService.getToken();
    if (token == null) throw Exception('User not authenticated.');

    final uri = Uri.parse('$_baseUrl/WishList/$itemId');
    final response = await http.delete(uri, headers: {
      'Authorization': 'Bearer $token',
    });

    if (response.statusCode == 200) return; // Success

    if (response.statusCode == 404) {
      throw Exception('Item not found in wishlist.');
    } else {
      throw Exception('Failed to remove item from wishlist.');
    }
  }
}