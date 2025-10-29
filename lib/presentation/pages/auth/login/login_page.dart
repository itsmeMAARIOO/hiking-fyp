import 'dart:math';
import 'package:flutter/material.dart';
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

class _LoginPageState extends State<LoginPage> with TickerProviderStateMixin {
  late AnimationController _waveController;
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late AnimationController _breatheController;

  @override
  void initState() {
    super.initState();

    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..forward();

    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..forward();

    _breatheController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3500),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _waveController.dispose();
    _fadeController.dispose();
    _slideController.dispose();
    _breatheController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(LoginController());
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Stack(
        children: [
          // Layered gradient background
          Container(
            decoration: const BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.topLeft,
                radius: 1.5,
                colors: [
                  kMediumSage,
                  kDeepForest,
                  kDeepTeal,
                  Color(0xFF0d2929),
                ],
                stops: [0.0, 0.4, 0.7, 1.0],
              ),
            ),
          ),

          // Animated wave patterns
          AnimatedBuilder(
            animation: _waveController,
            builder: (context, child) {
              return CustomPaint(
                size: size,
                painter: _WavePainter(animationValue: _waveController.value),
              );
            },
          ),

          // Content split layout
          SafeArea(
            child: Stack(
              children: [
                // Top section - Brand identity (fixed)
                Align(
                  alignment: Alignment.topCenter,
                  child: Container(
                    padding: const EdgeInsets.all(32),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        return FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.center,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // Breathing logo
                              AnimatedBuilder(
                                animation: _breatheController,
                                builder: (context, child) {
                                  return Transform.scale(
                                    scale:
                                        1.0 + (_breatheController.value * 0.08),
                                    child: FadeTransition(
                                      opacity: _fadeController,
                                      child: Container(
                                        padding: const EdgeInsets.all(20),
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          gradient: LinearGradient(
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                            colors: [
                                              kSoftMint.withOpacity(0.3),
                                              kMediumSage.withOpacity(0.2),
                                            ],
                                          ),
                                        ),
                                        child: Image.asset(
                                          ImageLocation.appLogo,
                                          width: 120,
                                          height: 120,
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),

                              const SizedBox(height: 24),

                              // Minimalist title
                              FadeTransition(
                                opacity: _fadeController,
                                child: Column(
                                  children: [
                                    Text(
                                      "TrailGuard",
                                      style: TextStyle(
                                        fontSize: 42,
                                        fontWeight: FontWeight.w300,
                                        letterSpacing: 8,
                                        color: Colors.white,
                                        shadows: [
                                          Shadow(
                                            color: kSoftMint.withOpacity(0.5),
                                            blurRadius: 20,
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Container(
                                      height: 2,
                                      width: 60,
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [
                                            Colors.transparent,
                                            kSoftMint,
                                            Colors.transparent,
                                          ],
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      "Explore with Confidence",
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w400,
                                        letterSpacing: 2,
                                        color: kSoftMint.withOpacity(0.9),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ),

                // Bottom section - Login form (draggable sheet)
                DraggableScrollableSheet(
                  initialChildSize: 0.60,
                  minChildSize: 0.55,
                  maxChildSize: 0.70,
                  builder: (context, scrollController) {
                    return Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(50),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.3),
                            blurRadius: 50,
                            offset: const Offset(0, -10),
                          ),
                        ],
                      ),
                      child: SingleChildScrollView(
                        controller: scrollController,
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Drag indicator
                            Center(
                              child: Container(
                                width: 50,
                                height: 5,
                                decoration: BoxDecoration(
                                  color: kMediumSage.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(3),
                                ),
                              ),
                            ),

                            const SizedBox(height: 6),

                            // Welcome header
                            Text(
                              "Welcome Back",
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.w700,
                                color: kDeepTeal,
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              "Sign in to continue your adventure",
                              style: TextStyle(
                                fontSize: 15,
                                color: kDeepTeal.withOpacity(0.6),
                                fontWeight: FontWeight.w500,
                              ),
                            ),

                            const SizedBox(height: 15),

                            // Email input
                            _buildMinimalTextField(
                              label: "Email Address",
                              icon: Icons.alternate_email_rounded,
                              onChanged: (value) =>
                                  controller.email.value = value,
                            ),

                            const SizedBox(height: 15),

                            // Password input
                            Obx(
                              () => _buildMinimalTextField(
                                label: "Password",
                                icon: Icons.lock_outline_rounded,
                                isPassword: true,
                                obscureText: controller.isPasswordHidden.value,
                                onChanged: (value) =>
                                    controller.password.value = value,
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    controller.isPasswordHidden.value
                                        ? Icons.visibility_off_outlined
                                        : Icons.visibility_outlined,
                                    color: kMediumSage,
                                    size: 22,
                                  ),
                                  onPressed: () {
                                    controller.isPasswordHidden.value =
                                        !controller.isPasswordHidden.value;
                                  },
                                ),
                              ),
                            ),

                            const SizedBox(height: 18),

                            // Login button
                            Obx(
                              () => Container(
                                height: 60,
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [kMediumSage, kDeepForest],
                                  ),
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: kMediumSage.withOpacity(0.4),
                                      blurRadius: 20,
                                      offset: const Offset(0, 10),
                                    ),
                                  ],
                                ),
                                child: ElevatedButton(
                                  onPressed: controller.isLoading.value
                                      ? null
                                      : () => controller.login(),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.transparent,
                                    shadowColor: Colors.transparent,
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
                                      : const Text(
                                          "Sign In",
                                          style: TextStyle(
                                            fontSize: 17,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.white,
                                            letterSpacing: 1,
                                          ),
                                        ),
                                ),
                              ),
                            ),

                            const SizedBox(height: 24),

                            // Divider with text
                            Row(
                              children: [
                                Expanded(
                                  child: Divider(
                                    color: kDeepTeal.withOpacity(0.2),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                  ),
                                  child: Text(
                                    "New to TrailGuard?",
                                    style: TextStyle(
                                      color: kDeepTeal.withOpacity(0.5),
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: Divider(
                                    color: kDeepTeal.withOpacity(0.2),
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 24),

                            // Sign up button
                            Container(
                              height: 60,
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: kMediumSage,
                                  width: 2,
                                ),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: ElevatedButton(
                                onPressed: () => Get.toNamed(AppRoutes.signup),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  shadowColor: Colors.transparent,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.person_add_outlined,
                                      color: kDeepForest,
                                      size: 22,
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      "Create Account",
                                      style: TextStyle(
                                        fontSize: 17,
                                        fontWeight: FontWeight.w600,
                                        color: kDeepForest,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMinimalTextField({
    required String label,
    required IconData icon,
    required Function(String) onChanged,
    bool isPassword = false,
    bool obscureText = false,
    Widget? suffixIcon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: kDeepTeal.withOpacity(0.8),
              letterSpacing: 0.5,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: kSoftMint.withOpacity(0.08),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: kMediumSage.withOpacity(0.3), width: 1.5),
          ),
          child: TextField(
            obscureText: obscureText,
            onChanged: onChanged,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: kDeepTeal,
            ),
            decoration: InputDecoration(
              prefixIcon: Icon(icon, color: kMediumSage, size: 22),
              suffixIcon: suffixIcon,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 18,
              ),
              filled: true,
              fillColor: Colors.transparent,
            ),
          ),
        ),
      ],
    );
  }
}

// Wave pattern painter
class _WavePainter extends CustomPainter {
  final double animationValue;

  _WavePainter({required this.animationValue});

  @override
  void paint(Canvas canvas, Size size) {
    final paint1 = Paint()
      ..color = kSoftMint.withOpacity(0.1)
      ..style = PaintingStyle.fill;

    final paint2 = Paint()
      ..color = kMediumSage.withOpacity(0.08)
      ..style = PaintingStyle.fill;

    final path1 = Path();
    final path2 = Path();

    // First wave
    path1.moveTo(0, size.height * 0.3);
    for (double i = 0; i <= size.width; i++) {
      path1.lineTo(
        i,
        size.height * 0.3 +
            sin((i / size.width * 2 * pi) + (animationValue * 2 * pi)) * 30,
      );
    }
    path1.lineTo(size.width, 0);
    path1.lineTo(0, 0);
    path1.close();

    // Second wave
    path2.moveTo(0, size.height * 0.5);
    for (double i = 0; i <= size.width; i++) {
      path2.lineTo(
        i,
        size.height * 0.5 +
            sin((i / size.width * 2 * pi) + (animationValue * 2 * pi) + 1) * 40,
      );
    }
    path2.lineTo(size.width, 0);
    path2.lineTo(0, 0);
    path2.close();

    canvas.drawPath(path1, paint1);
    canvas.drawPath(path2, paint2);

    // Circular patterns
    final circlePaint = Paint()
      ..color = Colors.white.withOpacity(0.03)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(
      Offset(size.width * 0.8, size.height * 0.2),
      80,
      circlePaint,
    );
    canvas.drawCircle(
      Offset(size.width * 0.2, size.height * 0.4),
      60,
      circlePaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
