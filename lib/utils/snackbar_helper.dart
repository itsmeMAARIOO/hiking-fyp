// utils/snackbar_helper.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hikingapp/presentation/styles/colors.dart';

class SnackbarHelper {
  // Uses centralized color palette from config/colors.dart

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
