import 'package:flutter/material.dart';
import 'package:hikingapp/presentation/pages/emergency/emergency_page.dart';
import 'package:hikingapp/presentation/pages/group/group_page.dart';
import 'package:hikingapp/presentation/pages/profile/profile_page.dart';
import 'package:provider/provider.dart';
import 'package:hikingapp/presentation/pages/map/map_page.dart';
import 'package:hikingapp/presentation/widgets/bottom_nav_bar.dart';
import 'widgets/status_card.dart';
import 'widgets/weather_widget.dart';
import 'widgets/dashboard_quick_actions.dart';
import '../../../providers/dashboard_provider.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  int _currentIndex = 0;

  // List of pages
  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      const DashboardPageContent(), // Dashboard content
      const MapPage(), // Map page
      const EmergencyPage(),
      const GroupPage(),
      const ProfilePage(),
    ];
  }

  void _onTabTap(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAF9),
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavBar(
        currentIndex: _currentIndex,
        onTap: _onTabTap,
      ),
    );
  }
}

// Dashboard content separated to avoid recursion
class DashboardPageContent extends StatelessWidget {
  const DashboardPageContent({super.key});

  @override
  Widget build(BuildContext context) {
    final dashboardProvider = Provider.of<DashboardProvider>(context);

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    "Hiker Safety",
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2C3E50),
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    "Stay safe on the trail",
                    style: TextStyle(fontSize: 16, color: Color(0xFF8B7355)),
                  ),
                ],
              ),
            ),

            // Weather Widget
            const WeatherWidget(),

            // Status Grid
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  StatusCard(
                    icon: Icons.location_pin,
                    iconColor: dashboardProvider.isTracking
                        ? const Color(0xFF8B7355)
                        : const Color(0xFF16A085),
                    title: "GPS Tracking",
                    status: dashboardProvider.isTracking
                        ? "Active"
                        : "Inactive",
                    statusColor: dashboardProvider.isTracking
                        ? const Color(0xFF8B7355)
                        : const Color(0xFF16A085),
                  ),
                  StatusCard(
                    icon: dashboardProvider.isOnline
                        ? Icons.wifi
                        : Icons.wifi_off,
                    iconColor: dashboardProvider.isOnline
                        ? const Color(0xFF16A085)
                        : const Color(0xFFE74C3C),
                    title: "Connectivity",
                    status: dashboardProvider.isOnline ? "Online" : "Offline",
                    statusColor: dashboardProvider.isOnline
                        ? const Color(0xFF16A085)
                        : const Color(0xFFE74C3C),
                  ),
                  StatusCard(
                    icon: Icons.access_time,
                    iconColor: const Color(0xFF16A085),
                    title: "Last Check-in",
                    status:
                        "${dashboardProvider.lastCheckIn.hour.toString().padLeft(2, '0')}:${dashboardProvider.lastCheckIn.minute.toString().padLeft(2, '0')}",
                    statusColor: const Color(0xFF16A085),
                  ),
                  StatusCard(
                    icon: Icons.group,
                    iconColor: const Color(0xFF16A085),
                    title: "Group Members",
                    status: "${dashboardProvider.groupMembers} Active",
                    statusColor: const Color(0xFF16A085),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Quick Actions
            QuickActions(
              isTracking: dashboardProvider.isTracking,
              onTrackingToggle: dashboardProvider.toggleTracking,
              onCheckIn: dashboardProvider.checkIn,
            ),

            const SizedBox(height: 20),

            // Safety Tips
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Today's Safety Tip",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2C3E50),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F8F5),
                      borderRadius: BorderRadius.circular(12),
                      border: const Border(
                        left: BorderSide(color: Color(0xFF16A085), width: 4),
                      ),
                    ),
                    padding: const EdgeInsets.all(16),
                    child: const Text(
                      "Always inform someone about your planned route and expected return time before heading out.",
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0xFF2C3E50),
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
