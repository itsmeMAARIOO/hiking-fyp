import 'dart:async';
import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:hikingapp/providers/auth_provider.dart';
import 'package:hikingapp/services/checkin_service.dart';
import 'package:provider/provider.dart';

class DashboardProvider extends ChangeNotifier {
  bool _isTracking = false;
  bool _isOnline = true;
  DateTime? _lastCheckIn;
  int _groupMembers = 0;

  String? _currentUserId;
  late final AuthProvider _authProvider;
  late final VoidCallback _authListener;

  final CheckInService _checkInService = CheckInService();
  final Connectivity _connectivity = Connectivity();
  StreamSubscription<ConnectivityResult>? _connectivitySubscription;

  DashboardProvider(AuthProvider authProvider) {
    _authProvider = authProvider;
    _authListener = _onAuthChanged;
    _authProvider.addListener(_authListener);

    _initConnectivity();

    // Listen to connectivity changes
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen(
      _updateConnectionStatus,
    );

    // Initial sync with auth state
    _onAuthChanged();
  }

  // ===== Getters =====
  bool get isTracking => _isTracking;
  bool get isOnline => _isOnline;
  DateTime? get lastCheckIn => _lastCheckIn;
  int get groupMembers => _groupMembers;

  // ===== Public Methods =====
  void toggleTracking() {
    _isTracking = !_isTracking;
    notifyListeners();
  }

  Future<void> loadLastCheckIn(BuildContext context) async {
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
      print('Failed to load last check-in: $e');
    }
  }

  void updateLastCheckIn(DateTime newTime) {
    _lastCheckIn = newTime;
    notifyListeners();
  }

  void updateGroupMembers(int count) {
    _groupMembers = count;
    notifyListeners();
  }

  // ===== Private Methods =====
  Future<void> _initConnectivity() async {
    try {
      final result = await _connectivity.checkConnectivity();
      _updateConnectionStatus(result);
    } catch (e) {
      print('Failed to initialize connectivity: $e');
    }
  }

  void _updateConnectionStatus(ConnectivityResult result) {
    _isOnline = result != ConnectivityResult.none;
    notifyListeners();
  }

  void _onAuthChanged() {
    final newUserId = _authProvider.userId;
    if (newUserId == _currentUserId) return;

    _currentUserId = newUserId;

    // Clear stale check-in when user logs out or switches accounts
    if (newUserId == null) {
      _lastCheckIn = null;
      notifyListeners();
      return;
    }

    // Fetch last check-in for the new user
    fetchLastCheckInOnInit(newUserId);
  }

  Future<void> fetchLastCheckInOnInit(String userId) async {
    try {
      final fetched = await _checkInService.fetchLastCheckIn(userId);
      if (fetched != null) {
        _lastCheckIn = fetched;
        notifyListeners();
      }
    } catch (e) {
      print('Failed to fetch last check-in: $e');
    }
  }

  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    // Remove auth listener to avoid leaks
    _authProvider.removeListener(_authListener);
    super.dispose();
  }
}
