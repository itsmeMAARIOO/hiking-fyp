import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hikingapp/utils/snackbar_helper.dart';
import 'package:hikingapp/config/api_config.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:hikingapp/providers/trail_provider.dart';
import 'package:hikingapp/presentation/styles/colors.dart';

class TrailServices {
  final String baseUrl = ApiConfig.baseUrl;

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
    } else {
      provider.stopLocationUpdates();
    }
  }

  /// Show dialog when ending the trail (different for creator vs joiner)
  static void showEndTrailDialog({
    required BuildContext context,
    required GroupProvider provider,
    required String userId,
  }) {
    final group = provider.activeGroup;
    if (group == null) return;

    final isCreator = group['createdBy'].toString() == userId;

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
                child: Icon(
                  isCreator ? Icons.flag_rounded : Icons.exit_to_app_rounded,
                  color: const Color(0xFFFF6B6B),
                  size: 32,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                isCreator ? 'End Trail?' : 'Leave Group?',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: kDeepTeal,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                isCreator
                    ? 'This will end the trail for all members and disband the group.'
                    : 'Are you sure you want to leave this group?',
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
                    child: _buildActionButton(
                      context,
                      provider,
                      userId,
                      isCreator,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
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

  static Widget _buildActionButton(
    BuildContext context,
    GroupProvider provider,
    String userId,
    bool isCreator,
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
            // Get the navigator before any async operations
            final navigator = Navigator.of(context);

            // Close dialog first
            navigator.pop();

            bool success = false;
            String? errorMessage;

            try {
              if (isCreator) {
                // Creator ends trail for everyone
                success = await provider.endTrail(userId);
                if (!success && provider.lastError != null) {
                  errorMessage = provider.lastError;
                }
              } else {
                // Joiner just leaves the group
                await provider.leaveGroup(userId);
                success = true;
              }
            } catch (e) {
              errorMessage = e.toString();
            }

            // Navigate back to dashboard first
            Get.offAllNamed('/dashboard', arguments: {'tab': 3});

            // Show snackbar after navigation using SnackbarHelper
            if (success) {
              final msg = isCreator
                  ? '🏁 Trail ended for all members'
                  : '👋 You left the group';
              SnackbarHelper.showSuccess('Success', msg);
            } else {
              final msg = '⚠️ Failed: ${errorMessage ?? "Unknown error"}';
              SnackbarHelper.showError('Error', msg);
            }
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
            child: Text(
              isCreator ? 'End Trail' : 'Leave Group',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<Map<String, dynamic>?> checkInvitation(String userId) async {
    final res = await http.get(Uri.parse('$baseUrl/group/invitation/$userId'));

    if (res.statusCode == 200) {
      return jsonDecode(res.body);
    }
    return null;
  }

  Future<bool> respondInvitation(
    String userId,
    String groupId,
    String status,
  ) async {
    final res = await http.put(
      Uri.parse('$baseUrl/group/invitation/respond'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'userId': userId,
        'groupId': groupId,
        'status': status,
      }),
    );

    return res.statusCode == 200;
  }
}
