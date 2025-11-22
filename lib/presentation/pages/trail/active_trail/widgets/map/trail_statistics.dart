// lib/presentation/pages/group/active_trail/widgets/trail_statistics.dart
import 'package:flutter/material.dart';
import 'package:hikingapp/presentation/styles/colors.dart';

class TrailStatistics extends StatelessWidget {
  final Duration elapsedTime;
  final double totalDistance;
  final double currentSpeed;
  final bool isTracking;

  const TrailStatistics({
    super.key,
    required this.elapsedTime,
    required this.totalDistance,
    required this.currentSpeed,
    required this.isTracking,
  });

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = twoDigits(duration.inHours);
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$hours:$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: kSoftMint.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: kDeepTeal.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Header Row
          Row(
            children: [
              Icon(Icons.analytics_outlined, color: kDeepTeal, size: 18),
              const SizedBox(width: 6),
              const Text(
                'Trail Stats',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: kDeepTeal,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isTracking
                      ? kMediumSage.withOpacity(0.15)
                      : Colors.grey.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  isTracking ? 'ACTIVE' : 'PAUSED',
                  style: TextStyle(
                    fontSize: 10,
                    color: isTracking ? kMediumSage : Colors.grey,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // Duration Center
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.timer_rounded, color: kDeepTeal, size: 18),
              const SizedBox(width: 6),
              Text(
                _formatDuration(elapsedTime),
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: kDeepTeal,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),
          Divider(color: kSoftMint.withOpacity(0.4), height: 1),
          const SizedBox(height: 6),

          // Distance + Speed Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildSmallStat(
                icon: Icons.alt_route_rounded,
                label: 'Distance',
                value: '${totalDistance.toStringAsFixed(2)} km',
              ),
              Container(
                width: 1,
                height: 22,
                color: kSoftMint.withOpacity(0.5),
              ),
              _buildSmallStat(
                icon: Icons.speed_rounded,
                label: 'Speed',
                value: '${currentSpeed.toStringAsFixed(1)} km/h',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSmallStat({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(icon, color: kMediumSage, size: 16),
        const SizedBox(width: 4),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                color: kDeepTeal.withOpacity(0.7),
                fontSize: 10,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              value,
              style: const TextStyle(
                color: kDeepTeal,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
