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
      shape: CircularNotchedRectangle(),
      notchMargin: 8,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Left side icons: Home, Message
          Row(
            children: [
              IconButton(
                icon: Icon(Icons.home),
                color: currentIndex == 0 ? Colors.amber : Colors.black,
                onPressed: () => onTap(0),
              ),
              IconButton(
                icon: Icon(Icons.message),
                color: currentIndex == 1 ? Colors.amber : Colors.black,
                onPressed: () => onTap(1),
              ),
            ],
          ),
          // Right side icons: Cart, Profile
          Row(
            children: [
              IconButton(
                icon: Icon(Icons.shopping_cart),
                color: currentIndex == 3 ? Colors.amber : Colors.black,
                onPressed: () => onTap(3),
              ),
              IconButton(
                icon: Icon(Icons.person),
                color: currentIndex == 4 ? Colors.amber : Colors.black,
                onPressed: () => onTap(4),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
