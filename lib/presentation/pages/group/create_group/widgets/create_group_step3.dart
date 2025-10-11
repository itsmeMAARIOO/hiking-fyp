import 'package:flutter/material.dart';
import 'package:hikingapp/data/models/group_model.dart';
import 'package:hikingapp/presentation/pages/group/create_group/widgets/hiker_card_widgets.dart'; // Use explicit path if necessary

// --- Color Palette & Constants (Copied from hiker_card_widgets.dart for consistency) ---
const Color kPrimaryColor = Color(0xFF6BAF89); // Lighter Green/Nature
const Color kDarkPrimaryColor = Color(0xFF3E7B5B); // Darker Green/Accent
const Color kTextColor = Color(0xFF1C3F3F); // Main text color
const Color kSuccessBg = Color(0xFFE8F5E9); // Very light green background

class Step3Confirm extends StatelessWidget {
  final String groupName;
  final String trailName;
  final String currentUserName;
  final List<GroupMember> selectedHikers;

  const Step3Confirm({
    super.key,
    required this.groupName,
    required this.trailName,
    required this.currentUserName,
    required this.selectedHikers,
  });

  // Helper widget to display key group details
  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: kDarkPrimaryColor, size: 20),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: kTextColor.withOpacity(0.7),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: kTextColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- Group Details Card ---
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: kSuccessBg, // Light success background
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: kPrimaryColor, width: 2),
              boxShadow: [
                BoxShadow(
                  color: kPrimaryColor.withOpacity(0.3),
                  blurRadius: 15,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Group Name
                _buildInfoRow(
                  icon: Icons.map,
                  label: 'Group Name',
                  value: groupName,
                ),

                // Trail Name
                _buildInfoRow(
                  icon: Icons.route,
                  label: 'Selected Trail',
                  value: trailName.isEmpty
                      ? 'Any trail (Not specified)'
                      : trailName,
                ),

                const Divider(color: kPrimaryColor, height: 14, thickness: 1),

                // Leader Name
                _buildInfoRow(
                  icon: Icons.shield,
                  label: 'Group Leader',
                  value: currentUserName,
                ),

                // Total Members
                _buildInfoRow(
                  icon: Icons.people_rounded,
                  label: 'Total Group Size',
                  value: '${selectedHikers.length + 1} Hiker(s)',
                ),
              ],
            ),
          ),

          const SizedBox(height: 10),

          // --- Invited Members Section ---
          if (selectedHikers.isNotEmpty) ...[
            const SizedBox(height: 30),

            Text(
              'Invited Hikers (${selectedHikers.length})',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: kTextColor,
              ),
            ),
            const SizedBox(height: 16),
            ...selectedHikers
                // Using the ConfirmMemberCard widget from the imported file
                .map((hiker) => ConfirmMemberCard(hiker: hiker))
                .toList(),
          ] else
            Container(
              alignment: Alignment.center,
              child: Text(
                'Creating a solo group.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: kTextColor.withOpacity(0.6),
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
