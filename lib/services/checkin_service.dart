import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:hikingapp/providers/auth_provider.dart';
import 'package:hikingapp/providers/dashboard_provider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:provider/provider.dart';

class CheckInService {
  int _tapCount = 0;
  DateTime _firstTapTime = DateTime.now();
  final int _tapThresholdMs = 500;
  // static const baseUrl = 'http://10.0.2.2:3000/api/checkin';
  static const baseUrl = 'http://192.168.100.12:3000/api/checkin';

  Future<void> handleCheckInTripleTap(
    DashboardProvider dashboardProvider,
    BuildContext context,
  ) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final now = DateTime.now();

    if (now.difference(_firstTapTime).inMilliseconds > _tapThresholdMs) {
      _tapCount = 0;
      _firstTapTime = now;
    }

    _tapCount++;

    if (_tapCount >= 3) {
      _tapCount = 0;
      dashboardProvider.loadLastCheckIn(context);

      double latitude = 0.0;
      double longitude = 0.0;

      try {
        final position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        );
        latitude = position.latitude;
        longitude = position.longitude;
      } catch (_) {}

      print('userid isssssssssssssssssssssss');
      print(authProvider.userId);

      if (authProvider.userId == null) {
        print('❌ No userId found in AuthProvider.');
        return;
      }

      await saveCheckIn(
        userId: authProvider.userId!,
        // malaysia time
        checkinTime: DateTime.now().toUtc().add(const Duration(hours: 8)),
        lastCheckinTime: dashboardProvider.lastCheckIn,
        latitude: latitude,
        longitude: longitude,
        extraData: {'note': 'Manual triple-tap check-in'},
      );

      // ✅ Update dashboard provider instantly
      dashboardProvider.updateLastCheckIn(
        DateTime.now().toUtc().add(const Duration(hours: 8)),
      );
    }
  }

  Future<void> saveCheckIn({
    required String? userId,
    required DateTime checkinTime,
    required DateTime lastCheckinTime,
    required double latitude,
    required double longitude,
    Map<String, dynamic>? extraData,
  }) async {
    if (userId == null) throw Exception('User ID cannot be null');

    final body = {
      'userId': userId,
      'checkinTime': checkinTime.toIso8601String(),
      'lastCheckinTime': lastCheckinTime.toIso8601String(),
      'latitude': latitude,
      'longitude': longitude,
      'extraData': extraData ?? {},
    };
    print(body);
    final response = await http.post(
      Uri.parse(baseUrl),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to save check-in: ${response.body}');
    }
  }

  Future<DateTime?> fetchLastCheckIn(String userId) async {
    final response = await http.get(
      Uri.parse('http://192.168.100.12:3000/api/checkin/$userId'),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return DateTime.parse(data['checkinTime']);
    } else if (response.statusCode == 404) {
      return null; // No check-ins yet
    } else {
      throw Exception('Failed to fetch last check-in: ${response.body}');
    }
  }
}
