import 'package:get/get.dart';
import '/config/routes.dart';
import 'dart:async';

class SplashController extends GetxController {
  @override
  void onInit() {
    super.onInit();
    _navigateToNext();
  }

  void _navigateToNext() {
    // Simulate loading, e.g., fetching config, checking auth, etc.
    Timer(const Duration(seconds: 3), () {
      // Check if user is logged in, navigate accordingly
      bool isLoggedIn = false; // Replace with your auth check
      if (isLoggedIn) {
        Get.offAllNamed(AppRoutes.home);
      } else {
        Get.offAllNamed(AppRoutes.login);
      }
    });
  }
}
