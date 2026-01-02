import 'package:get/get.dart';
import 'package:hikingapp/config/routes.dart';
import 'package:hikingapp/providers/auth_provider.dart';
import 'package:hikingapp/providers/profile_provider.dart';
import 'package:provider/provider.dart';

class SplashController extends GetxController {
  @override
  void onInit() {
    super.onInit();
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    await Future.delayed(const Duration(seconds: 2)); // show splash for 2s

    if (Get.context == null) {
      Get.offAllNamed(AppRoutes.login);
      return;
    }

    try {
      final authProvider = Provider.of<AuthProvider>(
        Get.context!,
        listen: false,
      );
      final isLoggedIn = await authProvider.tryAutoLogin();

      if (isLoggedIn) {
        // Sync ProfileProvider
        final profileProvider = Provider.of<ProfileProvider>(
          Get.context!,
          listen: false,
        );
        profileProvider.setProfile({
          'id': authProvider.userId,
          'email': authProvider.userEmail,
          'name': authProvider.userName,
          'profileImage': authProvider.userData?['profileImage'],
        });

        Get.offAllNamed(AppRoutes.dashboard);
      } else {
        Get.offAllNamed(AppRoutes.login);
      }
    } catch (e) {
      Get.offAllNamed(AppRoutes.login);
    }
  }
}
