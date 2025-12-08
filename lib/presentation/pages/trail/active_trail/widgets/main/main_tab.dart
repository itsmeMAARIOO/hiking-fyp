import 'package:flutter/material.dart';

import 'member_selector.dart';
import 'section_header.dart';
import 'solo_live_map.dart';
import '../../../../../styles/colors.dart';
import 'trail_statistics.dart';
import 'trail_actions.dart';

class MainTab extends StatelessWidget {
  final List<dynamic> otherMembers;
  final double? focusLat;
  final double? focusLon;
  final int showAllTrigger;
  final VoidCallback onShowAll;
  final void Function(double lat, double lon) onSelectMember;
  final Duration elapsedTime;
  final double totalDistance;
  final double currentSpeed;
  final bool isTracking;
  final VoidCallback onToggleTracking;
  final VoidCallback onEndTrail;

  const MainTab({
    super.key,
    required this.otherMembers,
    required this.focusLat,
    required this.focusLon,
    required this.showAllTrigger,
    required this.onShowAll,
    required this.onSelectMember,
    required this.elapsedTime,
    required this.totalDistance,
    required this.currentSpeed,
    required this.isTracking,
    required this.onToggleTracking,
    required this.onEndTrail,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(title: 'Live Location'),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: kDeepTeal.withOpacity(0.12),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: SoloLiveMap(
                height: 280,
                members: otherMembers.cast<Map<String, dynamic>>(),
                focusLat: focusLat,
                focusLon: focusLon,
                showAllTrigger: showAllTrigger,
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Stats at top of map tab
          TrailStatistics(
            elapsedTime: elapsedTime,
            totalDistance: totalDistance,
            currentSpeed: currentSpeed,
            isTracking: isTracking,
          ),

          const SizedBox(height: 16),

          // Actions for tracking and ending trail
          TrailActions(
            isTracking: isTracking,
            onToggleTracking: onToggleTracking,
            onEndTrail: onEndTrail,
          ),

          const SizedBox(height: 16),

          MemberSelector(
            members: otherMembers,
            focusLat: focusLat,
            focusLon: focusLon,
            onShowAll: onShowAll,
            onSelectMember: onSelectMember,
          ),
          const SizedBox(height: 14),
        ],
      ),
    );
  }
}
