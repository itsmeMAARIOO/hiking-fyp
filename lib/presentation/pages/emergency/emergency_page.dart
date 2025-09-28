import 'package:flutter/material.dart';
import 'package:hikingapp/presentation/pages/emergency/widgets/emergency_quick_actions.dart';
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
              Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 20,
                  horizontal: 20,
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.shield,
                      size: 32,
                      color: emergencyProvider.emergencyMode
                          ? Colors.white
                          : Colors.red,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Emergency",
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: emergencyProvider.emergencyMode
                            ? Colors.white
                            : const Color(0xFF2C3E50),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      emergencyProvider.emergencyMode
                          ? 'SOS ACTIVE - Help is on the way'
                          : 'Safety tools and emergency contacts',
                      style: TextStyle(
                        fontSize: 16,
                        color: emergencyProvider.emergencyMode
                            ? Colors.white
                            : const Color(0xFF8B7355),
                        fontWeight: emergencyProvider.emergencyMode
                            ? FontWeight.w600
                            : FontWeight.normal,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),

              // Emergency Button
              EmergencyButton(),

              // Fall Detection
              FallDetection(),

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
