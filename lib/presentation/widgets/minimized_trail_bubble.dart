import 'package:flutter/material.dart';
import 'package:hikingapp/presentation/styles/colors.dart';

class MinimizedTrailBubble extends StatelessWidget {
  final String groupName;
  final VoidCallback onTap;
  const MinimizedTrailBubble({
    super.key,
    required this.groupName,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [kDeepForest, kMediumSage],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF16A085).withOpacity(0.35),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.directions_run_rounded,
                color: kDeepTeal,
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                'Trail Active · $groupName',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
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
