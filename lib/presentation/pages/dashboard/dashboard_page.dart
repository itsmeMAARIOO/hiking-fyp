import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hikingapp/presentation/pages/dashboard/animations/checkin_success_animation.dart';
import 'package:hikingapp/presentation/pages/emergency/emergency_page.dart';
import 'package:hikingapp/presentation/pages/group/create_group/group_page.dart';
import 'package:hikingapp/presentation/pages/profile/main_profile/profile_page.dart';
import 'package:hikingapp/presentation/widgets/common_header.dart';
import 'package:hikingapp/providers/auth_provider.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:hikingapp/presentation/pages/map/main_map/map_page.dart';
import 'widgets/status_card.dart';
import 'widgets/weather_widget.dart';
import 'widgets/dashboard_quick_actions.dart';
import '../../../providers/dashboard_provider.dart';
import '../../../services/checkin_service.dart';
import 'package:hikingapp/presentation/widgets/bottom_nav_bar.dart';

// Color constants matching the map page
const Color kDeepTeal = Color(0xFF1c3f3f);
const Color kSoftMint = Color(0xFFa0d5b9);
const Color kMediumSage = Color(0xFF6baf89);
const Color kDeepForest = Color(0xFF3e7b5b);

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    final args = Get.arguments;
    if (args != null && args['tab'] != null) {
      _currentIndex = args['tab'];
    }
  }

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

    return Stack(
      children: [
        // Content Layer
        SafeArea(
          child: Column(
            children: [
              // Header matching map page style
              _buildHeader(),

              // Main Content Container with rounded top
              Expanded(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 500),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.95),
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(30),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: kDeepTeal.withOpacity(0.3),
                        blurRadius: 30,
                        spreadRadius: 5,
                        offset: const Offset(0, -10),
                      ),
                    ],
                  ),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.only(bottom: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 20),

                        // Weather Widget
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 20),
                          child: WeatherWidget(),
                        ),

                        const SizedBox(height: 24),

                        // Status Grid
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Wrap(
                            spacing: 12,
                            runSpacing: 12,
                            children: [
                              // location tracking status
                              StatusCard(
                                icon: Icons.location_pin,
                                iconColor: dashboardProvider.isTracking
                                    ? kDeepForest
                                    : kMediumSage,
                                title: "GPS Tracking",
                                status: dashboardProvider.isTracking
                                    ? "Active"
                                    : "Inactive",
                                statusColor: dashboardProvider.isTracking
                                    ? kDeepForest
                                    : Colors.grey,
                              ),
                              // connectivity status
                              StatusCard(
                                icon: dashboardProvider.isOnline
                                    ? Icons.wifi
                                    : Icons.wifi_off,
                                iconColor: dashboardProvider.isOnline
                                    ? kDeepForest
                                    : const Color(0xFFFF6B6B),
                                title: "Connectivity",
                                status: dashboardProvider.isOnline
                                    ? "Online"
                                    : "Offline",
                                statusColor: dashboardProvider.isOnline
                                    ? kDeepForest
                                    : const Color(0xFFFF6B6B),
                              ),
                              // check in status
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
                                    iconColor: kDeepForest,
                                    title: "Last Check-in",
                                    status:
                                        dashboardProvider.lastCheckIn != null
                                        ? DateFormat(
                                            'dd-MMM-yy - HH:mm',
                                          ).format(
                                            dashboardProvider.lastCheckIn!,
                                          )
                                        : 'No check-in',
                                    statusColor: kDeepForest,
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
                                      iconColor: kMediumSage,
                                      title: "Group Members",
                                      status:
                                          "${dashboardProvider.groupMembers} Active",
                                      statusColor: kMediumSage,
                                    ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Quick Actions
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: kDeepTeal.withOpacity(0.1),
                                  blurRadius: 15,
                                  offset: const Offset(0, 5),
                                ),
                              ],
                            ),
                            child: QuickActions(
                              isTracking: dashboardProvider.isTracking,
                              onTrackingToggle:
                                  dashboardProvider.toggleTracking,
                              onCheckIn: () =>
                                  dashboardProvider.loadLastCheckIn(context),
                            ),
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Safety Tip
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: kSoftMint.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Icon(
                                      Icons.lightbulb_outline_rounded,
                                      color: kDeepForest,
                                      size: 20,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  const Text(
                                    "Today's Safety Tip",
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w700,
                                      color: kDeepTeal,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Container(
                                decoration: BoxDecoration(
                                  color: kSoftMint.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: kSoftMint.withOpacity(0.3),
                                    width: 1,
                                  ),
                                ),
                                padding: const EdgeInsets.all(20),
                                child: Text(
                                  "Always inform someone about your planned route and expected return time before heading out. Carry essential supplies and check weather conditions regularly.",
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: kDeepTeal.withOpacity(0.8),
                                    height: 1.5,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Widget _buildHeader() {
  //   return Container(
  //     padding: const EdgeInsets.all(25),
  //     decoration: BoxDecoration(
  //       gradient: LinearGradient(
  //         colors: [kDeepTeal, kDeepForest],
  //         begin: Alignment.topLeft,
  //         end: Alignment.bottomRight,
  //       ),
  //       boxShadow: [
  //         BoxShadow(
  //           color: kDeepTeal.withOpacity(0.5),
  //           blurRadius: 15,
  //           offset: const Offset(0, 5),
  //         ),
  //       ],
  //     ),
  //     child: Row(
  //       mainAxisAlignment: MainAxisAlignment.spaceBetween,
  //       children: [
  //         Column(
  //           crossAxisAlignment: CrossAxisAlignment.start,
  //           children: [
  //             Text(
  //               "Hiker Safety",
  //               style: TextStyle(
  //                 fontSize: 28,
  //                 fontWeight: FontWeight.w700,
  //                 color: Colors.white,
  //                 shadows: [
  //                   Shadow(blurRadius: 10, color: kDeepTeal.withOpacity(0.5)),
  //                 ],
  //               ),
  //             ),
  //             const SizedBox(height: 4),
  //             Text(
  //               "Stay safe on the trail",
  //               style: TextStyle(
  //                 fontSize: 14,
  //                 color: kSoftMint,
  //                 fontWeight: FontWeight.w500,
  //               ),
  //             ),
  //           ],
  //         ),
  //       ],
  //     ),
  //   );
  // }

  Widget _buildHeader() {
    return const CommonHeader(
      title: 'Dashboard',
      subtitle: 'Stay safe on trail',
    );
  }

  Widget _buildEnhancedStatusCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String status,
    required Color statusColor,
    required Gradient gradient,
  }) {
    return Container(
      width: (MediaQuery.of(context).size.width - 52) / 2,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            gradient: gradient,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: Colors.white, size: 20),
                ),
                const SizedBox(height: 12),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  status,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
