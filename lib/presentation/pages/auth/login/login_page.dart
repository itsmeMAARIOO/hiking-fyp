import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:hikingapp/config/images/image_locations.dart';
import 'package:hikingapp/config/routes.dart';
import 'login_controller.dart';
import 'package:hikingapp/presentation/styles/colors.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Curves.easeOutCubic,
          ),
        );

    // Start animation after build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _animationController.forward();
    });
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

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness:
            Brightness.light, // White icons for image header
      ),
      child: Scaffold(
        backgroundColor: kDeepForest, // Fallback color
        body: Stack(
          children: [
            // =================================================
            // 1. TOP HERO IMAGE (Atmospheric)
            // =================================================
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: size.height * 0.45, // Takes top 45%
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Replace with your asset image or a network placeholder
                  Image.asset(ImageLocation.banner, fit: BoxFit.cover),
                  // Gradient Overlay for text legibility
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withOpacity(0.3),
                          Colors.transparent,
                          kDeepForest.withOpacity(
                            0.8,
                          ), // Fade into bottom sheet
                        ],
                      ),
                    ),
                  ),
                  // App Logo / Title
                  Positioned(
                    top: size.height * 0.12,
                    left: 0,
                    right: 0,
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withOpacity(0.2),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.3),
                            ),
                            boxShadow: [
                              BoxShadow(color: Colors.black26, blurRadius: 20),
                            ],
                          ),
                          child: Image.asset(
                            ImageLocation.appLogo,
                            width: 80,
                            height: 80,
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          "TRAILGUARD",
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            letterSpacing: 4.0,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "Adventure Safely",
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white.withOpacity(0.8),
                            letterSpacing: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // =================================================
            // 2. BOTTOM SHEET (Login Form)
            // =================================================
            Align(
              alignment: Alignment.bottomCenter,
              child: SlideTransition(
                position: _slideAnimation,
                child: Container(
                  height: size.height * 0.62, // Takes bottom 62% (overlap)
                  decoration: const BoxDecoration(
                    color: kLightCream, // Your app bg color
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(32),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 30,
                        offset: Offset(0, -10),
                      ),
                    ],
                  ),
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(32, 40, 32, 32),
                      physics: const BouncingScrollPhysics(),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Welcome Back",
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                              color: kDeepForest,
                            ),
                          ),
                          const SizedBox(height: 16),

                          // --- Email Field ---
                          Obx(
                            () => _CleanTextField(
                              label: "Email",
                              icon: Icons.email_outlined,
                              onChanged: (v) {
                                controller.email.value = v;
                                if (controller.emailError.value.isNotEmpty) {
                                  controller.emailError.value = '';
                                }
                              },
                              errorText: controller.emailError.value.isNotEmpty
                                  ? controller.emailError.value
                                  : null,
                            ),
                          ),

                          const SizedBox(height: 20),

                          // --- Password Field ---
                          Obx(
                            () => _CleanTextField(
                              label: "Password",
                              icon: Icons.lock_outline_rounded,
                              isPassword: true,
                              obscureText: controller.isPasswordHidden.value,
                              onToggleVisibility: () =>
                                  controller.isPasswordHidden.toggle(),
                              onChanged: (v) {
                                controller.password.value = v;
                                if (controller.passwordError.value.isNotEmpty) {
                                  controller.passwordError.value = '';
                                }
                              },
                              errorText:
                                  controller.passwordError.value.isNotEmpty
                                  ? controller.passwordError.value
                                  : null,
                            ),
                          ),

                          // Forgot Password
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: () => Get.toNamed(AppRoutes.forgotPassword),
                              style: TextButton.styleFrom(
                                padding: EdgeInsets.zero,
                              ),
                              child: Text(
                                "Forgot Password?",
                                style: TextStyle(
                                  color: kDeepTeal.withOpacity(0.8),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),

                          // --- Sign In Button ---
                          Obx(
                            () => SizedBox(
                              width: double.infinity,
                              height: 56,
                              child: ElevatedButton(
                                onPressed: controller.isLoading.value
                                    ? null
                                    : () => controller.login(),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: kDeepTeal,
                                  foregroundColor: Colors.white,
                                  elevation: 8,
                                  shadowColor: kDeepTeal.withOpacity(0.4),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                                child: controller.isLoading.value
                                    ? const SizedBox(
                                        height: 24,
                                        width: 24,
                                        child: CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 2.5,
                                        ),
                                      )
                                    : const Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            "Sign In",
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          SizedBox(width: 8),
                                          Icon(
                                            Icons.arrow_forward_rounded,
                                            size: 20,
                                          ),
                                        ],
                                      ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 32),

                          // --- Footer ---
                          Row(
                            children: [
                              Expanded(child: Divider(color: Colors.grey[300])),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                ),
                                child: Text(
                                  "OR",
                                  style: TextStyle(
                                    color: Colors.grey[400],
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              Expanded(child: Divider(color: Colors.grey[300])),
                            ],
                          ),

                          const SizedBox(height: 24),

                          Center(
                            child: GestureDetector(
                              onTap: () => Get.toNamed(AppRoutes.signup),
                              child: RichText(
                                text: TextSpan(
                                  text: "Don't have an account? ",
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 14,
                                  ),
                                  children: const [
                                    TextSpan(
                                      text: "Create one",
                                      style: TextStyle(
                                        color: kDeepTeal,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
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
            ),
          ],
        ),
      ),
    );
  }
}

// =================================================
// 3. CLEAN TEXT FIELD WIDGET
// =================================================
class _CleanTextField extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isPassword;
  final bool obscureText;
  final VoidCallback? onToggleVisibility;
  final Function(String) onChanged;
  final String? errorText;

  const _CleanTextField({
    required this.label,
    required this.icon,
    required this.onChanged,
    this.isPassword = false,
    this.obscureText = false,
    this.onToggleVisibility,
    this.errorText,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: kDeepForest,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          obscureText: obscureText,
          onChanged: onChanged,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: kDeepForest,
          ),
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white,
            prefixIcon: Icon(icon, color: kMediumSage, size: 22),
            suffixIcon: isPassword
                ? IconButton(
                    icon: Icon(
                      obscureText
                          ? Icons.visibility_off_rounded
                          : Icons.visibility_rounded,
                      color: Colors.grey[400],
                    ),
                    onPressed: onToggleVisibility,
                  )
                : null,
            contentPadding: const EdgeInsets.symmetric(
              vertical: 16,
              horizontal: 16,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: Colors.grey.shade200, width: 1.5),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: kDeepTeal, width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
            ),
            errorText: errorText,
          ),
        ),
      ],
    );
  }
}
