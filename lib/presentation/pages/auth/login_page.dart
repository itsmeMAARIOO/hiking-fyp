import 'dart:math';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hikingapp/config/images/image_locations.dart';
import 'package:hikingapp/config/routes.dart';
import 'package:hikingapp/providers/auth_provider.dart';
import 'package:provider/provider.dart';
import 'login_controller.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;

  final List<String> backgroundGifs = [
    ImageLocation.climber,
    ImageLocation.icemount,
    ImageLocation.mountain,
    ImageLocation.mountains,
    ImageLocation.rocky,
    ImageLocation.route,
    ImageLocation.summit,
    ImageLocation.volcano,
    ImageLocation.winter,
  ];

  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(LoginController());
    final size = MediaQuery.of(context).size;
    final rows = (size.height / 50).ceil();
    final cols = (size.width / 50).ceil();
    return Scaffold(
      body: Stack(
        children: [
          // Background GIFs
          for (int r = 0; r < rows; r++)
            for (int c = 0; c < cols; c++)
              Positioned(
                top: r * 50 + _random.nextDouble() * 25,
                left: c * 50 + _random.nextDouble() * 25,
                child: Opacity(
                  opacity: 0.1 + _random.nextDouble() * 0.15,
                  child: Transform.rotate(
                    angle: _random.nextDouble() * 0.5 - 0.25,
                    child: Image.asset(
                      backgroundGifs[_random.nextInt(backgroundGifs.length)],
                      width: 25 + _random.nextDouble() * 25,
                      height: 25 + _random.nextDouble() * 25,
                    ),
                  ),
                ),
              ),

          // Dark overlay for better readability
          Container(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.center,
                radius: 1.0,
                colors: [
                  Colors.black.withOpacity(0.4),
                  Colors.black.withOpacity(0.7),
                ],
              ),
            ),
          ),

          // Main content
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: FadeTransition(
                  opacity: _animationController,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Logo with animation
                      ScaleTransition(
                        scale: Tween<double>(begin: 0.5, end: 1.0).animate(
                          CurvedAnimation(
                            parent: _animationController,
                            curve: Curves.elasticOut,
                          ),
                        ),
                        child: Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.4),
                                blurRadius: 40,
                                spreadRadius: 10,
                              ),
                            ],
                          ),
                          child: Image.asset(
                            ImageLocation.appLogo,
                            width: 100,
                            height: 100,
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // App name
                      const Text(
                        "TrailGuard",
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          shadows: [
                            Shadow(
                              offset: Offset(2, 2),
                              blurRadius: 4,
                              color: Colors.black87,
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 8),

                      const Text(
                        "Welcome Back",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 1.5,
                          color: Colors.white70,
                        ),
                      ),

                      const SizedBox(height: 40),

                      // Login form container
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.95),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.3),
                              blurRadius: 30,
                              spreadRadius: 5,
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            // Email field
                            TextField(
                              decoration: InputDecoration(
                                labelText: "Email",
                                prefixIcon: const Icon(
                                  Icons.email_outlined,
                                  color: Colors.green,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                    color: Colors.green,
                                    width: 2,
                                  ),
                                ),
                                filled: true,
                                fillColor: Colors.grey[50],
                              ),
                              onChanged: (value) =>
                                  controller.email.value = value,
                            ),

                            const SizedBox(height: 20),

                            // Password field
                            Obx(
                              () => TextField(
                                obscureText: controller.isPasswordHidden.value,
                                decoration: InputDecoration(
                                  labelText: "Password",
                                  prefixIcon: const Icon(
                                    Icons.lock_outline,
                                    color: Colors.green,
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(
                                      color: Colors.green,
                                      width: 2,
                                    ),
                                  ),
                                  filled: true,
                                  fillColor: Colors.grey[50],
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      controller.isPasswordHidden.value
                                          ? Icons.visibility_off
                                          : Icons.visibility,
                                      color: Colors.green,
                                    ),
                                    onPressed: () {
                                      controller.isPasswordHidden.value =
                                          !controller.isPasswordHidden.value;
                                    },
                                  ),
                                ),
                                onChanged: (value) =>
                                    controller.password.value = value,
                              ),
                            ),

                            const SizedBox(height: 30),

                            // Login button
                            Obx(
                              () => ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green[700],
                                  foregroundColor: Colors.white,
                                  minimumSize: const Size.fromHeight(55),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  elevation: 5,
                                  shadowColor: Colors.green.withOpacity(0.5),
                                ),
                                onPressed: controller.isLoading.value
                                    ? null
                                    : () => controller.login(),
                                child: controller.isLoading.value
                                    ? const SizedBox(
                                        height: 24,
                                        width: 24,
                                        child: CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 2.5,
                                        ),
                                      )
                                    : const Text(
                                        "Login",
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: 1,
                                        ),
                                      ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 25),

                      // Sign up link
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: TextButton(
                          onPressed: () => Get.toNamed(AppRoutes.signup),
                          child: const Text(
                            "Don't have an account? Sign up",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
