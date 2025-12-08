import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get/get.dart';
import 'package:hikingapp/config/images/image_locations.dart';
import 'package:hikingapp/config/routes.dart';
import 'package:hikingapp/presentation/pages/profile/main_profile/profile_controller.dart';
import 'package:provider/provider.dart';
import 'package:hikingapp/presentation/styles/colors.dart';
import 'package:hikingapp/presentation/styles/app_styles.dart';
import '../../../../providers/profile_provider.dart';
import '../../../../providers/auth_provider.dart';
import 'widgets/hiking_stats_card.dart';
import 'widgets/stat_card.dart';
import 'widgets/settings_toggle.dart';

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
    final profileProvider = Provider.of<ProfileProvider>(
      context,
      listen: false,
    );
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
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          const AnimatedBackground(),
          SafeArea(
            child: RefreshIndicator(
              onRefresh: _refresh,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Consumer<ProfileProvider>(
                  builder: (context, profile, _) {
                    return Column(
                      children: [
                        // Minimal profile header (aligned with modern apps)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(28, 12, 28, 12),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              CircleAvatar(
                                radius: 35,
                                backgroundColor: const Color(0xFFE8F8F5),
                                backgroundImage:
                                    (profile.profileImage != null &&
                                        profile.profileImage!.isNotEmpty)
                                    ? profile.profileImage!.startsWith('http')
                                          ? NetworkImage(profile.profileImage!)
                                          : FileImage(
                                              File(
                                                profile.profileImage!
                                                    .replaceFirst(
                                                      'file://',
                                                      '',
                                                    ),
                                              ),
                                            )
                                    : AssetImage(ImageLocation.climber)
                                          as ImageProvider,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      profile.userName ?? 'Hiker',
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.w700,
                                        color: kDeepTeal,
                                        letterSpacing: -0.2,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      profile.userEmail ?? '',
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 13,
                                        color: Color(0xFF7F8C8D),
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.edit_outlined,
                                  color: kDeepTeal,
                                  size: 30,
                                ),
                                onPressed: () async {
                                  await Get.toNamed(AppRoutes.editProfile);
                                },
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
                              // Health Card entry
                              Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: SizedBox(
                                  width: double.infinity,
                                  child: OutlinedButton.icon(
                                    onPressed: () =>
                                        Get.toNamed(AppRoutes.healthCard),
                                    icon: const Icon(
                                      Icons.health_and_safety_rounded,
                                      color: kDeepTeal,
                                    ),
                                    label: const Text(
                                      'Health Card',
                                      style: TextStyle(
                                        color: kDeepTeal,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    style: OutlinedButton.styleFrom(
                                      side: const BorderSide(
                                        color: kDeepTeal,
                                        width: 2,
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 12,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const Text(
                                'Hiking Stats',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: kDeepTeal,
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
                                      StatCard(
                                        label: 'Solo Hikes',
                                        value: solo.toString(),
                                        icon: Icons.terrain_rounded,
                                        color: kMediumSage,
                                        onTap: () {
                                          Get.toNamed(
                                            AppRoutes.hikeHistory,
                                            arguments: {'type': 'solo'},
                                          );
                                        },
                                      ),
                                      const SizedBox(width: 12),
                                      StatCard(
                                        label: 'Group Hikes',
                                        value: group.toString(),
                                        icon: Icons.straighten_rounded,
                                        color: kDeepForest,
                                        onTap: () {
                                          Get.toNamed(
                                            AppRoutes.hikeHistory,
                                            arguments: {'type': 'group'},
                                          );
                                        },
                                      ),
                                    ],
                                  );
                                },
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Hiking Activity Overview - analytics card
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 20),
                          child: HikingStatsCard(),
                        ),
                        const SizedBox(height: 24),

                        // Safety Settings
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
                                      color: kDeepTeal,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Container(
                                decoration: BoxDecoration(
                                  color: kWarmWhite,
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
                                    // _buildEnhancedSettingsToggle(
                                    //   icon: Icons.notifications_active_rounded,
                                    //   label: 'Push Notifications',
                                    //   value: profile.settings['pushNotifications']!,
                                    //   onToggle: (v) => controller.toggleSetting(
                                    //     'pushNotifications',
                                    //     v,
                                    //   ),
                                    //   isFirst: true,
                                    // ),
                                    // _buildEnhancedSettingsToggle(
                                    //   icon: Icons.my_location_rounded,
                                    //   label: 'Location Sharing',
                                    //   value: profile.settings['locationSharing']!,
                                    //   onToggle: (v) => controller.toggleSetting(
                                    //     'locationSharing',
                                    //     v,
                                    //   ),
                                    // ),
                                    SettingsToggle(
                                      icon: Icons.health_and_safety_rounded,
                                      label: 'Fall Detection',
                                      value: profile.settings['fallDetection']!,
                                      onToggle: (v) => controller.toggleSetting(
                                        'fallDetection',
                                        v,
                                      ),
                                    ),
                                    // _buildEnhancedSettingsToggle(
                                    //   icon: Icons.check_circle_outline_rounded,
                                    //   label: 'Auto Check-in',
                                    //   value: profile.settings['autoCheckIn']!,
                                    //   onToggle: (v) =>
                                    //       controller.toggleSetting('autoCheckIn', v),
                                    // ),
                                    SettingsToggle(
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
                                        color: kWarmWhite,
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
                                              color: kDeepTeal,
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
                                                      Navigator.pop(
                                                        context,
                                                        false,
                                                      ),
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
                                                          BorderRadius.circular(
                                                            12,
                                                          ),
                                                    ),
                                                  ),
                                                  child: const Text(
                                                    'Cancel',
                                                    style: TextStyle(
                                                      fontSize: 16,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      color: kDeepTeal,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 12),
                                              Expanded(
                                                child: ElevatedButton(
                                                  onPressed: () =>
                                                      Navigator.pop(
                                                        context,
                                                        true,
                                                      ),
                                                  style: ElevatedButton.styleFrom(
                                                    backgroundColor:
                                                        const Color(0xFFE74C3C),
                                                    padding:
                                                        const EdgeInsets.symmetric(
                                                          vertical: 14,
                                                        ),
                                                    shape: RoundedRectangleBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            12,
                                                          ),
                                                    ),
                                                  ),
                                                  child: const Text(
                                                    'Logout',
                                                    style: TextStyle(
                                                      fontSize: 16,
                                                      fontWeight:
                                                          FontWeight.bold,
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
                                backgroundColor: kWarmWhite,
                                side: const BorderSide(
                                  color: Color(0xFFE74C3C),
                                  width: 2,
                                ),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
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
          ),
        ],
      ),
    );
  }

  Future<void> _refresh() async {
    try {
      await controller.fetchUserData();
      setState(() {});
    } catch (_) {}
  }
}
