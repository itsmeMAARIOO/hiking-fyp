import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:hikingapp/providers/profile_provider.dart';
import 'package:hikingapp/providers/auth_provider.dart';
import 'package:hikingapp/config/api_config.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:hikingapp/services/history_service.dart';
import 'package:provider/provider.dart';
import 'package:hikingapp/services/weather_alert_service.dart';

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

  Future<void> addEmergencyContact({
    required String name,
    required String email,
    required String phone,
  }) async {
    if (userId == null) return;
    final provider = Provider.of<ProfileProvider>(context, listen: false);
    try {
      final url = Uri.parse(
        "${ApiConfig.baseUrl}/users/emergency-contacts/add",
      );
      final resp = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "userId": userId,
          "contact": {"name": name, "email": email, "phone": phone},
        }),
      );
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body) as Map<String, dynamic>;
        final list = (data['emergencyContacts'] as List<dynamic>? ?? []);
        provider.emergencyContacts = list
            .map(
              (c) => {
                'name': (c['name'] ?? '').toString(),
                'email': (c['email'] ?? '').toString(),
                'phone': (c['phone'] ?? '').toString(),
                'share': ((c['share'] ?? false) as bool).toString(),
              },
            )
            .toList();
        provider.notifyListeners();
      }
    } catch (_) {}
  }

  Future<void> removeEmergencyContact(int index) async {
    if (userId == null) return;
    final provider = Provider.of<ProfileProvider>(context, listen: false);
    try {
      final url = Uri.parse(
        "${ApiConfig.baseUrl}/users/emergency-contacts/remove",
      );
      final resp = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"userId": userId, "index": index}),
      );
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body) as Map<String, dynamic>;
        final list = (data['emergencyContacts'] as List<dynamic>? ?? []);
        provider.emergencyContacts = list
            .map(
              (c) => {
                'name': (c['name'] ?? '').toString(),
                'email': (c['email'] ?? '').toString(),
                'phone': (c['phone'] ?? '').toString(),
                'share': ((c['share'] ?? false) as bool).toString(),
              },
            )
            .toList();
        provider.notifyListeners();
      }
    } catch (_) {}
  }

  Future<bool> toggleContactShare(int index, bool share) async {
    if (userId == null) return false;
    final provider = Provider.of<ProfileProvider>(context, listen: false);
    try {
      final url = Uri.parse(
        "${ApiConfig.baseUrl}/users/emergency-contacts/share-toggle",
      );
      final resp = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"userId": userId, "index": index, "share": share}),
      );
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body) as Map<String, dynamic>;
        final list = (data['emergencyContacts'] as List<dynamic>? ?? []);
        provider.emergencyContacts = list
            .map(
              (c) => {
                'name': (c['name'] ?? '').toString(),
                'email': (c['email'] ?? '').toString(),
                'phone': (c['phone'] ?? '').toString(),
                'share': ((c['share'] ?? false) as bool).toString(),
              },
            )
            .toList();
        provider.notifyListeners();
        return true;
      }
    } catch (_) {}
    return false;
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
        debugPrint(
          "❌ Failed to fetch group hike count: ${groupResp.statusCode}",
        );
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
        debugPrint(
          "❌ Failed to fetch combined hike counts: ${resp.statusCode}",
        );
      }
    } catch (e) {
      debugPrint("⚠️ Error fetching combined hike counts: $e");
    }
  }

  Future<void> loadHikingStats(String filter) async {
    if (userId == null) return;
    final provider = Provider.of<ProfileProvider>(context, listen: false);
    try {
      final solo = await HistoryService.fetchSoloHistory(userId!);
      final group = await HistoryService.fetchGroupHistory(userId!);

      final years = _extractYears([...solo, ...group]);
      final effectiveYear = filter == 'Year'
          ? (provider.selectedYear ?? DateTime.now().year)
          : null;
      final soloAgg = _aggregate(
        solo,
        filter,
        isGroup: false,
        year: effectiveYear,
      );
      final groupAgg = _aggregate(
        group,
        filter,
        isGroup: true,
        year: effectiveYear,
      );

      provider.setHikingStats(
        solo: soloAgg,
        group: groupAgg,
        soloTotal: soloAgg.fold<int>(0, (sum, p) => sum + (p['y'] as int)),
        groupTotal: groupAgg.fold<int>(0, (sum, p) => sum + (p['y'] as int)),
        years: years,
        year: effectiveYear,
      );
    } catch (e) {
      // ignore for now
    }
  }

  List<Map<String, dynamic>> _aggregate(
    List<Map<String, dynamic>> raw,
    String filter, {
    required bool isGroup,
    int? year,
  }) {
    DateTime? extractEnd(Map<String, dynamic> item) {
      try {
        if (isGroup) {
          final endRaw = item['activeTrail']?['endTime'];
          if (endRaw is String) return DateTime.parse(endRaw).toLocal();
          if (endRaw is Map && endRaw['\$date'] != null) {
            final d = endRaw['\$date'];
            if (d is Map && d['\$numberLong'] != null) {
              return DateTime.fromMillisecondsSinceEpoch(
                int.parse(d['\$numberLong'] as String),
              ).toLocal();
            }
          }
        } else {
          final endRaw = item['endTime'] ?? item['startTime'];
          if (endRaw is String) return DateTime.parse(endRaw).toLocal();
        }
      } catch (_) {}
      return null;
    }

    final now = DateTime.now();
    final Map<String, int> bucketCounts = {};
    String keyFor(DateTime d) {
      switch (filter) {
        case 'Year':
          return DateFormat('yyyy-MM').format(DateTime(d.year, d.month));
        case 'All time':
          return DateFormat('yyyy').format(DateTime(d.year));
        case 'Month':
        default:
          return DateFormat(
            'yyyy-MM-dd',
          ).format(DateTime(d.year, d.month, d.day));
      }
    }

    String labelFor(String key) {
      switch (filter) {
        case 'Year':
          final dt = DateTime.parse('$key-01');
          return DateFormat('MMM').format(dt);
        case 'All time':
          return key;
        case 'Month':
        default:
          final dt = DateTime.parse(key);
          return DateFormat('d MMM').format(dt);
      }
    }

    for (final item in raw) {
      final d = extractEnd(item);
      if (d == null) continue;
      if (filter == 'Year' && year != null && d.year != year) continue;
      final k = keyFor(d);
      bucketCounts[k] = (bucketCounts[k] ?? 0) + 1;
    }

    List<String> orderedKeys;
    if (filter == 'Month') {
      orderedKeys = List.generate(30, (i) {
        final d = now.subtract(Duration(days: 29 - i));
        return keyFor(d);
      });
    } else if (filter == 'Year') {
      final targetYear = year ?? now.year;
      orderedKeys = List.generate(12, (i) {
        final d = DateTime(targetYear, i + 1, 1);
        return keyFor(d);
      });
    } else {
      final years = bucketCounts.keys.toSet().toList()..sort();
      orderedKeys = years;
    }

    final points = <Map<String, dynamic>>[];
    for (var i = 0; i < orderedKeys.length; i++) {
      final k = orderedKeys[i];
      final y = bucketCounts[k] ?? 0;
      points.add({'x': i.toDouble(), 'y': y, 'label': labelFor(k)});
    }
    return points;
  }

  List<int> _extractYears(List<Map<String, dynamic>> raw) {
    final s = <int>{};
    DateTime? extractEnd(Map<String, dynamic> item) {
      try {
        final endRaw =
            item['activeTrail']?['endTime'] ??
            item['endTime'] ??
            item['startTime'];
        if (endRaw is String) return DateTime.parse(endRaw).toLocal();
        if (endRaw is Map && endRaw['\$date'] != null) {
          final d = endRaw['\$date'];
          if (d is Map && d['\$numberLong'] != null) {
            return DateTime.fromMillisecondsSinceEpoch(
              int.parse(d['\$numberLong'] as String),
            ).toLocal();
          }
        }
      } catch (_) {}
      return null;
    }

    for (final item in raw) {
      final d = extractEnd(item);
      if (d != null) s.add(d.year);
    }
    final list = s.toList()..sort();
    return list.reversed.toList();
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

    if (key == 'weatherAlerts') {
      if (value) {
        await WeatherAlertService.enable();
      } else {
        await WeatherAlertService.disable();
      }
    }
  }

  // Fetch latest hike counts directly for UI display
  Future<Map<String, int>> loadHikeCountsLatest() async {
    final profileProvider = Provider.of<ProfileProvider>(
      context,
      listen: false,
    );
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final effectiveUserId =
        userId ?? authProvider.userId ?? profileProvider.userId;
    if (effectiveUserId == null) {
      return {
        'solo': profileProvider.totalSoloHikes,
        'group': profileProvider.totalGroupHikes,
      };
    }

    try {
      final url = Uri.parse(
        "${ApiConfig.baseUrl}/users/hike-counts/$effectiveUserId",
      );
      final resp = await http.get(url);
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body) as Map<String, dynamic>;
        final sc = data['totalSoloHikes'];
        final gc = data['totalGroupHikes'];
        final soloCount = sc is num ? sc.toInt() : int.tryParse('$sc') ?? 0;
        final groupCount = gc is num ? gc.toInt() : int.tryParse('$gc') ?? 0;
        return {'solo': soloCount, 'group': groupCount};
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
