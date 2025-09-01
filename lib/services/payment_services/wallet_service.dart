import 'dart:convert';
import 'package:http/http.dart' as http;

// --- Assumed Imports ---
import 'package:myfirstflutterapp/environment/env.dart';
import 'package:myfirstflutterapp/models/wallet_DTO/wallet_view.dart';
import 'package:myfirstflutterapp/models/wallet_DTO/withdrawal_request.dart';
import 'package:myfirstflutterapp/services/auth_service.dart';

class WalletService {
  // Centralized API path for the wallet controller
  final String _walletApiUrl = "${AppConfig.ApibaseUrl}/wallet";
  final AuthService _authService = AuthService();

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

  /// Fetches the user's complete wallet view (balances and transactions).
  /// This correctly calls the GET /api/wallet endpoint.
  Future<WalletView> getWallet() async {
    final headers = await _getAuthHeaders();
    final url = Uri.parse(_walletApiUrl);
    final response = await http.get(url, headers: headers);

    if (response.statusCode == 200) {
      // The response is a single JSON object containing the WalletView data.
      return WalletView.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to load wallet data.');
    }
  }

  /// Submits a request to withdraw funds.
  Future<void> requestWithdrawal(WithdrawalRequest withdrawalRequest) async {
    final headers = await _getAuthHeaders();
    final url = Uri.parse("$_walletApiUrl/withdraw");
    
    final response = await http.post(
      url,
      headers: headers,
      body: jsonEncode(withdrawalRequest.toJson()),
    );

    if (response.statusCode != 200 && response.statusCode != 204) {
      // Try to parse a more detailed error message from the backend
      try {
        final errorBody = jsonDecode(response.body);
        throw Exception(errorBody['message'] ?? 'Failed to make withdrawal request.');
      } catch (_) {
         throw Exception('Failed to make withdrawal request: ${response.body}');
      }
    }
  }
}
