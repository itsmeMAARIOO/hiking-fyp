import 'package:flutter/material.dart';

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

class _BottomNavBarState extends State<BottomNavBar> {
  final List<NavItem> _navItems = const [
    NavItem(Icons.dashboard_outlined, Icons.dashboard, "Dashboard"),
    NavItem(Icons.map_outlined, Icons.map, "Map"),
    NavItem(Icons.emergency, Icons.emergency, "SOS", isEmergency: true),
    NavItem(Icons.people_outlined, Icons.people, "Groups"),
    NavItem(Icons.person_outlined, Icons.person, "Profile"),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            children: _navItems.asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value;
              return item.isEmergency
                  ? _buildEmergencyButton(index)
                  : _buildNavItem(item, index);
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(NavItem item, int index) {
    final isActive = widget.currentIndex == index;

    return Expanded(
      child: GestureDetector(
        onTap: () => widget.onTap(index),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              height: 2,
              width: isActive ? 20 : 0,
              decoration: BoxDecoration(
                color: const Color(0xFF16A085),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 6),
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isActive
                    ? const Color(0xFF16A085).withOpacity(0.15)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                isActive ? item.activeIcon : item.icon,
                size: 24,
                color: isActive
                    ? const Color(0xFF16A085)
                    : const Color(0xFF8B7355),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              item.label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                color: isActive
                    ? const Color(0xFF16A085)
                    : const Color(0xFF8B7355),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmergencyButton(int index) {
    final isActive = widget.currentIndex == index;

    return GestureDetector(
      onTap: () => widget.onTap(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: isActive ? 64 : 56,
        height: isActive ? 64 : 56,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            colors: isActive
                ? [const Color(0xFFFF4444), const Color(0xFFC0392B)]
                : [const Color(0xFFFF6B35), const Color(0xFFE74C3C)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFF6B35).withOpacity(isActive ? 0.5 : 0.3),
              blurRadius: isActive ? 12 : 8,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(color: Colors.white, width: isActive ? 4 : 3),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.emergency,
              color: Colors.white,
              size: isActive ? 24 : 20,
            ),
            Text(
              "SOS",
              style: TextStyle(
                color: Colors.white,
                fontSize: isActive ? 10 : 8,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class NavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool isEmergency;

  const NavItem(
    this.icon,
    this.activeIcon,
    this.label, {
    this.isEmergency = false,
  });
}
