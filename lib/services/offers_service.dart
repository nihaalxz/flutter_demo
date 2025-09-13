import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/Offer_DTO/OfferResponse_DTO.dart';
import '../environment/env.dart';
import 'auth_service.dart';

class OfferService {
  final String _baseUrl = AppConfig.ApibaseUrl;
  final AuthService _authService = AuthService();

  Future<Map<String, String>> _getAuthHeaders() async {
    final token = await _authService.getToken();
    if (token == null) throw Exception('User not authenticated.');
    return {
      'Content-Type': 'application/json; charset=UTF-8',
      'Authorization': 'Bearer $token',
    };
  }

  /// Creates a new offer for an item.
  Future<OfferResponseDTO> createOffer(int itemId, double offeredPrice) async {
    final headers = await _getAuthHeaders();
    final url = Uri.parse('$_baseUrl/Offer');
    final body = jsonEncode({
      'itemId': itemId,
      'offeredPrice': offeredPrice,
    });

    final response = await http.post(url, headers: headers, body: body);

    if (response.statusCode == 200) {
      return OfferResponseDTO.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to create offer: ${response.body}');
    }
  }

  /// Gets a list of offers made by the current user.
  Future<List<OfferResponseDTO>> getMyOffers() async {
    final headers = await _getAuthHeaders();
    final url = Uri.parse('$_baseUrl/Offer/my-offers');
    final response = await http.get(url, headers: headers);

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((json) => OfferResponseDTO.fromJson(json)).toList();
    } else {
      throw Exception('Failed to fetch your offers.');
    }
  }

  /// Gets a list of offers received for the current user's items.
  Future<List<OfferResponseDTO>> getReceivedOffers() async {
    final headers = await _getAuthHeaders();
    final url = Uri.parse('$_baseUrl/Offer/received-offers');
    final response = await http.get(url, headers: headers);

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((json) => OfferResponseDTO.fromJson(json)).toList();
    } else {
      throw Exception('Failed to fetch received offers.');
    }
  }

  /// Updates the status of an offer (Accepts or Rejects).
  Future<OfferResponseDTO> updateOfferStatus(int offerId, String status) async {
    final headers = await _getAuthHeaders();
    final url = Uri.parse('$_baseUrl/Offer/$offerId/status');
    final body = jsonEncode({'status': status});

    final response = await http.put(url, headers: headers, body: body);

    if (response.statusCode == 200) {
      return OfferResponseDTO.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to update offer status: ${response.body}');
    }
  }
}
