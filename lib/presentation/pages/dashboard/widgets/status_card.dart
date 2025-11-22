import 'package:flutter/material.dart';
import 'package:hikingapp/presentation/styles/colors.dart';

class StatusCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String status;
  final Color statusColor;
  final bool active;
  final List<Color>? gradientColors;

  const StatusCard({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.status,
    required this.statusColor,
    this.active = false,
    this.gradientColors,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: (MediaQuery.of(context).size.width - 52) / 2,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: active ? null : kGlassMorphismLight,
        gradient: active
            ? LinearGradient(
                colors: gradientColors ?? const [kMediumSage, kDeepForest],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: active ? Colors.white.withOpacity(0.25) : iconColor.withOpacity(0.25),
          width: active ? 1 : 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: active
                ? Colors.black.withOpacity(0.12)
                : iconColor.withOpacity(0.10),
            blurRadius: active ? 20 : 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: active
                      ? Colors.white.withOpacity(0.2)
                      : iconColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
              ),
              Icon(icon, color: active ? Colors.white : iconColor, size: 24),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: active
                  ? Colors.white.withOpacity(0.9)
                  : Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            status,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: active ? Colors.white : statusColor,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
