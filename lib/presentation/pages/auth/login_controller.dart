import 'package:get/get.dart';
import 'package:hikingapp/presentation/widgets/bottom_nav_bar.dart';
import 'package:hikingapp/services/api_services.dart';

class LoginController extends GetxController {
  var isLoading = false.obs;

  // For text fields
  var email = ''.obs;
  var password = ''.obs;

  Future<void> login() async {
    if (email.value.isEmpty || password.value.isEmpty) {
      Get.snackbar("Error", "Please enter email and password");
      return;
    }

    try {
      isLoading.value = true;

      final response = await ApiService.login(
        email.value.trim(),
        password.value.trim(),
      );

      // ✅ Adjust check to match backend response
      if (response.containsKey("id") && response.containsKey("email")) {
        // Save user info if needed
        // Example: GetStorage().write("user", response);

        Get.snackbar("Success", "Welcome back, ${response["name"]}!");

        // Navigate to dashboard
        Get.offAllNamed("/dashboard");
      } else {
        Get.snackbar("Error", response["message"] ?? "Login failed");
      }
    } catch (e) {
      Get.snackbar("Error", "Something went wrong: $e");
    } finally {
      isLoading.value = false;
    }
  }
}
