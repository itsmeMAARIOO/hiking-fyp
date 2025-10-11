import 'package:flutter/material.dart';

class SettingsToggle extends StatelessWidget {
  final String label;
  final bool value;
  final ValueChanged<bool> onToggle;

  const SettingsToggle({
    super.key,
    required this.label,
    required this.value,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Text(
              label,
              style: const TextStyle(fontSize: 16, color: Color(0xFF2C3E50)),
            ),
            const Spacer(),
            Switch(
              value: value,
              onChanged: onToggle,
              activeColor: const Color(0xFF16A085),
            ),
          ],
        ),
        const Divider(height: 1, color: Color(0xFFF3F4F6)),
      ],
    );
  }
}
