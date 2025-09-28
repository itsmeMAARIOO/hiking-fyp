import 'package:flutter/material.dart';
import 'package:hikingapp/providers/group_provider.dart';
import 'package:provider/provider.dart';

class GroupStats extends StatelessWidget {
  const GroupStats({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<GroupProvider>(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Row(
        children: [
          _buildStatCard(
            Icons.people,
            provider.members.length.toString(),
            "Members",
            Colors.teal,
          ),
          const SizedBox(width: 12),
          _buildStatCard(
            Icons.wifi,
            provider.onlineCount.toString(),
            "Online",
            Colors.teal,
          ),
          const SizedBox(width: 12),
          _buildStatCard(Icons.map, '2', "On Trail", Colors.teal),
        ],
      ),
    );
  }

  Expanded _buildStatCard(
    IconData icon,
    String number,
    String label,
    Color color,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              offset: const Offset(0, 2),
              blurRadius: 4,
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, size: 24, color: color),
            const SizedBox(height: 8),
            Text(
              number,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            Text(
              label,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
