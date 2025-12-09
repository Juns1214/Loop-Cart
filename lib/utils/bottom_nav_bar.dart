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
      shape: const CircularNotchedRectangle(),
      notchMargin: 8,
      elevation: 10,
      shadowColor: Colors.black26,
      child: SizedBox(
        height: 60,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _NavItem(
                    icon: Icons.build_outlined, activeIcon: Icons.build,
                    label: 'Repair', index: 0, 
                    currentIndex: currentIndex, onTap: onTap
                  ),
                  _NavItem(
                    icon: Icons.recycling_outlined, activeIcon: Icons.recycling,
                    label: 'Recycle', index: 1, 
                    currentIndex: currentIndex, onTap: onTap
                  ),
                ],
              ),
            ),
            const SizedBox(width: 60), // Space for FAB
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _NavItem(
                    icon: Icons.analytics_outlined, activeIcon: Icons.analytics,
                    label: 'Analytics', index: 3, 
                    currentIndex: currentIndex, onTap: onTap
                  ),
                  _NavItem(
                    icon: Icons.support_agent_outlined, activeIcon: Icons.support_agent_rounded,
                    label: 'ChatBot', index: 4, 
                    currentIndex: currentIndex, onTap: onTap
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final int index;
  final int currentIndex;
  final Function(int) onTap;

  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.index,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bool isSelected = currentIndex == index;
    final Color color = isSelected ? const Color(0xFF2E7D32) : Colors.grey.shade600; // 0xFF2E7D32 is a sharp green

    return InkWell(
      onTap: () => onTap(index),
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(isSelected ? activeIcon : icon, color: color, size: 26),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: color,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}