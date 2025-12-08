import 'package:flutter/material.dart';

class ProfileProvider with ChangeNotifier {
  String? userId;
  String? userEmail;
  String? userName;
  String? phone;
  String? profileImage;
  List<Map<String, String>> emergencyContacts = [];
  int totalSoloHikes = 0;
  int totalGroupHikes = 0;

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

    emergencyContacts = [];
    if (data['emergencyContacts'] is List) {
      for (final c in (data['emergencyContacts'] as List)) {
        if (c is Map<String, dynamic>) {
          emergencyContacts.add({
            'name': (c['name'] ?? '').toString(),
            'email': (c['email'] ?? '').toString(),
            'phone': (c['phone'] ?? '').toString(),
            'share': ((c['share'] ?? false) as bool).toString(),
          });
        }
      }
    }

    

    // Preserve existing counts unless provided explicitly
    if (data.containsKey('totalSoloHikes')) {
      final v = data['totalSoloHikes'];
      if (v is num) {
        totalSoloHikes = v.toInt();
      } else if (v is String) {
        totalSoloHikes = int.tryParse(v) ?? totalSoloHikes;
      }
    }
    if (data.containsKey('totalGroupHikes')) {
      final v = data['totalGroupHikes'];
      if (v is num) {
        totalGroupHikes = v.toInt();
      } else if (v is String) {
        totalGroupHikes = int.tryParse(v) ?? totalGroupHikes;
      }
    }

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

  void setContactShare(int index, bool share) {
    if (index < 0 || index >= emergencyContacts.length) return;
    emergencyContacts[index]['share'] = share.toString();
    notifyListeners();
  }

  // Explicit setters for hike counts
  void setSoloHikeCount(int count) {
    totalSoloHikes = count;
    notifyListeners();
  }

  void setGroupHikeCount(int count) {
    totalGroupHikes = count;
    notifyListeners();
  }

  // Update UI toggle state locally (used when controller updates)
  void toggleSetting(String key, bool value) {
    settings[key] = value;
    notifyListeners();
  }
  // Hiking stats state
  String statsFilter = 'Year';
  List<Map<String, dynamic>> soloStats = [];
  List<Map<String, dynamic>> groupStats = [];
  int soloTotalFiltered = 0;
  int groupTotalFiltered = 0;
  int? selectedYear;
  List<int> availableYears = [];

  void setStatsFilter(String filter) {
    statsFilter = filter;
    notifyListeners();
  }

  void setHikingStats({
    required List<Map<String, dynamic>> solo,
    required List<Map<String, dynamic>> group,
    required int soloTotal,
    required int groupTotal,
    List<int>? years,
    int? year,
  }) {
    soloStats = solo;
    groupStats = group;
    soloTotalFiltered = soloTotal;
    groupTotalFiltered = groupTotal;
    if (years != null) availableYears = years;
    if (year != null) selectedYear = year;
    notifyListeners();
  }
}
