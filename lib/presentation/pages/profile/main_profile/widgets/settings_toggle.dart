import 'package:flutter/material.dart';
import 'package:hikingapp/presentation/styles/colors.dart';

class SettingsToggle extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool value;
  final void Function(bool) onToggle;
  final bool isLast;

  const SettingsToggle({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    required this.onToggle,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: isLast
              ? BorderSide.none
              : BorderSide(color: kDeepForest.withOpacity(0.2), width: 1.5),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: kSoftMint.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: kMediumSage, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 16,
                  color: kDeepTeal,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Switch(
              value: value,
              onChanged: onToggle,
              inactiveThumbColor: kDeepTeal.withOpacity(0.6),
              inactiveTrackColor: kDeepTeal.withOpacity(0.2),
              activeColor: kMediumSage,
              activeTrackColor: kMediumSage.withOpacity(0.3),
            ),
          ],
        ),
      ),
    );
  }
}
