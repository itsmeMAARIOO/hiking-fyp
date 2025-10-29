import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:hikingapp/presentation/pages/emergency/widgets/emergency_quick_actions.dart';
import 'package:hikingapp/presentation/widgets/common_header.dart';
import 'package:provider/provider.dart';
import 'widgets/emergency_button.dart';
import '../../../providers/emergency_provider.dart';
import 'package:hikingapp/presentation/styles/colors.dart';

class EmergencyPage extends StatelessWidget {
  const EmergencyPage({super.key});

  @override
  Widget build(BuildContext context) {
    final emergencyProvider = Provider.of<EmergencyProvider>(context);

    return Stack(
      children: [
        // Animated gradient background
        AnimatedContainer(
          duration: const Duration(milliseconds: 1200),
          curve: Curves.easeInOutCubic,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: emergencyProvider.emergencyMode
                  ? [
                      Colors.red.shade900,
                      Colors.red.shade700,
                      const Color(0xFFFF6B6B),
                    ]
                  : [kDeepTeal, kDeepForest, kMediumSage],
            ),
          ),
        ),

        // Animated overlay pattern
        AnimatedOpacity(
          duration: const Duration(milliseconds: 800),
          opacity: emergencyProvider.emergencyMode ? 0.3 : 0.1,
          child: Container(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.topRight,
                radius: 1.5,
                colors: [Colors.white.withOpacity(0.2), Colors.transparent],
              ),
            ),
          ),
        ),

        SafeArea(
          child: Column(
            children: [
              // Header with glassmorphic effect
              Container(
                margin: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.2),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 16,
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Icon(
                              emergencyProvider.emergencyMode
                                  ? Icons.emergency
                                  : Icons.shield_outlined,
                              color: Colors.white,
                              size: 28,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Emergency",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  emergencyProvider.emergencyMode
                                      ? "SOS ACTIVE"
                                      : "Safety First",
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.9),
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (emergencyProvider.emergencyMode)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 8,
                                    height: 8,
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    "ACTIVE",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // Main content with glassy card
              Expanded(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 800),
                  curve: Curves.easeOutCubic,
                  margin: const EdgeInsets.only(top: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.95),
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(40),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 30,
                        offset: const Offset(0, -10),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(40),
                    ),
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          children: [
                            // Drag indicator
                            Container(
                              width: 40,
                              height: 4,
                              decoration: BoxDecoration(
                                color: kMediumSage.withOpacity(0.3),
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                            const SizedBox(height: 32),

                            // Emergency Button
                            const EmergencyButton(),
                            const SizedBox(height: 32),

                            // Quick Actions
                            const QuickActionsButtons(),
                            const SizedBox(height: 32),

                            // Emergency Guidelines Card
                            Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    kSoftMint.withOpacity(0.15),
                                    kMediumSage.withOpacity(0.1),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(24),
                                border: Border.all(
                                  color: kMediumSage.withOpacity(0.3),
                                  width: 1,
                                ),
                              ),
                              padding: const EdgeInsets.all(20),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(10),
                                        decoration: BoxDecoration(
                                          color: kDeepForest.withOpacity(0.15),
                                          borderRadius: BorderRadius.circular(
                                            14,
                                          ),
                                        ),
                                        child: Icon(
                                          Icons.info_outline_rounded,
                                          color: kDeepForest,
                                          size: 22,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Text(
                                        "Emergency Guidelines",
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w700,
                                          color: kDeepTeal,
                                          letterSpacing: 0.3,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    "In case of emergency, stay calm and press the SOS button. Your location will be shared with emergency contacts and authorities. Ensure your phone has signal or move to higher ground if needed.",
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: kDeepTeal.withOpacity(0.8),
                                      height: 1.6,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  _buildGuidelineItem(
                                    Icons.phone_in_talk_rounded,
                                    "Keep emergency contacts updated",
                                  ),
                                  const SizedBox(height: 10),
                                  _buildGuidelineItem(
                                    Icons.signal_cellular_alt_rounded,
                                    "Check signal strength regularly",
                                  ),
                                  const SizedBox(height: 10),
                                  _buildGuidelineItem(
                                    Icons.battery_charging_full_rounded,
                                    "Maintain sufficient battery level",
                                  ),
                                ],
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
      ],
    );
  }

  Widget _buildGuidelineItem(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 18, color: kMediumSage),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 13,
              color: kDeepTeal.withOpacity(0.75),
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}
