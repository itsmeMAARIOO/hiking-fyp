// lib/presentation/pages/group/active_trail/widgets/trail_floating_actions.dart
import 'package:flutter/material.dart';
import 'package:hikingapp/providers/group_provider.dart';

class TrailFloatingActions extends StatelessWidget {
  final GroupProvider provider;
  final String currentUserId;

  static const Color kDeepTeal = Color(0xFF1c3f3f);
  static const Color kSoftMint = Color(0xFFa0d5b9);
  static const Color kMediumSage = Color(0xFF6baf89);
  static const Color kDeepForest = Color(0xFF3e7b5b);

  const TrailFloatingActions({
    super.key,
    required this.provider,
    required this.currentUserId,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Alert Button
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFFFF6B6B), Color(0xFFFF5252)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Color(0xFFFF6B6B).withOpacity(0.4),
                blurRadius: 15,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(20),
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              // onPressed: () => provider.sendGroupAlert(context),
              child: const Icon(
                Icons.warning_amber_rounded,
                color: Colors.white,
                size: 28,
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        // Refresh Button
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [kDeepTeal, kDeepForest],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: kDeepTeal.withOpacity(0.4),
                blurRadius: 15,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(20),
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              // onPressed: () {
              //   provider.fetchNearbyMembers(excludeUserId: currentUserId);
              //   ScaffoldMessenger.of(context).showSnackBar(
              //     SnackBar(
              //       content: const Text('🔄 Scanning for nearby hikers...'),
              //       backgroundColor: kMediumSage,
              //       behavior: SnackBarBehavior.floating,
              //       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              //     ),
              //   );
              // },
              child: const Icon(
                Icons.refresh_rounded,
                color: Colors.white,
                size: 28,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
