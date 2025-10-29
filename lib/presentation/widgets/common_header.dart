// lib/presentation/widgets/common_header.dart
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hikingapp/presentation/styles/colors.dart';

class CommonHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final String? lastError;
  final Widget? trailingWidget;
  final bool showBackgroundGradient;

  const CommonHeader({
    super.key,
    required this.title,
    required this.subtitle,
    this.lastError,
    this.trailingWidget,
    this.showBackgroundGradient = true,
  });

  @override
  Widget build(BuildContext context) {
    final statusBarHeight = MediaQuery.of(context).padding.top;

    // Ensure the status bar color matches the header
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: kDeepTeal,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: kDeepTeal,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
    );

    return Container(
      decoration: BoxDecoration(
        gradient: showBackgroundGradient
            ? LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [kDeepTeal, kDeepForest.withOpacity(0.9)],
              )
            : null,
      ),
      child: Column(
        children: [
          // Status bar background
          Container(height: statusBarHeight, color: kDeepTeal),
          // Header content
          Container(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    // Main content
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Title
                          Text(
                            title,
                            style: const TextStyle(
                              fontSize: 36,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              letterSpacing: -1.2,
                              height: 1.0,
                              shadows: [
                                Shadow(
                                  color: Colors.black38,
                                  blurRadius: 12,
                                  offset: Offset(2, 3),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          // Subtitle
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 18,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: kSoftMint.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(
                                color: kSoftMint.withOpacity(0.4),
                                width: 2.0,
                              ),
                            ),
                            child: Text(
                              subtitle,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.4,
                                height: 1.1,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Trailing widget
                    if (trailingWidget != null)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.3),
                            width: 2.0,
                          ),
                        ),
                        child: trailingWidget,
                      ),
                  ],
                ),
                // Error banner
                if (lastError != null) ...[
                  const SizedBox(height: 24),
                  GlassErrorBanner(message: lastError!),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class GlassErrorBanner extends StatelessWidget {
  final String message;
  const GlassErrorBanner({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.15),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.red.withOpacity(0.4), width: 2.0),
      ),
      child: Row(
        children: [
          // Warning icon
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.red.shade500,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.warning_rounded,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          // Error message
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Attention Required',
                  style: TextStyle(
                    color: Colors.red.shade50,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  message,
                  style: TextStyle(
                    color: Colors.red.shade100,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    height: 1.3,
                    letterSpacing: 0.2,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
