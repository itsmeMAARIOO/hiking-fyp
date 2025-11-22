// lib/presentation/pages/group/active_trail/widgets/trail_actions.dart
import 'package:flutter/material.dart';
import 'package:hikingapp/presentation/styles/colors.dart';

class TrailActions extends StatelessWidget {
  final bool isTracking;
  final VoidCallback onToggleTracking;
  final VoidCallback onEndTrail;

  const TrailActions({
    super.key,
    required this.isTracking,
    required this.onToggleTracking,
    required this.onEndTrail,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: _buildGradientButton(
              icon: isTracking ? Icons.pause_rounded : Icons.play_arrow_rounded,
              gradient: LinearGradient(
                colors: isTracking
                    ? [kDeepOrange, kDeepOrange]
                    : [kMediumSage, kMediumSage],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              onTap: onToggleTracking,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildGradientButton(
              icon: Icons.stop_rounded,
              gradient: LinearGradient(
                colors: [Colors.redAccent.shade200, Colors.red.shade700],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              onTap: onEndTrail,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGradientButton({
    required IconData icon,
    required LinearGradient gradient,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 56,
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: gradient.colors.last.withOpacity(0.4),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [Icon(icon, color: Colors.white, size: 26)],
            ),
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                height: 1.5,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.white.withOpacity(0.2),
                      Colors.white.withOpacity(0.05),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
