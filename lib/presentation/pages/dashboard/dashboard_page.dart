import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hikingapp/providers/trail_provider.dart';
import 'package:provider/provider.dart';
import 'package:get/get.dart';
import 'package:hikingapp/presentation/pages/dashboard/dashboard_controller.dart';
import 'package:hikingapp/providers/map_provider.dart';
import 'package:hikingapp/providers/auth_provider.dart';
import 'package:hikingapp/presentation/pages/emergency/emergency_page.dart';
import 'package:hikingapp/presentation/pages/trail/create_trail/trail_page.dart';
import 'package:hikingapp/presentation/pages/profile/main_profile/profile_page.dart';
import 'package:hikingapp/services/trail_services.dart';
import 'package:hikingapp/presentation/pages/map/map_page.dart';
import 'package:hikingapp/presentation/widgets/bottom_nav_bar.dart';
import 'package:hikingapp/presentation/styles/colors.dart';
import 'package:hikingapp/presentation/styles/app_styles.dart';
import 'package:hikingapp/presentation/pages/dashboard/widgets/check_in_card.dart';
import 'package:hikingapp/presentation/pages/dashboard/widgets/status_card.dart';
import '../../../providers/dashboard_provider.dart';
import '../../../services/checkin_service.dart';
import 'package:hikingapp/presentation/pages/dashboard/widgets/weather_widget.dart';

import 'package:hikingapp/providers/profile_provider.dart';
import 'package:hikingapp/services/weather_alert_service.dart';
import 'package:hikingapp/utils/snackbar_helper.dart';

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
    TrailPage(),
    ProfilePage(),
  ];

  void _onTabTap(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
      ),
      child: Scaffold(
        extendBody: true,
        backgroundColor: Colors.transparent,
        body: Stack(
          children: [IndexedStack(index: _currentIndex, children: _pages)],
        ),
        bottomNavigationBar: BottomNavBar(
          currentIndex: _currentIndex,
          onTap: _onTabTap,
        ),
      ),
    );
  }
}

// ============================================================================
// DASHBOARD CONTENT
// ============================================================================

class DashboardPageContent extends StatefulWidget {
  const DashboardPageContent({super.key});

  @override
  State<DashboardPageContent> createState() => _DashboardPageContentState();
}

class _DashboardPageContentState extends State<DashboardPageContent>
    with WidgetsBindingObserver, TickerProviderStateMixin {
  late final CheckInService checkInService;
  late final DashboardController dashboardController;
  late final AuthProvider authProvider;
  late final TrailServices trailService;
  late AnimationController _floatingController;

  bool _checkInTriggered = false;
  bool _checkInLoading = false;
  bool _checkInFailed = false;
  Key _weatherKey = UniqueKey();
  bool _hasPendingInvite = false;

  Timer? _invitePollTimer;
  String? _lastInviteId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    checkInService = CheckInService();
    dashboardController = DashboardController(checkInService);
    trailService = TrailServices();

    _floatingController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      authProvider = Provider.of<AuthProvider>(context, listen: false);

      final profile = Provider.of<ProfileProvider>(context, listen: false);
      final weatherEnabled = profile.settings['weatherAlerts'] ?? false;
      if (weatherEnabled && authProvider.userId != null) {
        WeatherAlertService.enable();
      }

      // Initialize map location tracking (handles permissions)
      final mapProvider = Provider.of<MapProvider>(context, listen: false);
      await mapProvider.initLocationTracking();

      await dashboardController.refreshDashboard(context);
      await _checkInitialInvitation();
      _startInvitePolling();
    });
  }

  Future<void> _onRefresh() async {
    try {
      await dashboardController.refreshDashboard(context);
      setState(() {
        _weatherKey = UniqueKey();
      });

      final userId = authProvider.userId;
      if (userId != null) {
        final invitation = await dashboardController.checkForInvitation(
          trailService: trailService,
          userId: userId,
        );
        if (invitation != null) {
          final groupId = invitation['groupId'] ?? '';
          setState(() {
            _hasPendingInvite = true;
            _lastInviteId = groupId.isNotEmpty ? groupId : _lastInviteId;
          });
          await dashboardController.notifyInvitationIfNew(
            lastInviteId: _lastInviteId,
            invitation: invitation,
          );
        }
      }
    } catch (_) {}
  }

  Future<void> _checkPendingInvitations() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    await dashboardController.handlePendingInvitation(
      context: context,
      trailService: trailService,
      authProvider: auth,
    );
    if (!mounted) return;
    setState(() {
      _hasPendingInvite = false;
    });
  }

  Future<void> _checkInitialInvitation() async {
    try {
      final userId = authProvider.userId;
      if (userId == null) return;
      final invitation = await dashboardController.checkForInvitation(
        trailService: trailService,
        userId: userId,
      );
      if (invitation != null) {
        final groupId = invitation['groupId'] ?? '';
        setState(() {
          _hasPendingInvite = true;
          _lastInviteId = groupId.isNotEmpty ? groupId : _lastInviteId;
        });
        await dashboardController.notifyInvitationIfNew(
          lastInviteId: _lastInviteId,
          invitation: invitation,
        );
      }
    } catch (_) {}
  }

  void _startInvitePolling() {
    _invitePollTimer?.cancel();
    _invitePollTimer = Timer.periodic(const Duration(seconds: 15), (
      timer,
    ) async {
      if (!mounted) return;
      try {
        final userId = authProvider.userId;
        if (userId == null) return;
        final invitation = await dashboardController.checkForInvitation(
          trailService: trailService,
          userId: userId,
        );
        if (invitation != null) {
          final groupId = invitation['groupId'] ?? '';
          final isNewInvite = _lastInviteId != groupId || !_hasPendingInvite;
          if (isNewInvite) {
            setState(() {
              _hasPendingInvite = true;
              _lastInviteId = groupId.isNotEmpty ? groupId : _lastInviteId;
            });
            await dashboardController.notifyInvitationIfNew(
              lastInviteId: _lastInviteId,
              invitation: invitation,
            );
          }
        }
      } catch (_) {}
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkInitialInvitation();
      if (_invitePollTimer == null) {
        _startInvitePolling();
      }

      // Re-trigger location permission check via MapProvider on app resume
      final mapProvider = Provider.of<MapProvider>(context, listen: false);
      mapProvider.initLocationTracking();
    } else if (state == AppLifecycleState.paused) {
      _invitePollTimer?.cancel();
      _invitePollTimer = null;
    }
  }

  @override
  void dispose() {
    _invitePollTimer?.cancel();
    _floatingController.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void _triggerCheckInAnimation() {
    setState(() {
      _checkInTriggered = true;
    });
    Future.delayed(const Duration(milliseconds: 1500), () {
      // Increased delay for smoother animation
      if (mounted) setState(() => _checkInTriggered = false);
    });
  }

  void _triggerCheckInFailure() {
    setState(() {
      _checkInFailed = true;
    });
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) setState(() => _checkInFailed = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final dashboardProvider = Provider.of<DashboardProvider>(context);

    return Stack(
      children: [
        // Background
        AnimatedBackground(),

        SafeArea(
          bottom: false,
          child: Column(
            children: [
              // 1. Header
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 6),
                child: Consumer<AuthProvider>(
                  builder: (context, auth, _) {
                    final name = (auth.userName ?? 'Hiker').split(' ').first;
                    final hasInvite = _hasPendingInvite;

                    return Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Hello $name',
                              style: const TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.w900,
                                color: kDeepTeal,
                                letterSpacing: -0.5,
                              ),
                            ),
                            Text(
                              'Explore the outdoors',
                              style: TextStyle(
                                fontSize: 14,
                                color: kDeepTeal.withOpacity(0.7),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        GestureDetector(
                          onTap: () {
                            if (!dashboardProvider.isOnline) {
                              SnackbarHelper.showError(
                                'No internet Connection',
                                'Please try again',
                              );
                              return;
                            }
                            _checkPendingInvitations();
                          },
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.6),
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: kDeepForest.withOpacity(0.05),
                                  blurRadius: 10,
                                ),
                              ],
                              border: Border.all(
                                color: Colors.white,
                                width: 1.5,
                              ),
                            ),
                            child: Icon(
                              hasInvite
                                  ? Icons.group_add_rounded
                                  : Icons.group_add_outlined,
                              color: hasInvite ? Colors.deepOrange : kDeepTeal,
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),

              Expanded(
                child: RefreshIndicator(
                  onRefresh: _onRefresh,
                  color: kDeepForest,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(
                      parent: BouncingScrollPhysics(),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const SizedBox(height: 16),

                          // 2. Weather Hero
                          WeatherWidget(key: _weatherKey),

                          const SizedBox(height: 20),

                          // 3. Status Capsules
                          Row(
                            children: [
                              Expanded(
                                child: Consumer2<GroupProvider, MapProvider>(
                                  builder: (context, gp, mp, _) {
                                    final isActive =
                                        (gp.wasTracking == true) ||
                                        (mp.isRecording == true);
                                    return StatusCard(
                                      icon: Icons.navigation,
                                      label: "Tracking",
                                      status: isActive ? "Active" : "Ready",
                                      isActive: isActive,
                                      activeColor: kDeepOrange,
                                    );
                                  },
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: StatusCard(
                                  icon: dashboardProvider.isOnline
                                      ? Icons.wifi
                                      : Icons.wifi_off,
                                  label: "Signal",
                                  status: dashboardProvider.isOnline
                                      ? "Online"
                                      : "Lost",
                                  isActive: dashboardProvider.isOnline,
                                  activeColor: kDeepTeal,
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 24),

                          // 4. Check In - SMOOTH ANIMATION
                          CheckInInterestingCard(
                            isLoading: _checkInLoading,
                            celebrate: _checkInTriggered,
                            failed: _checkInFailed,
                            lastCheckIn: dashboardProvider.lastCheckIn,
                            onCheckIn: () async {
                              if (!dashboardProvider.isOnline) {
                                _triggerCheckInFailure();
                                return;
                              }
                              final uid =
                                  authProvider.userId ??
                                  Provider.of<AuthProvider>(
                                    context,
                                    listen: false,
                                  ).userId;
                              if (uid == null) return;
                              final last =
                                  dashboardProvider.lastCheckIn ??
                                  DateTime.now();
                              setState(() => _checkInLoading = true);
                              try {
                                await dashboardController.performCheckIn(
                                  userId: uid,
                                  lastCheckIn: last,
                                );
                                dashboardProvider.updateLastCheckIn(
                                  DateTime.now(),
                                );
                              } catch (_) {
                              } finally {
                                await Future.delayed(
                                  const Duration(milliseconds: 1000),
                                );
                                setState(() => _checkInLoading = false);
                                _triggerCheckInAnimation();
                              }
                            },
                          ),

                          const SizedBox(height: 20), // Bottom padding
                        ],
                      ),
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
}
