import 'package:get/get.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class SplashController extends GetxController {
  final storage = const FlutterSecureStorage();

  @override
  void onInit() {
    super.onInit();
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    await Future.delayed(const Duration(seconds: 2)); // show splash for 2s

    String? token = await storage.read(key: "authToken");

    if (token != null) {
      try {
        final response = await http.get(
          Uri.parse("http://10.0.2.2:3000/validate-token"), // your backend
          headers: {"Authorization": "Bearer $token"},
        );

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          if (data["valid"] == true) {
            Get.offAllNamed("/dashboard"); // ✅ already logged in
            return;
          }
        }
      } catch (e) {
        // ignore, fallback to login
      }
    }

    Get.offAllNamed("/login"); // ⛔ no valid token → go to login
  }
}
