// lib/services/auth_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:google_sign_in/google_sign_in.dart' as gsi;
import 'package:hikingapp/config/api_config.dart';

class AuthService {
  /// Signup
  static Future<Map<String, dynamic>> signup(
    String name,
    String email,
    String password, {
    String? dateOfBirth,
    String? gender,
    double? weightKg,
    double? heightCm,
    String? bloodType,
    List<String>? allergies,
    String? phone,
  }) async {
    try {
      final baseUrl = ApiConfig.baseUrl;
      final url = Uri.parse("$baseUrl/auth/signup");
      final Map<String, dynamic> payload = {
        "name": name,
        "email": email,
        "password": password,
      };
      if (phone != null) payload["phone"] = phone;
      if (dateOfBirth != null) payload["dateOfBirth"] = dateOfBirth;
      if (gender != null) payload["gender"] = gender;
      if (weightKg != null) payload["weightKg"] = weightKg;
      if (heightCm != null) payload["heightCm"] = heightCm;
      if (bloodType != null) payload["bloodType"] = bloodType;
      if (allergies != null) payload["allergies"] = allergies;

      final body = jsonEncode(payload);

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
      final baseUrl = ApiConfig.baseUrl;
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

  /// Send Google ID Token to Backend for Verification & Login
  static Future<Map<String, dynamic>> googleLogin(String idToken) async {
    try {
      final baseUrl =
          ApiConfig.baseUrl; // Ensure this is your Node.js backend URL
      final url = Uri.parse('$baseUrl/auth/google');

      print('🚀 Authenticating with Backend: $url');

      final response = await http
          .post(
            url,
            headers: {
              "Content-Type": "application/json",
              "Accept": "application/json",
            },
            body: jsonEncode({"idToken": idToken}),
          )
          .timeout(const Duration(seconds: 10));

      print('📥 Backend Response: ${response.statusCode} ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        return jsonDecode(response.body);
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['message'] ?? "Google Backend Login failed");
      }
    } catch (e) {
      print('❌ Backend Auth Error: $e');
      rethrow;
    }
  }

  /// Google Sign In (Client Side Only)
  static Future<Map<String, String>?> signInWithGoogle() async {
    try {
      final gsi.GoogleSignIn googleSignIn = gsi.GoogleSignIn(
        scopes: ['email', 'profile'],
        // This is the WEB Client ID required to get the `idToken` for the backend
        serverClientId:
            "557709030517-tq6a90j36no5slu8tbfc7aacntj86hop.apps.googleusercontent.com",
      );
      final gsi.GoogleSignInAccount? googleUser = await googleSignIn.signIn();

      if (googleUser != null) {
        // Essential: Retrieve the authentication details (idToken)
        final gsi.GoogleSignInAuthentication googleAuth =
            await googleUser.authentication;

        // Print token for debugging (remove in production)
        print('🆔 Google ID Token: ${googleAuth.idToken}');

        return {
          'name': googleUser.displayName ?? '',
          'email': googleUser.email,
          'idToken': googleAuth.idToken ?? '',
        };
      }
      return null;
    } catch (e) {
      print('❌ Google Sign In Error: $e');
      return null;
    }
  }

  /// Test connection to server
  static Future<bool> testConnection() async {
    try {
      final baseUrl = ApiConfig.baseUrl;
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

  static Future<Map<String, dynamic>> requestPasswordReset(String email) async {
    try {
      final baseUrl = ApiConfig.baseUrl;
      final url = Uri.parse('$baseUrl/auth/forgot-password');
      final response = await http
          .post(
            url,
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode({'email': email}),
          )
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () => throw Exception(
              'Connection timeout - please check if server is running',
            ),
          );
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['message'] ?? 'Failed to send reset email');
      }
    } catch (e) {
      rethrow;
    }
  }

  static Future<Map<String, dynamic>> resetPassword(
    String token,
    String newPassword,
  ) async {
    try {
      final baseUrl = ApiConfig.baseUrl;
      final url = Uri.parse('$baseUrl/auth/reset-password');
      final response = await http
          .post(
            url,
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode({'token': token, 'password': newPassword}),
          )
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () => throw Exception(
              'Connection timeout - please check if server is running',
            ),
          );
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['message'] ?? 'Reset failed');
      }
    } catch (e) {
      rethrow;
    }
  }
}
