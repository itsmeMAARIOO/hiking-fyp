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
    return Row(
      children: [
        Expanded(
          child: _buildActionButton(
            icon: isTracking
                ? Icons.pause_circle_filled_rounded
                : Icons.play_circle_filled_rounded,
            label: isTracking ? 'Pause' : 'Resume',
            color: isTracking ? Colors.orange : kMediumSage,
            onTap: onToggleTracking,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildActionButton(
            icon: Icons.stop_circle_rounded,
            label: 'End Trail',
            color: Color(0xFFFF6B6B),
            onTap: onEndTrail,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.2),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [color.withOpacity(0.1), color.withOpacity(0.05)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: color.withOpacity(0.2)),
            ),
            child: Column(
              children: [
                Icon(icon, color: color, size: 32),
                const SizedBox(height: 8),
                Text(
                  label,
                  style: TextStyle(
                    color: color,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
