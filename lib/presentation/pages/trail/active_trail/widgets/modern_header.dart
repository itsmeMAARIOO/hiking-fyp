import 'package:flutter/material.dart';

import '../../../../styles/colors.dart';

class ModernHeader extends StatelessWidget {
  final String groupName;
  final String trailName;
  final bool isTracking;
  final Animation<double>? pulseAnimation;
  final VoidCallback onMinimize;
  final Widget? trailingButton;

  const ModernHeader({
    super.key,
    required this.groupName,
    required this.trailName,
    required this.isTracking,
    this.pulseAnimation,
    required this.onMinimize,
    this.trailingButton,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      decoration: BoxDecoration(
        color: Colors.transparent,
        boxShadow: [
          BoxShadow(
            color: kDeepTeal.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: kDeepForest.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.forest_rounded,
                  color: kDeepForest,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      groupName.isNotEmpty ? groupName : 'Unnamed Group',
                      style: TextStyle(
                        color: kDeepTeal.withOpacity(0.85),
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      trailName.isNotEmpty ? trailName : 'Exploring Trail',
                      style: TextStyle(
                        color: kDeepTeal.withOpacity(0.65),
                        fontSize: 12,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              if (isTracking)
                (pulseAnimation != null)
                    ? FadeTransition(
                        opacity: pulseAnimation!,
                        child: _LiveBadge(),
                      )
                    : _LiveBadge(),
              const SizedBox(width: 10),
              trailingButton ?? _DefaultMinimizeButton(onMinimize: onMinimize),
            ],
          ),
        ],
      ),
    );
  }
}

class _LiveBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFF6B6B), Color(0xFFFF5252)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Row(
        children: [
          Icon(Icons.fiber_manual_record, color: Colors.white, size: 8),
          SizedBox(width: 5),
          Text(
            'LIVE',
            style: TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _DefaultMinimizeButton extends StatelessWidget {
  final VoidCallback onMinimize;

  const _DefaultMinimizeButton({required this.onMinimize});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onMinimize,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: kDeepTeal.withOpacity(0.12),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.close, color: kDeepTeal, size: 16),
      ),
    );
  }
}
