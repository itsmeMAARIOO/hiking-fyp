import 'package:flutter/material.dart';

import '../../../../styles/colors.dart';

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
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: kDeepTeal.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _Tab(
              icon: Icons.map_outlined,
              isSelected: selectedIndex == 0,
              onTap: () => onSelect(0),
            ),
          ),
          if (showChat)
            Expanded(
              child: _Tab(
                icon: Icons.chat_bubble_outline,
                isSelected: selectedIndex == 1,
                onTap: () => onSelect(1),
              ),
            ),
          Expanded(
            child: _Tab(
              icon: Icons.photo_library_outlined,
              isSelected: showChat ? selectedIndex == 2 : selectedIndex == 1,
              onTap: () => onSelect(showChat ? 2 : 1),
            ),
          ),
        ],
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
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 15),
        decoration: BoxDecoration(
          color: isSelected ? kMediumSage : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.white : kDeepTeal.withOpacity(0.6),
              size: 18,
            ),
          ],
        ),
      ),
    );
  }
}
