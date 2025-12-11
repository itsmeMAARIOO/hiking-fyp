import 'package:flutter/material.dart';
import 'package:hikingapp/utils/snackbar_helper.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:async';

class MapProvider extends ChangeNotifier {
  bool _isRecording = false;
  List<Map<String, double>> _trailPoints = [];
  Map<String, double>? _currentLocation;

  StreamSubscription<Position>? _positionSubscription;

  bool get isRecording => _isRecording;
  List<Map<String, double>> get trailPoints => _trailPoints;
  Map<String, double>? get currentLocation => _currentLocation;

  MapProvider();

  LocationPermission _permissionStatus = LocationPermission.unableToDetermine;
  LocationPermission get permissionStatus => _permissionStatus;

  Future<void> initLocationTracking() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Check if location services are enabled
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('Location services are disabled.');
    }

    // Check permission
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    _permissionStatus = permission;
    notifyListeners();

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      return Future.error('Location permissions are denied');
    }

    // Cancel existing subscription if any to avoid duplicates
    await _positionSubscription?.cancel();

    // Start listening to location updates
    _positionSubscription =
        Geolocator.getPositionStream(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
            distanceFilter: 5, // update every 5 meters
          ),
        ).listen((Position position) {
          _currentLocation = {
            'latitude': position.latitude,
            'longitude': position.longitude,
            'altitude': position.altitude,
            'accuracy': position.accuracy,
          };

          if (_isRecording) {
            _trailPoints.add(_currentLocation!);
          }

          notifyListeners(); // rebuild map and location display
        });
  }

  void startRecording(BuildContext context) {
    _isRecording = true;
    _trailPoints = [];
    notifyListeners();
    SnackbarHelper.showSuccess('Info', 'GPS tracking started');
  }

  void stopRecording(BuildContext context) {
    _isRecording = false;
    notifyListeners();
    SnackbarHelper.showSuccess('Info', 'GPS tracking stopped');
  }

  void addTrailPoint(Map<String, double> point) {
    _trailPoints.add(point);
    notifyListeners();
  }

  void updateCurrentLocation(Map<String, double> location) {
    _currentLocation = location;
    notifyListeners();
  }

  @override
  void dispose() {
    _positionSubscription?.cancel();
    _soloStatsTimer?.cancel();
    super.dispose();
  }

  // ---------------------------------------------
  // ✅ Solo trail minimize support (persistent stats)
  // ---------------------------------------------
  bool _isSoloTrailMinimized = false;
  int _soloElapsedSeconds = 0;
  double _soloTotalDistanceKm = 0.0;
  double _soloCurrentSpeedKmh = 0.0;
  String? _soloTrailName;
  double? _soloLastLat;
  double? _soloLastLon;
  DateTime? _soloLastUpdateTime;
  bool _soloWasTracking = true;
  Timer? _soloStatsTimer;

  bool get isSoloTrailMinimized => _isSoloTrailMinimized;
  int get soloElapsedSeconds => _soloElapsedSeconds;
  double get soloTotalDistanceKm => _soloTotalDistanceKm;
  double get soloCurrentSpeedKmh => _soloCurrentSpeedKmh;
  String? get soloTrailName => _soloTrailName;
  double? get soloLastLat => _soloLastLat;
  double? get soloLastLon => _soloLastLon;
  DateTime? get soloLastUpdateTime => _soloLastUpdateTime;
  bool get soloWasTracking => _soloWasTracking;

  void setSoloTrailMinimized(bool minimized) {
    _isSoloTrailMinimized = minimized;
    if (minimized) {
      _startSoloStatsTimer();
    } else {
      _stopSoloStatsTimer();
    }
    notifyListeners();
  }

  void saveSoloTrailStats({
    required int elapsedSeconds,
    required double totalDistanceKm,
    required double currentSpeedKmh,
    String? trailName,
    double? lastLat,
    double? lastLon,
    DateTime? lastUpdateTime,
    required bool wasTracking,
  }) {
    _soloElapsedSeconds = elapsedSeconds;
    _soloTotalDistanceKm = totalDistanceKm;
    _soloCurrentSpeedKmh = currentSpeedKmh;
    _soloTrailName = trailName;
    _soloLastLat = lastLat;
    _soloLastLon = lastLon;
    _soloLastUpdateTime = lastUpdateTime;
    _soloWasTracking = wasTracking;
    notifyListeners();
  }

  void clearSoloTrailStats() {
    _soloElapsedSeconds = 0;
    _soloTotalDistanceKm = 0.0;
    _soloCurrentSpeedKmh = 0.0;
    _soloTrailName = null;
    _soloLastLat = null;
    _soloLastLon = null;
    _soloLastUpdateTime = null;
    _soloWasTracking = true;
    notifyListeners();
  }

  void _startSoloStatsTimer() {
    _soloStatsTimer?.cancel();
    _soloStatsTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _soloElapsedSeconds += 1;
      _soloLastUpdateTime = DateTime.now();
      notifyListeners();
    });
  }

  void _stopSoloStatsTimer() {
    _soloStatsTimer?.cancel();
    _soloStatsTimer = null;
  }
}
