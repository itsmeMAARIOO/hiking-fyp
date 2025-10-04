import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:hikingapp/providers/auth_provider.dart';
import 'package:hikingapp/services/checkin_service.dart';
import 'package:provider/provider.dart';

class DashboardProvider extends ChangeNotifier {
  bool _isTracking = false;
  bool _isOnline = true;
  DateTime _lastCheckIn = DateTime.now();
  int _groupMembers = 0;

  final CheckInService _checkInService = CheckInService();
  final Connectivity _connectivity = Connectivity();

  DashboardProvider() {
    _initConnectivity();
    _connectivity.onConnectivityChanged.listen(_updateConnectionStatus);
  }

  bool get isTracking => _isTracking;
  bool get isOnline => _isOnline;
  DateTime get lastCheckIn => _lastCheckIn;
  int get groupMembers => _groupMembers;

  void toggleTracking() {
    _isTracking = !_isTracking;
    notifyListeners();
  }

  Future<void> loadLastCheckIn(context) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userId = authProvider.userId;
    if (userId == null) return;

    try {
      final fetched = await _checkInService.fetchLastCheckIn(userId);
      if (fetched != null) {
        _lastCheckIn = fetched;
        notifyListeners();
      }
    } catch (e) {
      print('❌ Failed to load last check-in: $e');
    }
  }

  void updateLastCheckIn(DateTime newTime) {
    _lastCheckIn = newTime;
    notifyListeners(); // 👈 this rebuilds the UI
  }

  Future<void> _initConnectivity() async {
    final result = await _connectivity.checkConnectivity();
    _updateConnectionStatus(result);
  }

  void _updateConnectionStatus(ConnectivityResult result) {
    _isOnline = result != ConnectivityResult.none;
    notifyListeners();
  }

  void updateGroupMembers(int count) {
    _groupMembers = count;
    notifyListeners();
  }
}
