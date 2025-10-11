import 'package:get/get.dart';
import 'package:hikingapp/config/routes.dart';
import 'package:hikingapp/providers/auth_provider.dart';
import 'package:hikingapp/providers/profile_provider.dart';
import 'package:hikingapp/services/auth_services.dart';
import 'package:hikingapp/utils/snackbar_helper.dart';
import 'package:provider/provider.dart';

class LoginController extends GetxController {
  var isLoading = false.obs;

  // Text field bindings
  var email = ''.obs;
  var password = ''.obs;

  // Password visibility
  var isPasswordHidden = true.obs;

  Future<void> login() async {
    if (email.value.trim().isEmpty || password.value.trim().isEmpty) {
      SnackbarHelper.showError("Error", "Please enter email and password");
      return;
    }

    try {
      isLoading.value = true;

      // 🔥 Call backend API
      final response = await ApiService.login(
        email.value.trim(),
        password.value.trim(),
      );

      if (response.containsKey("id") &&
          response.containsKey("email") &&
          response["id"] != null) {
        // ✅ Get AuthProvider
        final authProvider = Get.context!.read<AuthProvider>();
        authProvider.setUser({
          'id': response['id'],
          'email': response['email'],
          'name': response['name'] ?? 'User',
          'profileImage': response['profileImage'], // ✅ Added here
        });

        // ✅ Get ProfileProvider
        final profileProvider = Get.context!.read<ProfileProvider>();
        profileProvider.setProfile({
          'id': response['id'],
          'email': response['email'],
          'name': response['name'] ?? 'User',
          'profileImage': response['profileImage'], // ✅ Added here
        });

        SnackbarHelper.showSuccess(
          "Success",
          "Welcome back, ${response["name"] ?? "User"}!",
        );

        Get.offAllNamed(AppRoutes.dashboard);
      } else {
        final errorMsg =
            response["message"] ??
            response["error"] ??
            "Login failed. Please try again.";
        SnackbarHelper.showError("Error", errorMsg);
      }
    } catch (e) {
      SnackbarHelper.showError(
        "Error",
        "Could not connect to server. Please check your internet or try again.\n\nDetails: $e",
      );
    } finally {
      isLoading.value = false;
    }
  }
}
