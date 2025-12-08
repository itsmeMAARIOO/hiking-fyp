import 'package:flutter/material.dart';

class GroupExistsNotice extends StatelessWidget {
  final Map<String, dynamic>? group;
  final bool isSolo;
  final String? soloTrailName;
  const GroupExistsNotice({
    super.key,
    this.group,
    this.isSolo = false,
    this.soloTrailName,
  });

  @override
  Widget build(BuildContext context) {
    final isGroup = !isSolo && group != null;
    final name = isGroup
        ? (group!['groupName']?.toString() ?? 'Active Group')
        : 'Solo Trail';
    final dynamic activeTrail = isGroup ? group!['activeTrail'] : null;
    final String trail = isGroup
        ? (activeTrail is Map && activeTrail['trailName'] != null
              ? activeTrail['trailName'].toString()
              : '')
        : (soloTrailName ?? 'Unnamed Trail');

    // Body-only component suitable for embedding under an existing header
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.hiking_rounded,
                color: Color(0xFF1C3F3F),
                size: 64,
              ),
              const SizedBox(height: 16),
              const Text(
                'Active Trail Detected',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1C3F3F),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'You already have an active trail. Please finish or leave your current trail before starting another.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  color: Color(0xFF4A4A4A),
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF1C3F3F).withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Text(
                      isGroup ? 'Group: $name' : 'Mode: $name',
                      style: const TextStyle(
                        fontSize: 16,
                        color: Color(0xFF1C3F3F),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (trail != null && trail.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Trail: $trail',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF1C3F3F),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                '⛰️ Keep hiking safely!',
                style: TextStyle(
                  color: Color(0xFF6BAF89),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
