// lib/presentation/pages/group/create_group/create_group_page.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hikingapp/data/models/group_model.dart';
import 'package:hikingapp/presentation/pages/trail/create_trail/widgets/create_group_step1.dart';
import 'package:hikingapp/presentation/pages/trail/create_trail/widgets/create_group_step2.dart'
    hide kDarkPrimaryColor;
import 'package:hikingapp/presentation/pages/trail/create_trail/widgets/create_group_step3.dart';
import 'package:hikingapp/presentation/pages/trail/active_trail/active_trail.dart';
import 'package:hikingapp/presentation/widgets/common_header.dart';
import 'package:hikingapp/providers/auth_provider.dart';
import 'package:hikingapp/providers/trail_provider.dart';
import 'package:provider/provider.dart';
import 'package:get/get.dart';
import 'package:hikingapp/config/routes.dart';
import 'package:hikingapp/utils/snackbar_helper.dart';
import 'widgets/step_indicator_widgets.dart' hide kDarkPrimaryColor;
import 'widgets/group_exists_notice.dart';
import 'package:hikingapp/providers/map_provider.dart';
import 'package:hikingapp/presentation/styles/colors.dart';
import 'package:hikingapp/presentation/styles/app_styles.dart';
import 'widgets/create_solo_step1.dart';
import 'widgets/create_solo_step2.dart';
import 'widgets/create_solo_step3.dart';
import 'package:hikingapp/config/images/image_locations.dart';
import 'package:hikingapp/presentation/widgets/loading_overlay.dart';
import 'package:hikingapp/providers/emergency_provider.dart';
import 'package:hikingapp/providers/profile_provider.dart';
import 'package:hikingapp/providers/dashboard_provider.dart';

class TrailPage extends StatefulWidget {
  const TrailPage({super.key});

  @override
  State<TrailPage> createState() => _TrailPageState();
}

class _TrailPageState extends State<TrailPage> with TickerProviderStateMixin {
  late GroupProvider _groupProvider;
  final TextEditingController _groupNameController = TextEditingController();
  final TextEditingController _trailNameController = TextEditingController();
  final TextEditingController _trailDescController = TextEditingController();
  final TextEditingController _soloTrailNameController =
      TextEditingController();
  final TextEditingController _soloTrailDescController =
      TextEditingController();
  bool _soloIsLoading = false;
  late TabController _tabController;

  final List<GroupMember> _selectedHikers = [];
  bool _isScanning = false;
  int _currentStep = 0;
  int _soloStep = 0;
  int? _soloExpectedDurationMinutes;
  late AnimationController _stepTransitionController;
  late Animation<double> _fadeAnimation;

  String get _currentUserId {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    return authProvider.userId ?? "no user id";
  }

  String get _currentUserName {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    return authProvider.userName ?? "no user name";
  }

  @override
  void initState() {
    super.initState();
    _groupProvider = Provider.of<GroupProvider>(context, listen: false);
    _tabController = TabController(length: 2, vsync: this)
      ..addListener(() {
        if (mounted) setState(() {});
      });
    _stepTransitionController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _stepTransitionController,
        curve: Curves.easeInOut,
      ),
    );
    _stepTransitionController.forward();
  }

  @override
  void dispose() {
    _stepTransitionController.dispose();
    _groupNameController.dispose();
    _trailNameController.dispose();
    _trailDescController.dispose();
    _soloTrailNameController.dispose();
    _soloTrailDescController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _scanNearbyHikers() async {
    setState(() => _isScanning = true);
    await _groupProvider.fetchNearbyMembers(excludeUserId: _currentUserId);

    final nearbyHikerIds = _groupProvider.nearbyMembers
        .map((h) => h.userId)
        .toSet();
    _selectedHikers.removeWhere(
      (selected) => !nearbyHikerIds.contains(selected.userId),
    );

    setState(() => _isScanning = false);
  }

  void _toggleHikerSelection(GroupMember hiker) {
    setState(() {
      if (_selectedHikers.any((h) => h.userId == hiker.userId)) {
        _selectedHikers.removeWhere((h) => h.userId == hiker.userId);
      } else {
        _selectedHikers.add(hiker);
      }
    });
  }

  Future<void> _createGroup() async {
    if (_groupNameController.text.isEmpty) {
      _showSnackBar('Please enter a group name');
      return;
    }

    await _groupProvider.createGroup(
      groupName: _groupNameController.text,
      createdBy: _currentUserId,
      creatorName: _currentUserName,
      trailName: _trailNameController.text.isEmpty
          ? null
          : _trailNameController.text,
      trailDescription: _trailDescController.text.isEmpty
          ? null
          : _trailDescController.text,
      invitedMembers: _selectedHikers,
    );

    if (_groupProvider.activeGroup != null && mounted) {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
              const ActiveTrailPage(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return ScaleTransition(
              scale: animation.drive(
                Tween<double>(
                  begin: 0.8,
                  end: 1.0,
                ).chain(CurveTween(curve: Curves.elasticOut)),
              ),
              child: FadeTransition(opacity: animation, child: child),
            );
          },
          transitionDuration: const Duration(milliseconds: 700),
        ),
      );
    }
  }

  void _showSnackBar(String message) {
    SnackbarHelper.showError('Error', message);
  }

  void _startSoloTrail() async {
    final name = _soloTrailNameController.text.trim();
    final desc = _soloTrailDescController.text.trim();
    if (name.isEmpty) {
      SnackbarHelper.showError(
        'Trail Name Required',
        'Please enter a trail name',
      );
      return;
    }
    final profile = Provider.of<ProfileProvider>(context, listen: false);
    final hasShare = profile.emergencyContacts.any(
      (c) => (c['share'] ?? 'false') == 'true',
    );
    final durMin = _soloExpectedDurationMinutes ?? 0;
    if (durMin <= 0) {
      SnackbarHelper.showError(
        'Expected Duration Required',
        'Please set the expected duration',
      );
      return;
    }
    final expectedEnd = DateTime.now().add(Duration(minutes: durMin));
    setState(() => _soloIsLoading = true);
    if (hasShare) {
      final emergency = Provider.of<EmergencyProvider>(context, listen: false);
      try {
        await emergency.shareSoloStartLocation(
          context,
          trailName: name,
          expectedEndTime: expectedEnd,
        );
      } catch (_) {}
    }
    Get.toNamed(
      AppRoutes.soloTrail,
      arguments: {
        "trailName": name,
        "trailDescription": desc,
        "expectedEndTime": expectedEnd.toIso8601String(),
      },
    );
  }

  void _nextStep() {
    if (_currentStep == 0 && _groupNameController.text.isEmpty) {
      _showSnackBar('Please enter a group name');
      return;
    }

    _stepTransitionController.reverse().then((_) {
      setState(() => _currentStep++);
      _stepTransitionController.forward();
    });
  }

  void _previousStep() {
    _stepTransitionController.reverse().then((_) {
      setState(() => _currentStep--);
      _stepTransitionController.forward();
    });
  }

  void _soloNextStep() {
    setState(() {
      if (_soloStep < 2) _soloStep += 1;
    });
  }

  void _soloPrevStep() {
    setState(() {
      if (_soloStep > 0) _soloStep -= 1;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<GroupProvider>(
      builder: (context, provider, _) {
        final isOnline = Provider.of<DashboardProvider>(context).isOnline;
        return Scaffold(
          backgroundColor: Colors.transparent,
          resizeToAvoidBottomInset: false,
          body: AnnotatedRegion<SystemUiOverlayStyle>(
            value: const SystemUiOverlayStyle(
              statusBarColor: Colors.transparent,
              statusBarIconBrightness: Brightness.dark,
              statusBarBrightness: Brightness.dark,
            ),
            child: Stack(
              children: [
                const AnimatedBackground(),

                // Scrollable content
                Positioned.fill(
                  child: SafeArea(
                    child: Column(
                      children: [
                        CommonHeader(title: 'Trail'),

                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal:
                                20, // Increased spacing from screen edge
                            vertical: 12,
                          ),
                          child: Container(
                            height: 56, // Taller touch target
                            padding: const EdgeInsets.all(
                              4,
                            ), // Creates the "floating" look
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(
                                0.6,
                              ), // Milky glass effect
                              borderRadius: BorderRadius.circular(30),
                              border: Border.all(
                                color: Colors.white,
                                width: 1.5,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: kDeepTeal.withOpacity(0.05),
                                  blurRadius: 15,
                                  offset: const Offset(0, 5),
                                ),
                              ],
                            ),
                            child: TabBar(
                              controller: _tabController,
                              dividerColor: Colors.transparent,
                              indicator: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [kDeepTeal, Color(0xFF2B8A7E)],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(
                                  24,
                                ), // Smooth pill shape
                                boxShadow: [
                                  BoxShadow(
                                    color: kDeepTeal.withOpacity(0.3),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              labelColor: Colors.white,
                              unselectedLabelColor: kDeepTeal.withOpacity(0.6),
                              labelStyle: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                                letterSpacing: 0.5,
                              ),
                              unselectedLabelStyle: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                              indicatorSize: TabBarIndicatorSize.tab,
                              overlayColor: MaterialStateProperty.all(
                                Colors.transparent,
                              ),
                              tabs: [
                                Tab(
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: const [
                                      Icon(Icons.person_rounded, size: 18),
                                      SizedBox(width: 8),
                                      Text('Solo Hike'),
                                    ],
                                  ),
                                ),
                                Tab(
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: const [
                                      Icon(Icons.group_rounded, size: 18),
                                      SizedBox(width: 8),
                                      Text('Group Trip'),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        Expanded(
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 500),
                            decoration: const BoxDecoration(
                              color: Colors.transparent,
                            ),
                            child: TabBarView(
                              controller: _tabController,
                              children: [
                                // Tab 1: Solo Trail
                                Builder(
                                  builder: (context) {
                                    final mapProvider =
                                        Provider.of<MapProvider>(context);
                                    final soloActive =
                                        mapProvider.isSoloTrailMinimized;
                                    final groupActive =
                                        provider.activeGroup != null &&
                                        provider.isTrailMinimized == true;
                                    if (!isOnline) {
                                      return Center(
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 20,
                                            vertical: 16,
                                          ),
                                          margin: const EdgeInsets.symmetric(
                                            horizontal: 24,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius: BorderRadius.circular(
                                              16,
                                            ),
                                            boxShadow: [
                                              BoxShadow(
                                                color: kDeepTeal.withOpacity(
                                                  0.08,
                                                ),
                                                blurRadius: 18,
                                                offset: const Offset(0, 8),
                                              ),
                                            ],
                                          ),
                                          child: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 14,
                                                      vertical: 10,
                                                    ),
                                                decoration: BoxDecoration(
                                                  color: Colors.white
                                                      .withOpacity(0.6),
                                                  borderRadius:
                                                      BorderRadius.circular(24),
                                                  border: Border.all(
                                                    color: Colors.white,
                                                    width: 1.5,
                                                  ),
                                                  boxShadow: [
                                                    BoxShadow(
                                                      color: kDeepForest
                                                          .withOpacity(0.08),
                                                      blurRadius: 25,
                                                      offset: const Offset(
                                                        0,
                                                        10,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                child: Row(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: const [
                                                    Icon(
                                                      Icons.wifi_off_rounded,
                                                      color: kDeepForest,
                                                      size: 24,
                                                    ),
                                                    SizedBox(width: 10),
                                                    Text(
                                                      'No Connection',
                                                      style: TextStyle(
                                                        color: kDeepForest,
                                                        fontSize: 16,
                                                        fontWeight:
                                                            FontWeight.w800,
                                                        letterSpacing: -0.2,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              const SizedBox(height: 10),
                                              const Padding(
                                                padding: EdgeInsets.symmetric(
                                                  horizontal: 24,
                                                ),
                                                child: Text(
                                                  'Please try again later.',
                                                  style: TextStyle(
                                                    color: kDeepForest,
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                  textAlign: TextAlign.center,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    }
                                    if (soloActive || groupActive) {
                                      return SingleChildScrollView(
                                        padding: EdgeInsets.only(
                                          bottom:
                                              MediaQuery.of(
                                                context,
                                              ).viewInsets.bottom +
                                              120,
                                        ),
                                        child: GroupExistsNotice(
                                          group: groupActive
                                              ? provider.activeGroup
                                              : null,
                                          isSolo: soloActive && !groupActive,
                                          soloTrailName:
                                              mapProvider.soloTrailName,
                                        ),
                                      );
                                    }
                                    return SingleChildScrollView(
                                      padding: EdgeInsets.only(
                                        bottom:
                                            MediaQuery.of(
                                              context,
                                            ).viewInsets.bottom +
                                            40,
                                      ),
                                      child: Column(
                                        children: [
                                          StepProgressIndicator(
                                            currentStep: _soloStep,
                                            labels: const [
                                              'Details',
                                              'Notify',
                                              'Confirm',
                                            ],
                                          ),
                                          IndexedStack(
                                            index: _soloStep,
                                            children: [
                                              CreateSoloStep1(
                                                controller:
                                                    _soloTrailNameController,
                                                descriptionController:
                                                    _soloTrailDescController,
                                                isLoading: _soloIsLoading,
                                                onNext: _soloNextStep,
                                                durationMinutes:
                                                    _soloExpectedDurationMinutes,
                                                onDurationChanged: (v) {
                                                  setState(() {
                                                    _soloExpectedDurationMinutes =
                                                        v;
                                                  });
                                                },
                                              ),
                                              const SoloNotifyStep(),
                                              SoloConfirmStep(
                                                nameController:
                                                    _soloTrailNameController,
                                                descriptionController:
                                                    _soloTrailDescController,
                                                durationMinutes:
                                                    _soloExpectedDurationMinutes,
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),

                                // Tab 2: Create Trail Group
                                Builder(
                                  builder: (context) {
                                    final mapProvider =
                                        Provider.of<MapProvider>(context);
                                    final soloActive =
                                        mapProvider.isSoloTrailMinimized;
                                    final groupActive =
                                        provider.activeGroup != null &&
                                        provider.isTrailMinimized == true;
                                    if (!isOnline) {
                                      return Center(
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 20,
                                            vertical: 16,
                                          ),
                                          margin: const EdgeInsets.symmetric(
                                            horizontal: 24,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius: BorderRadius.circular(
                                              16,
                                            ),
                                            boxShadow: [
                                              BoxShadow(
                                                color: kDeepTeal.withOpacity(
                                                  0.08,
                                                ),
                                                blurRadius: 18,
                                                offset: const Offset(0, 8),
                                              ),
                                            ],
                                          ),
                                          child: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 14,
                                                      vertical: 10,
                                                    ),
                                                decoration: BoxDecoration(
                                                  color: Colors.white
                                                      .withOpacity(0.6),
                                                  borderRadius:
                                                      BorderRadius.circular(24),
                                                  border: Border.all(
                                                    color: Colors.white,
                                                    width: 1.5,
                                                  ),
                                                  boxShadow: [
                                                    BoxShadow(
                                                      color: kDeepForest
                                                          .withOpacity(0.08),
                                                      blurRadius: 25,
                                                      offset: const Offset(
                                                        0,
                                                        10,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                child: Row(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: const [
                                                    Icon(
                                                      Icons.wifi_off_rounded,
                                                      color: kDeepForest,
                                                      size: 24,
                                                    ),
                                                    SizedBox(width: 10),
                                                    Text(
                                                      'No Connection',
                                                      style: TextStyle(
                                                        color: kDeepForest,
                                                        fontSize: 16,
                                                        fontWeight:
                                                            FontWeight.w800,
                                                        letterSpacing: -0.2,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              const SizedBox(height: 10),
                                              const Padding(
                                                padding: EdgeInsets.symmetric(
                                                  horizontal: 24,
                                                ),
                                                child: Text(
                                                  'Please try again later.',
                                                  style: TextStyle(
                                                    color: kDeepForest,
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                  textAlign: TextAlign.center,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    }
                                    if (soloActive || groupActive) {
                                      return SingleChildScrollView(
                                        padding: EdgeInsets.only(
                                          bottom:
                                              MediaQuery.of(
                                                context,
                                              ).viewInsets.bottom +
                                              120,
                                        ),
                                        child: GroupExistsNotice(
                                          group: groupActive
                                              ? provider.activeGroup
                                              : null,
                                          isSolo: soloActive && !groupActive,
                                          soloTrailName:
                                              mapProvider.soloTrailName,
                                        ),
                                      );
                                    }
                                    return SingleChildScrollView(
                                      padding: EdgeInsets.only(
                                        bottom:
                                            MediaQuery.of(
                                              context,
                                            ).viewInsets.bottom +
                                            120,
                                      ),
                                      child: Column(
                                        children: [
                                          StepProgressIndicator(
                                            currentStep: _currentStep,
                                          ),
                                          FadeTransition(
                                            opacity: _fadeAnimation,
                                            child: IndexedStack(
                                              index: _currentStep,
                                              children: [
                                                Step1GroupDetails(
                                                  groupNameController:
                                                      _groupNameController,
                                                  trailNameController:
                                                      _trailNameController,
                                                  trailDescriptionController:
                                                      _trailDescController,
                                                ),
                                                Step2InviteHikers(
                                                  provider: provider,
                                                  selectedHikers:
                                                      _selectedHikers,
                                                  isScanning: _isScanning,
                                                  onScan: _scanNearbyHikers,
                                                  onToggleSelection:
                                                      _toggleHikerSelection,
                                                ),
                                                Step3Confirm(
                                                  groupName:
                                                      _groupNameController.text,
                                                  trailName:
                                                      _trailNameController.text,
                                                  currentUserName:
                                                      _currentUserName,
                                                  selectedHikers:
                                                      _selectedHikers,
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                LoadingOverlay(
                  visible: _soloIsLoading || provider.isLoading,
                  message: 'Creating trail...',
                  shadeColor: Colors.black.withOpacity(0.08),
                  spinnerColor: kMediumSage,
                  spinnerBackgroundColor: kMediumSage.withOpacity(0.2),
                  logoAsset: ImageLocation.appLogo,
                  size: 110,
                ),

                IgnorePointer(
                  ignoring:
                      provider.activeGroup != null && provider.isTrailMinimized,
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    child: SafeArea(
                      top: false,
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        transitionBuilder:
                            (Widget child, Animation<double> animation) {
                              return SlideTransition(
                                position: Tween<Offset>(
                                  begin: const Offset(0, 1),
                                  end: Offset.zero,
                                ).animate(animation),
                                child: FadeTransition(
                                  opacity: animation,
                                  child: child,
                                ),
                              );
                            },
                        child: !isOnline
                            ? const SizedBox.shrink()
                            : (provider.activeGroup != null &&
                                  provider.isTrailMinimized == true)
                            ? const SizedBox.shrink()
                            : Container(
                                color: Colors.transparent,
                                padding: const EdgeInsets.only(
                                  left: 16,
                                  right: 16,
                                  bottom: 12,
                                ),
                                child: _tabController.index == 1
                                    ? NavigationButton(
                                        key: ValueKey(
                                          'groupStep_${_currentStep}',
                                        ),
                                        currentStep: _currentStep,
                                        isLoading: provider.isLoading,
                                        onNext: _currentStep < 2
                                            ? _nextStep
                                            : _createGroup,
                                        onBack: _previousStep,
                                      )
                                    : NavigationButton(
                                        key: ValueKey('soloStep_${_soloStep}'),
                                        currentStep: _soloStep,
                                        isLoading: _soloIsLoading,
                                        onNext: _soloStep < 2
                                            ? _soloNextStep
                                            : _startSoloTrail,
                                        onBack: _soloPrevStep,
                                        showBackButton: true,
                                      ),
                              ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

Widget _buildTabLabel(IconData icon, String text) {
  return Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [Icon(icon, size: 18), const SizedBox(width: 8), Text(text)],
  );
}
