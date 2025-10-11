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
  // ✅ Accept / Decline Invitations
  // ----------------------------
  Future<bool> acceptInvitation({
    required String groupId,
    required String userId,
  }) async {
    return _handleInvitation(groupId, userId, true);
  }

  Future<bool> declineInvitation({
    required String groupId,
    required String userId,
  }) async {
    return _handleInvitation(groupId, userId, false);
  }

  Future<bool> _handleInvitation(
    String groupId,
    String userId,
    bool accept,
  ) async {
    final endpoint = accept ? 'accept-invitation' : 'decline-invitation';
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/$endpoint'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'groupId': groupId, 'userId': userId}),
      );

      if (response.statusCode == 200) {
        debugPrint(accept ? "✅ Invitation accepted" : "🚫 Invitation declined");
        if (accept) {
          final data = jsonDecode(response.body);
          _activeGroup = data['group'];
        }
        return true;
      } else {
        debugPrint("❌ Failed to handle invitation: ${response.body}");
        return false;
      }
    } catch (e) {
      debugPrint("❌ Network error: $e");
      return false;
    } finally {
      notifyListeners();
    }
  }

  // ----------------------------
  // ✅ Fetch active group details
  // ----------------------------
  Future<void> fetchActiveGroup(String groupId) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/group/$groupId'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _activeGroup = data['group'];
        _lastError = null;
        debugPrint("✅ Active group loaded: ${_activeGroup!['groupName']}");
      } else {
        _lastError = "Failed to fetch group";
      }
    } catch (e) {
      _lastError = "Network error: $e";
    } finally {
      _isLoading = false;
      notifyListeners();
    }
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
  // ✅ Emergency alert (UI only)
  // ----------------------------
  void sendGroupAlert(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            Icon(Icons.warning_amber, color: Colors.white),
            SizedBox(width: 8),
            Text('⚠️ Emergency alert sent to your trail group!'),
          ],
        ),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
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

// // lib/providers/group_provider.dart
// import 'dart:async';
// import 'dart:convert';
// import 'package:flutter/material.dart';
// import 'package:geolocator/geolocator.dart';
// import 'package:hikingapp/config/api_config.dart';
// import 'package:hikingapp/data/models/group_model.dart';
// import 'package:http/http.dart' as http;

// class GroupProvider with ChangeNotifier {
//   final String baseUrl = "${ApiConfig.baseUrl}/group";

//   bool _isLoading = false;
//   Map<String, dynamic>? _activeGroup;
//   List<GroupMember> _nearbyMembers = [];
//   Timer? _locationTimer;
//   String? _lastError;

//   bool get isLoading => _isLoading;
//   Map<String, dynamic>? get activeGroup => _activeGroup;
//   List<GroupMember> get nearbyMembers => _nearbyMembers;
//   String? get lastError => _lastError;

//   /// Get current GPS position
//   Future<Position?> _getCurrentPosition() async {
//     try {
//       bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
//       if (!serviceEnabled) {
//         _lastError = "Location services are disabled";
//         return null;
//       }

//       LocationPermission permission = await Geolocator.checkPermission();
//       if (permission == LocationPermission.denied) {
//         permission = await Geolocator.requestPermission();
//         if (permission == LocationPermission.denied) {
//           _lastError = "Location permission denied";
//           return null;
//         }
//       }

//       if (permission == LocationPermission.deniedForever) {
//         _lastError = "Location permission permanently denied";
//         return null;
//       }

//       return await Geolocator.getCurrentPosition(
//         desiredAccuracy: LocationAccuracy.high,
//       );
//     } catch (e) {
//       _lastError = "Error getting location: $e";
//       debugPrint("❌ Location error: $e");
//       return null;
//     }
//   }

//   /// Create Group with invited members
//   Future<void> createGroup({
//     required String groupName,
//     required String createdBy,
//     required String creatorName,
//     String? trailName,
//     List<GroupMember>? invitedMembers,
//   }) async {
//     _isLoading = true;
//     _lastError = null;
//     notifyListeners();

//     try {
//       // Prepare invited members data
//       final List<Map<String, dynamic>> membersData = [];

//       if (invitedMembers != null && invitedMembers.isNotEmpty) {
//         for (var member in invitedMembers) {
//           membersData.add({
//             'userId': member.userId,
//             'name': member.name,
//             'latitude': member.latitude,
//             'longitude': member.longitude,
//             'role': 'member',
//             'status': 'invited', // Mark as invited
//           });
//         }
//       }

//       final response = await http.post(
//         Uri.parse('$baseUrl/create-group'),
//         headers: {'Content-Type': 'application/json'},
//         body: jsonEncode({
//           'groupName': groupName,
//           'createdBy': createdBy,
//           'creatorName': creatorName,
//           'trailName': trailName ?? "Unnamed Trail",
//           'invitedMembers': membersData,
//         }),
//       );

//       if (response.statusCode == 200) {
//         final data = jsonDecode(response.body);
//         _activeGroup = data['group'];
//         _lastError = null;
//         debugPrint("✅ Group created: ${_activeGroup!['groupName']}");
//         debugPrint("   Invited ${invitedMembers?.length ?? 0} members");
//       } else {
//         _lastError = "Failed to create group";
//         debugPrint("❌ Failed to create group: ${response.body}");
//       }
//     } catch (e) {
//       _lastError = "Network error: $e";
//       debugPrint("❌ Error: $e");
//     }

//     _isLoading = false;
//     notifyListeners();
//   }

//   /// Update member location
//   Future<void> updateMyLocation({
//     required String groupId,
//     required String userId,
//     required String userName,
//   }) async {
//     final pos = await _getCurrentPosition();
//     if (pos == null) {
//       debugPrint("⚠️ Location unavailable");
//       notifyListeners();
//       return;
//     }

//     try {
//       final response = await http.post(
//         Uri.parse('$baseUrl/update-location'),
//         headers: {'Content-Type': 'application/json'},
//         body: jsonEncode({
//           'groupId': groupId,
//           'userId': userId,
//           'name': userName,
//           'latitude': pos.latitude,
//           'longitude': pos.longitude,
//         }),
//       );

//       if (response.statusCode == 200) {
//         debugPrint("✅ Updated location: ${pos.latitude}, ${pos.longitude}");
//         final data = jsonDecode(response.body);
//         _activeGroup = data['group'];
//         _lastError = null;
//         notifyListeners();
//       } else {
//         _lastError = "Failed to update location";
//         debugPrint("❌ Failed to update location: ${response.body}");
//       }
//     } catch (e) {
//       _lastError = "Network error: $e";
//       debugPrint("❌ Error: $e");
//     }
//   }

//   /// Fetch nearby hikers
//   Future<void> fetchNearbyMembers({String? excludeUserId}) async {
//     final pos = await _getCurrentPosition();
//     if (pos == null) {
//       notifyListeners();
//       return;
//     }

//     try {
//       debugPrint("🔍 Searching nearby at: ${pos.latitude}, ${pos.longitude}");

//       final response = await http.post(
//         Uri.parse('$baseUrl/nearby'),
//         headers: {'Content-Type': 'application/json'},
//         body: jsonEncode({
//           'latitude': pos.latitude,
//           'longitude': pos.longitude,
//           'radius': 1.5,
//           'excludeUserId': excludeUserId,
//         }),
//       );

//       if (response.statusCode == 200) {
//         final data = jsonDecode(response.body);
//         final List<dynamic> hikers = data['hikers'] ?? [];
//         _nearbyMembers = hikers.map((m) => GroupMember.fromJson(m)).toList();
//         _lastError = null;
//         debugPrint("✅ Found ${_nearbyMembers.length} nearby hikers");
//         notifyListeners();
//       } else {
//         _lastError = "Failed to fetch nearby hikers";
//         debugPrint("❌ Failed to fetch nearby hikers: ${response.body}");
//       }
//     } catch (e) {
//       _lastError = "Network error: $e";
//       debugPrint("❌ Error: $e");
//     }
//   }

//   /// Accept group invitation
//   Future<bool> acceptInvitation({
//     required String groupId,
//     required String userId,
//   }) async {
//     _isLoading = true;
//     notifyListeners();

//     try {
//       final response = await http.post(
//         Uri.parse('$baseUrl/accept-invitation'),
//         headers: {'Content-Type': 'application/json'},
//         body: jsonEncode({'groupId': groupId, 'userId': userId}),
//       );

//       if (response.statusCode == 200) {
//         debugPrint("✅ Invitation accepted");
//         final data = jsonDecode(response.body);
//         _activeGroup = data['group'];
//         _lastError = null;
//         _isLoading = false;
//         notifyListeners();
//         return true;
//       } else {
//         _lastError = "Failed to accept invitation";
//         debugPrint("❌ Failed to accept invitation: ${response.body}");
//         _isLoading = false;
//         notifyListeners();
//         return false;
//       }
//     } catch (e) {
//       _lastError = "Network error: $e";
//       debugPrint("❌ Error: $e");
//       _isLoading = false;
//       notifyListeners();
//       return false;
//     }
//   }

//   /// Decline group invitation
//   Future<bool> declineInvitation({
//     required String groupId,
//     required String userId,
//   }) async {
//     try {
//       final response = await http.post(
//         Uri.parse('$baseUrl/decline-invitation'),
//         headers: {'Content-Type': 'application/json'},
//         body: jsonEncode({'groupId': groupId, 'userId': userId}),
//       );

//       if (response.statusCode == 200) {
//         debugPrint("✅ Invitation declined");
//         return true;
//       } else {
//         debugPrint("❌ Failed to decline invitation: ${response.body}");
//         return false;
//       }
//     } catch (e) {
//       debugPrint("❌ Error: $e");
//       return false;
//     }
//   }

//   /// Get pending invitations for a user
//   Future<List<Map<String, dynamic>>> getPendingInvitations(
//     String userId,
//   ) async {
//     try {
//       final response = await http.get(
//         Uri.parse('$baseUrl/pending-invitations/$userId'),
//         headers: {'Content-Type': 'application/json'},
//       );

//       if (response.statusCode == 200) {
//         final data = jsonDecode(response.body);
//         final List<dynamic> invitations = data['invitations'] ?? [];
//         debugPrint("✅ Found ${invitations.length} pending invitations");
//         return invitations.cast<Map<String, dynamic>>();
//       } else {
//         debugPrint("❌ Failed to fetch invitations: ${response.body}");
//         return [];
//       }
//     } catch (e) {
//       debugPrint("❌ Error: $e");
//       return [];
//     }
//   }

//   /// Start auto-updating location every 30 seconds
//   void startLocationUpdates({
//     required String groupId,
//     required String userId,
//     required String userName,
//   }) {
//     _locationTimer?.cancel();

//     // Update immediately
//     updateMyLocation(groupId: groupId, userId: userId, userName: userName);

//     // Then update every 30 seconds
//     _locationTimer = Timer.periodic(const Duration(seconds: 30), (_) {
//       updateMyLocation(groupId: groupId, userId: userId, userName: userName);
//     });

//     debugPrint("🔄 Started location updates (every 30s)");
//   }

//   /// Stop location updates
//   void stopLocationUpdates() {
//     _locationTimer?.cancel();
//     _locationTimer = null;
//     debugPrint("⏸️ Stopped location updates");
//   }

//   /// Send emergency alert to group
//   void sendGroupAlert(BuildContext context) {
//     // TODO: Implement actual alert API call
//     ScaffoldMessenger.of(context).showSnackBar(
//       const SnackBar(
//         content: Row(
//           children: [
//             Icon(Icons.warning_amber, color: Colors.white),
//             SizedBox(width: 8),
//             Text('⚠️ Emergency alert sent to your trail group!'),
//           ],
//         ),
//         backgroundColor: Colors.red,
//         behavior: SnackBarBehavior.floating,
//       ),
//     );
//   }

//   /// Leave the active group
//   Future<void> leaveGroup(String userId) async {
//     if (_activeGroup == null) return;

//     _isLoading = true;
//     notifyListeners();

//     try {
//       final response = await http.post(
//         Uri.parse('$baseUrl/leave-group'),
//         headers: {'Content-Type': 'application/json'},
//         body: jsonEncode({'groupId': _activeGroup!['_id'], 'userId': userId}),
//       );

//       if (response.statusCode == 200) {
//         stopLocationUpdates();
//         _activeGroup = null;
//         _nearbyMembers = [];
//         _lastError = null;
//         debugPrint("✅ Left group successfully");
//       } else {
//         _lastError = "Failed to leave group";
//         debugPrint("❌ Failed to leave group: ${response.body}");
//       }
//     } catch (e) {
//       _lastError = "Network error: $e";
//       debugPrint("❌ Error: $e");
//     }

//     _isLoading = false;
//     notifyListeners();
//   }

//   /// Fetch active group details
//   Future<void> fetchActiveGroup(String groupId) async {
//     _isLoading = true;
//     notifyListeners();

//     try {
//       final response = await http.get(
//         Uri.parse('$baseUrl/group/$groupId'),
//         headers: {'Content-Type': 'application/json'},
//       );

//       if (response.statusCode == 200) {
//         final data = jsonDecode(response.body);
//         _activeGroup = data['group'];
//         _lastError = null;
//         debugPrint("✅ Fetched active group: ${_activeGroup!['groupName']}");
//       } else {
//         _lastError = "Failed to fetch group";
//         debugPrint("❌ Failed to fetch group: ${response.body}");
//       }
//     } catch (e) {
//       _lastError = "Network error: $e";
//       debugPrint("❌ Error: $e");
//     }

//     _isLoading = false;
//     notifyListeners();
//   }

//   /// Clear error message
//   void clearError() {
//     _lastError = null;
//     notifyListeners();
//   }

//   @override
//   void dispose() {
//     _locationTimer?.cancel();
//     super.dispose();
//   }
// }
