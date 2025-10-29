import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hikingapp/utils/snackbar_helper.dart';
import 'package:hikingapp/presentation/pages/dashboard/animations/checkin_success_animation.dart';
import 'package:hikingapp/presentation/pages/emergency/emergency_page.dart';
import 'package:hikingapp/presentation/pages/group/create_group/create_group_page.dart';
import 'package:hikingapp/presentation/pages/profile/main_profile/profile_page.dart';
import 'package:hikingapp/presentation/widgets/common_header.dart';
import 'package:hikingapp/providers/auth_provider.dart';
import 'package:hikingapp/providers/group_provider.dart';
import 'package:hikingapp/services/group_services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:hikingapp/presentation/pages/map/main_map/map_page.dart';
import 'package:hikingapp/presentation/pages/group/trail_group/trail_group_page.dart';
import 'widgets/status_card.dart';
import 'widgets/weather_widget.dart';
import 'widgets/dashboard_quick_actions.dart';
import '../../../providers/dashboard_provider.dart';
import '../../../services/checkin_service.dart';
import 'package:hikingapp/presentation/widgets/bottom_nav_bar.dart';
import 'package:hikingapp/presentation/styles/colors.dart';

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
      body: Stack(
        children: [IndexedStack(index: _currentIndex, children: _pages)],
      ),
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
  late final GroupServices groupService;

  bool _checkInTriggered = false;

  @override
  void initState() {
    super.initState();
    checkInService = CheckInService();
    groupService = GroupServices();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      authProvider = Provider.of<AuthProvider>(context, listen: false);
    });
  }

  Future<void> _checkPendingInvitations() async {
    final userId = authProvider.userId;
    final invite = await groupService.checkInvitation(userId!);

    if (invite == null) {
      if (!mounted) return;
      SnackbarHelper.showSuccess(
        'No Group Invitations',
        'Please check again with the group leader',
      );
      return;
    }

    final groupName = invite['groupName'] ?? 'Unnamed Group';
    final dynamic rawGroupId = invite['_id'];
    final String groupId = rawGroupId is Map && rawGroupId['\$oid'] != null
        ? rawGroupId['\$oid'] as String
        : rawGroupId?.toString() ?? '';

    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Group Invitation"),
        content: Text(
          "You've been invited to join '$groupName'. Accept invitation?",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, 'reject'),
            child: const Text("Reject"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, 'accept'),
            child: const Text("Accept"),
          ),
        ],
      ),
    );

    if (result == 'accept') {
      await groupService.respondInvitation(userId, groupId, 'active');
      if (!mounted) return;
      SnackbarHelper.showSuccess("Success", "Invitation accepted!");

      final groupProvider = Provider.of<GroupProvider>(context, listen: false);
      final auth = Provider.of<AuthProvider>(context, listen: false);

      try {
        await groupProvider.fetchGroupById(groupId);
        await groupProvider.updateMyLocation(
          groupId: groupId,
          userId: auth.userId ?? '',
          userName: auth.userName ?? '',
        );

        if (!mounted) return;
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>
                ChangeNotifierProvider.value(
                  value: groupProvider,
                  child: const TrailGroupPage(),
                ),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
                  return FadeTransition(opacity: animation, child: child);
                },
            transitionDuration: const Duration(milliseconds: 300),
          ),
        );
      } catch (e) {
        SnackbarHelper.showError("Error", "Failed to join group: $e");
      }
    } else if (result == 'reject') {
      await groupService.respondInvitation(userId, groupId, 'declined');
      if (!mounted) return;
      SnackbarHelper.showSuccess("Info", "Invitation rejected.");
    }
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

    return Stack(
      children: [
        // Background gradient for smoother transition
        Container(decoration: const BoxDecoration(color: kDeepForest)),

        // Content Layer
        SafeArea(
          child: Column(
            children: [
              // Header with improved fade transition
              Stack(
                children: [
                  const CommonHeader(
                    title: 'Dashboard',
                    subtitle: 'Stay safe on trail',
                    trailingWidget: Icon(
                      Icons.shield,
                      size: 32,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),

              // Main Content Container with improved overlap and animation
              Expanded(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 800),
                  curve: Curves.easeOutCubic,
                  // ✅ Solid color to remove bleed-through
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(30),
                    ),
                  ),
                  clipBehavior: Clip.hardEdge, // ✅ Ensures no overflow shadows
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      return SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.only(bottom: 20),
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            minHeight: constraints
                                .maxHeight, // ✅ fills all vertical space
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 20),

                              // Weather widget with fade-in
                              AnimatedOpacity(
                                duration: const Duration(milliseconds: 600),
                                opacity: 1.0,
                                child: const Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 20),
                                  child: WeatherWidget(),
                                ),
                              ),

                              const SizedBox(height: 28),

                              // Status cards
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                ),
                                child: Wrap(
                                  spacing: 12,
                                  runSpacing: 12,
                                  children: [
                                    AnimatedContainer(
                                      duration: const Duration(
                                        milliseconds: 400,
                                      ),
                                      curve: Curves.easeOut,
                                      child: StatusCard(
                                        icon: Icons.location_pin,
                                        iconColor: dashboardProvider.isTracking
                                            ? kDeepForest
                                            : kMediumSage,
                                        title: "GPS Tracking",
                                        status: dashboardProvider.isTracking
                                            ? "Active"
                                            : "Inactive",
                                        statusColor:
                                            dashboardProvider.isTracking
                                            ? kDeepForest
                                            : Colors.grey,
                                      ),
                                    ),
                                    AnimatedContainer(
                                      duration: const Duration(
                                        milliseconds: 500,
                                      ),
                                      curve: Curves.easeOut,
                                      child: StatusCard(
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
                                    ),
                                    AnimatedContainer(
                                      duration: const Duration(
                                        milliseconds: 600,
                                      ),
                                      curve: Curves.easeOut,
                                      child: GestureDetector(
                                        onTap: () async {
                                          await checkInService
                                              .handleCheckInTripleTap(
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
                                                dashboardProvider.lastCheckIn !=
                                                    null
                                                ? DateFormat(
                                                    'dd-MMM-yy - HH:mm',
                                                  ).format(
                                                    dashboardProvider
                                                        .lastCheckIn!
                                                        .toUtc()
                                                        .add(
                                                          const Duration(
                                                            hours: 8,
                                                          ),
                                                        ),
                                                  )
                                                : 'No check-in',
                                            statusColor: kDeepForest,
                                          ),
                                        ),
                                      ),
                                    ),
                                    AnimatedContainer(
                                      duration: const Duration(
                                        milliseconds: 700,
                                      ),
                                      curve: Curves.easeOut,
                                      child: dashboardProvider.groupMembers == 0
                                          ? GestureDetector(
                                              onTap: _checkPendingInvitations,
                                              child: StatusCard(
                                                icon: Icons.group_add,
                                                iconColor: Colors.grey,
                                                title: "Group Members",
                                                status: "View Invitation",
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
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(height: 28),

                              // Quick Actions
                              AnimatedOpacity(
                                duration: const Duration(milliseconds: 800),
                                opacity: 1.0,
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                  ),
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
                                      onCheckIn: () => dashboardProvider
                                          .loadLastCheckIn(context),
                                    ),
                                  ),
                                ),
                              ),

                              const SizedBox(height: 28),

                              // Safety Tip section
                              AnimatedOpacity(
                                duration: const Duration(milliseconds: 1000),
                                opacity: 1.0,
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.all(8),
                                            decoration: BoxDecoration(
                                              color: kSoftMint.withOpacity(0.2),
                                              borderRadius:
                                                  BorderRadius.circular(12),
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
                                          borderRadius: BorderRadius.circular(
                                            16,
                                          ),
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
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
