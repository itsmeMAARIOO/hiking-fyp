import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:hikingapp/config/images/image_locations.dart';
import 'package:hikingapp/config/routes.dart';
import 'package:hikingapp/presentation/styles/colors.dart';
import 'package:hikingapp/presentation/widgets/loading_overlay.dart';
import 'package:hikingapp/services/auth_services.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  final TextEditingController _emailController = TextEditingController();
  bool _isLoading = false;
  String _errorText = '';
  bool _submitted = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _animationController.forward();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final email = _emailController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      setState(() => _errorText = 'Please enter a valid email');
      return;
    }
    setState(() {
      _errorText = '';
      _isLoading = true;
    });
    try {
      await AuthService.requestPasswordReset(email);
      setState(() => _submitted = true);
    } catch (e) {
      setState(() => _errorText = 'Failed to send reset email');
    } finally {
      await Future.delayed(const Duration(milliseconds: 600));
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: kDeepForest,
        body: Stack(
          children: [
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: size.height * 0.45,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset(ImageLocation.banner, fit: BoxFit.cover),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withOpacity(0.3),
                          Colors.transparent,
                          kDeepForest.withOpacity(0.8),
                        ],
                      ),
                    ),
                  ),
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
                            boxShadow: const [
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
                          'TRAILGUARD',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            letterSpacing: 4.0,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Reset your password',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white.withOpacity(0.85),
                            letterSpacing: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: SlideTransition(
                position: _slideAnimation,
                child: Container(
                  height: size.height * 0.62,
                  decoration: const BoxDecoration(
                    color: kLightCream,
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
                            'Forgot Password',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                              color: kDeepForest,
                            ),
                          ),
                          const SizedBox(height: 16),
                          if (!_submitted) ...[
                            _CleanTextField(
                              label: 'Email',
                              icon: Icons.email_outlined,
                              onChanged: (v) {
                                if (_errorText.isNotEmpty) {
                                  setState(() => _errorText = '');
                                }
                              },
                              controller: _emailController,
                              errorText: _errorText.isNotEmpty
                                  ? _errorText
                                  : null,
                            ),
                            const SizedBox(height: 24),
                            SizedBox(
                              width: double.infinity,
                              height: 56,
                              child: ElevatedButton(
                                onPressed: _isLoading ? null : _submit,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: kDeepTeal,
                                  foregroundColor: Colors.white,
                                  elevation: 8,
                                  shadowColor: kDeepTeal.withOpacity(0.4),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                                child: _isLoading
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
                                            'Send Reset Link',
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          SizedBox(width: 8),
                                          Icon(
                                            Icons.mail_outline_rounded,
                                            size: 20,
                                          ),
                                        ],
                                      ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Center(
                              child: GestureDetector(
                                onTap: () => Get.toNamed(AppRoutes.login),
                                child: RichText(
                                  text: const TextSpan(
                                    text: 'Return to ',
                                    style: TextStyle(
                                      color: kDeepForest,
                                      fontSize: 14,
                                    ),
                                    children: [
                                      TextSpan(
                                        text: 'Sign In',
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
                          ] else ...[
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: const [
                                  BoxShadow(
                                    color: Colors.black12,
                                    blurRadius: 12,
                                    offset: Offset(0, 6),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: const [
                                  Text(
                                    'Email Sent',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w800,
                                      color: kDeepForest,
                                    ),
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    'Check your email for a link to reset your password.',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: kDeepForest,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 24),
                            SizedBox(
                              width: double.infinity,
                              height: 56,
                              child: ElevatedButton(
                                onPressed: () => Get.toNamed(AppRoutes.login),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: kDeepTeal,
                                  foregroundColor: Colors.white,
                                  elevation: 8,
                                  shadowColor: kDeepTeal.withOpacity(0.4),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                                child: const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      'Back to Sign In',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    SizedBox(width: 8),
                                    Icon(Icons.arrow_forward_rounded, size: 20),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            LoadingOverlay(
              visible: _isLoading,
              message: 'Sending reset email...',
              shadeColor: Colors.black.withOpacity(0.08),
              spinnerColor: kMediumSage,
              spinnerBackgroundColor: kMediumSage.withOpacity(0.2),
              logoAsset: ImageLocation.appLogo,
              size: 110,
            ),
          ],
        ),
      ),
    );
  }
}

class _CleanTextField extends StatelessWidget {
  final String label;
  final IconData icon;
  final Function(String) onChanged;
  final String? errorText;
  final TextEditingController? controller;

  const _CleanTextField({
    required this.label,
    required this.icon,
    required this.onChanged,
    this.errorText,
    this.controller,
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
          controller: controller,
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
          keyboardType: TextInputType.emailAddress,
        ),
      ],
    );
  }
}
