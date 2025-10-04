import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hikingapp/config/routes.dart';
import 'package:hikingapp/core/constants/env.dart';
import 'package:hikingapp/presentation/pages/dashboard/animations/checkin_success_animation.dart';
import 'package:hikingapp/presentation/pages/emergency/emergency_page.dart';
import 'package:hikingapp/presentation/pages/group/group_page.dart';
import 'package:hikingapp/presentation/pages/profile/profile_page.dart';
import 'package:hikingapp/providers/auth_provider.dart';
import 'package:provider/provider.dart';
import 'package:hikingapp/presentation/pages/map/map_page.dart';
import 'widgets/status_card.dart';
import 'widgets/weather_widget.dart';
import 'widgets/dashboard_quick_actions.dart';
import '../../../providers/dashboard_provider.dart';
import '../../../services/checkin_service.dart';
import 'package:hikingapp/presentation/widgets/bottom_nav_bar.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  int _currentIndex = 0;

  final List<Widget> _pages = const [
    DashboardPageContent(),
    MapPage(),
    EmergencyPage(),
    GroupPage(),
    ProfilePage(),
  ];

  void _onTabTap(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  void _goToTab(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAF9),
      body: IndexedStack(index: _currentIndex, children: _pages),
      bottomNavigationBar: BottomNavBar(
        currentIndex: _currentIndex,
        onTap: _onTabTap,
      ),
    );
  }
}

// ---------------------------------------------
// DashboardPageContent
// ---------------------------------------------
class DashboardPageContent extends StatefulWidget {
  const DashboardPageContent({super.key});

  @override
  State<DashboardPageContent> createState() => _DashboardPageContentState();
}

class _DashboardPageContentState extends State<DashboardPageContent> {
  late final CheckInService checkInService;
  late final AuthProvider authProvider;
  bool _checkInTriggered = false;

  @override
  void initState() {
    super.initState();
    checkInService = CheckInService();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      authProvider = Provider.of<AuthProvider>(context, listen: false);
    });
  }

  void _triggerCheckInAnimation() {
    setState(() {
      _checkInTriggered = true;
    });
    Future.delayed(const Duration(milliseconds: 1000), () {
      if (mounted) setState(() => _checkInTriggered = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final dashboardProvider = Provider.of<DashboardProvider>(context);
    final dashboardState = context
        .findAncestorStateOfType<_DashboardPageState>();

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
                  GestureDetector(
                    onTap: () async {
                      await checkInService.handleCheckInTripleTap(
                        dashboardProvider,
                        context,
                      );
                      _triggerCheckInAnimation();
                    },
                    child: CheckInSuccessAnimation(
                      trigger: _checkInTriggered,
                      child: StatusCard(
                        icon: Icons.access_time,
                        iconColor: const Color(0xFF16A085),
                        title: "Last Check-in",
                        status:
                            "${dashboardProvider.lastCheckIn.hour.toString().padLeft(2, '0')}:${dashboardProvider.lastCheckIn.minute.toString().padLeft(2, '0')}",
                        statusColor: const Color(0xFF16A085),
                      ),
                    ),
                  ),
                  // Group Members with Add logic
                  dashboardProvider.groupMembers == 0
                      ? GestureDetector(
                          onTap: () => dashboardState?._goToTab(3),
                          child: StatusCard(
                            icon: Icons.add,
                            iconColor: Colors.grey,
                            title: "Group Members",
                            status: "Add Group",
                            statusColor: Colors.grey,
                          ),
                        )
                      : StatusCard(
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

            QuickActions(
              isTracking: dashboardProvider.isTracking,
              onTrackingToggle: dashboardProvider.toggleTracking,
              onCheckIn: () => dashboardProvider.loadLastCheckIn(context),
            ),

            const SizedBox(height: 20),

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
