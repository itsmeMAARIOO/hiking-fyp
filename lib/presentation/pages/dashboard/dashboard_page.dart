import 'dart:async';
import 'dart:math';
import 'dart:ui';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hikingapp/providers/trail_provider.dart';
import 'package:provider/provider.dart';
import 'package:get/get.dart';
import 'package:geolocator/geolocator.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:hikingapp/presentation/pages/dashboard/dashboard_controller.dart';
import 'package:hikingapp/providers/map_provider.dart';
import 'package:hikingapp/providers/auth_provider.dart';
import 'package:hikingapp/presentation/pages/emergency/emergency_page.dart';
import 'package:hikingapp/presentation/pages/trail/create_group/trail_page.dart';
import 'package:hikingapp/presentation/pages/profile/main_profile/profile_page.dart';
import 'package:hikingapp/services/trail_services.dart';
import 'package:hikingapp/presentation/pages/map/map_page.dart';
import 'package:hikingapp/presentation/widgets/bottom_nav_bar.dart';
import 'package:hikingapp/presentation/styles/colors.dart';
import 'package:hikingapp/presentation/styles/app_styles.dart';
import 'package:hikingapp/utils/loading_helper.dart';
import 'package:hikingapp/config/images/image_locations.dart';
import 'package:hikingapp/presentation/pages/dashboard/animations/temparature_animation.dart';
import 'package:hikingapp/presentation/pages/dashboard/animations/checkin_success_animation.dart';
import '../../../providers/dashboard_provider.dart';
import '../../../services/checkin_service.dart';
import '../../../../data/models/weather_model.dart';
import '../../../../services/weather_service.dart';

// DASHBOARD PAGE (SCAFFOLD)

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
        statusBarBrightness: Brightness.dark,
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

// DASHBOARD CONTENT

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
    Future.delayed(const Duration(milliseconds: 1000), () {
      if (mounted) setState(() => _checkInTriggered = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final dashboardProvider = Provider.of<DashboardProvider>(context);

    return Stack(
      children: [
        // --- NEW ANIMATED BACKGROUND ---
        const AnimatedBackground(),

        SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                child: Consumer<AuthProvider>(
                  builder: (context, auth, _) {
                    final name = (auth.userName ?? 'Hiker').split(' ').first;
                    final dp = Provider.of<DashboardProvider>(
                      context,
                      listen: true,
                    );
                    final hasInvite = _hasPendingInvite;
                    final members = dp.groupMembers;
                    final canTap = hasInvite || members == 0;
                    final IconData icon = hasInvite
                        ? Icons.mark_email_unread_rounded
                        : (members == 0 ? Icons.group_add : Icons.group);
                    final Color tint = hasInvite
                        ? Colors.deepOrange
                        : (members == 0 ? Colors.grey : kMediumSage);

                    return Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Hi $name',
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700,
                                  color: kDeepTeal,
                                  letterSpacing: -0.3,
                                ),
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                'Get Ready to Hike',
                                style: TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.w800,
                                  color: kDeepForest,
                                  letterSpacing: -0.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                        GestureDetector(
                          onTap: canTap ? _checkPendingInvitations : null,
                          child: Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: tint.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(
                                color: tint.withOpacity(0.35),
                                width: 1.5,
                              ),
                            ),
                            child: Icon(icon, color: tint, size: 20),
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
                  backgroundColor: kLightCream,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(
                      parent: BouncingScrollPhysics(),
                    ),
                    child: Column(
                      children: [
                        const SizedBox(height: 24),

                        // Weather Hero Card - Full width immersive
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: WeatherWidget(key: _weatherKey),
                        ),

                        const SizedBox(height: 14),

                        // GPS & Connectivity - Horizontal cards
                        SizedBox(
                          height: 140,
                          child: ListView(
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            children: [
                              Consumer2<GroupProvider, MapProvider>(
                                builder: (context, gp, mp, _) {
                                  final isActive =
                                      (gp.wasTracking == true) ||
                                      (mp.isRecording == true);
                                  return StatusCard(
                                    icon: Icons.location_pin,
                                    iconColor: isActive
                                        ? kDeepForest
                                        : kDeepForest,
                                    title: "GPS Tracking",
                                    status: isActive ? "Active" : "Inactive",
                                    statusColor: isActive
                                        ? Colors.white
                                        : kDeepForest,
                                    active: true,
                                    gradientColors: const [
                                      kDeepTeal,
                                      kDeepForest,
                                    ],
                                  );
                                },
                              ),
                              const SizedBox(width: 16),
                              StatusCard(
                                icon: dashboardProvider.isOnline
                                    ? Icons.wifi
                                    : Icons.wifi_off,
                                iconColor: dashboardProvider.isOnline
                                    ? kDeepForest
                                    : kDeepForest,
                                title: "Connectivity",
                                status: dashboardProvider.isOnline
                                    ? "Online"
                                    : "Offline",
                                statusColor: dashboardProvider.isOnline
                                    ? Colors.white
                                    : kDeepForest,
                                active: true,
                                gradientColors: const [kDeepTeal, kDeepForest],
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 10),

                        // check in
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: CheckInVisualCard(
                            isLoading: _checkInLoading,
                            celebrate: _checkInTriggered,
                            lastCheckIn: dashboardProvider.lastCheckIn,
                            onCheckIn: () async {
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
                                  const Duration(milliseconds: 1500),
                                );
                                setState(() => _checkInLoading = false);
                                _triggerCheckInAnimation();
                              }
                            },
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
}

//  ANIMATED BACKGROUND WIDGET

// ============================================================================
// 4. STATUS CARD (ORIGINAL WIDGET)
// ============================================================================

class StatusCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String status;
  final Color statusColor;
  final bool active;
  final List<Color>? gradientColors;

  const StatusCard({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.status,
    required this.statusColor,
    this.active = false,
    this.gradientColors,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: (MediaQuery.of(context).size.width - 52) / 2,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: active ? null : kGlassMorphismLight,
        gradient: active
            ? LinearGradient(
                colors: gradientColors ?? const [kMediumSage, kDeepForest],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: active
              ? Colors.white.withOpacity(0.25)
              : iconColor.withOpacity(0.25),
          width: active ? 1 : 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: active
                ? Colors.black.withOpacity(0.12)
                : iconColor.withOpacity(0.10),
            blurRadius: active ? 20 : 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: active
                      ? Colors.white.withOpacity(0.2)
                      : iconColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
              ),
              Icon(icon, color: active ? Colors.white : iconColor, size: 24),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: active
                  ? Colors.white.withOpacity(0.9)
                  : Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            status,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: active ? Colors.white : statusColor,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// 5. CHECK-IN VISUAL CARD (ORIGINAL WIDGET)
// ============================================================================

class CheckInVisualCard extends StatefulWidget {
  final bool isLoading;
  final bool celebrate;
  final DateTime? lastCheckIn;
  final VoidCallback onCheckIn;
  final bool showTime;
  final bool showButton;

  const CheckInVisualCard({
    super.key,
    required this.isLoading,
    required this.celebrate,
    required this.lastCheckIn,
    required this.onCheckIn,
    this.showTime = true,
    this.showButton = true,
  });

  @override
  State<CheckInVisualCard> createState() => _CheckInVisualCardState();
}

class _CheckInVisualCardState extends State<CheckInVisualCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _loadingController;

  @override
  void initState() {
    super.initState();
    _loadingController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
  }

  @override
  void didUpdateWidget(CheckInVisualCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isLoading && !oldWidget.isLoading) {
      _loadingController.repeat();
    } else if (!widget.isLoading && oldWidget.isLoading) {
      _loadingController.stop();
      _loadingController.reset();
    }
  }

  @override
  void dispose() {
    _loadingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _glass(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Last Check-in',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _formatCheckInTime(widget.lastCheckIn),
                    style: const TextStyle(
                      fontSize: 21,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: -0.5,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 18),
            if (widget.showButton) _buildCheckInButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildCheckInButton() {
    const double size = 72;

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CheckInSuccessAnimation(
            trigger: widget.celebrate,
            child: Container(
              width: size * 0.78,
              height: size * 0.78,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [kSoftMint, kDeepTeal],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                border: Border.all(color: kSoftMint, width: 2),
              ),
              child: IconButton(
                onPressed: widget.onCheckIn,
                icon: Icon(
                  Icons.location_on_rounded,
                  color: kPureWhite,
                  size: size * 0.38,
                ),
                splashRadius: size * 0.5,
              ),
            ),
          ),
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _loadingController,
              builder: (context, child) {
                if (!widget.isLoading) return const SizedBox();
                return Transform.rotate(
                  angle: _loadingController.value * 2 * pi,
                  child: CustomPaint(
                    painter: _LoadingArcPainter(
                      color: kSoftMint,
                      strokeWidth: 5,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  String _formatCheckInTime(DateTime? dt) {
    if (dt == null) return 'No check-in yet';
    final adjusted = dt.toUtc().add(const Duration(hours: 8));
    String two(int n) => n.toString().padLeft(2, '0');
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final day = two(adjusted.day);
    final mon = months[adjusted.month - 1];
    final year = adjusted.year.toString().substring(2);
    final time = '${two(adjusted.hour)}:${two(adjusted.minute)}';
    return '$day $mon $year - $time';
  }

  Widget _glass({required Widget child}) {
    return Container(
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(24)),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [kDeepForest, kDeepOrange],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: Colors.white.withOpacity(0.25),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.12),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}

class _LoadingArcPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;

  _LoadingArcPainter({required this.color, required this.strokeWidth});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - strokeWidth;
    final p = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    final rect = Rect.fromCircle(center: center, radius: radius);
    canvas.drawArc(rect, -math.pi / 3, math.pi / 1.5, false, p);
  }

  @override
  bool shouldRepaint(covariant _LoadingArcPainter old) {
    return old.color != color || old.strokeWidth != strokeWidth;
  }
}

// ============================================================================
// 6. WEATHER WIDGET (ORIGINAL WIDGET)
// ============================================================================

class WeatherWidget extends StatefulWidget {
  const WeatherWidget({super.key});

  @override
  State<WeatherWidget> createState() => _WeatherWidgetState();
}

class _WeatherWidgetState extends State<WeatherWidget>
    with SingleTickerProviderStateMixin {
  Weather? weather;
  late WeatherService weatherService;
  bool isLoading = true;
  bool isOffline = false;
  bool isFahrenheit = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    weatherService = WeatherService();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOutCubic,
      ),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Curves.easeOutCubic,
          ),
        );

    loadWeather();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> loadWeather() async {
    setState(() {
      isLoading = true;
      isOffline = false;
    });

    final connectivityResult = await Connectivity().checkConnectivity();

    if (connectivityResult == ConnectivityResult.none) {
      setState(() {
        isOffline = true;
        isLoading = false;
      });
      _animationController.forward();
      return;
    }

    try {
      LocationPermission permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {
            isOffline = true;
            isLoading = false;
          });
          _animationController.forward();
          return;
        }
      }
      if (permission == LocationPermission.deniedForever) {
        setState(() {
          isOffline = true;
          isLoading = false;
        });
        _animationController.forward();
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      final fetchedWeather = await weatherService.fetchWeatherByCoords(
        position.latitude,
        position.longitude,
      );

      setState(() {
        weather = fetchedWeather;
        isLoading = false;
      });
      _animationController.forward();
    } catch (e) {
      setState(() {
        isOffline = true;
        isLoading = false;
      });
      _animationController.forward();
    }
  }

  WeatherCondition getWeatherCondition(String condition) {
    final lowerCondition = condition.toLowerCase();

    if (lowerCondition.contains('sunny') || lowerCondition.contains('clear')) {
      return WeatherCondition(
        icon: Icons.wb_sunny_rounded,
        conditionText: 'Sunny',
        description: 'Perfect day for hiking!\nClear skies ahead.',
        iconColor: kDeepGrey,
      );
    } else if (lowerCondition.contains('rain') ||
        lowerCondition.contains('drizzle')) {
      return WeatherCondition(
        icon: Icons.cloudy_snowing,
        conditionText: 'Rainy',
        description: 'Rain expected.\nConsider waterproof gear.',
        iconColor: kDeepGrey,
      );
    } else if (lowerCondition.contains('cloud') ||
        lowerCondition.contains('overcast')) {
      return WeatherCondition(
        icon: Icons.cloud_rounded,
        conditionText: 'Cloudy',
        description: 'Partly cloudy.\nGreat hiking conditions.',
        iconColor: kDeepGrey,
      );
    } else if (lowerCondition.contains('storm') ||
        lowerCondition.contains('thunder')) {
      return WeatherCondition(
        icon: Icons.flash_on_rounded,
        conditionText: 'Stormy',
        description: 'Storm warning.\nConsider postponing hike.',
        iconColor: kDeepGrey,
      );
    } else {
      return WeatherCondition(
        icon: Icons.cloud_rounded,
        conditionText: condition,
        description: 'Good conditions for outdoor activities.',
        iconColor: kDeepGrey,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: _buildWeatherContent(),
      ),
    );
  }

  Widget _buildWeatherContent() {
    if (isLoading) {
      return _buildGradientContainer(
        colors: const [kWeatherRainy, kDeepBlue],
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              LoadingHelper(imagePath: ImageLocation.loading, size: 60),
              const SizedBox(height: 16),
              Text(
                "Fetching weather...",
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white.withOpacity(0.9),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (isOffline) {
      return _buildGradientContainer(
        colors: const [kWeatherCloudy, kDeepTeal],
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withOpacity(0.25),
                    width: 2,
                  ),
                ),
                child: Icon(
                  Icons.signal_wifi_off_rounded,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Offline Mode",
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      "Weather data unavailable. Stay safe on the trail!",
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withOpacity(0.8),
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 12),
                    GestureDetector(
                      onTap: loadWeather,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [kWeatherRainy, kDeepBlue],
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Text(
                          "Try Again",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
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

    final weatherCondition = getWeatherCondition(weather!.condition);

    return _buildGradientContainer(
      colors: [kDeepTeal, kDeepForest],
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "CURRENT WEATHER",
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white.withOpacity(0.9),
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        weather!.location,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          letterSpacing: -0.5,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                // Weather condition badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.25),
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        weatherCondition.icon,
                        color: Colors.white,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        weatherCondition.conditionText.toUpperCase(),
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                weatherCondition.description,
                textAlign: TextAlign.left,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.white.withOpacity(0.9),
                  height: 1.4,
                ),
              ),
            ),

            const SizedBox(height: 14),

            // Main content
            Row(
              children: [
                // Temperature section
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AnimatedTemperatureWidget(
                        temperatureF: weather!.temperature,
                        temperatureC: temperatureC,
                        isFahrenheit: isFahrenheit,
                        weatherIcon: weatherCondition.icon,
                        onTap: () {
                          setState(() {
                            isFahrenheit = !isFahrenheit;
                          });
                        },
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 24),

                // Stats section
                Column(
                  children: [
                    _buildWeatherStat(
                      Icons.water_drop_rounded,
                      "${weather!.humidity}%",
                      "Humidity",
                      Colors.white,
                    ),
                    const SizedBox(height: 16),
                    _buildWeatherStat(
                      Icons.air_rounded,
                      "${weather!.windSpeed} mph",
                      "Wind",
                      Colors.white,
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGradientContainer({
    required Widget child,
    required List<Color> colors,
  }) {
    return Container(
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(28)),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: colors,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: Colors.white.withOpacity(0.25), width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.12),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }

  Widget _buildWeatherStat(
    IconData icon,
    String value,
    String label,
    Color color,
  ) {
    return SizedBox(
      width: 110,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.white.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Icon(icon, color: Colors.white, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.white.withOpacity(0.85),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  double get temperatureC => ((weather!.temperature - 32) * 5 / 9);
}

class WeatherCondition {
  final IconData icon;
  final String conditionText;
  final String description;
  final Color iconColor;

  WeatherCondition({
    required this.icon,
    required this.conditionText,
    required this.description,
    required this.iconColor,
  });
}
