// lib/services/api_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:hikingapp/config/api_config.dart';

class ApiService {
  /// Base URL is dynamic, read from ApiConfig
  static String get baseUrl => ApiConfig.baseUrl;

  /// Signup
  static Future<Map<String, dynamic>> signup(
    String name,
    String email,
    String password,
  ) async {
    try {
      final url = Uri.parse("$baseUrl/auth/signup");
      final body = jsonEncode({
        "name": name,
        "email": email,
        "password": password,
      });

      print('🚀 Making request to: $url');
      print('📤 Request body: $body');

      final response = await http
          .post(
            url,
            headers: {
              "Content-Type": "application/json",
              "Accept": "application/json",
            },
            body: body,
          )
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () => throw Exception(
              'Connection timeout - please check if server is running',
            ),
          );

      print('📥 Response status: ${response.statusCode}');
      print('📥 Response body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        return jsonDecode(response.body);
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['message'] ?? "Signup failed");
      }
    } catch (e) {
      print('❌ API Signup Error: $e');
      rethrow;
    }
  }

  /// Login
  static Future<Map<String, dynamic>> login(
    String email,
    String password,
  ) async {
    try {
      final url = Uri.parse('$baseUrl/auth/login');

      print('🚀 Making request to: $url');

      final response = await http
          .post(
            url,
            headers: {
              "Content-Type": "application/json",
              "Accept": "application/json",
            },
            body: jsonEncode({"email": email, "password": password}),
          )
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () => throw Exception(
              'Connection timeout - please check if server is running',
            ),
          );

      print('📥 Login response status: ${response.statusCode}');
      print('📥 Login response body: ${response.body}');

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['message'] ?? "Login failed");
      }
    } catch (e) {
      print('❌ Login API Error: $e');
      rethrow;
    }
  }

  /// Test connection to server
  static Future<bool> testConnection() async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/'), headers: {"Accept": "application/json"})
          .timeout(const Duration(seconds: 5));

      print('🔍 Server test response: ${response.statusCode}');
      return response.statusCode == 200;
    } catch (e) {
      print('❌ Server connection test failed: $e');
      return false;
    }
  }
}
