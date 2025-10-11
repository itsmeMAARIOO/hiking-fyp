import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:hikingapp/providers/profile_provider.dart';
import 'package:hikingapp/config/api_config.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

class ProfileController {
  final BuildContext context;
  ProfileController(this.context);

  String? userId;

  void setUserId(String id) {
    userId = id;
  }

  // Fetch user data including toggle settings
  Future<void> fetchUserData() async {
    if (userId == null) return;

    final provider = Provider.of<ProfileProvider>(context, listen: false);
    provider.isLoading = true;
    provider.notifyListeners();

    try {
      final url = Uri.parse("${ApiConfig.baseUrl}/users/$userId");
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        provider.setProfile(data);
      } else {
        debugPrint("❌ Failed to fetch user data: ${response.statusCode}");
      }
    } catch (e) {
      debugPrint("⚠️ Error fetching user data: $e");
    } finally {
      provider.isLoading = false;
      provider.notifyListeners();
    }
  }

  // Toggle setting and save to backend
  Future<void> toggleSetting(String key, bool value) async {
    final provider = Provider.of<ProfileProvider>(context, listen: false);

    // Update UI immediately
    provider.toggleSetting(key, value);

    if (userId == null) return;

    try {
      final url = Uri.parse("${ApiConfig.baseUrl}/users/update-setting");
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'userId': userId, 'key': key, 'value': value}),
      );

      if (response.statusCode != 200) {
        // Revert if backend fails
        provider.toggleSetting(key, !value);
      }
    } catch (e) {
      provider.toggleSetting(key, !value);
    }
  }
}
