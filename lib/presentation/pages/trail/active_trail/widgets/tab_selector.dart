import 'package:flutter/material.dart';
import 'package:hikingapp/presentation/styles/colors.dart';

class TabSelector extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onSelect;
  final bool showChat;
  final bool showLibrary;
  final bool hasUnread;

  const TabSelector({
    super.key,
    required this.selectedIndex,
    required this.onSelect,
    this.showChat = true,
    this.showLibrary = true,
    this.hasUnread = false,
  });

  @override
  Widget build(BuildContext context) {
    int tabCount = 1; // Always have Map
    if (showChat) tabCount++;
    if (showLibrary) tabCount++;

    // Calculate precise alignment for the sliding indicator
    // Maps index 0..N to Alignment -1.0..1.0
    double alignmentX = 0;
    if (tabCount > 1) {
      alignmentX = -1.0 + (2.0 * selectedIndex / (tabCount - 1));
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      height: 56,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: kDeepForest.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.grey.withOpacity(0.1)),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final double indicatorWidth = (constraints.maxWidth - 8) / tabCount;

          return Stack(
            children: [
              Padding(
                padding: const EdgeInsets.all(4),
                child: AnimatedAlign(
                  alignment: Alignment(alignmentX, 0),
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeInOutCubic,
                  child: Container(
                    width: indicatorWidth,
                    height: double.infinity,
                    decoration: BoxDecoration(
                      color: kDeepTeal,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: kDeepTeal.withOpacity(0.25),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Row(
                children: [
                  Expanded(
                    child: _Tab(
                      icon: Icons.map_rounded,
                      isSelected: selectedIndex == 0,
                      onTap: () => onSelect(0),
                    ),
                  ),
                  if (showChat)
                    Expanded(
                      child: _Tab(
                        icon: Icons.chat_bubble_rounded,
                        isSelected: selectedIndex == 1,
                        onTap: () => onSelect(1),
                        isUnread: hasUnread,
                      ),
                    ),
                  if (showLibrary)
                    Expanded(
                      child: _Tab(
                        icon: Icons.photo_library_rounded,
                        isSelected: selectedIndex == (showChat ? 2 : 1),
                        onTap: () => onSelect(showChat ? 2 : 1),
                      ),
                    ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

class _Tab extends StatelessWidget {
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;
  final bool isUnread;

  const _Tab({
    required this.icon,
    required this.isSelected,
    required this.onTap,
    this.isUnread = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Center(
        child: TweenAnimationBuilder<Color?>(
          duration: const Duration(milliseconds: 200),
          tween: ColorTween(
            begin: isUnread && !isSelected
                ? kFreshRed
                : kDeepForest.withOpacity(0.5),
            end: isSelected
                ? Colors.white
                : (isUnread ? kFreshRed : kDeepForest.withOpacity(0.5)),
          ),
          builder: (context, color, child) {
            return Icon(icon, color: color, size: 20);
          },
        ),
      ),
    );
  }
}
