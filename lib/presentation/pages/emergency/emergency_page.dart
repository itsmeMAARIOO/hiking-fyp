import 'package:flutter/material.dart';
import 'package:hikingapp/presentation/pages/emergency/widgets/emergency_quick_actions.dart';
import 'package:hikingapp/presentation/widgets/common_header.dart';
import 'package:provider/provider.dart';
import 'widgets/emergency_button.dart';
import 'widgets/fall_detection.dart';
import 'widgets/emergency_contacts.dart';
import '../../../providers/emergency_provider.dart';

class EmergencyPage extends StatelessWidget {
  const EmergencyPage({super.key});

  @override
  Widget build(BuildContext context) {
    final emergencyProvider = Provider.of<EmergencyProvider>(context);

    return Scaffold(
      backgroundColor: emergencyProvider.emergencyMode
          ? Colors.red
          : const Color(0xFFF8FAF9),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Header
              CommonHeader(
                title: "Emergency",
                subtitle: emergencyProvider.emergencyMode
                    ? "SOS ACTIVE - Help is on the way"
                    : "Safety tools and emergency contacts",
                trailingWidget: Icon(
                  Icons.shield,
                  size: 32,
                  color: emergencyProvider.emergencyMode
                      ? Colors.white
                      : Colors.red,
                ),
              ),

              // Emergency Button
              const EmergencyButton(),

              // Fall Detection
              const FallDetection(),

              // Quick Actions
              const QuickActionsButtons(),

              // Emergency Contacts
              const EmergencyContacts(),
            ],
          ),
        ),
      ),
    );
  }
}
