import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hikingapp/presentation/styles/colors.dart';
import 'package:hikingapp/utils/snackbar_helper.dart';
import 'package:hikingapp/config/api_config.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:hikingapp/providers/trail_provider.dart';
import 'package:hikingapp/presentation/widgets/app_action_dialog.dart';

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

    Future<void> _handleResult(String? result) async {
      if (result != 'confirm') return;

      final navigator = Navigator.of(context);
      try {
        bool success = false;
        String? errorMessage;
        if (isCreator) {
          success = await provider.endTrail(userId);
          if (!success && provider.lastError != null) {
            errorMessage = provider.lastError;
          }
        } else {
          await provider.leaveGroup(userId);
          success = true;
        }

        Get.offAllNamed('/dashboard', arguments: {'tab': 3});
        if (success) {
          final msg = isCreator
              ? 'Trail ended for all members'
              : 'You left the group';
          SnackbarHelper.showSuccess('Success', msg);
        } else {
          final msg = 'Failed: ${errorMessage ?? "Unknown error"}';
          SnackbarHelper.showError('Error', msg);
        }
      } catch (e) {
        navigator.pop();
        SnackbarHelper.showError('Error', '⚠️ Failed: ${e.toString()}');
      }
    }

    showDialog<String>(
      context: context,
      builder: (context) => AppActionDialog(
        title: isCreator ? 'End Trail?' : 'Leave Group?',
        icon: isCreator ? Icons.flag_rounded : Icons.exit_to_app_rounded,
        message: isCreator
            ? 'This will end the trail for all members'
            : 'Are you sure to leave ?',
        cancelText: 'Cancel',
        confirmText: isCreator ? 'End Trail' : 'Leave Group',
        confirmColor: kFreshRed.withOpacity(0.6),
      ),
    ).then(_handleResult);
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
