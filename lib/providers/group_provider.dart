// lib/providers/group_provider.dart
import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:hikingapp/config/api_config.dart';
import 'package:hikingapp/data/models/group_model.dart';
import 'package:http/http.dart' as http;

/// Provider for managing group activities, locations, and member updates.
class GroupProvider with ChangeNotifier {
  final String baseUrl = "${ApiConfig.baseUrl}/group";

  bool _isLoading = false;
  Map<String, dynamic>? _activeGroup;
  List<GroupMember> _nearbyMembers = [];
  Timer? _locationTimer;
  String? _lastError;
  bool _isUpdatingLocation = false;

  bool get isLoading => _isLoading;
  Map<String, dynamic>? get activeGroup => _activeGroup;
  List<GroupMember> get nearbyMembers => _nearbyMembers;
  String? get lastError => _lastError;

  // ----------------------------
  // ✅ Utility: Get current GPS position safely
  // ----------------------------
  Future<Position?> _getCurrentPosition() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _lastError = "Location services are disabled";
        return null;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _lastError = "Location permission denied";
          return null;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        _lastError = "Location permission permanently denied";
        return null;
      }

      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.best,
      );
    } catch (e) {
      _lastError = "Error getting location: $e";
      debugPrint("❌ Location error: $e");
      return null;
    }
  }

  // ----------------------------
  // ✅ Create a new group
  // ----------------------------
  Future<void> createGroup({
    required String groupName,
    required String createdBy,
    required String creatorName,
    String? trailName,
    List<GroupMember>? invitedMembers,
  }) async {
    _isLoading = true;
    _lastError = null;
    notifyListeners();

    try {
      final membersData = invitedMembers
          ?.map(
            (m) => {
              'userId': m.userId,
              'name': m.name,
              'latitude': m.latitude,
              'longitude': m.longitude,
              'role': 'member',
              'status': 'invited',
            },
          )
          .toList();

      final response = await http.post(
        Uri.parse('$baseUrl/create-group'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'groupName': groupName,
          'createdBy': createdBy,
          'creatorName': creatorName,
          'trailName': trailName ?? "Unnamed Trail",
          'invitedMembers': membersData ?? [],
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _activeGroup = data['group'];
        _lastError = null;
        debugPrint("✅ Group created: ${_activeGroup!['groupName']}");
      } else {
        _lastError = "Failed to create group (${response.statusCode})";
        debugPrint("❌ Failed to create group: ${response.body}");
      }
    } catch (e) {
      _lastError = "Network error: $e";
      debugPrint("❌ Error: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ----------------------------
  // ✅ Update member location
  // ----------------------------
  Future<void> updateMyLocation({
    required String groupId,
    required String userId,
    required String userName,
  }) async {
    if (_isUpdatingLocation) return; // prevent overlapping requests
    _isUpdatingLocation = true;

    final pos = await _getCurrentPosition();
    if (pos == null) {
      _isUpdatingLocation = false;
      debugPrint("⚠️ Location unavailable");
      notifyListeners();
      return;
    }

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/update-location'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'groupId': groupId,
          'userId': userId,
          'name': userName,
          'latitude': pos.latitude,
          'longitude': pos.longitude,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _activeGroup = data['group'];
        _lastError = null;
        debugPrint("📍 Updated location: ${pos.latitude}, ${pos.longitude}");
      } else {
        _lastError = "Failed to update location (${response.statusCode})";
      }
    } catch (e) {
      _lastError = "Network error while updating location: $e";
    } finally {
      _isUpdatingLocation = false;
      notifyListeners();
    }
  }

  // ----------------------------
  // ✅ Start auto location updates
  // ----------------------------
  void startLocationUpdates({
    required String groupId,
    required String userId,
    required String userName,
  }) {
    stopLocationUpdates(); // ensure only one timer exists

    updateMyLocation(groupId: groupId, userId: userId, userName: userName);
    _locationTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      updateMyLocation(groupId: groupId, userId: userId, userName: userName);
    });

    debugPrint("🔄 Started location updates every 30s");
  }

  // ----------------------------
  // ✅ Stop location updates
  // ----------------------------
  void stopLocationUpdates() {
    _locationTimer?.cancel();
    _locationTimer = null;
    debugPrint("⏸️ Stopped location updates");
  }

  // ----------------------------
  // ✅ Fetch nearby hikers
  // ----------------------------
  Future<void> fetchNearbyMembers({String? excludeUserId}) async {
    final pos = await _getCurrentPosition();
    if (pos == null) {
      notifyListeners();
      return;
    }

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/nearby'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'latitude': pos.latitude,
          'longitude': pos.longitude,
          'radius': 1.5,
          'excludeUserId': excludeUserId,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final hikers = (data['hikers'] ?? []) as List;
        _nearbyMembers = hikers
            .map((m) => GroupMember.fromJson(m))
            .toList(growable: false);
        _lastError = null;
        debugPrint("👣 Found ${_nearbyMembers.length} nearby hikers");
      } else {
        _lastError = "Failed to fetch nearby hikers";
      }
    } catch (e) {
      _lastError = "Network error: $e";
    }

    notifyListeners();
  }

  // ----------------------------
  // ✅ Leave group safely
  // ----------------------------
  Future<void> leaveGroup(String userId) async {
    if (_activeGroup == null) return;

    _isLoading = true;
    notifyListeners();

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/leave-group'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'groupId': _activeGroup!['_id'], 'userId': userId}),
      );

      if (response.statusCode == 200) {
        stopLocationUpdates();
        _activeGroup = null;
        _nearbyMembers = [];
        _lastError = null;
        debugPrint("👋 Left group successfully");
      } else {
        _lastError = "Failed to leave group";
      }
    } catch (e) {
      _lastError = "Network error: $e";
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ----------------------------
  // ✅ fetch group by id for invited user
  // ----------------------------
  // Add this method to your GroupProvider class

  Future<void> fetchGroupById(String groupId) async {
    try {
      _isLoading = true;
      notifyListeners();

      final response = await http.get(
        Uri.parse('$baseUrl/groups/$groupId'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _activeGroup = data['group'];
        notifyListeners();
      } else {
        throw Exception('Failed to fetch group: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching group: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ----------------------------
  // ✅ End trail (creator only - ends for all members)
  // ----------------------------
  Future<bool> endTrail(String userId) async {
    if (_activeGroup == null) {
      _lastError = "No active group";
      return false;
    }

    _isLoading = true;
    notifyListeners();

    try {
      debugPrint("🔄 Attempting to end trail...");
      debugPrint("   Group ID: ${_activeGroup!['_id']}");
      debugPrint("   User ID: $userId");

      final response = await http.post(
        Uri.parse('$baseUrl/end-trail'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'groupId': _activeGroup!['_id'], 'userId': userId}),
      );

      debugPrint("   Response status: ${response.statusCode}");
      debugPrint("   Response body: ${response.body}");

      if (response.statusCode == 200) {
        stopLocationUpdates();
        final data = jsonDecode(response.body);
        _activeGroup = data['group']; // keep updated group to expose completed status
        _nearbyMembers = [];
        _lastError = null;
        debugPrint("🏁 Trail completed successfully for all members");
        return true;
      } else if (response.statusCode == 403) {
        _lastError = "Only the creator can end the trail";
        debugPrint("❌ Not authorized to end trail");
        return false;
      } else {
        final errorData = jsonDecode(response.body);
        _lastError = errorData['error'] ?? "Failed to end trail";
        debugPrint("❌ Failed to end trail: $_lastError");
        return false;
      }
    } catch (e) {
      _lastError = "Network error: $e";
      debugPrint("❌ Exception while ending trail: $e");
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ----------------------------
  // ✅ Misc utilities
  // ----------------------------
  void clearError() {
    _lastError = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _locationTimer?.cancel();
    super.dispose();
  }
}
