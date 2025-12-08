import 'package:flutter/material.dart';

class AuthProvider with ChangeNotifier {
  String? userId;
  String? userEmail;
  String? userName;

  void setUser(Map<String, dynamic> data) {
    userId = data['id']?.toString();
    userEmail = data['email'];
    userName = data['name'] ?? 'User';
    notifyListeners();
  }

  void clearUser() {
    userId = null;
    userEmail = null;
    userName = null;
    notifyListeners();
  }
}
