// TODO Implement this library.
// utils/snackbar_helper.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class SnackbarHelper {
  static void showError(String title, String message) {
    Get.snackbar(
      title,
      message,
      backgroundColor: Colors.redAccent,
      colorText: Colors.white,
      snackPosition: SnackPosition.TOP,
      margin: const EdgeInsets.all(12),
      borderRadius: 8,
      duration: const Duration(seconds: 3),
    );
  }

  static void showSuccess(String title, String message) {
    Get.snackbar(
      title,
      message,
      backgroundColor: Colors.green,
      colorText: Colors.white,
      snackPosition: SnackPosition.TOP,
      margin: const EdgeInsets.all(12),
      borderRadius: 8,
      duration: const Duration(seconds: 2),
    );
  }
}
