// lib/presentation/pages/group/active_trail/widgets/group_members.dart
import 'package:flutter/material.dart';

class GroupMembers extends StatelessWidget {
  final List members;

  static const Color kDeepTeal = Color(0xFF1c3f3f);
  static const Color kSoftMint = Color(0xFFa0d5b9);
  static const Color kMediumSage = Color(0xFF6baf89);
  static const Color kDeepForest = Color(0xFF3e7b5b);

  const GroupMembers({super.key, required this.members});

  String _getTimeAgo(DateTime dateTime) {
    final difference = DateTime.now().difference(dateTime);

    if (difference.inSeconds < 60) {
      return 'just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (members.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: kDeepTeal.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.people_rounded, color: kDeepTeal, size: 20),
            ),
            const SizedBox(width: 12),
            const Text(
              'Group Members',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: kDeepTeal,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ...members.map((member) => _buildMemberCard(member)).toList(),
      ],
    );
  }

  Widget _buildMemberCard(dynamic member) {
    final hasLocation =
        member['latitude'] != null && member['longitude'] != null;
    final isLeader = member['role'] == 'leader';
    final lastUpdated = DateTime.tryParse(member['lastUpdated'] ?? '');
    final timeAgo = lastUpdated != null ? _getTimeAgo(lastUpdated) : 'Unknown';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: kDeepTeal.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: isLeader
              ? kMediumSage.withOpacity(0.3)
              : kSoftMint.withOpacity(0.2),
          width: isLeader ? 2 : 1,
        ),
      ),
      child: Row(
        children: [
          Stack(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isLeader
                      ? kMediumSage.withOpacity(0.1)
                      : kSoftMint.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isLeader ? Icons.star_rounded : Icons.person_rounded,
                  color: isLeader ? kMediumSage : kDeepForest,
                  size: 24,
                ),
              ),
              if (hasLocation)
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      color: kMediumSage,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: kMediumSage.withOpacity(0.5),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      member['name'] ?? 'Unknown',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: kDeepTeal,
                      ),
                    ),
                    if (isLeader) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [kMediumSage, kDeepForest],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'LEADER',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(
                      hasLocation
                          ? Icons.location_on_rounded
                          : Icons.location_off_rounded,
                      size: 14,
                      color: hasLocation ? kMediumSage : Colors.grey,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      hasLocation ? 'Updated $timeAgo' : 'Location unavailable',
                      style: TextStyle(
                        fontSize: 12,
                        color: hasLocation
                            ? kDeepTeal.withOpacity(0.7)
                            : Colors.grey,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (hasLocation)
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: kDeepTeal.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.explore_rounded, color: kDeepForest, size: 20),
            ),
        ],
      ),
    );
  }
}
