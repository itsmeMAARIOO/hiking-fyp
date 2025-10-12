import 'package:flutter/material.dart';
import 'package:hikingapp/presentation/pages/emergency/widgets/emergency_quick_actions.dart';
import 'package:hikingapp/presentation/widgets/common_header.dart';
import 'package:provider/provider.dart';
import 'widgets/emergency_button.dart';
import 'widgets/fall_detection.dart';
import 'widgets/emergency_contacts.dart';
import '../../../providers/emergency_provider.dart';

// Color constants
const Color kDeepTeal = Color(0xFF1c3f3f);
const Color kSoftMint = Color(0xFFa0d5b9);
const Color kMediumSage = Color(0xFF6baf89);
const Color kDeepForest = Color(0xFF3e7b5b);

class EmergencyPage extends StatelessWidget {
  const EmergencyPage({super.key});

  @override
  Widget build(BuildContext context) {
    final emergencyProvider = Provider.of<EmergencyProvider>(context);

    return Stack(
      children: [
        // Background gradient for smoother transition
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: emergencyProvider.emergencyMode
                  ? [
                      Colors.red.shade900,
                      Colors.red.shade700,
                      Colors.white.withOpacity(0.95),
                    ]
                  : [
                      kDeepTeal,
                      kDeepForest.withOpacity(0.9),
                      Colors.white.withOpacity(0.95),
                    ],
              stops: const [0.0, 0.35, 0.5],
            ),
          ),
        ),

        // Content Layer
        SafeArea(
          child: Column(
            children: [
              // Header without separate background (uses parent gradient)
              CommonHeader(
                title: "Emergency",
                subtitle: emergencyProvider.emergencyMode
                    ? "SOS ACTIVE"
                    : "Watch your step",
                trailingWidget: Icon(
                  Icons.shield,
                  size: 32,
                  color: Colors.white,
                ),
                showBackgroundGradient: false, // Let parent handle gradient
              ),

              // Main Content Container with smooth transition
              Expanded(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 800),
                  curve: Curves.easeOutCubic,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(40),
                    ),
                  ),
                  clipBehavior: Clip.hardEdge,
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      return SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.only(bottom: 20),
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            minHeight: constraints.maxHeight,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 20),

                              // Emergency Button with fade-in
                              AnimatedOpacity(
                                duration: const Duration(milliseconds: 600),
                                opacity: 1.0,
                                child: const Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 20),
                                  child: EmergencyButton(),
                                ),
                              ),

                              const SizedBox(height: 24),

                              // Fall Detection with animation
                              AnimatedOpacity(
                                duration: const Duration(milliseconds: 700),
                                opacity: 1.0,
                                child: const Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 20),
                                  child: FallDetection(),
                                ),
                              ),

                              const SizedBox(height: 24),

                              // Quick Actions with staggered animation
                              AnimatedOpacity(
                                duration: const Duration(milliseconds: 800),
                                opacity: 1.0,
                                child: const Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 20),
                                  child: QuickActionsButtons(),
                                ),
                              ),

                              const SizedBox(height: 24),

                              // Emergency Contacts with delayed fade-in
                              AnimatedOpacity(
                                duration: const Duration(milliseconds: 900),
                                opacity: 1.0,
                                child: const Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 20),
                                  child: EmergencyContacts(),
                                ),
                              ),

                              const SizedBox(height: 28),

                              // Safety reminder section (matching dashboard style)
                              AnimatedOpacity(
                                duration: const Duration(milliseconds: 1000),
                                opacity: 1.0,
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.all(8),
                                            decoration: BoxDecoration(
                                              color: Colors.red.withOpacity(
                                                0.1,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            child: Icon(
                                              Icons.info_outline_rounded,
                                              color: Colors.red.shade700,
                                              size: 20,
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Text(
                                            "Emergency Guidelines",
                                            style: TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.w700,
                                              color: kDeepTeal,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 12),
                                      Container(
                                        decoration: BoxDecoration(
                                          color: Colors.red.withOpacity(0.05),
                                          borderRadius: BorderRadius.circular(
                                            16,
                                          ),
                                          border: Border.all(
                                            color: Colors.red.withOpacity(0.2),
                                            width: 1,
                                          ),
                                        ),
                                        padding: const EdgeInsets.all(20),
                                        child: Text(
                                          "In case of emergency, stay calm and press the SOS button. Your location will be shared with emergency contacts and authorities. Ensure your phone has signal or move to higher ground if needed.",
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: kDeepTeal.withOpacity(0.8),
                                            height: 1.5,
                                            fontWeight: FontWeight.w500,
                                          ),
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
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
