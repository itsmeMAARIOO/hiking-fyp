import 'package:get/get.dart';

class LoginController extends GetxController {
  var isLoading = false.obs;

  // For text fields
  var email = ''.obs;
  var password = ''.obs;

  void login() async {
    if (email.isEmpty || password.isEmpty) {
      Get.snackbar("Error", "Please enter email and password");
      return;
    }

    isLoading.value = true;

    // TODO: Call your MongoDB authentication logic here
    await Future.delayed(const Duration(seconds: 2));

    isLoading.value = false;

    // If login success
    Get.offAllNamed("/home");
  }
}
