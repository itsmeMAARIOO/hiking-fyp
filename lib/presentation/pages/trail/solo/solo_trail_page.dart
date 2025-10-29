import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hikingapp/providers/auth_provider.dart';
import 'package:hikingapp/utils/snackbar_helper.dart';
import 'package:hikingapp/presentation/pages/group/trail_group/widgets/trail_statistics.dart';
import 'package:hikingapp/presentation/pages/group/trail_group/widgets/trail_actions.dart';
import 'package:provider/provider.dart';
import 'package:location/location.dart';
import 'package:hikingapp/services/solo_trail_services.dart';
import 'package:hikingapp/config/routes.dart';
import 'package:hikingapp/presentation/styles/colors.dart';
import 'package:hikingapp/providers/map_provider.dart';
import 'package:hikingapp/providers/group_provider.dart';
import 'package:hikingapp/presentation/pages/trail/widget/solo_live_map.dart';

class SoloTrailPage extends StatefulWidget {
  const SoloTrailPage({super.key});

  @override
  State<SoloTrailPage> createState() => _SoloTrailPageState();
}

class _SoloTrailPageState extends State<SoloTrailPage>
    with SingleTickerProviderStateMixin {
  // Use centralized color palette from config/colors.dart

  late AnimationController _pulseController;
  bool _isTracking = true;
  final Location _location = Location();
  LocationData? _lastLocation;
  DateTime? _lastUpdateTime;
  // Cache providers to avoid using context during dispose or after navigation
  GroupProvider? _groupProvider;
  MapProvider? _mapProvider;
  AuthProvider? _authProvider;
  StreamSubscription<LocationData>? _locationSub;

  Duration _elapsedTime = Duration.zero;
  double _totalDistance = 0.0;
  double _currentSpeed = 0.0;
  Timer? _timer;
  late final String _trailName;
  late final DateTime _startTime;

  String get _currentUserId {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    return authProvider.userId ?? "no user id";
  }

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    // Cache providers (listen: false is OK in initState)
    _mapProvider = Provider.of<MapProvider>(context, listen: false);
    _groupProvider = Provider.of<GroupProvider>(context, listen: false);
    _authProvider = Provider.of<AuthProvider>(context, listen: false);

    // Prefer provider-saved trail name when resuming, else route argument
    _trailName = _mapProvider!.soloTrailName ??
        (Get.arguments?['trailName'] as String?) ??
        'Unnamed Trail';
    _startTime = DateTime.now();

    // Restore minimized solo trail stats if present
    if (_mapProvider!.soloElapsedSeconds > 0) {
      _elapsedTime = Duration(seconds: _mapProvider!.soloElapsedSeconds);
      _totalDistance = _mapProvider!.soloTotalDistanceKm;
      _currentSpeed = _mapProvider!.soloCurrentSpeedKmh;
      _lastUpdateTime = _mapProvider!.soloLastUpdateTime;
      _isTracking = _mapProvider!.soloWasTracking;
      // Stop provider background timer and resume local if tracking
      _mapProvider!.setSoloTrailMinimized(false);
      if (_isTracking) {
        _startTimer();
      }
      // Clear provider stats to avoid reapplying on future opens
      _mapProvider!.clearSoloTrailStats();
    }

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final hasPermission = await _checkLocationPermission();
      if (hasPermission) {
        _groupProvider?.startLocationUpdates(
          forSolo: true,
          userId: _currentUserId,
          userName: _authProvider?.userName ?? 'User',
          trailName: _trailName,
        );
        _locationSub = _location.onLocationChanged.listen((newLocation) {
          if (_isTracking && mounted) {
            _updateTrailStats(newLocation);
          }
        });
        _startTimer();
      } else {
        SnackbarHelper.showError(
          'Location Required',
          'Please enable location permissions',
        );
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
    if (!mounted) return;

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
    // Ensure only one timer instance is running
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() {
        _elapsedTime += const Duration(seconds: 1);
      });
    });
  }

  void _stopTimer() {
    _timer?.cancel();
  }

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

  Future<void> _onCompleteTrail() async {
    _stopTimer();
    final endTime = DateTime.now();

    final ok = await SoloTrailServices.saveSoloTrail(
      context: context,
      userId: _currentUserId,
      trailName: _trailName,
      startTime: _startTime,
      endTime: endTime,
    );

    if (ok) {
      // Stop location updates before navigating away
      _groupProvider?.stopLocationUpdates();
      Get.offAllNamed(AppRoutes.dashboard);
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _stopTimer();
    // Cancel location subscription and stop updates without using context
    _locationSub?.cancel();
    _groupProvider?.stopLocationUpdates();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kDeepTeal,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: kMediumSage.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.hiking_rounded,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _trailName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const Text(
                          'Solo Trail',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 8),
                  _MinimizeButton(onMinimize: _onMinimize),
                ],
              ),
            ),
            // Body content
            Expanded(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 500),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.95),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(30),
                  ),
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SoloLiveMap(height: 220),
                      const SizedBox(height: 16),
                      TrailStatistics(
                        elapsedTime: _elapsedTime,
                        totalDistance: _totalDistance,
                        currentSpeed: _currentSpeed,
                        isTracking: _isTracking,
                      ),
                      const SizedBox(height: 20),
                      TrailActions(
                        isTracking: _isTracking,
                        onToggleTracking: () {
                          setState(() {
                            _isTracking = !_isTracking;
                          });
                          if (_isTracking) {
                            _startTimer();
                            _groupProvider?.startLocationUpdates(
                              forSolo: true,
                              userId: _currentUserId,
                              userName: _authProvider?.userName ?? 'User',
                              trailName: _trailName,
                            );
                          } else {
                            _stopTimer();
                            _groupProvider?.stopLocationUpdates();
                          }
                        },
                        onEndTrail: _onCompleteTrail,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _onMinimize() {
    // Persist stats first, then navigate; avoid using context after navigation
    _stopTimer();
    _mapProvider?.saveSoloTrailStats(
      elapsedSeconds: _elapsedTime.inSeconds,
      totalDistanceKm: _totalDistance,
      currentSpeedKmh: _currentSpeed,
      trailName: _trailName,
      lastLat: _lastLocation?.latitude,
      lastLon: _lastLocation?.longitude,
      lastUpdateTime: _lastUpdateTime,
      wasTracking: _isTracking,
    );
    _mapProvider?.setSoloTrailMinimized(true);
    Get.offNamed(AppRoutes.dashboard);
  }
}

class _MinimizeButton extends StatelessWidget {
  final VoidCallback onMinimize;
  const _MinimizeButton({required this.onMinimize});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onMinimize,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF16A085), Color(0xFF1ABC9C)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF16A085).withOpacity(0.35),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Row(
            children: const [
              SizedBox(width: 6),
              Icon(Icons.circle_outlined, color: Colors.white, size: 18),
              SizedBox(width: 6),
            ],
          ),
        ),
      ),
    );
  }
}
