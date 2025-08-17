import 'dart:convert';
import 'package:google_sign_in/google_sign_in.dart' as googleSignIn; // Prefixed import
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../environment/env.dart';

class AuthService {
  final String _baseUrl = AppConfig.ApibaseUrl;
  final _storage = const FlutterSecureStorage();
  // Use type inference to simplify the constructor call
  final _googleSignIn = googleSignIn.GoogleSignIn();

  // --- Token Management ---

  Future<void> saveToken(String token) async {
    await _storage.write(key: 'jwt_token', value: token);
  }

  Future<String?> getToken() async {
    return await _storage.read(key: 'jwt_token');
  }

  Future<void> deleteToken() async {
    await _storage.delete(key: 'jwt_token');
  }

  // --- API Methods ---

  Future<bool> register(String fullName, String email, String phoneNumber, String password) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/Auth/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'fullName': fullName,
        'emailAddress': email,
        'phoneNumber': phoneNumber,
        'password': password,
      }),
    );
    return response.statusCode == 200;
  }

  Future<bool> login(String email, String password) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/Auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'emailAddress': email,
        'password': password,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      await saveToken(data['token']);
      return true;
    }
    return false;
  }

  Future<bool> googleLogin() async {
    try {
      // Use the prefixed types
      final googleSignIn.GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        // The user canceled the sign-in
        return false;
      }

      final googleSignIn.GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final String? idToken = googleAuth.idToken;

      if (idToken == null) {
        return false;
      }

      final response = await http.post(
        Uri.parse('$_baseUrl/Auth/google-login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(idToken), // Your backend expects the token as a JSON string
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        await saveToken(data['token']);
        return true;
      }
      return false;
    } catch (e) {
      print("Google Sign-In Error: $e");
      return false;
    }
  }

  Future<void> logout() async {
    await _googleSignIn.signOut();
    await deleteToken();
  }

  Future<bool> forgotPassword(String email) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/Auth/forgot-password'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'emailAddress': email}),
    );
    return response.statusCode == 200;
  }
}
