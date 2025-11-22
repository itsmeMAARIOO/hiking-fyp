// lib/presentation/pages/group/create_group/create_group_page.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui' as ui;
import 'package:hikingapp/data/models/group_model.dart';
import 'package:hikingapp/presentation/pages/trail/create_group/widgets/create_group_step1.dart';
import 'package:hikingapp/presentation/pages/trail/create_group/widgets/create_group_step2.dart'
    hide kDarkPrimaryColor;
import 'package:hikingapp/presentation/pages/trail/create_group/widgets/create_group_step3.dart';
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
import 'package:hikingapp/presentation/styles/colors.dart';
import 'package:hikingapp/presentation/styles/app_styles.dart';

class TrailPage extends StatefulWidget {
  const TrailPage({super.key});

  @override
  State<TrailPage> createState() => _TrailPageState();
}

class _TrailPageState extends State<TrailPage> with TickerProviderStateMixin {
  late GroupProvider _groupProvider;
  final TextEditingController _groupNameController = TextEditingController();
  final TextEditingController _trailNameController = TextEditingController();
  final TextEditingController _soloTrailNameController =
      TextEditingController();
  bool _soloIsLoading = false;
  late TabController _tabController;

  final List<GroupMember> _selectedHikers = [];
  bool _isScanning = false;
  int _currentStep = 0;
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
    _soloTrailNameController.dispose();
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
      invitedMembers: _selectedHikers,
    );

    if (_groupProvider.activeGroup != null && mounted) {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
              const TrailGroupPage(),
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
    if (name.isEmpty) {
      SnackbarHelper.showError(
        'Trail Name Required',
        'Please enter a trail name',
      );
      return;
    }
    setState(() => _soloIsLoading = true);
    await Future.delayed(const Duration(milliseconds: 300));
    setState(() => _soloIsLoading = false);
    Get.toNamed(AppRoutes.soloTrail, arguments: {"trailName": name});
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

  @override
  Widget build(BuildContext context) {
    return Consumer<GroupProvider>(
      builder: (context, provider, _) {
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

              // ✅ Scrollable content that DOES move above keyboard
              Positioned.fill(
                child: SafeArea(
                  child: Column(
                    children: [
                      CommonHeader(title: 'Trail'),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: BackdropFilter(
                            filter: ui.ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: kMediumSage,
                                  width: 1,
                                ),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 6,
                              ),
                              child: TabBar(
                                dividerColor: Colors.transparent,
                                controller: _tabController,
                                isScrollable: false,
                                labelColor: kWarmWhite,
                                unselectedLabelColor: kDeepForest,
                                overlayColor: MaterialStateProperty.all(
                                  Colors.transparent,
                                ),
                                indicatorSize: TabBarIndicatorSize.tab,
                                labelPadding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                ),
                                labelStyle: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                ),
                                unselectedLabelStyle: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                                indicator: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [kDeepTeal, Color(0xFF2B8A7E)],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: kDeepTeal.withOpacity(0.25),
                                      blurRadius: 12,
                                      offset: const Offset(0, 6),
                                    ),
                                  ],
                                ),
                                tabs: [
                                  Tab(
                                    child: _buildTabLabel(
                                      Icons.person_pin_circle_rounded,
                                      'Solo',
                                    ),
                                  ),
                                  Tab(
                                    child: _buildTabLabel(
                                      Icons.group_add_rounded,
                                      'Group',
                                    ),
                                  ),
                                ],
                              ),
                            ),
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
                              SingleChildScrollView(
                                padding: EdgeInsets.only(
                                  bottom:
                                      MediaQuery.of(context).viewInsets.bottom +
                                      120,
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: 20),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 20,
                                      ),
                                      child: Container(
                                        padding: const EdgeInsets.all(16),
                                        decoration: BoxDecoration(
                                          color: kWarmWhite,
                                          borderRadius: BorderRadius.circular(
                                            16,
                                          ),
                                          border: Border.all(
                                            color: kMediumSage,
                                          ),
                                        ),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            const Text(
                                              'Trail Name',
                                              style: TextStyle(
                                                color: kDeepTeal,
                                                fontSize: 16,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                            const SizedBox(height: 12),
                                            TextField(
                                              controller:
                                                  _soloTrailNameController,
                                              decoration: InputDecoration(
                                                hintText:
                                                    'Enter a name for your trail',
                                                filled: true,
                                                fillColor: kWarmWhite,
                                                border: OutlineInputBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                  borderSide: const BorderSide(
                                                    color: kMediumSage,
                                                  ),
                                                ),
                                                enabledBorder:
                                                    OutlineInputBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            12,
                                                          ),
                                                      borderSide:
                                                          const BorderSide(
                                                            color: kMediumSage,
                                                          ),
                                                    ),
                                                focusedBorder:
                                                    const OutlineInputBorder(
                                                      borderRadius:
                                                          BorderRadius.all(
                                                            Radius.circular(12),
                                                          ),
                                                      borderSide: BorderSide(
                                                        color: kDeepForest,
                                                        width: 1.5,
                                                      ),
                                                    ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 24),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                      ),
                                      child: NavigationButton(
                                        key: const ValueKey('soloTrailStart'),
                                        currentStep: 1,
                                        isLoading: _soloIsLoading,
                                        onNext: _startSoloTrail,
                                        onBack: () => Get.back(),
                                        showBackButton: false,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              // Tab 2: Create Trail Group
                              (provider.activeGroup != null &&
                                      provider.isTrailMinimized == true)
                                  ? SingleChildScrollView(
                                      padding: EdgeInsets.only(
                                        bottom:
                                            MediaQuery.of(
                                              context,
                                            ).viewInsets.bottom +
                                            120,
                                      ),
                                      child: GroupExistsNotice(
                                        group: provider.activeGroup!,
                                      ),
                                    )
                                  : SingleChildScrollView(
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
                                    ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
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
                      child:
                          (provider.activeGroup != null &&
                              provider.isTrailMinimized == true)
                          ? const SizedBox.shrink()
                          : (_tabController.index != 1
                                ? const SizedBox.shrink()
                                : Container(
                                    color: Colors.transparent,
                                    padding: const EdgeInsets.only(
                                      left: 16,
                                      right: 16,
                                      bottom: 12,
                                    ),
                                    child: NavigationButton(
                                      key: ValueKey(_currentStep),
                                      currentStep: _currentStep,
                                      isLoading: provider.isLoading,
                                      onNext: _currentStep < 2
                                          ? _nextStep
                                          : _createGroup,
                                      onBack: _previousStep,
                                    ),
                                  )),
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
