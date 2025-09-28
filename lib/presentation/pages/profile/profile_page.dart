import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/profile_provider.dart';
import 'widgets/profile_section.dart';
import 'widgets/settings_toggle.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final profile = Provider.of<ProfileProvider>(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAF9),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 30,
                ),
                child: Column(
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: const Color(0xFF16A085),
                        borderRadius: BorderRadius.circular(40),
                      ),
                      child: const Icon(
                        Icons.person,
                        color: Colors.white,
                        size: 40,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      profile.name,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2C3E50),
                      ),
                    ),
                    Text(
                      profile.email,
                      style: const TextStyle(
                        fontSize: 16,
                        color: Color(0xFF8B7355),
                      ),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      icon: const Icon(
                        Icons.edit,
                        color: Color(0xFF16A085),
                        size: 16,
                      ),
                      label: const Text(
                        'Edit Profile',
                        style: TextStyle(color: Color(0xFF16A085)),
                      ),
                      onPressed: () => profile.editProfile(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFE8F8F5),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Hiking Stats
              ProfileSection(
                title: 'Hiking Stats',
                child: Row(
                  children: [
                    _buildStatCard(
                      'Total Hikes',
                      profile.totalHikes.toString(),
                    ),
                    const SizedBox(width: 12),
                    _buildStatCard('Distance', profile.totalDistance),
                  ],
                ),
              ),

              // Emergency Contact
              ProfileSection(
                title: 'Emergency Contact',
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F8F5),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.shield, color: Color(0xFF16A085)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          profile.emergencyContact,
                          style: const TextStyle(color: Color(0xFF2C3E50)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Safety Settings
              ProfileSection(
                title: 'Safety Settings',
                child: Column(
                  children: [
                    SettingsToggle(
                      label: 'Push Notifications',
                      value: profile.settings['pushNotifications']!,
                      onToggle: (v) =>
                          profile.toggleSetting('pushNotifications', v),
                    ),
                    SettingsToggle(
                      label: 'Location Sharing',
                      value: profile.settings['locationSharing']!,
                      onToggle: (v) =>
                          profile.toggleSetting('locationSharing', v),
                    ),
                    SettingsToggle(
                      label: 'Fall Detection',
                      value: profile.settings['fallDetection']!,
                      onToggle: (v) =>
                          profile.toggleSetting('fallDetection', v),
                    ),
                    SettingsToggle(
                      label: 'Auto Check-in',
                      value: profile.settings['autoCheckIn']!,
                      onToggle: (v) => profile.toggleSetting('autoCheckIn', v),
                    ),
                    SettingsToggle(
                      label: 'Weather Alerts',
                      value: profile.settings['weatherAlerts']!,
                      onToggle: (v) =>
                          profile.toggleSetting('weatherAlerts', v),
                    ),
                  ],
                ),
              ),

              // Logout Button
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 20,
                ),
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.logout, color: Color(0xFFE74C3C)),
                  label: const Text(
                    'Logout',
                    style: TextStyle(color: Color(0xFFE74C3C)),
                  ),
                  onPressed: () => profile.logout(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    side: const BorderSide(color: Color(0xFFE74C3C)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Expanded _buildStatCard(String label, String value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFE8F8F5),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF16A085),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(fontSize: 12, color: Color(0xFF8B7355)),
            ),
          ],
        ),
      ),
    );
  }
}
