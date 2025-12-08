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

  // Inline error messages for fields
  var emailError = ''.obs;
  var passwordError = ''.obs;

  // Password visibility
  var isPasswordHidden = true.obs;

  Future<void> login() async {
    // Clear previous errors
    emailError.value = '';
    passwordError.value = '';

    final trimmedEmail = email.value.trim();
    final trimmedPassword = password.value.trim();

    // Basic email format validation
    final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

    // Required checks and format validation
    if (trimmedEmail.isEmpty) {
      emailError.value = 'Email is required';
      return;
    }
    if (!emailRegex.hasMatch(trimmedEmail)) {
      emailError.value = 'Please enter a valid email address';
      return;
    }
    if (trimmedPassword.isEmpty) {
      passwordError.value = 'Password is required';
      return;
    }

    try {
      isLoading.value = true;

      // 🔥 Call backend API
      final response = await AuthService.login(trimmedEmail, trimmedPassword);

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
        // Prefer field-level errors instead of snackbars
        final errorMsg =
            response["message"] ?? response["error"] ?? "Invalid credentials";

        // Heuristic mapping: if the server hints email issues, show on email; otherwise on password
        final lowerMsg = errorMsg.toString().toLowerCase();
        if (lowerMsg.contains('email')) {
          emailError.value = errorMsg;
        } else {
          passwordError.value = 'Incorrect email or password';
        }
      }
    } catch (e) {
      // Connection issues shown as a generic password field error to avoid snackbars
      passwordError.value = 'Wrong password. Please try again.';
    } finally {
      isLoading.value = false;
    }
  }
}
