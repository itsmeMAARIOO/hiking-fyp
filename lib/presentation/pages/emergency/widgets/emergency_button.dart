import 'package:flutter/material.dart';
import 'package:hikingapp/providers/emergency_provider.dart';
import 'package:provider/provider.dart';

class EmergencyButton extends StatelessWidget {
  const EmergencyButton({super.key});

  @override
  Widget build(BuildContext context) {
    final emergencyProvider = Provider.of<EmergencyProvider>(context);

    return Column(
      children: [
        GestureDetector(
          onTap: () => emergencyProvider.triggerSOS(context),
          child: Container(
            width: 160,
            height: 160,
            decoration: BoxDecoration(
              color: emergencyProvider.sosActive
                  ? Colors.red.shade800
                  : Colors.red,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.red.withOpacity(0.3),
                  offset: const Offset(0, 8),
                  blurRadius: 16,
                ),
              ],
            ),
            alignment: Alignment.center,
            child: Icon(
              emergencyProvider.sosActive ? Icons.close : Icons.warning,
              size: 60,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          emergencyProvider.sosActive
              ? 'Tap to cancel emergency alert'
              : 'Hold for 3 seconds to trigger emergency alert',
          style: const TextStyle(fontSize: 14, color: Color(0xFF8B7355)),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
