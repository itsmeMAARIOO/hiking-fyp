import 'package:flutter/material.dart';
import 'package:hikingapp/presentation/styles/colors.dart';

class TabSelector extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onSelect;
  final bool showChat;

  const TabSelector({
    super.key,
    required this.selectedIndex,
    required this.onSelect,
    this.showChat = true,
  });

  @override
  Widget build(BuildContext context) {
    final int tabCount = showChat ? 3 : 2;

    // Calculate precise alignment for the sliding indicator
    // Maps index 0..N to Alignment -1.0..1.0
    double alignmentX = -1.0 + (2.0 * selectedIndex / (tabCount - 1));

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      // Matches the exact height of your original snippet:
      // 4 (pad) + 15 (top) + 18 (icon) + 15 (bottom) + 4 (pad) = 56
      height: 56,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28), // Fully rounded stadium shape
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
          // Calculate the width of the active indicator based on available space
          final double indicatorWidth = (constraints.maxWidth - 8) / tabCount;

          return Stack(
            children: [
              // 1. The Sliding Active Indicator
              // Using Padding allows the indicator to "float" inside the border
              Padding(
                padding: const EdgeInsets.all(4),
                child: AnimatedAlign(
                  alignment: Alignment(alignmentX, 0),
                  duration: const Duration(
                    milliseconds: 250,
                  ), // Fast but smooth
                  curve: Curves.easeInOutCubic, // Non-glitchy, premium feel
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

              // 2. The Tab Icons Layer
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
                      ),
                    ),
                  Expanded(
                    child: _Tab(
                      icon: Icons.photo_library_rounded,
                      isSelected: showChat
                          ? selectedIndex == 2
                          : selectedIndex == 1,
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

  const _Tab({
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Center(
        // Smoothly animate color change
        child: TweenAnimationBuilder<Color?>(
          duration: const Duration(milliseconds: 200),
          tween: ColorTween(
            begin: kDeepForest.withOpacity(0.5),
            end: isSelected ? Colors.white : kDeepForest.withOpacity(0.5),
          ),
          builder: (context, color, child) {
            return Icon(
              icon,
              color: color,
              size: 20, // Balanced size for the 56px height
            );
          },
        ),
      ),
    );
  }
}
