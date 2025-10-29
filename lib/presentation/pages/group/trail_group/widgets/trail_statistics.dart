// lib/presentation/pages/group/active_trail/widgets/trail_statistics.dart
import 'package:flutter/material.dart';
import 'package:hikingapp/presentation/styles/colors.dart';

class TrailStatistics extends StatelessWidget {
  final Duration elapsedTime;
  final double totalDistance;
  final double currentSpeed;
  final bool isTracking;

  // Colors provided by centralized palette in config/colors.dart

  const TrailStatistics({
    super.key,
    required this.elapsedTime,
    required this.totalDistance,
    required this.currentSpeed,
    required this.isTracking,
  });

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String hours = twoDigits(duration.inHours);
    String minutes = twoDigits(duration.inMinutes.remainder(60));
    String seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$hours:$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: kDeepTeal.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(color: kSoftMint.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: kMediumSage.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.analytics_rounded,
                  color: kMediumSage,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Trail Statistics',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: kDeepTeal,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: isTracking
                      ? kMediumSage.withOpacity(0.1)
                      : Colors.grey.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isTracking
                        ? kMediumSage.withOpacity(0.3)
                        : Colors.grey.withOpacity(0.3),
                  ),
                ),
                child: Text(
                  isTracking ? 'ACTIVE' : 'PAUSED',
                  style: TextStyle(
                    color: isTracking ? kMediumSage : Colors.grey,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Duration Row
          _buildStatRow(
            icon: Icons.timer_rounded,
            value: _formatDuration(elapsedTime),
            label: 'Duration',
            color: kDeepForest,
          ),
          const SizedBox(height: 16),

          // Distance Row
          _buildStatRow(
            icon: Icons.alt_route_rounded,
            value: '${totalDistance.toStringAsFixed(2)} km',
            label: 'Distance',
            color: kMediumSage,
          ),
          const SizedBox(height: 16),

          // Speed Row
          _buildStatRow(
            icon: Icons.speed_rounded,
            value: '${currentSpeed.toStringAsFixed(1)} km/h',
            label: 'Speed',
            color: kDeepTeal,
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          // Icon
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 16),

          // Text Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: kDeepTeal.withOpacity(0.7),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    color: kDeepTeal,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),

          // Optional trailing indicator
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.trending_up_rounded, color: color, size: 16),
          ),
        ],
      ),
    );
  }
}
