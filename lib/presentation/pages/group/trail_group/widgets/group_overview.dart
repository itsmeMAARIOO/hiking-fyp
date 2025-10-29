// lib/presentation/pages/group/active_trail/widgets/group_overview.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hikingapp/providers/group_provider.dart';
import 'package:hikingapp/presentation/styles/colors.dart';

class GroupOverview extends StatelessWidget {
  final Map<String, dynamic> group;
  final List members;

  const GroupOverview({super.key, required this.group, required this.members});

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
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: kDeepForest.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.groups_rounded, color: kDeepForest, size: 20),
              ),
              const SizedBox(width: 12),
              const Text(
                'Group Overview',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: kDeepTeal,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: kSoftMint.withOpacity(0.05),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: kSoftMint.withOpacity(0.1)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildGroupStatItem(
                  Icons.people_alt_rounded,
                  '${members.length}',
                  'Members',
                  kMediumSage,
                ),
                Container(
                  width: 1,
                  height: 40,
                  color: kSoftMint.withOpacity(0.3),
                ),
                _buildGroupStatItem(
                  Icons.location_on_rounded,
                  '${members.where((m) => m['latitude'] != null).length}',
                  'Active',
                  kDeepForest,
                ),
                Container(
                  width: 1,
                  height: 40,
                  color: kSoftMint.withOpacity(0.3),
                ),
                _buildGroupStatItem(
                  Icons.explore_rounded,
                  '${Provider.of<GroupProvider>(context, listen: false).nearbyMembers.length}',
                  'Nearby',
                  kDeepTeal,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGroupStatItem(
    IconData icon,
    String value,
    String label,
    Color color,
  ) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            color: kDeepTeal,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: kDeepTeal.withOpacity(0.6),
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
