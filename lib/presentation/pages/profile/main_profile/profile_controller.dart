import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:hikingapp/providers/profile_provider.dart';
import 'package:hikingapp/providers/auth_provider.dart';
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

        // Also fetch hike counts for solo and group
        await fetchHikeCounts();
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

  Future<void> fetchHikeCounts() async {
    if (userId == null) return;

    final provider = Provider.of<ProfileProvider>(context, listen: false);

    try {
      // Solo hikes count
      final soloUrl = Uri.parse("${ApiConfig.baseUrl}/solo/count/$userId");
      final soloResp = await http.get(soloUrl);
      if (soloResp.statusCode == 200) {
        final soloData = jsonDecode(soloResp.body) as Map<String, dynamic>;
        final sc = soloData['totalSoloHikes'];
        final soloCount = sc is num ? sc.toInt() : int.tryParse('$sc') ?? 0;
        provider.setSoloHikeCount(soloCount);
      } else {
        debugPrint("❌ Failed to fetch solo hike count: ${soloResp.statusCode}");
      }

      // Group hikes count
      final groupUrl = Uri.parse("${ApiConfig.baseUrl}/group/count/$userId");
      final groupResp = await http.get(groupUrl);
      if (groupResp.statusCode == 200) {
        final groupData = jsonDecode(groupResp.body) as Map<String, dynamic>;
        final gc = groupData['totalGroupHikes'];
        final groupCount = gc is num ? gc.toInt() : int.tryParse('$gc') ?? 0;
        provider.setGroupHikeCount(groupCount);
      } else {
        debugPrint("❌ Failed to fetch group hike count: ${groupResp.statusCode}");
      }
    } catch (e) {
      debugPrint("⚠️ Error fetching hike counts: $e");
    }
  }

  // Fetch both counts via a single combined API
  Future<void> fetchHikeCountsCombined() async {
    if (userId == null) return;

    final provider = Provider.of<ProfileProvider>(context, listen: false);

    try {
      final url = Uri.parse("${ApiConfig.baseUrl}/users/hike-counts/$userId");
      final resp = await http.get(url);
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body) as Map<String, dynamic>;

        final sc = data['totalSoloHikes'];
        final gc = data['totalGroupHikes'];

        final soloCount = sc is num ? sc.toInt() : int.tryParse('$sc') ?? 0;
        final groupCount = gc is num ? gc.toInt() : int.tryParse('$gc') ?? 0;

        provider.setSoloHikeCount(soloCount);
        provider.setGroupHikeCount(groupCount);
      } else {
        debugPrint("❌ Failed to fetch combined hike counts: ${resp.statusCode}");
      }
    } catch (e) {
      debugPrint("⚠️ Error fetching combined hike counts: $e");
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

  // Fetch latest hike counts directly for UI display
  Future<Map<String, int>> loadHikeCountsLatest() async {
    final profileProvider = Provider.of<ProfileProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final effectiveUserId = userId ?? authProvider.userId ?? profileProvider.userId;
    if (effectiveUserId == null) {
      return {
        'solo': profileProvider.totalSoloHikes,
        'group': profileProvider.totalGroupHikes,
      };
    }

    try {
      final url = Uri.parse("${ApiConfig.baseUrl}/users/hike-counts/$effectiveUserId");
      final resp = await http.get(url);
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body) as Map<String, dynamic>;
        final sc = data['totalSoloHikes'];
        final gc = data['totalGroupHikes'];
        final soloCount = sc is num ? sc.toInt() : int.tryParse('$sc') ?? 0;
        final groupCount = gc is num ? gc.toInt() : int.tryParse('$gc') ?? 0;
        return {
          'solo': soloCount,
          'group': groupCount,
        };
      } else {
        debugPrint("❌ Failed to fetch latest hike counts: ${resp.statusCode}");
        return {
          'solo': profileProvider.totalSoloHikes,
          'group': profileProvider.totalGroupHikes,
        };
      }
    } catch (e) {
      debugPrint("⚠️ Error fetching latest hike counts: $e");
      return {
        'solo': profileProvider.totalSoloHikes,
        'group': profileProvider.totalGroupHikes,
      };
    }
  }
}
