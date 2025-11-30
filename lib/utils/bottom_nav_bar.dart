import 'package:flutter/material.dart';

class BottomNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const BottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return BottomAppBar(
      color: Colors.white,
      shape: CircularNotchedRectangle(),
      notchMargin: 6,
      elevation: 8,
      child: Container(
        height: 60,
        padding: EdgeInsets.symmetric(horizontal: 4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Left side - Repair and Recycle
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildNavItem(
                    icon: Icons.build_outlined,
                    selectedIcon: Icons.build,
                    label: 'Repair',
                    index: 0,
                  ),
                  _buildNavItem(
                    icon: Icons.recycling_outlined,
                    selectedIcon: Icons.recycling,
                    label: 'Recycle',
                    index: 1,
                  ),
                ],
              ),
            ),
            // Space for floating action button
            SizedBox(width: 80),
            // Right side - Analytics and Profile
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildNavItem(
                    icon: Icons.analytics_outlined,
                    selectedIcon: Icons.analytics,
                    label: 'Analytics',
                    index: 3,
                  ),
                  _buildNavItem(
                    icon: Icons.support_agent_outlined,
                    selectedIcon: Icons.support_agent_rounded,
                    label: 'ChatBot',
                    index: 4,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required IconData selectedIcon,
    required String label,
    required int index,
  }) {
    final isSelected = currentIndex == index;
    return InkWell(
      onTap: () => onTap(index),
      splashColor: Colors.green.withOpacity(0.2),
      highlightColor: Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 6, horizontal: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isSelected ? selectedIcon : icon,
              color: isSelected ? Color(0xFF388E3C) : Colors.grey.shade600,
              size: 26,
            ),
            SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: isSelected ? Color(0xFF388E3C) : Colors.grey.shade600,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}