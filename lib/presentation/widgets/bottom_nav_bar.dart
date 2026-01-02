import 'package:flutter/material.dart';
import 'package:hikingapp/presentation/styles/colors.dart';

class BottomNavBar extends StatefulWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const BottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  State<BottomNavBar> createState() => _BottomNavBarState();
}

class _BottomNavBarState extends State<BottomNavBar>
    with TickerProviderStateMixin {
  final List<NavItem> _navItems = const [
    NavItem(Icons.dashboard_outlined, Icons.dashboard),
    NavItem(Icons.map_outlined, Icons.map),
    NavItem(Icons.emergency, Icons.emergency, isEmergency: true),
    NavItem(Icons.terrain_outlined, Icons.terrain_rounded),
    NavItem(Icons.person_outlined, Icons.person),
  ];

  late AnimationController _pulseController;
  late AnimationController _slideController;
  late Animation<double> _slideAnimation;

  int _previousIndex = 0;
  final GlobalKey _navRowKey = GlobalKey();
  final List<GlobalKey> _itemKeys = List.generate(5, (_) => GlobalKey());

  @override
  void initState() {
    super.initState();
    _previousIndex = widget.currentIndex;

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );

    _slideAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _slideController, curve: Curves.easeInOutCubic),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void didUpdateWidget(BottomNavBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentIndex != widget.currentIndex) {
      _previousIndex = oldWidget.currentIndex;
      _slideController.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  double _getIndicatorPosition(int index) {
    final RenderBox? renderBox =
        _itemKeys[index].currentContext?.findRenderObject() as RenderBox?;
    final RenderBox? navBox =
        _navRowKey.currentContext?.findRenderObject() as RenderBox?;

    if (renderBox != null && navBox != null) {
      final position = renderBox.localToGlobal(Offset.zero);
      final navPosition = navBox.localToGlobal(Offset.zero);
      return position.dx - navPosition.dx + (renderBox.size.width / 2);
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.zero,
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(20),
          bottom: Radius.circular(0),
        ),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 350),
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
          decoration: BoxDecoration(
            color: kWarmWhite,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(20),
              bottom: Radius.circular(0),
            ),
            border: const Border(
              top: BorderSide(color: kGlassBorder, width: 1.0),
            ),
            boxShadow: const [],
          ),
          child: SafeArea(
            child: Stack(
              children: [
                // Sliding selection background
                AnimatedBuilder(
                  animation: _slideAnimation,
                  builder: (context, child) {
                    if (_navItems[widget.currentIndex].isEmergency) {
                      return const SizedBox.shrink();
                    }

                    final startPos = _getIndicatorPosition(_previousIndex);
                    final endPos = _getIndicatorPosition(widget.currentIndex);
                    final currentPos =
                        startPos + (endPos - startPos) * _slideAnimation.value;

                    return Positioned(
                      left: currentPos - 28,
                      top: 8,
                      child: Container(
                        width: 56,
                        height: 46,
                        decoration: BoxDecoration(
                          color: kMediumSage.withOpacity(0.18),
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: kMediumSage.withOpacity(0.15),
                              blurRadius: 12,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                // Navigation items
                Row(
                  key: _navRowKey,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: _navItems.asMap().entries.map((entry) {
                    final index = entry.key;
                    final item = entry.value;

                    return item.isEmergency
                        ? _buildEmergencyButton(index)
                        : _buildNavItem(item, index);
                  }).toList(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(NavItem item, int index) {
    final bool isActive = widget.currentIndex == index;
    final int actualIndex = _navItems.indexOf(item);

    return Expanded(
      child: GestureDetector(
        key: _itemKeys[actualIndex],
        onTap: () => widget.onTap(index),
        child: Container(
          color: Colors.transparent,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                child: TweenAnimationBuilder<double>(
                  duration: const Duration(milliseconds: 300),
                  tween: Tween(begin: 0.9, end: isActive ? 1.15 : 1.0),
                  curve: Curves.easeOutBack,
                  builder: (_, scale, child) =>
                      Transform.scale(scale: scale, child: child),
                  child: Icon(
                    isActive ? item.activeIcon : item.icon,
                    size: 26,
                    color: isActive ? kDeepForest : kDeepGrey,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmergencyButton(int index) {
    final bool isActive = widget.currentIndex == index;

    return GestureDetector(
      key: _itemKeys[index],
      onTap: () => widget.onTap(index),
      child: AnimatedBuilder(
        animation: _pulseController,
        builder: (_, child) {
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 6),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: isActive
                      ? [kFreshRed, kEmergencyMediumRed]
                      : [kEmergencyMediumRed, kEmergencyLightRed],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                border: Border.all(
                  color: Colors.white.withOpacity(0.9),
                  width: 3,
                ),
              ),
              child: child,
            ),
          );
        },
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.emergency, color: Colors.white, size: 26),
            SizedBox(height: 2),
          ],
        ),
      ),
    );
  }
}

class NavItem {
  final IconData icon;
  final IconData activeIcon;
  final bool isEmergency;

  const NavItem(this.icon, this.activeIcon, {this.isEmergency = false});
}
