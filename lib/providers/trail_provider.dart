// lib/providers/group_provider.dart
import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:hikingapp/config/api_config.dart';
import 'package:hikingapp/data/models/group_model.dart';
import 'package:http/http.dart' as http;
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:hikingapp/services/notification_service.dart';

/// Provider for managing group activities, locations, and member updates.
class GroupProvider with ChangeNotifier {
  final String baseUrl = "${ApiConfig.baseUrl}/group";
  final String soloBaseUrl = "${ApiConfig.baseUrl}/solo";

  bool _isLoading = false;
  Map<String, dynamic>? _activeGroup;
  List<GroupMember> _nearbyMembers = [];
  Timer? _locationTimer;
  Timer? _statsTimer; // background elapsed-time timer
  String? _lastError;
  bool _isUpdatingLocation = false;
  bool _isTrailMinimized = false;
  IO.Socket? _socket;
  String? _currentUserId;
  bool _isChatVisible = false;
  bool _hasUnreadMessages = false;

  bool get hasUnreadMessages => _hasUnreadMessages;

  void setChatVisible(bool visible) {
    _isChatVisible = visible;
    if (visible && _hasUnreadMessages) {
      _hasUnreadMessages = false;
      notifyListeners();
    }
  }

  // ----------------------------
  // ✅ Persisted trail stats (for minimize/restore)
  // ----------------------------
  int _elapsedSeconds = 0; // total elapsed tracking time
  double _totalDistanceKm = 0.0; // accumulated distance
  double _currentSpeedKmh = 0.0; // last computed speed
  double? _lastLat; // last coordinate used for distance calc
  double? _lastLon;
  DateTime? _lastUpdateTime; // last tick time for speed calc
  bool _wasTracking = false; // whether tracking was active

  bool get isLoading => _isLoading;
  Map<String, dynamic>? get activeGroup => _activeGroup;
  List<GroupMember> get nearbyMembers => _nearbyMembers;
  String? get lastError => _lastError;
  bool get isTrailMinimized => _isTrailMinimized;

  // Expose persisted stats
  int get elapsedSeconds => _elapsedSeconds;
  double get totalDistanceKm => _totalDistanceKm;
  double get currentSpeedKmh => _currentSpeedKmh;
  double? get lastLat => _lastLat;
  double? get lastLon => _lastLon;
  DateTime? get lastUpdateTime => _lastUpdateTime;
  bool get wasTracking => _wasTracking;

  // ----------------------------
  // ✅ Minimize / restore trail state
  // ----------------------------
  void setTrailMinimized(bool minimized) {
    _isTrailMinimized = minimized;
    notifyListeners();
  }

  /// Save trail stats so UI can restore after minimize/reopen
  void saveTrailStats({
    required int elapsedSeconds,
    required double totalDistanceKm,
    required double currentSpeedKmh,
    double? lastLat,
    double? lastLon,
    DateTime? lastUpdateTime,
    required bool wasTracking,
  }) {
    _elapsedSeconds = elapsedSeconds;
    _totalDistanceKm = totalDistanceKm;
    _currentSpeedKmh = currentSpeedKmh;
    _lastLat = lastLat;
    _lastLon = lastLon;
    _lastUpdateTime = lastUpdateTime;
    _wasTracking = wasTracking;
    notifyListeners();
  }

  /// Clear persisted stats (e.g., on trail end or leaving group)
  void clearTrailStats() {
    _elapsedSeconds = 0;
    _totalDistanceKm = 0.0;
    _currentSpeedKmh = 0.0;
    _lastLat = null;
    _lastLon = null;
    _lastUpdateTime = null;
    _wasTracking = true;
    notifyListeners();
  }

  // ----------------------------
  // ✅ Socket Logic
  // ----------------------------
  String get _origin {
    final base = ApiConfig.baseUrl;
    return base.endsWith('/api') ? base.substring(0, base.length - 4) : base;
  }

  void _connectSocket(String groupId) {
    if (_socket != null) return; // already connected

    final origin = _origin;
    _socket = IO.io(
      origin,
      IO.OptionBuilder()
          .setTransports(['websocket'])
          .disableAutoConnect()
          .enableForceNew()
          .build(),
    );

    _socket!.onConnect((_) {
      debugPrint("🔌 Socket connected for GroupProvider");
      _socket!.emit('join', {'groupId': groupId});
    });

    _socket!.on('group:time_update', (data) {
      // Sync time from creator
      if (data != null && data['seconds'] != null) {
        final int s = data['seconds'];
        // If current user NOT the creator, update time
        if (_activeGroup != null && _currentUserId != null) {
          final creatorId = _activeGroup!['createdBy']?.toString();
          if (creatorId != _currentUserId) {
            if ((_elapsedSeconds - s).abs() > 1) {
              _elapsedSeconds = s;
              notifyListeners();
            }
          }
        }
      }
    });

    _socket!.on('chat:new', (data) {
      // pop notification if message received
      if (!_isChatVisible && _currentUserId != null) {
        if (data is Map) {
          final uid = data['userId']?.toString();
          if (uid != null && uid != _currentUserId) {
            _hasUnreadMessages = true;
            notifyListeners();
            final sender = data['userName']?.toString() ?? 'User';
            final body = data['text']?.toString() ?? 'Image';
            NotificationService.chatNotification(
              senderName: sender,
              message: body,
            );
          }
        }
      }
    });

    _socket!.connect();
  }

  void _disconnectSocket() {
    _socket?.dispose();
    _socket = null;
  }

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
    String? trailDescription,
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
          'trailDescription': trailDescription,
          'invitedMembers': membersData ?? [],
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _activeGroup = data['group'];
        // Ensure fresh stats for a new group session
        clearTrailStats();
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
        debugPrint(
          "📍 Updated location:  $userName, ${pos.latitude}, ${pos.longitude}",
        );

        // Fetch populated group so members include user profile images
        try {
          final populated = await http.get(
            Uri.parse('$baseUrl/group/${_activeGroup!['_id']}'),
            headers: {'Content-Type': 'application/json'},
          );
          if (populated.statusCode == 200) {
            final popData = jsonDecode(populated.body);
            if (popData is Map && popData['group'] != null) {
              _activeGroup = popData['group'] as Map<String, dynamic>;
            }
          }
        } catch (_) {}
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
  // ✅ Update solo live location
  // ----------------------------
  Future<void> _updateSoloLocation({
    required String userId,
    required String userName,
    String? trailName,
    String? trailDescription,
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
        Uri.parse('$soloBaseUrl/update-location'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'userId': userId,
          'trailName': trailName ?? 'Unnamed Trail',
          'trailDescription': trailDescription,
          'latitude': pos.latitude,
          'longitude': pos.longitude,
        }),
      );

      if (response.statusCode == 200) {
        _lastError = null;
        debugPrint(
          "🏃‍♂️ Solo updated: $userName, ${pos.latitude}, ${pos.longitude}",
        );
      } else {
        _lastError = "Failed to update solo location (${response.statusCode})";
      }
    } catch (e) {
      _lastError = "Network error while updating solo location: $e";
    } finally {
      _isUpdatingLocation = false;
      notifyListeners();
    }
  }

  // ----------------------------
  // ✅ Start auto location updates
  // ----------------------------
  void startLocationUpdates({
    String? groupId,
    required String userId,
    required String userName,
    bool forSolo = false,
    String? trailName,
    String? trailDescription,
  }) {
    stopLocationUpdates(); // ensure only one timer exists
    if (forSolo) {
      _updateSoloLocation(
        userId: userId,
        userName: userName,
        trailName: trailName,
        trailDescription: trailDescription,
      );
      _locationTimer = Timer.periodic(const Duration(seconds: 30), (_) {
        _updateSoloLocation(
          userId: userId,
          userName: userName,
          trailName: trailName,
          trailDescription: trailDescription,
        );
      });
      // Do NOT start stats timer here for solo; solo page manages its own UI timer
    } else {
      updateMyLocation(groupId: groupId!, userId: userId, userName: userName);
      _locationTimer = Timer.periodic(const Duration(seconds: 30), (_) {
        updateMyLocation(groupId: groupId, userId: userId, userName: userName);
      });
      // Start background stats timer so elapsed time continues while minimized
      _startStatsTimer();
    }
    _wasTracking = true; // mark tracking active
    notifyListeners();

    debugPrint("🔄 Started location updates every 30s");

    // Setup socket for group time sync
    _currentUserId = userId;
    if (!forSolo && groupId != null) {
      _connectSocket(groupId);
    }
  }

  // ----------------------------
  // ✅ Stop location updates
  // ----------------------------
  void stopLocationUpdates() {
    _locationTimer?.cancel();
    _locationTimer = null;
    _stopStatsTimer();
    _disconnectSocket();
    _wasTracking = false; // mark paused tracking
    debugPrint("⏸️ Stopped location updates");
  }

  // ----------------------------
  // ✅ Complete solo trail
  // ----------------------------
  Future<void> completeSoloTrail({
    required String userId,
    required String trailName,
    DateTime? endTime,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$soloBaseUrl/save'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'userId': userId,
          'trailName': trailName,
          'endTime': (endTime ?? DateTime.now()).toIso8601String(),
        }),
      );

      if (response.statusCode == 200) {
        _lastError = null;
        debugPrint("✅ Solo trail completed and saved");
      } else {
        _lastError = "Failed to complete solo trail (${response.statusCode})";
        debugPrint("❌ Failed to save solo trail: ${response.body}");
      }
    } catch (e) {
      _lastError = "Network error while saving solo trail: $e";
      debugPrint("❌ Error saving solo trail: $e");
    }
    notifyListeners();
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
        clearTrailStats();
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

  Future<void> fetchGroupById(String groupId, {String? currentUserId}) async {
    try {
      _isLoading = true;
      notifyListeners();

      // Use populated endpoint to include members' profile info
      final response = await http.get(
        Uri.parse('$baseUrl/group/$groupId'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _activeGroup = data['group'];

        // Sync trail status if active
        if (_activeGroup != null &&
            _activeGroup!['activeTrail'] != null &&
            _activeGroup!['activeTrail']['status'] == 'active') {
          final active = _activeGroup!['activeTrail'];
          if (active['startTime'] != null) {
            final serverStart = DateTime.parse(active['startTime']).toUtc();
            // Server stores time as MYT but in UTC container (+8h offset stored as UTC value)
            // So we subtract 8 hours to get the real UTC start time
            final realStart = serverStart.subtract(const Duration(hours: 8));
            final now = DateTime.now().toUtc();
            final diff = now.difference(realStart).inSeconds;
            _elapsedSeconds = diff > 0 ? diff : 0;
            _wasTracking = true;

            // If we have userId, we can start updates/sockets immediately
            if (currentUserId != null) {
              // Find my name in members
              String myName = 'User';
              final members = _activeGroup!['members'] as List?;
              if (members != null) {
                final me = members.firstWhere((m) {
                  final uid = m['userId'];
                  if (uid is Map)
                    return uid['_id'] == currentUserId ||
                        uid['id'] == currentUserId;
                  return uid == currentUserId;
                }, orElse: () => null);
                if (me != null) {
                  // Try to extract name
                  if (me['name'] != null)
                    myName = me['name'];
                  else if (me['userId'] is Map && me['userId']['name'] != null)
                    myName = me['userId']['name'];
                }
              }

              debugPrint("🚀 Auto-starting tracking for joined group");
              startLocationUpdates(
                groupId: _activeGroup!['_id'],
                userId: currentUserId,
                userName: myName,
              );
            }
          }
        }

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
        _activeGroup =
            data['group']; // keep updated group to expose completed status
        _nearbyMembers = [];
        clearTrailStats();
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
    _statsTimer?.cancel();
    super.dispose();
  }

  // ----------------------------
  // ✅ Internal: stats timer to keep elapsed time running in background
  // ----------------------------
  void _startStatsTimer() {
    _statsTimer?.cancel();
    _statsTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _elapsedSeconds += 1;
      // keep last update time in sync for potential speed calc continuity
      _lastUpdateTime = DateTime.now();

      // Emit time if creator
      if (_socket != null && _activeGroup != null && _currentUserId != null) {
        final creatorId = _activeGroup!['createdBy']?.toString();
        if (creatorId == _currentUserId) {
          _socket!.emit('group:time_update', {
            'groupId': _activeGroup!['_id'],
            'seconds': _elapsedSeconds,
          });
        }
      }

      // Notify listeners so any UI (e.g., bubble or page) can reflect time
      notifyListeners();
    });
    debugPrint("⏱️ Started stats timer");
  }

  void _stopStatsTimer() {
    _statsTimer?.cancel();
    _statsTimer = null;
    debugPrint("⏱️ Stopped stats timer");
  }
}
