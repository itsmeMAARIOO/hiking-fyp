import 'package:flutter/material.dart';

class ProfileProvider with ChangeNotifier {
  String? userId;
  String? userEmail;
  String? userName;
  String? phone;
  String? profileImage;
  String? emergencyContact;
  int totalHikes = 0;
  String totalDistance = '0 miles';

  // Safety toggle settings with default values
  Map<String, bool> settings = {
    'pushNotifications': false,
    'locationSharing': false,
    'fallDetection': false,
    'autoCheckIn': false,
    'weatherAlerts': false,
  };

  bool isLoading = false;

  // Update all profile fields including toggle settings
  void setProfile(Map<String, dynamic> data) {
    userId = data['id']?.toString();
    userEmail = data['email'];
    userName = data['name'] ?? 'User';
    phone = data['phone'] ?? '';
    profileImage = data['profileImage'];

    // Store full emergency contact as Map<String, String>
    if (data['emergencyContact'] != null) {
      if (data['emergencyContact'] is Map<String, dynamic>) {
        final ec = data['emergencyContact'] as Map<String, dynamic>;
        emergencyContact = '${ec['name']} - ${ec['phone']}';
      } else if (data['emergencyContact'] is String) {
        emergencyContact = data['emergencyContact'];
      }
    } else {
      emergencyContact = null;
    }

    totalHikes = data['totalHikes'] ?? totalHikes;
    totalDistance = data['totalDistance'] ?? totalDistance;

    // Load toggle settings safely
    if (data['settings'] != null && data['settings'] is Map<String, dynamic>) {
      final s = data['settings'] as Map<String, dynamic>;
      settings = {
        'pushNotifications': s['pushNotifications'] == true,
        'locationSharing': s['locationSharing'] == true,
        'fallDetection': s['fallDetection'] == true,
        'autoCheckIn': s['autoCheckIn'] == true,
        'weatherAlerts': s['weatherAlerts'] == true,
      };
    }

    notifyListeners();
  }

  // Update UI toggle state locally (used when controller updates)
  void toggleSetting(String key, bool value) {
    settings[key] = value;
    notifyListeners();
  }
}
