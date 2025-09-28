import 'package:flutter/material.dart';

class ProfileProvider with ChangeNotifier {
  String name = 'Alex Thompson';
  String email = 'alex.thompson@email.com';
  String emergencyContact = 'Jane Thompson - (555) 123-4567';
  String joinDate = 'March 2024';
  int totalHikes = 23;
  String totalDistance = '127 miles';

  Map<String, bool> settings = {
    'pushNotifications': true,
    'locationSharing': true,
    'fallDetection': true,
    'autoCheckIn': true,
    'weatherAlerts': true,
  };

  void toggleSetting(String key, bool value) {
    settings[key] = value;
    notifyListeners();
  }

  void editProfile(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Profile editing feature coming soon...')),
    );
  }

  void logout(BuildContext context) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Logged out successfully')));
  }
}
