import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:hikingapp/config/api_config.dart';
import 'package:hikingapp/utils/snackbar_helper.dart';
import 'package:http/http.dart' as http;

class SoloTrailServices {
  static final String baseUrl = "${ApiConfig.baseUrl}/solo";

  static Future<bool> saveSoloTrail({
    required BuildContext context,
    required String userId,
    required String trailName,
    required DateTime startTime,
    required DateTime endTime,
  }) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/save'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'userId': userId,
          'trailName': trailName,
          'startTime': startTime.toIso8601String(),
          'endTime': endTime.toIso8601String(),
        }),
      );

      if (res.statusCode == 200) {
        return true;
      }

      final data = jsonDecode(res.body);
      SnackbarHelper.showError('Save Failed', data['error'] ?? 'Unknown error');
      return false;
    } catch (e) {
      SnackbarHelper.showError('Network Error', e.toString());
      return false;
    }
  }
}
