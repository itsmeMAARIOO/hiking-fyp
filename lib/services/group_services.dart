import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hikingapp/presentation/pages/group/create_group/group_page.dart';
import 'package:provider/provider.dart';
import 'package:hikingapp/providers/group_provider.dart';

class GroupServices {
  /// Start location tracking immediately
  static void startTracking({
    required BuildContext context,
    required String userId,
    required String userName,
  }) {
    final provider = Provider.of<GroupProvider>(context, listen: false);
    if (provider.activeGroup != null) {
      provider.startLocationUpdates(
        groupId: provider.activeGroup!['_id'],
        userId: userId,
        userName: userName,
      );
    }
  }

  /// Toggle location tracking with snackbars
  static void toggleTracking({
    required BuildContext context,
    required bool isTracking,
    required String userId,
    required String userName,
    required Function(bool) onTrackingChanged,
  }) {
    final provider = Provider.of<GroupProvider>(context, listen: false);
    if (provider.activeGroup == null) return;

    final newTrackingState = !isTracking;
    onTrackingChanged(newTrackingState);

    if (newTrackingState) {
      provider.startLocationUpdates(
        groupId: provider.activeGroup!['_id'],
        userId: userId,
        userName: userName,
      );
      _showSnackBar(context, '🎯 Location tracking started', kMediumSage);
    } else {
      provider.stopLocationUpdates();
      _showSnackBar(context, '⏸️ Location tracking paused', kDeepTeal);
    }
  }

  /// Show dialog when ending the trail
  static void showEndTrailDialog({
    required BuildContext context,
    required GroupProvider provider,
    required String userId,
  }) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF6B6B).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.stop_circle_rounded,
                  color: Color(0xFFFF6B6B),
                  size: 32,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'End Trail?',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: kDeepTeal,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Are you sure you want to end this trail and leave the group?',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: kDeepTeal.withOpacity(0.7),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(child: _buildCancelButton(context)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildEndTrailButton(context, provider, userId),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// --- Private helper widgets and functions ---

  static void _showSnackBar(
    BuildContext context,
    String message,
    Color bgColor,
  ) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: bgColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  static Widget _buildCancelButton(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: kDeepTeal.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => Navigator.of(context).pop(),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: kSoftMint.withOpacity(0.3)),
            ),
            child: const Text(
              'Cancel',
              textAlign: TextAlign.center,
              style: TextStyle(color: kDeepTeal, fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ),
    );
  }

  static Widget _buildEndTrailButton(
    BuildContext context,
    GroupProvider provider,
    String userId,
  ) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFF6B6B).withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () async {
            await provider.leaveGroup(userId);
            WidgetsBinding.instance.addPostFrameCallback((_) {
              Get.offAllNamed('/dashboard', arguments: {'tab': 3});
            });
          },

          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFF6B6B), Color(0xFFFF5252)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text(
              'End Trail',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
