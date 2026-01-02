import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ShoppingCart extends StatelessWidget {
  const ShoppingCart({super.key});

  @override
  Widget build(BuildContext context) {
    final User? currentUser = FirebaseAuth.instance.currentUser;

    final Widget cartButton = IconButton(
      onPressed: () => Navigator.pushNamed(context, '/shopping-cart'),
      icon: const Icon(
        Icons.shopping_cart_outlined,
        size: 28,
        color: Colors.black87,
      ),
      tooltip: 'Shopping Cart',
    );

    if (currentUser == null) {
      return cartButton;
    }

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('cart_items')
          .where('userId', isEqualTo: currentUser.uid)
          .snapshots(),
      builder: (context, snapshot) {
        final itemCount = snapshot.hasData ? snapshot.data!.docs.length : 0;

        if (itemCount == 0) return cartButton;

        return Stack(
          clipBehavior: Clip.none,
          children: [
            cartButton,
            Positioned(right: 6, top: 2, child: _buildBadge(itemCount)),
          ],
        );
      },
    );
  }

  Widget _buildBadge(int count) {
    return Container(
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
        border: Border.all(color: Colors.white, width: 1.5),
      ),
      constraints: const BoxConstraints(minWidth: 20, minHeight: 20),
      child: Center(
        child: Text(
          count > 99 ? '99+' : '$count',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w900,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
