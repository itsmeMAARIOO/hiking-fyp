import 'package:flutter/material.dart';
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

  MapProvider() {
    _initLocationTracking();
  }

  Future<void> _initLocationTracking() async {
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
      if (permission == LocationPermission.denied) {
        return Future.error('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return Future.error(
        'Location permissions are permanently denied, cannot request.',
      );
    }

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
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('GPS tracking started')));
  }

  void stopRecording(BuildContext context) {
    _isRecording = false;
    notifyListeners();
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('GPS tracking stopped')));
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
    super.dispose();
  }
}
