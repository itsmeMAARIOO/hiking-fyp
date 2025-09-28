import 'package:flutter/material.dart';
import 'package:hikingapp/providers/emergency_provider.dart';
import 'package:provider/provider.dart';

class FallDetection extends StatelessWidget {
  const FallDetection({super.key});

  @override
  Widget build(BuildContext context) {
    final emergencyProvider = Provider.of<EmergencyProvider>(context);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
      ),
      child: Row(
        children: [
          const Icon(Icons.shield, color: Colors.green),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  "Fall Detection",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text("Automatically trigger SOS if a fall is detected"),
              ],
            ),
          ),
          Switch(
            value: emergencyProvider.fallDetectionEnabled,
            onChanged: emergencyProvider.toggleFallDetection,
            activeColor: Colors.green,
          ),
        ],
      ),
    );
  }
}
