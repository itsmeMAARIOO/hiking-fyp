// lib/presentation/pages/group/active_trail/active_trail_page.dart
import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hikingapp/utils/snackbar_helper.dart';
import 'package:hikingapp/providers/auth_provider.dart';
import 'package:hikingapp/providers/group_provider.dart';
import 'package:hikingapp/services/group_services.dart';
import 'package:provider/provider.dart';
import 'package:location/location.dart'; // ✅ Add this import
import 'widgets/trail_statistics.dart';
import 'widgets/trail_actions.dart';
import 'widgets/group_overview.dart';
import 'widgets/group_members.dart';
import 'widgets/trail_floating_actions.dart';

class TrailGroupPage extends StatefulWidget {
  const TrailGroupPage({super.key});

  @override
  State<TrailGroupPage> createState() => _TrailGroupPageState();
}

class _TrailGroupPageState extends State<TrailGroupPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  bool _isTracking = true;

  // Cache provider to avoid context lookups during dispose
  late GroupProvider _groupProvider;

  // Trail statistics
  Duration _elapsedTime = Duration.zero;
  double _totalDistance = 0.0;
  double _currentSpeed = 0.0;
  Timer? _timer;
  Timer? _statusPoller; // polls group status for instant redirect

  // Location tracking variables
  final Location _location = Location(); // ✅ Initialize location service
  LocationData? _lastLocation; // ✅ Store last known location
  DateTime? _lastUpdateTime; // ✅ For speed/duration tracking

  // Color constants
  static const Color kDeepTeal = Color(0xFF1c3f3f);
  static const Color kSoftMint = Color(0xFFa0d5b9);
  static const Color kMediumSage = Color(0xFF6baf89);
  static const Color kDeepForest = Color(0xFF3e7b5b);

  String get _currentUserId {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    return authProvider.userId ?? "no user id";
  }

  String get _currentUserName {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    return authProvider.userName ?? "no user name";
  }

  @override
  void initState() {
    super.initState();
    _groupProvider = Provider.of<GroupProvider>(context, listen: false);
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _initLocationTracking();

    // Auto-start tracking when entering page
    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() => _isTracking = true);
      _startTimer();

      GroupServices.startTracking(
        context: context,
        userId: _currentUserId,
        userName: _currentUserName,
      );

      // Start short polling to detect trail completion instantly
      final groupId = _groupProvider.activeGroup?['_id']?.toString();
      if (groupId != null && groupId.isNotEmpty) {
        _statusPoller?.cancel();
        _statusPoller = Timer.periodic(const Duration(seconds: 3), (t) async {
          if (!mounted) return;
          try {
            await _groupProvider.fetchGroupById(groupId);
            final status = _groupProvider.activeGroup?['activeTrail']?['status']
                ?.toString();
            if (status == 'completed') {
              t.cancel();
              // Use standardized snackbar helper
              SnackbarHelper.showSuccess(
                'Trail Ended',
                'Trail ended by group leader',
              );
              Get.offAllNamed('/dashboard');
            }
          } catch (_) {
            // ignore transient errors during polling
          }
        });
      }
    });
  }

  Future<void> _initLocationTracking() async {
    final hasPermission = await _checkLocationPermission();
    if (!hasPermission) return;

    _location.onLocationChanged.listen((newLocation) {
      if (_isTracking && mounted) {
        _updateTrailStats(newLocation);
      }
    });
  }

  Future<bool> _checkLocationPermission() async {
    bool serviceEnabled = await _location.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await _location.requestService();
      if (!serviceEnabled) return false;
    }

    PermissionStatus permissionGranted = await _location.hasPermission();
    if (permissionGranted == PermissionStatus.denied) {
      permissionGranted = await _location.requestPermission();
      if (permissionGranted != PermissionStatus.granted) return false;
    }

    return true;
  }

  void _updateTrailStats(LocationData newLocation) {
    // ✅ Prevent setState after dispose
    if (!mounted) return;
    setState(() {
      // update trail stats here
    });

    if (_lastLocation != null) {
      final distance = _calculateDistance(
        _lastLocation!.latitude!,
        _lastLocation!.longitude!,
        newLocation.latitude!,
        newLocation.longitude!,
      );

      final now = DateTime.now();
      if (_lastUpdateTime != null) {
        final timeDiff = now.difference(_lastUpdateTime!).inSeconds;
        final speed = timeDiff > 0 ? (distance / timeDiff) * 3600 : 0.0; // km/h
        setState(() {
          _totalDistance += distance;
          _currentSpeed = speed;
        });
      }
      _lastUpdateTime = now;
    } else {
      _lastUpdateTime = DateTime.now();
    }

    _lastLocation = newLocation;
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() {
        _elapsedTime += const Duration(seconds: 1);
      });
    });
  }

  void _stopTimer() {
    _timer?.cancel();
  }

  // Calculate distance between two coordinates using Haversine formula
  double _calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const earthRadius = 6371.0; // km
    final dLat = _degToRad(lat2 - lat1);
    final dLon = _degToRad(lon2 - lon1);
    final a =
        (sin(dLat / 2) * sin(dLat / 2)) +
        cos(_degToRad(lat1)) *
            cos(_degToRad(lat2)) *
            sin(dLon / 2) *
            sin(dLon / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadius * c;
  }

  double _degToRad(double deg) => deg * (pi / 180);

  @override
  void dispose() {
    _pulseController.dispose();
    _timer?.cancel();
    _statusPoller?.cancel();
    // Use cached provider to avoid accessing context of a deactivated widget
    _groupProvider.stopLocationUpdates();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<GroupProvider>(
      builder: (context, provider, _) {
        if (provider.activeGroup == null) {
          return _buildNoGroupState();
        }

        return Scaffold(
          backgroundColor: kDeepTeal,
          body: Stack(
            children: [
              // Background gradient
              Container(
                width: double.infinity,
                height: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [kDeepTeal, kDeepForest.withOpacity(0.8)],
                  ),
                ),
              ),

              // Foreground content
              SafeArea(
                child: Column(
                  children: [
                    _buildHeader(provider),
                    Expanded(
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 500),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.95),
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(30),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: kDeepTeal.withOpacity(0.3),
                              blurRadius: 30,
                              spreadRadius: 5,
                              offset: const Offset(0, -10),
                            ),
                          ],
                        ),
                        child: _buildTrailContent(provider),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          // floatingActionButton: TrailFloatingActions(
          //   provider: provider,
          //   currentUserId: _currentUserId,
          // ),
          // floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
        );
      },
    );
  }

  Widget _buildTrailContent(GroupProvider provider) {
    final group = provider.activeGroup!;
    final members = (group['members'] as List?) ?? [];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TrailStatistics(
            elapsedTime: _elapsedTime,
            totalDistance: _totalDistance,
            currentSpeed: _currentSpeed,
            isTracking: _isTracking,
          ),
          const SizedBox(height: 20),
          TrailActions(
            isTracking: _isTracking,
            onToggleTracking: () => GroupServices.toggleTracking(
              context: context,
              isTracking: _isTracking,
              userId: _currentUserId,
              userName: _currentUserName,
              onTrackingChanged: (val) {
                setState(() => _isTracking = val);

                if (val) {
                  _startTimer(); // ✅ start tracking time
                } else {
                  _stopTimer(); // ✅ stop timer
                }
              },
            ),
            onEndTrail: () => GroupServices.showEndTrailDialog(
              context: context,
              provider: provider,
              userId: _currentUserId,
            ),
          ),
          const SizedBox(height: 24),
          GroupOverview(group: group, members: members),
          const SizedBox(height: 24),
          GroupMembers(members: members),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildNoGroupState() {
    return Scaffold(
      backgroundColor: kDeepTeal,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: kSoftMint.withOpacity(0.5),
            ),
            const SizedBox(height: 20),
            const Text(
              'No Active Group',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Join or create a group to start tracking',
              style: TextStyle(color: kSoftMint, fontSize: 14),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: kMediumSage,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'Go Back',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(GroupProvider provider) {
    final group = provider.activeGroup!;
    return Container(
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [kDeepTeal, kDeepForest],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: kDeepTeal.withOpacity(0.5),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.forest_rounded, color: Colors.white, size: 32),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  group['groupName'] ?? 'Unnamed Group',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  group['activeTrail']?['trailName'] ?? 'Exploring Trail',
                  style: const TextStyle(color: kSoftMint, fontSize: 14),
                ),
              ],
            ),
          ),
          if (_isTracking)
            FadeTransition(
              opacity: _pulseController,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFF6B6B), Color(0xFFFF5252)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  children: [
                    Icon(
                      Icons.fiber_manual_record,
                      color: Colors.white,
                      size: 12,
                    ),
                    SizedBox(width: 6),
                    Text(
                      'LIVE',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
