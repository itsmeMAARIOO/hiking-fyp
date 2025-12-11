import 'package:flutter/material.dart';
import 'package:hikingapp/presentation/pages/emergency/widgets/emergency_quick_actions.dart';
import 'package:hikingapp/presentation/pages/emergency/widgets/emergency_contact_card.dart';
import 'package:hikingapp/presentation/widgets/common_header.dart';
import 'package:provider/provider.dart';
import 'package:hikingapp/providers/profile_provider.dart';
import 'package:hikingapp/providers/auth_provider.dart';
import 'package:hikingapp/presentation/pages/profile/main_profile/profile_controller.dart';
import 'widgets/emergency_button.dart';
import '../../../providers/emergency_provider.dart';
import 'package:hikingapp/presentation/styles/app_styles.dart';

class EmergencyPage extends StatelessWidget {
  const EmergencyPage({super.key});

  @override
  Widget build(BuildContext context) {
    final emergencyProvider = Provider.of<EmergencyProvider>(context);
    final profileProvider = Provider.of<ProfileProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final controller = ProfileController(context);
    final effectiveUserId = authProvider.userId ?? profileProvider.userId;
    if (effectiveUserId != null) {
      controller.setUserId(effectiveUserId);
    }

    return Stack(
      children: [
        const AnimatedBackground(),
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
          bottom: false,
          child: Column(
            children: [
              Stack(children: [const CommonHeader(title: 'Emergency')]),
              // body content
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: EdgeInsets.fromLTRB(20, 0, 20, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 16),
                      const EmergencyButton(),
                      const SizedBox(height: 16),
                      const QuickActionsButtons(),
                      const SizedBox(height: 24),
                      EmergencyContactCard(controller: controller),
                    ],
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
