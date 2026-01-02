import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class AuthProvider with ChangeNotifier {
  String? userId;
  String? userEmail;
  String? userName;
  Map<String, dynamic>? _userData;

  Map<String, dynamic>? get userData => _userData;

  Future<void> setUser(Map<String, dynamic> data) async {
    _userData = data;
    userId = data['id']?.toString();
    userEmail = data['email'];
    userName = data['name'] ?? 'User';
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_data', jsonEncode(data));
    } catch (e) {
      debugPrint('Error saving user data: $e');
    }
  }

  Future<void> clearUser() async {
    _userData = null;
    userId = null;
    userEmail = null;
    userName = null;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('user_data');
    } catch (e) {
      debugPrint('Error clearing user data: $e');
    }
  }

  Future<bool> tryAutoLogin() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (!prefs.containsKey('user_data')) return false;

      final userDataStr = prefs.getString('user_data');
      if (userDataStr == null) return false;

      final data = jsonDecode(userDataStr) as Map<String, dynamic>;
      _userData = data;
      userId = data['id']?.toString();
      userEmail = data['email'];
      userName = data['name'] ?? 'User';
      notifyListeners();
      return true;
    } catch (e) {
      return false;
    }
  }
}
