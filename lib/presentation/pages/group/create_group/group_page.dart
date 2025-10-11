// lib/presentation/pages/group/create_group/create_group_page.dart
import 'package:flutter/material.dart';
import 'package:hikingapp/data/models/group_model.dart';
import 'package:hikingapp/presentation/pages/group/create_group/widgets/create_group_step1.dart';
import 'package:hikingapp/presentation/pages/group/create_group/widgets/create_group_step2.dart'
    hide kDarkPrimaryColor;
import 'package:hikingapp/presentation/pages/group/create_group/widgets/create_group_step3.dart';
import 'package:hikingapp/presentation/pages/group/trail_group/trail_group_page.dart';
import 'package:hikingapp/presentation/widgets/common_header.dart';
import 'package:hikingapp/providers/auth_provider.dart';
import 'package:hikingapp/providers/group_provider.dart';
import 'package:provider/provider.dart';
// Note: We'll use the new 'NavigationButton' widget instead of 'NavigationButtons'
import 'widgets/step_indicator_widgets.dart'
    hide kDarkPrimaryColor; // This file now contains NavigationButton

// The color constants from the previous file for the gradient
const Color kDeepTeal = Color(0xFF1c3f3f);
const Color kSoftMint = Color(0xFFa0d5b9);
const Color kMediumSage = Color(0xFF6baf89);
const Color kDeepForest = Color(0xFF3e7b5b);

class GroupPage extends StatefulWidget {
  const GroupPage({super.key});

  @override
  State<GroupPage> createState() => _GroupPageState();
}

class _GroupPageState extends State<GroupPage> with TickerProviderStateMixin {
  final GroupProvider _groupProvider = GroupProvider();
  final TextEditingController _groupNameController = TextEditingController();
  final TextEditingController _trailNameController = TextEditingController();

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
    super.dispose();
  }

  Future<void> _scanNearbyHikers() async {
    setState(() => _isScanning = true);
    await _groupProvider.fetchNearbyMembers(excludeUserId: _currentUserId);

    // Filter out selected hikers that are no longer in the nearby list
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
              ChangeNotifierProvider.value(
                value: _groupProvider,
                child: const TrailGroupPage(),
              ),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            // Apply a more dynamic transition here, like a ScaleTransition
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
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: kDarkPrimaryColor, // Use the dark sage color
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        margin: const EdgeInsets.all(24), // Larger margin for a modern look
      ),
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

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _groupProvider,
      child: Consumer<GroupProvider>(
        builder: (context, provider, _) {
          return Scaffold(
            resizeToAvoidBottomInset:
                false, // ✅ prevent shrinking when keyboard opens
            body: Stack(
              children: [
                // 2. Main Content (Header, Steps, Step Indicator)
                SafeArea(
                  child: Column(
                    children: [
                      // Header
                      CommonHeader(
                        title: 'Trail Explorer',
                        subtitle: 'Discover and record your hiking paths',
                      ),
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

                          // ✅ Wrap the inner Column in SingleChildScrollView
                          child: SingleChildScrollView(
                            // This ensures the screen is scrollable when the keyboard pops up
                            reverse: true,
                            padding: EdgeInsets.only(
                              bottom:
                                  MediaQuery.of(context).viewInsets.bottom + 70,
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
                                        selectedHikers: _selectedHikers,
                                        isScanning: _isScanning,
                                        onScan: _scanNearbyHikers,
                                        onToggleSelection:
                                            _toggleHikerSelection,
                                      ),
                                      Step3Confirm(
                                        groupName: _groupNameController.text,
                                        trailName: _trailNameController.text,
                                        currentUserName: _currentUserName,
                                        selectedHikers: _selectedHikers,
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

                // 3. Floating Navigation Button (Layered on top of content)
                Align(
                  alignment: Alignment.bottomCenter,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 16),
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
                      child: NavigationButton(
                        key: ValueKey(_currentStep),
                        currentStep: _currentStep,
                        isLoading: provider.isLoading,
                        onNext: _currentStep < 2 ? _nextStep : _createGroup,
                        onBack: _previousStep,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
