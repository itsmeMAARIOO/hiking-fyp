import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:hikingapp/providers/auth_provider.dart';
import 'package:hikingapp/providers/dashboard_provider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:hikingapp/config/api_config.dart';

import 'package:provider/provider.dart';

class CheckInService {
  int _tapCount = 0;
  DateTime _firstTapTime = DateTime.now();
  final int _tapThresholdMs = 500;
  final baseUrl = ApiConfig.baseUrl;

  // ✅ Remove duplicated /api
  late final url = "$baseUrl/checkin";

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

      DateTime? previousCheckIn = dashboardProvider.lastCheckIn;
      if (previousCheckIn == null) {
        await dashboardProvider.loadLastCheckIn(context);
        previousCheckIn = dashboardProvider.lastCheckIn;
      }

      double latitude = 0.0;
      double longitude = 0.0;

      try {
        final position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        );
        latitude = position.latitude;
        longitude = position.longitude;
      } catch (_) {}

      if (authProvider.userId == null) {
        print('❌ No userId found in AuthProvider.');
        return;
      }

      final currentCheckIn = DateTime.now();

      await saveCheckIn(
        userId: authProvider.userId!,
        checkinTime: currentCheckIn,
        lastCheckinTime: previousCheckIn,
        latitude: latitude,
        longitude: longitude,
        extraData: {'note': 'Manual triple-tap check-in'},
      );

      dashboardProvider.updateLastCheckIn(currentCheckIn);
    }
  }

  Future<void> saveCheckIn({
    required String? userId,
    required DateTime checkinTime,
    required DateTime? lastCheckinTime,
    required double latitude,
    required double longitude,
    Map<String, dynamic>? extraData,
  }) async {
    if (userId == null) throw Exception('User ID cannot be null');

    final body = {
      'userId': userId,
      'checkinTime': checkinTime.toIso8601String(),
      'lastCheckinTime': lastCheckinTime?.toIso8601String(),
      'latitude': latitude,
      'longitude': longitude,
      'extraData': extraData ?? {},
    };

    print('🌍 Sending check-in to $url');
    print(body);

    final response = await http.post(
      Uri.parse(url),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to save check-in: ${response.body}');
    }
  }

  Future<DateTime?> fetchLastCheckIn(String userId) async {
    // ✅ Do NOT prepend http:// if baseUrl already includes protocol
    final response = await http.get(Uri.parse('$baseUrl/checkin/$userId'));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final lastCheckinData = data['checkinTime'];

      if (lastCheckinData == null) return null;

      if (lastCheckinData is String) {
        return DateTime.parse(lastCheckinData);
      } else if (lastCheckinData is Map<String, dynamic>) {
        final millis = int.parse(lastCheckinData['\$date']['\$numberLong']);
        return DateTime.fromMillisecondsSinceEpoch(millis);
      } else {
        throw Exception('Unexpected checkinTime format: $lastCheckinData');
      }
    } else if (response.statusCode == 404) {
      return null;
    } else {
      throw Exception('Failed to fetch check-in: ${response.body}');
    }
  }
}

// class CheckInService {
//   int _tapCount = 0;
//   DateTime _firstTapTime = DateTime.now();
//   final int _tapThresholdMs = 500;
//   final baseUrl = ApiConfig.baseUrl;

//   // static const baseUrl = 'http://10.0.2.2:3000/api/checkin';
//   late final url = "$baseUrl/api/checkin";
//   //'http://192.168.100.12:3000/api/checkin';

//   Future<void> handleCheckInTripleTap(
//     DashboardProvider dashboardProvider,
//     BuildContext context,
//   ) async {
//     final authProvider = Provider.of<AuthProvider>(context, listen: false);
//     final now = DateTime.now();

//     if (now.difference(_firstTapTime).inMilliseconds > _tapThresholdMs) {
//       _tapCount = 0;
//       _firstTapTime = now;
//     }

//     _tapCount++;

//     if (_tapCount >= 3) {
//       _tapCount = 0;

//       // Fetch the last check-in from provider or backend
//       DateTime? previousCheckIn = dashboardProvider.lastCheckIn;
//       if (previousCheckIn == null) {
//         await dashboardProvider.loadLastCheckIn(context);
//         previousCheckIn = dashboardProvider.lastCheckIn;
//       }

//       double latitude = 0.0;
//       double longitude = 0.0;

//       try {
//         final position = await Geolocator.getCurrentPosition(
//           desiredAccuracy: LocationAccuracy.high,
//         );
//         latitude = position.latitude;
//         longitude = position.longitude;
//       } catch (_) {}

//       if (authProvider.userId == null) {
//         print('❌ No userId found in AuthProvider.');
//         return;
//       }

//       final currentCheckIn = DateTime.now().toUtc().add(
//         const Duration(hours: 8),
//       );

//       await saveCheckIn(
//         userId: authProvider.userId!,
//         checkinTime: currentCheckIn,
//         lastCheckinTime: previousCheckIn,
//         latitude: latitude,
//         longitude: longitude,
//         extraData: {'note': 'Manual triple-tap check-in'},
//       );

//       // Update provider with the new check-in time
//       dashboardProvider.updateLastCheckIn(currentCheckIn);
//     }
//   }

//   Future<void> saveCheckIn({
//     required String? userId,
//     required DateTime checkinTime,
//     required DateTime? lastCheckinTime,
//     required double latitude,
//     required double longitude,
//     Map<String, dynamic>? extraData,
//   }) async {
//     if (userId == null) throw Exception('User ID cannot be null');

//     final body = {
//       'userId': userId,
//       'checkinTime': checkinTime.toIso8601String(),
//       'lastCheckinTime': lastCheckinTime?.toIso8601String(),
//       'latitude': latitude,
//       'longitude': longitude,
//       'extraData': extraData ?? {},
//     };
//     print(body);
//     final response = await http.post(
//       Uri.parse(url),
//       headers: {'Content-Type': 'application/json'},
//       body: jsonEncode(body),
//     );

//     if (response.statusCode != 200) {
//       throw Exception('Failed to save check-in: ${response.body}');
//     }
//   }

//   Future<DateTime?> fetchLastCheckIn(String userId) async {
//     final response = await http.get(
//       Uri.parse('http://$baseUrl:3000/api/checkin/$userId'),
//     );

//     if (response.statusCode == 200) {
//       final data = jsonDecode(response.body);

//       final lastCheckinData = data['checkinTime'];

//       if (lastCheckinData == null) return null;

//       if (lastCheckinData is String) {
//         // ISO 8601 string
//         return DateTime.parse(lastCheckinData);
//       } else if (lastCheckinData is Map<String, dynamic>) {
//         // MongoDB $date format
//         final millis = int.parse(lastCheckinData['\$date']['\$numberLong']);
//         return DateTime.fromMillisecondsSinceEpoch(millis);
//       } else {
//         throw Exception('Unexpected checkinTime format: $lastCheckinData');
//       }
//     } else if (response.statusCode == 404) {
//       return null; // No check-ins yet
//     } else {
//       throw Exception('Failed to fetch check-in: ${response.body}');
//     }
//   }
// }
