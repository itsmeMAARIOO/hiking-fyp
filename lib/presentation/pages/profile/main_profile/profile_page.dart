import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get/get.dart';
import 'package:hikingapp/config/images/image_locations.dart';
import 'package:hikingapp/config/routes.dart';
import 'package:hikingapp/presentation/pages/profile/main_profile/profile_controller.dart';
import 'package:hikingapp/presentation/pages/profile/main_profile/widgets/emergency_contact_card.dart';
import 'package:provider/provider.dart';
import 'package:hikingapp/presentation/styles/colors.dart';
import '../../../../providers/profile_provider.dart';
import '../../../../providers/auth_provider.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  late ProfileController controller;

  @override
  void initState() {
    super.initState();
    final profileProvider = Provider.of<ProfileProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    controller = ProfileController(context);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final effectiveUserId = authProvider.userId ?? profileProvider.userId;
      if (effectiveUserId != null) {
        controller.setUserId(effectiveUserId);
        controller.fetchUserData();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAF9),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Consumer<ProfileProvider>(
            builder: (context, profile, _) {
              return Column(
                children: [
                  // Header with gradient background
                  // Header with background
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 30,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [kDeepTeal, kDeepForest],
                      ),
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(24),
                        bottomRight: Radius.circular(24),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        // Profile Image with border
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              colors: [
                                Colors.white,
                                const Color(0xFF16A085).withOpacity(0.3),
                              ],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: CircleAvatar(
                            radius: 42,
                            backgroundColor: const Color(0xFFE8F8F5),
                            backgroundImage:
                                (profile.profileImage != null &&
                                    profile.profileImage!.isNotEmpty)
                                ? profile.profileImage!.startsWith('http')
                                      ? NetworkImage(profile.profileImage!)
                                      : FileImage(
                                          File(
                                            profile.profileImage!.replaceFirst(
                                              'file://',
                                              '',
                                            ),
                                          ),
                                        )
                                : AssetImage(ImageLocation.climber)
                                      as ImageProvider,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          profile.userName ?? 'Hiker',
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          profile.userEmail ?? '',
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.white70,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          icon: const Icon(
                            Icons.edit_outlined,
                            color: Colors.white,
                            size: 18,
                          ),
                          label: const Text(
                            'Edit Profile',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          onPressed: () async {
                            await Get.toNamed(AppRoutes.editProfile);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.black.withOpacity(0.3),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 10,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                              side: BorderSide(
                                color: Colors.white.withOpacity(0.5),
                                width: 1,
                              ),
                            ),
                            elevation: 2,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Hiking Stats - Enhanced cards
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Hiking Stats',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2C3E50),
                          ),
                        ),
                        const SizedBox(height: 12),
                        FutureBuilder<Map<String, int>>(
                          future: controller.loadHikeCountsLatest(),
                          builder: (context, snapshot) {
                            final solo = snapshot.hasData
                                ? (snapshot.data!['solo'] ?? 0)
                                : profile.totalSoloHikes;
                            final group = snapshot.hasData
                                ? (snapshot.data!['group'] ?? 0)
                                : profile.totalGroupHikes;
                            return Row(
                              children: [
                                _buildEnhancedStatCard(
                                  'Total Solo Hikes',
                                  solo.toString(),
                                  Icons.terrain_rounded,
                                  const Color(0xFF16A085),
                                ),
                                const SizedBox(width: 12),
                                _buildEnhancedStatCard(
                                  'Total Group Hikes',
                                  group.toString(),
                                  Icons.straighten_rounded,
                                  const Color(0xFF8B4513),
                                ),
                              ],
                            );
                          },
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Emergency Contact - Enhanced
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.emergency_rounded,
                              color: Color(0xFFFF6B35),
                              size: 24,
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'Emergency Contact',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF2C3E50),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        const EmergencyContactCard(),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Safety Settings - Enhanced section
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.security_rounded,
                              color: Color(0xFF16A085),
                              size: 24,
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'Safety Settings',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF2C3E50),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 10,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              _buildEnhancedSettingsToggle(
                                icon: Icons.notifications_active_rounded,
                                label: 'Push Notifications',
                                value: profile.settings['pushNotifications']!,
                                onToggle: (v) => controller.toggleSetting(
                                  'pushNotifications',
                                  v,
                                ),
                                isFirst: true,
                              ),
                              _buildEnhancedSettingsToggle(
                                icon: Icons.my_location_rounded,
                                label: 'Location Sharing',
                                value: profile.settings['locationSharing']!,
                                onToggle: (v) => controller.toggleSetting(
                                  'locationSharing',
                                  v,
                                ),
                              ),
                              _buildEnhancedSettingsToggle(
                                icon: Icons.health_and_safety_rounded,
                                label: 'Fall Detection',
                                value: profile.settings['fallDetection']!,
                                onToggle: (v) => controller.toggleSetting(
                                  'fallDetection',
                                  v,
                                ),
                              ),
                              _buildEnhancedSettingsToggle(
                                icon: Icons.check_circle_outline_rounded,
                                label: 'Auto Check-in',
                                value: profile.settings['autoCheckIn']!,
                                onToggle: (v) =>
                                    controller.toggleSetting('autoCheckIn', v),
                              ),
                              _buildEnhancedSettingsToggle(
                                icon: Icons.cloud_rounded,
                                label: 'Weather Alerts',
                                value: profile.settings['weatherAlerts']!,
                                onToggle: (v) => controller.toggleSetting(
                                  'weatherAlerts',
                                  v,
                                ),
                                isLast: true,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Logout Button - Enhanced
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        icon: const Icon(
                          Icons.logout_rounded,
                          color: Color(0xFFE74C3C),
                          size: 22,
                        ),
                        label: const Text(
                          'Logout',
                          style: TextStyle(
                            color: Color(0xFFE74C3C),
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                        onPressed: () async {
                          final confirmed = await showDialog<bool>(
                            context: context,
                            builder: (context) => Dialog(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Container(
                                padding: const EdgeInsets.all(24),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFFFEBEE),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.logout_rounded,
                                        size: 48,
                                        color: Color(0xFFE74C3C),
                                      ),
                                    ),
                                    const SizedBox(height: 20),
                                    const Text(
                                      'Logout',
                                      style: TextStyle(
                                        fontSize: 22,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF2C3E50),
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    const Text(
                                      'Are you sure you want to logout?',
                                      style: TextStyle(
                                        fontSize: 15,
                                        color: Color(0xFF7F8C8D),
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                    const SizedBox(height: 24),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: OutlinedButton(
                                            onPressed: () =>
                                                Navigator.pop(context, false),
                                            style: OutlinedButton.styleFrom(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    vertical: 14,
                                                  ),
                                              side: const BorderSide(
                                                color: Color(0xFF95A5A6),
                                                width: 2,
                                              ),
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                              ),
                                            ),
                                            child: const Text(
                                              'Cancel',
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w600,
                                                color: Color(0xFF2C3E50),
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: ElevatedButton(
                                            onPressed: () =>
                                                Navigator.pop(context, true),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: const Color(
                                                0xFFE74C3C,
                                              ),
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    vertical: 14,
                                                  ),
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                              ),
                                            ),
                                            child: const Text(
                                              'Logout',
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );

                          if (confirmed == true) {
                            const storage = FlutterSecureStorage();
                            await storage.delete(key: "authToken");
                            Get.offAllNamed(AppRoutes.login);
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          side: const BorderSide(
                            color: Color(0xFFE74C3C),
                            width: 2,
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildEnhancedStatCard(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF7F8C8D),
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEnhancedSettingsToggle({
    required IconData icon,
    required String label,
    required bool value,
    required Function(bool) onToggle,
    bool isFirst = false,
    bool isLast = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: isLast
              ? BorderSide.none
              : BorderSide(color: const Color(0xFFF0F0F0), width: 1),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F8F5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: const Color(0xFF16A085), size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 16,
                  color: Color(0xFF2C3E50),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Switch(
              value: value,
              onChanged: onToggle,
              activeColor: const Color(0xFF16A085),
              activeTrackColor: const Color(0xFF16A085).withOpacity(0.3),
            ),
          ],
        ),
      ),
    );
  }
}
