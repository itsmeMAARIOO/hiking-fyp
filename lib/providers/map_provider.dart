import 'package:flutter/material.dart';

class MapProvider extends ChangeNotifier {
  bool _isRecording = false;
  List<Map<String, double>> _trailPoints = [];
  Map<String, double> _currentLocation = {
    'latitude': 37.7749,
    'longitude': -122.4194,
    'altitude': 152,
    'accuracy': 5,
  };

  bool get isRecording => _isRecording;
  List<Map<String, double>> get trailPoints => _trailPoints;
  Map<String, double> get currentLocation => _currentLocation;

  void startRecording(BuildContext context) {
    _isRecording = true;
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
}
