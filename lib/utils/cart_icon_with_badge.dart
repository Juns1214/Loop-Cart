import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CartIconWithBadge extends StatelessWidget {
  const CartIconWithBadge({super.key});

  @override
  Widget build(BuildContext context) {
    final User? currentUser = FirebaseAuth.instance.currentUser;

    // 1. Define the base button to avoid code duplication
    final Widget cartButton = IconButton(
      onPressed: () => Navigator.pushNamed(context, '/shopping-cart'),
      icon: const Icon(
        Icons.shopping_cart_outlined,
        size: 28,
        color: Colors.black87, // Changed from default to darker black for visibility
      ),
      tooltip: 'Shopping Cart',
    );

    // 2. If user is not logged in, just show the button without the stream listener
    if (currentUser == null) {
      return cartButton;
    }

    // 3. If logged in, listen to the cart count
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('cart_items')
          .where('userId', isEqualTo: currentUser.uid)
          .snapshots(),
      builder: (context, snapshot) {
        int itemCount = 0;
        if (snapshot.hasData) {
          itemCount = snapshot.data!.docs.length;
        }

        // If cart is empty, don't show the badge, just the button
        if (itemCount == 0) {
          return cartButton;
        }

        return Stack(
          clipBehavior: Clip.none,
          children: [
            cartButton,
            Positioned(
              right: 6,
              top: 6,
              child: _buildBadge(itemCount),
            ),
          ],
        );
      },
    );
  }

  // Helper widget to keep the main build method clean
  Widget _buildBadge(int count) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.red,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(color: Colors.white, width: 1.5), // Added white border for better contrast
      ),
      constraints: const BoxConstraints(
        minWidth: 20, // Slightly larger for better visibility
        minHeight: 20,
      ),
      child: Center(
        child: Text(
          count > 99 ? '99+' : '$count',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 11, // Increased size
            fontWeight: FontWeight.w900, // Extra bold for readability
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}