import 'package:flutter/material.dart';

class DashboardProvider extends ChangeNotifier {
  bool _isTracking = false;
  bool _isOnline = true;
  DateTime _lastCheckIn = DateTime.now();
  int _groupMembers = 5;

  bool get isTracking => _isTracking;
  bool get isOnline => _isOnline;
  DateTime get lastCheckIn => _lastCheckIn;
  int get groupMembers => _groupMembers;

  void toggleTracking() {
    _isTracking = !_isTracking;
    notifyListeners();
  }

  void checkIn() {
    _lastCheckIn = DateTime.now();
    notifyListeners();
  }

  // Optional: Methods to update connectivity, group members, etc.
  void setOnline(bool status) {
    _isOnline = status;
    notifyListeners();
  }

  void updateGroupMembers(int count) {
    _groupMembers = count;
    notifyListeners();
  }
}
