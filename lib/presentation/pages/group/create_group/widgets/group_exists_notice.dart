import 'package:flutter/material.dart';

class GroupExistsNotice extends StatelessWidget {
  final Map<String, dynamic> group;
  const GroupExistsNotice({super.key, required this.group});

  @override
  Widget build(BuildContext context) {
    final name = group['groupName']?.toString() ?? 'Active Group';
    final trail = group['activeTrail']?['name']?.toString();

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
                Icons.groups_rounded,
                color: Color(0xFF1C3F3F),
                size: 64,
              ),
              const SizedBox(height: 16),
              const Text(
                'Active Group Detected',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1C3F3F),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'You are already part of an active hiking group. Please finish or leave your current trail before joining another.',
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
                      'Group: $name',
                      style: const TextStyle(
                        fontSize: 16,
                        color: Color(0xFF1C3F3F),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (trail != null) ...[
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
