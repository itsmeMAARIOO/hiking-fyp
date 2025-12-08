import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import 'package:hikingapp/presentation/widgets/app_action_dialog.dart';
import 'package:hikingapp/providers/auth_provider.dart';
import 'package:hikingapp/providers/trail_provider.dart';
import 'package:hikingapp/services/trail_services.dart';
import 'package:hikingapp/utils/snackbar_helper.dart';
import 'package:hikingapp/services/notification_service.dart';
import '../../../services/checkin_service.dart';
import '../../../providers/dashboard_provider.dart';
import 'package:hikingapp/presentation/pages/trail/active_trail/active_trail.dart';

class DashboardController {
  final CheckInService checkInService;

  DashboardController(this.checkInService);

  Future<void> performCheckIn({
    required String? userId,
    required DateTime lastCheckIn,
  }) async {
    try {
      // Get current GPS position
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      await checkInService.saveCheckIn(
        userId: userId,
        checkinTime: DateTime.now(),
        lastCheckinTime: lastCheckIn,
        latitude: position.latitude,
        longitude: position.longitude,
      );
    } catch (e) {
      rethrow;
    }
  }

  Future<void> refreshDashboard(BuildContext context) async {
    final dashboardProvider = Provider.of<DashboardProvider>(
      context,
      listen: false,
    );
    await dashboardProvider.loadLastCheckIn(context);
  }

  Future<Map<String, String>?> checkForInvitation({
    required TrailServices trailService,
    required String userId,
  }) async {
    final invite = await trailService.checkInvitation(userId);
    if (invite == null) return null;
    final groupName = (invite['groupName'] ?? 'Unnamed Group').toString();
    final dynamic rawGroupId = invite['_id'];
    final String groupId = rawGroupId is Map && rawGroupId['\$oid'] != null
        ? rawGroupId['\$oid'] as String
        : rawGroupId?.toString() ?? '';
    return {'groupId': groupId, 'groupName': groupName};
  }

  Future<void> handlePendingInvitation({
    required BuildContext context,
    required TrailServices trailService,
    required AuthProvider authProvider,
  }) async {
    final userId = authProvider.userId;
    if (userId == null) return;
    final invitation = await checkForInvitation(
      trailService: trailService,
      userId: userId,
    );
    if (invitation == null) {
      SnackbarHelper.showSuccess(
        'No Group Invitations',
        'Please check again with the group leader',
      );
      return;
    }

    final groupId = invitation['groupId'] ?? '';
    final groupName = invitation['groupName'] ?? 'Unnamed Group';

    final result = await showDialog<String>(
      context: context,
      builder: (context) => AppActionDialog(
        title: 'GROUP INVITATION',
        icon: Icons.group_add_rounded,
        message: "You've been invited to join '$groupName'. Accept invitation?",
        cancelText: 'REJECT',
        confirmText: 'ACCEPT',
        confirmColor: const Color(0xFFFF6B35),
        cancelResult: 'reject',
        confirmResult: 'accept',
        headerGradient: [
          const Color(0xFF16A085),
          const Color(0xFF16A085).withOpacity(0.8),
        ],
        infoCard: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFF8F9FA),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF16A085).withOpacity(0.2)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF16A085).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.groups_rounded,
                  color: Color(0xFF16A085),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Group Name',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF2C3E50),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      groupName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF16A085),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (result == 'accept') {
      await trailService.respondInvitation(userId, groupId, 'active');
      SnackbarHelper.showSuccess('Success', 'Invitation accepted!');

      final groupProvider = Provider.of<GroupProvider>(context, listen: false);
      final auth = Provider.of<AuthProvider>(context, listen: false);
      try {
        await groupProvider.fetchGroupById(groupId);
        await groupProvider.updateMyLocation(
          groupId: groupId,
          userId: auth.userId ?? '',
          userName: auth.userName ?? '',
        );
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>
                ChangeNotifierProvider.value(
                  value: groupProvider,
                  child: const ActiveTrailPage(),
                ),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
                  return FadeTransition(opacity: animation, child: child);
                },
            transitionDuration: const Duration(milliseconds: 300),
          ),
        );
      } catch (e) {
        SnackbarHelper.showError('Error', 'Failed to join group: $e');
      }
    } else if (result == 'reject') {
      await trailService.respondInvitation(userId, groupId, 'declined');
      SnackbarHelper.showSuccess('Info', 'Invitation rejected.');
    }
  }

  Future<void> notifyInvitationIfNew({
    required String? lastInviteId,
    required Map<String, String> invitation,
  }) async {
    final groupId = invitation['groupId'] ?? '';
    final groupName = invitation['groupName'] ?? 'Unnamed Group';
    if (lastInviteId == groupId || lastInviteId == null) {
      await NotificationService.invitationNotification(
        title: 'Group Invitation',
        body: "You've been invited to join '$groupName'.",
      );
    }
  }
}
