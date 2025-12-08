import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hikingapp/presentation/styles/colors.dart';
import 'package:hikingapp/utils/snackbar_helper.dart';
import 'package:hikingapp/providers/auth_provider.dart';
import 'package:hikingapp/providers/trail_provider.dart';
import 'package:hikingapp/providers/map_provider.dart';
import 'package:hikingapp/services/trail_services.dart';
import 'package:provider/provider.dart';
import 'package:location/location.dart';
import 'package:hikingapp/config/routes.dart';
import 'package:hikingapp/presentation/pages/trail/active_trail/widgets/modern_header.dart';
import 'package:hikingapp/presentation/pages/trail/active_trail/widgets/tab_selector.dart';
import 'package:hikingapp/presentation/pages/trail/active_trail/widgets/main/main_tab.dart';
import 'package:hikingapp/presentation/pages/trail/active_trail/widgets/chat/chat_tab.dart';
import 'package:hikingapp/presentation/pages/trail/active_trail/widgets/library/library_tab.dart';
import 'package:hikingapp/presentation/pages/trail/active_trail/widgets/no_group_state.dart';
import 'package:hikingapp/presentation/styles/app_styles.dart';
import 'package:hikingapp/presentation/widgets/app_action_dialog.dart';

class ActiveTrailPage extends StatefulWidget {
  const ActiveTrailPage({super.key});

  @override
  State<ActiveTrailPage> createState() => _ActiveTrailPageState();
}

class _ActiveTrailPageState extends State<ActiveTrailPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  bool _isTracking = true;

  late GroupProvider _groupProvider;
  bool _isSolo = false;
  String _soloTrailName = '';
  String _soloTrailDescription = '';

  Duration _elapsedTime = Duration.zero;
  double _totalDistance = 0.0;
  double _currentSpeed = 0.0;
  Timer? _timer;
  Timer? _statusPoller;

  // Focused member location for map centering
  double? _focusLat;
  double? _focusLon;
  // Trigger counter to request map to fit all member markers
  int _showAllTrigger = 0;

  final Location _location = Location();
  LocationData? _lastLocation;
  DateTime? _lastUpdateTime;

  // Tab control for features
  int _selectedTab = 0; // 0: Map, 1: Chat, 2: Library

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
    final args = Get.arguments ?? {};
    _isSolo =
        (args['isSolo'] == true) ||
        ((args['trailName'] ?? '').toString().isNotEmpty);
    _soloTrailName = (args['trailName'] ?? '').toString();
    _soloTrailDescription = (args['trailDescription'] ?? '').toString();
    _groupProvider = Provider.of<GroupProvider>(context, listen: false);
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _initLocationTracking();
    _restoreSavedStats();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_isSolo) {
        final mapProvider = Provider.of<MapProvider>(context, listen: false);
        final isNewSession = mapProvider.soloElapsedSeconds == 0;
        final shouldStart = isNewSession || mapProvider.soloWasTracking;
        setState(() => _isTracking = shouldStart);
        if (shouldStart) {
          _startTimer();
          _groupProvider.startLocationUpdates(
            forSolo: true,
            userId: _currentUserId,
            userName: _currentUserName,
            trailName: _soloTrailName,
            trailDescription: _soloTrailDescription.isNotEmpty
                ? _soloTrailDescription
                : null,
          );
        }
      } else {
        final wasTracking = _groupProvider.wasTracking;
        setState(() => _isTracking = wasTracking);
        if (wasTracking) {
          _startTimer();
          TrailServices.startTracking(
            context: context,
            userId: _currentUserId,
            userName: _currentUserName,
          );
        }

        final groupId = _groupProvider.activeGroup?['_id']?.toString();
        if (groupId != null && groupId.isNotEmpty) {
          _statusPoller?.cancel();
          _statusPoller = Timer.periodic(const Duration(seconds: 3), (t) async {
            if (!mounted) return;
            try {
              await _groupProvider.fetchGroupById(groupId);
              final status = _groupProvider
                  .activeGroup?['activeTrail']?['status']
                  ?.toString();
              if (status == 'completed') {
                t.cancel();
                _stopTimer();
                setState(() {
                  _elapsedTime = Duration.zero;
                  _totalDistance = 0.0;
                  _currentSpeed = 0.0;
                  _lastLocation = null;
                  _lastUpdateTime = null;
                  _focusLat = null;
                  _focusLon = null;
                  _showAllTrigger = 0;
                });
                _groupProvider.clearTrailStats();
                _groupProvider.stopLocationUpdates();

                SnackbarHelper.showSuccess(
                  'Trail Ended',
                  'Trail ended by group leader',
                );
                Get.offAllNamed('/dashboard');
              }
            } catch (_) {}
          });
        }
      }
    });
  }

  void _restoreSavedStats() {
    if (_isSolo) {
      final mp = Provider.of<MapProvider>(context, listen: false);
      setState(() {
        _elapsedTime = Duration(seconds: mp.soloElapsedSeconds);
        _totalDistance = mp.soloTotalDistanceKm;
        _currentSpeed = mp.soloCurrentSpeedKmh;
        _isTracking = mp.soloWasTracking;
        _lastUpdateTime = mp.soloLastUpdateTime;
        if (mp.soloLastLat != null && mp.soloLastLon != null) {
          try {
            _lastLocation = LocationData.fromMap({
              'latitude': mp.soloLastLat!,
              'longitude': mp.soloLastLon!,
            });
          } catch (_) {
            _lastLocation = null;
          }
        }
      });
    } else {
      final p = _groupProvider;
      setState(() {
        _elapsedTime = Duration(seconds: p.elapsedSeconds);
        _totalDistance = p.totalDistanceKm;
        _currentSpeed = p.currentSpeedKmh;
        _isTracking = p.wasTracking;
        _lastUpdateTime = p.lastUpdateTime;
        if (p.lastLat != null && p.lastLon != null) {
          try {
            _lastLocation = LocationData.fromMap({
              'latitude': p.lastLat!,
              'longitude': p.lastLon!,
            });
          } catch (_) {
            _lastLocation = null;
          }
        }
      });
    }
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
    if (!mounted) return;
    setState(() {});

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
        final speed = timeDiff > 0 ? (distance / timeDiff) * 3600 : 0.0;
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

    if (_isSolo) {
      final mp = Provider.of<MapProvider>(context, listen: false);
      mp.saveSoloTrailStats(
        elapsedSeconds: _elapsedTime.inSeconds,
        totalDistanceKm: _totalDistance,
        currentSpeedKmh: _currentSpeed,
        trailName: _soloTrailName.isNotEmpty ? _soloTrailName : null,
        lastLat: newLocation.latitude,
        lastLon: newLocation.longitude,
        lastUpdateTime: _lastUpdateTime,
        wasTracking: _isTracking,
      );
    } else {
      _groupProvider.saveTrailStats(
        elapsedSeconds: _elapsedTime.inSeconds,
        totalDistanceKm: _totalDistance,
        currentSpeedKmh: _currentSpeed,
        lastLat: newLocation.latitude,
        lastLon: newLocation.longitude,
        lastUpdateTime: _lastUpdateTime,
        wasTracking: _isTracking,
      );
    }
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() {
        _elapsedTime += const Duration(seconds: 1);
      });

      if (_isSolo) {
        final mp = Provider.of<MapProvider>(context, listen: false);
        mp.saveSoloTrailStats(
          elapsedSeconds: _elapsedTime.inSeconds,
          totalDistanceKm: _totalDistance,
          currentSpeedKmh: _currentSpeed,
          trailName: _soloTrailName.isNotEmpty ? _soloTrailName : null,
          lastLat: _lastLocation?.latitude,
          lastLon: _lastLocation?.longitude,
          lastUpdateTime: _lastUpdateTime,
          wasTracking: _isTracking,
        );
      } else {
        _groupProvider.saveTrailStats(
          elapsedSeconds: _elapsedTime.inSeconds,
          totalDistanceKm: _totalDistance,
          currentSpeedKmh: _currentSpeed,
          lastLat: _lastLocation?.latitude,
          lastLon: _lastLocation?.longitude,
          lastUpdateTime: _lastUpdateTime,
          wasTracking: _isTracking,
        );
      }
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
    const earthRadius = 6371.0;
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

    if (_isSolo) {
      final mp = Provider.of<MapProvider>(context, listen: false);
      if (!mp.isSoloTrailMinimized) {
        _groupProvider.stopLocationUpdates();
      }
    } else {
      final status = _groupProvider.activeGroup?['activeTrail']?['status']
          ?.toString();
      if (_groupProvider.isTrailMinimized && status != 'completed') {
        _groupProvider.saveTrailStats(
          elapsedSeconds: _elapsedTime.inSeconds,
          totalDistanceKm: _totalDistance,
          currentSpeedKmh: _currentSpeed,
          lastLat: _lastLocation?.latitude,
          lastLon: _lastLocation?.longitude,
          lastUpdateTime: _lastUpdateTime,
          wasTracking: _isTracking,
        );
      }
      if (!_groupProvider.isTrailMinimized) {
        _groupProvider.stopLocationUpdates();
      }
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<GroupProvider>(
      builder: (context, provider, _) {
        if (!_isSolo && provider.activeGroup == null) {
          return const NoGroupState();
        }

        return Scaffold(
          backgroundColor: Colors.transparent,
          body: Stack(
            children: [
              const AnimatedBackground(),
              SafeArea(
                child: Column(
                  children: [
                    ModernHeader(
                      groupName: _isSolo
                          ? 'Solo Trail'
                          : provider.activeGroup?['groupName']?.toString() ??
                                '',
                      trailName: _isSolo
                          ? _soloTrailName
                          : provider.activeGroup?['activeTrail']?['trailName']
                                    ?.toString() ??
                                '',
                      isTracking: _isTracking,
                      pulseAnimation: _pulseController,
                      onMinimize: () => _onMinimize(provider),
                      trailingButton: _MinimizeButton(
                        onMinimize: () => _onMinimize(provider),
                      ),
                    ),
                    Expanded(child: _buildTrailContent(provider)),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTrailContent(GroupProvider provider) {
    final List<dynamic> otherMembers;
    String groupId = '';
    String groupName = '';
    if (_isSolo) {
      otherMembers = [];
      groupId = '';
      groupName = _soloTrailName;
    } else {
      final group = provider.activeGroup!;
      groupId = group['_id']?.toString() ?? '';
      groupName = provider.activeGroup?['groupName']?.toString() ?? '';
      final members = (group['members'] as List?) ?? [];
      otherMembers = members.where((m) {
        try {
          final id = (m['userId'] ?? m['id'])?.toString();
          final status = (m['status'] ?? '').toString().toLowerCase();
          final hasJoined = status == 'active' || status == 'accepted';
          return id != _currentUserId && hasJoined;
        } catch (_) {
          return false;
        }
      }).toList();
    }

    return Container(
      color: Colors.transparent,
      child: Column(
        children: [
          SizedBox(height: 12),
          // Tab Selector
          TabSelector(
            selectedIndex: _selectedTab,
            onSelect: (i) => setState(() => _selectedTab = i),
            showChat: !_isSolo,
          ),

          const SizedBox(height: 12),

          // Tabbed Content Area
          Expanded(
            child: _selectedTab == 0
                ? MainTab(
                    otherMembers: otherMembers,
                    focusLat: _focusLat,
                    focusLon: _focusLon,
                    showAllTrigger: _showAllTrigger,
                    onShowAll: () {
                      setState(() {
                        _focusLat = null;
                        _focusLon = null;
                        _showAllTrigger++;
                      });
                    },
                    onSelectMember: (lat, lon) {
                      setState(() {
                        _focusLat = lat;
                        _focusLon = lon;
                      });
                    },
                    elapsedTime: _elapsedTime,
                    totalDistance: _totalDistance,
                    currentSpeed: _currentSpeed,
                    isTracking: _isTracking,
                    onToggleTracking: () {
                      if (_isSolo) {
                        final newVal = !_isTracking;
                        setState(() => _isTracking = newVal);
                        if (newVal) {
                          _startTimer();
                          _groupProvider.startLocationUpdates(
                            forSolo: true,
                            userId: _currentUserId,
                            userName: _currentUserName,
                            trailName: _soloTrailName,
                          );
                        } else {
                          _stopTimer();
                          _groupProvider.stopLocationUpdates();
                        }
                      } else {
                        TrailServices.toggleTracking(
                          context: context,
                          isTracking: _isTracking,
                          userId: _currentUserId,
                          userName: _currentUserName,
                          onTrackingChanged: (val) {
                            setState(() => _isTracking = val);
                            if (val) {
                              _startTimer();
                            } else {
                              _stopTimer();
                            }
                          },
                        );
                      }
                    },
                    onEndTrail: () {
                      if (_isSolo) {
                        _showSoloEndDialog(context);
                      } else {
                        TrailServices.showEndTrailDialog(
                          context: context,
                          provider: provider,
                          userId: _currentUserId,
                        );
                      }
                    },
                  )
                : _selectedTab == 1
                ? (_isSolo
                      ? LibraryTab(
                          groupId: groupId,
                          groupName: groupName,
                          currentUserId: _currentUserId,
                          currentUserName: _currentUserName,
                        )
                      : ChatTab(
                          groupId: groupId,
                          groupName: groupName,
                          currentUserId: _currentUserId,
                          currentUserName: _currentUserName,
                        ))
                : LibraryTab(
                    groupId: groupId,
                    groupName: groupName,
                    currentUserId: _currentUserId,
                    currentUserName: _currentUserName,
                  ),
          ),
          SizedBox(height: 12),
        ],
      ),
    );
  }

  Future<void> _showSoloEndDialog(BuildContext context) async {
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AppActionDialog(
        title: 'End Solo Trail',
        icon: Icons.flag_rounded,
        message: 'Are you sure you want to end this trail?',
        cancelText: 'CANCEL',
        confirmText: 'END',
        confirmColor: const Color(0xFFE74C3C),
        headerGradient: const [Color(0xFFc0392b), Color(0xFFe74c3c)],
        cancelResult: 'cancel',
        confirmResult: 'confirm',
      ),
    );
    if (result == 'confirm') {
      final mp = Provider.of<MapProvider>(context, listen: false);
      mp.clearSoloTrailStats();
      _groupProvider.completeSoloTrail(
        userId: _currentUserId,
        trailName: _soloTrailName,
        endTime: DateTime.now(),
      );
      _groupProvider.stopLocationUpdates();
      _stopTimer();
      Get.offAllNamed(AppRoutes.dashboard);
    }
  }

  void _onMinimize(GroupProvider provider) {
    Get.offNamed(AppRoutes.dashboard);
    Future.microtask(() {
      if (_isSolo) {
        final mp = Provider.of<MapProvider>(context, listen: false);
        mp.saveSoloTrailStats(
          elapsedSeconds: _elapsedTime.inSeconds,
          totalDistanceKm: _totalDistance,
          currentSpeedKmh: _currentSpeed,
          trailName: _soloTrailName.isNotEmpty ? _soloTrailName : null,
          lastLat: _lastLocation?.latitude,
          lastLon: _lastLocation?.longitude,
          lastUpdateTime: _lastUpdateTime,
          wasTracking: _isTracking,
        );
        mp.setSoloTrailMinimized(true);
      } else {
        _groupProvider.saveTrailStats(
          elapsedSeconds: _elapsedTime.inSeconds,
          totalDistanceKm: _totalDistance,
          currentSpeedKmh: _currentSpeed,
          lastLat: _lastLocation?.latitude,
          lastLon: _lastLocation?.longitude,
          lastUpdateTime: _lastUpdateTime,
          wasTracking: _isTracking,
        );
        _groupProvider.setTrailMinimized(true);
      }
    });
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
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: kDeepTeal.withOpacity(0.15),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: kDeepTeal.withOpacity(0.3), width: 1),
          ),
          child: const Icon(Icons.circle_outlined, color: kDeepTeal, size: 20),
        ),
      ),
    );
  }
}
