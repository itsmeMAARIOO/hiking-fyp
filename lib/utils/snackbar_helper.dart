// utils/snackbar_helper.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class SnackbarHelper {
  static const Color kMediumSage = Color(0xFF6baf89);
  static const Color kDeepTeal = Color(0xFF1c3f3f);

  static void showError(String title, String message) {
    Get.snackbar(
      title,
      message,
      backgroundColor: const Color(0xFFFF6B6B),
      colorText: Colors.white,
      snackPosition: SnackPosition.TOP,
      margin: const EdgeInsets.all(12),
      borderRadius: 16,
      duration: const Duration(seconds: 3),
      boxShadows: [
        BoxShadow(
          color: const Color(0xFFFF6B6B).withOpacity(0.3),
          blurRadius: 15,
          offset: const Offset(0, 5),
        ),
      ],
    );
  }

  static void showSuccess(String title, String message) {
    Get.snackbar(
      title,
      message,
      backgroundColor: kMediumSage,
      colorText: Colors.white,
      snackPosition: SnackPosition.TOP,
      margin: const EdgeInsets.all(12),
      borderRadius: 16,
      duration: const Duration(seconds: 2),
      boxShadows: [
        BoxShadow(
          color: kMediumSage.withOpacity(0.3),
          blurRadius: 15,
          offset: const Offset(0, 5),
        ),
      ],
    );
  }
}
