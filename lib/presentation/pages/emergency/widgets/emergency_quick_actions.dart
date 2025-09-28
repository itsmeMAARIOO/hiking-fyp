// import 'package:flutter/material.dart';
// import 'package:hikingapp/providers/emergency_provider.dart';
// import 'package:provider/provider.dart';

// class QuickActionsButtons extends StatelessWidget {
//   const QuickActionsButtons({super.key});

//   @override
//   Widget build(BuildContext context) {
//     final emergencyProvider = Provider.of<EmergencyProvider>(
//       context,
//       listen: false,
//     );

//     return Padding(
//       padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
//       child: Row(
//         children: [
//           Expanded(
//             child: ElevatedButton(
//               onPressed: () => emergencyProvider.callEmergency(context),
//               style: ElevatedButton.styleFrom(
//                 backgroundColor: Colors.red.shade700,
//                 padding: const EdgeInsets.symmetric(vertical: 16),
//                 shape: RoundedRectangleBorder(
//                   borderRadius: BorderRadius.circular(16),
//                 ),
//               ),
//               child: const Column(
//                 mainAxisSize: MainAxisSize.min,
//                 children: [
//                   Icon(Icons.phone, size: 24),
//                   SizedBox(height: 6),
//                   Text(
//                     "Call",
//                     style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
//                   ),
//                   Text("911", style: TextStyle(fontSize: 10)),
//                 ],
//               ),
//             ),
//           ),
//           const SizedBox(width: 12),
//           Expanded(
//             child: ElevatedButton(
//               onPressed: () => emergencyProvider.showFirstAid(context),
//               style: ElevatedButton.styleFrom(
//                 backgroundColor: Colors.green.shade700,
//                 padding: const EdgeInsets.symmetric(vertical: 16),
//                 shape: RoundedRectangleBorder(
//                   borderRadius: BorderRadius.circular(16),
//                 ),
//               ),
//               child: const Column(
//                 mainAxisSize: MainAxisSize.min,
//                 children: [
//                   Icon(Icons.medical_services, size: 24),
//                   SizedBox(height: 6),
//                   Text(
//                     "First",
//                     style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
//                   ),
//                   Text("Aid", style: TextStyle(fontSize: 10)),
//                 ],
//               ),
//             ),
//           ),
//           const SizedBox(width: 12),
//           Expanded(
//             child: ElevatedButton(
//               onPressed: () {}, // implement share location logic
//               style: ElevatedButton.styleFrom(
//                 backgroundColor: Colors.blue.shade700,
//                 padding: const EdgeInsets.symmetric(vertical: 16),
//                 shape: RoundedRectangleBorder(
//                   borderRadius: BorderRadius.circular(16),
//                 ),
//               ),
//               child: const Column(
//                 mainAxisSize: MainAxisSize.min,
//                 children: [
//                   Icon(Icons.location_pin, size: 24),
//                   SizedBox(height: 6),
//                   Text(
//                     "Share",
//                     style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
//                   ),
//                   Text("Location", style: TextStyle(fontSize: 10)),
//                 ],
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

import 'package:flutter/material.dart';
import 'package:hikingapp/providers/emergency_provider.dart';
import 'package:provider/provider.dart';

class QuickActionsButtons extends StatelessWidget {
  const QuickActionsButtons({super.key});

  @override
  Widget build(BuildContext context) {
    final emergencyProvider = Provider.of<EmergencyProvider>(
      context,
      listen: false,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          // Emergency Call Button
          Expanded(
            child: _ActionButton(
              onPressed: () => emergencyProvider.callEmergency(context),
              backgroundColor: const Color(0xFFDC2626), // Rich red
              icon: Icons.emergency,
              title: "Emergency",
              subtitle: "Call 911",
              iconColor: Colors.white,
              hasShadow: true,
            ),
          ),
          const SizedBox(width: 12),

          // First Aid Button
          Expanded(
            child: _ActionButton(
              onPressed: () => emergencyProvider.showFirstAid(context),
              backgroundColor: const Color(0xFF059669), // Forest green
              icon: Icons.medical_services,
              title: "First Aid",
              subtitle: "Guide",
              iconColor: Colors.white,
              hasShadow: true,
            ),
          ),
          const SizedBox(width: 12),

          // Share Location Button
          Expanded(
            child: _ActionButton(
              onPressed: () {}, // implement share location logic
              backgroundColor: const Color(0xFF2563EB), // Mountain blue
              icon: Icons.location_on_outlined,
              title: "Share",
              subtitle: "Location",
              iconColor: Colors.white,
              hasShadow: true,
            ),
          ),
        ],
      ),
    );
  }
}

// Custom button widget for consistent styling
class _ActionButton extends StatelessWidget {
  final VoidCallback onPressed;
  final Color backgroundColor;
  final IconData icon;
  final String title;
  final String subtitle;
  final Color iconColor;
  final bool hasShadow;

  const _ActionButton({
    required this.onPressed,
    required this.backgroundColor,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.iconColor,
    this.hasShadow = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: hasShadow
          ? BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: backgroundColor.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            )
          : null,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0, // We're using custom shadow instead
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 28, color: iconColor),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: Colors.white.withOpacity(0.9),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// Alternative version with outdoor-inspired colors
class QuickActionsButtonsOutdoor extends StatelessWidget {
  const QuickActionsButtonsOutdoor({super.key});

  @override
  Widget build(BuildContext context) {
    final emergencyProvider = Provider.of<EmergencyProvider>(
      context,
      listen: false,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          Expanded(
            child: _GradientActionButton(
              onPressed: () => emergencyProvider.callEmergency(context),
              gradient: const LinearGradient(
                colors: [Color(0xFFEF4444), Color(0xFFDC2626)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              icon: Icons.emergency,
              title: "Emergency",
              subtitle: "Call 911",
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _GradientActionButton(
              onPressed: () => emergencyProvider.showFirstAid(context),
              gradient: const LinearGradient(
                colors: [Color(0xFF10B981), Color(0xFF059669)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              icon: Icons.medical_services,
              title: "First Aid",
              subtitle: "Guide",
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _GradientActionButton(
              onPressed: () {},
              gradient: const LinearGradient(
                colors: [Color(0xFF3B82F6), Color(0xFF2563EB)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              icon: Icons.location_on_outlined,
              title: "Share",
              subtitle: "Location",
            ),
          ),
        ],
      ),
    );
  }
}

// Gradient button variant
class _GradientActionButton extends StatelessWidget {
  final VoidCallback onPressed;
  final Gradient gradient;
  final IconData icon;
  final String title;
  final String subtitle;

  const _GradientActionButton({
    required this.onPressed,
    required this.gradient,
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF000000).withOpacity(0.2),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
          shadowColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 26),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: Colors.white.withOpacity(0.9),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
