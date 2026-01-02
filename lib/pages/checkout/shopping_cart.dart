import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../checkout/checkout.dart';
import '../../widget/custom_button.dart';

class ShoppingCart extends StatefulWidget {
  const ShoppingCart({super.key});

  @override
  State<ShoppingCart> createState() => _ShoppingCartState();
}

class _ShoppingCartState extends State<ShoppingCart> {
  final User? currentUser = FirebaseAuth.instance.currentUser;
  List<Map<String, dynamic>> cartItems = [];
  Set<String> selectedItems = {};
  bool isLoading = true;
  bool selectAll = false;

  @override
  void initState() {
    super.initState();
    _loadCartItems();
  }

  Future<void> _loadCartItems() async {
    if (currentUser == null) {
      if (mounted) setState(() => isLoading = false);
      return;
    }

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('cart_items')
          .where('userId', isEqualTo: currentUser!.uid)
          .get();

      final loadedItems = snapshot.docs.map((doc) {
        final data = doc.data();
        data['docId'] = doc.id;
        return data;
      }).toList();

      if (mounted) {
        setState(() {
          cartItems = loadedItems;
          isLoading = false;
          selectedItems = selectedItems.intersection(
            loadedItems.map((e) => e['docId'] as String).toSet(),
          );
        });
      }
    } catch (e) {
      debugPrint('Error loading cart: $e');
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> _updateQuantity(String docId, int newQuantity) async {
    if (newQuantity < 1) return;

    setState(() {
      final index = cartItems.indexWhere((item) => item['docId'] == docId);
      if (index != -1) cartItems[index]['quantity'] = newQuantity;
    });

    try {
      await FirebaseFirestore.instance.collection('cart_items').doc(docId).update({
        'quantity': newQuantity,
      });
    } catch (e) {
      debugPrint('Error updating quantity: $e');
      _loadCartItems();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          _buildSnackBar('Failed to update quantity', isError: true),
        );
      }
    }
  }

  Future<void> _removeItem(String docId) async {
    final removedItem = cartItems.firstWhere((item) => item['docId'] == docId);
    
    setState(() {
      cartItems.removeWhere((item) => item['docId'] == docId);
      selectedItems.remove(docId);
      if (cartItems.isEmpty) selectAll = false;
    });

    try {
      await FirebaseFirestore.instance.collection('cart_items').doc(docId).delete();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(_buildSnackBar('Item removed'));
      }
    } catch (e) {
      debugPrint('Error removing item: $e');
      setState(() => cartItems.add(removedItem));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          _buildSnackBar('Failed to remove item', isError: true),
        );
      }
    }
  }

  Future<Map<String, dynamic>?> _loadUserAddress() async {
    if (currentUser == null) return null;
    try {
      final doc = await FirebaseFirestore.instance
          .collection('user_profile')
          .doc(currentUser!.uid)
          .get();
      return doc.exists ? (doc.data()?['address'] as Map<String, dynamic>?) : null;
    } catch (e) {
      debugPrint('Error loading address: $e');
      return null;
    }
  }

  void _toggleSelectAll() {
    setState(() {
      selectAll = !selectAll;
      selectedItems = selectAll ? cartItems.map((item) => item['docId'] as String).toSet() : {};
    });
  }

  void _toggleItemSelection(String docId) {
    setState(() {
      if (selectedItems.contains(docId)) {
        selectedItems.remove(docId);
        selectAll = false;
      } else {
        selectedItems.add(docId);
        selectAll = selectedItems.length == cartItems.length;
      }
    });
  }

  double _calculateSelectedTotal() {
    return cartItems
        .where((item) => selectedItems.contains(item['docId']))
        .fold(0.0, (sum, item) => sum + ((item['productPrice'] ?? 0) * (item['quantity'] ?? 1)).toDouble());
  }

  int _calculateGreenCoins() {
    int total = 0;
    for (var item in cartItems) {
      if (selectedItems.contains(item['docId']) && (item['isPreowned'] ?? false)) {
        int quantity = item['quantity'] ?? 1;
        double price = (item['productPrice'] ?? 0).toDouble();
        total += (price * quantity).floor();
      }
    }
    return total;
  }

  Future<void> _proceedToCheckout() async {
    if (selectedItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        _buildSnackBar('Please select items to checkout', isWarning: true),
      );
      return;
    }

    final userAddress = await _loadUserAddress();
    final selectedItemsData = cartItems.where((item) => selectedItems.contains(item['docId'])).toList();

    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => Checkout(selectedItems: selectedItemsData, userAddress: userAddress),
        ),
      ).then((_) => _loadCartItems());
    }
  }

  SnackBar _buildSnackBar(String message, {bool isError = false, bool isWarning = false}) {
    return SnackBar(
      content: Text(message, style: const TextStyle(fontFamily: 'Roboto', fontWeight: FontWeight.w500)),
      backgroundColor: isError ? const Color(0xFFD32F2F) : isWarning ? const Color(0xFFF57C00) : const Color(0xFF2E7D32),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      margin: const EdgeInsets.all(16),
    );
  }

  @override
  Widget build(BuildContext context) {
    final greenCoinsToEarn = _calculateGreenCoins();

    return Scaffold(
      backgroundColor: const Color(0xFFF1F8F4),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF1B5E20), size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Shopping Cart',
          style: TextStyle(fontFamily: 'Roboto', fontWeight: FontWeight.w700, fontSize: 20, color: Color(0xFF1B5E20), letterSpacing: 0.5),
        ),
        centerTitle: true,
        actions: [
          if (cartItems.isNotEmpty)
            TextButton.icon(
              onPressed: _toggleSelectAll,
              icon: Icon(selectAll ? Icons.check_circle : Icons.check_circle_outline, size: 18, color: const Color(0xFF2E7D32)),
              label: Text(
                selectAll ? 'Deselect' : 'Select All',
                style: const TextStyle(fontFamily: 'Roboto', color: Color(0xFF2E7D32), fontWeight: FontWeight.w600, fontSize: 14),
              ),
            ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF2E7D32), strokeWidth: 3))
          : cartItems.isEmpty
              ? const _EmptyCartView()
              : Column(
                  children: [
                    if (greenCoinsToEarn > 0) _GreenCoinsBanner(coins: greenCoinsToEarn),
                    Expanded(
                      child: RefreshIndicator(
                        color: const Color(0xFF2E7D32),
                        onRefresh: _loadCartItems,
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          itemCount: cartItems.length,
                          itemBuilder: (context, index) => _CartItemTile(
                            item: cartItems[index],
                            isSelected: selectedItems.contains(cartItems[index]['docId']),
                            onToggle: () => _toggleItemSelection(cartItems[index]['docId']),
                            onQuantityChanged: (qty) => _updateQuantity(cartItems[index]['docId'], qty),
                            onRemove: () => _removeItem(cartItems[index]['docId']),
                          ),
                        ),
                      ),
                    ),
                    _CheckoutBottomBar(
                      itemCount: selectedItems.length,
                      totalPrice: _calculateSelectedTotal(),
                      onCheckout: selectedItems.isEmpty ? null : _proceedToCheckout,
                    ),
                  ],
                ),
    );
  }
}

class _EmptyCartView extends StatelessWidget {
  const _EmptyCartView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(color: Color(0xFFE8F5E9), shape: BoxShape.circle),
            child: const Icon(Icons.shopping_cart_outlined, size: 80, color: Color(0xFF66BB6A)),
          ),
          const SizedBox(height: 24),
          const Text('Your cart is empty', style: TextStyle(fontFamily: 'Roboto', fontSize: 24, fontWeight: FontWeight.w700, color: Color(0xFF1B5E20))),
          const SizedBox(height: 8),
          Text('Start shopping for sustainable products!', style: TextStyle(fontFamily: 'Roboto', fontSize: 16, fontWeight: FontWeight.w400, color: Colors.grey[600])),
        ],
      ),
    );
  }
}

class _GreenCoinsBanner extends StatelessWidget {
  final int coins;
  const _GreenCoinsBanner({required this.coins});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFFE8F5E9), Color(0xFFC8E6C9)], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF66BB6A), width: 2),
        boxShadow: [BoxShadow(color: Color(0xFF2E7D32), blurRadius: 8, offset: Offset(0, 4))],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [BoxShadow(color: Color(0xFF2E7D32), blurRadius: 8, offset: Offset(0, 2))],
            ),
            child: Image.asset('assets/images/icon/Green Coin.png', width: 28, height: 28,
                errorBuilder: (_, __, ___) => const Icon(Icons.eco, color: Color(0xFF2E7D32), size: 28)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: const TextStyle(fontFamily: 'Roboto', fontSize: 15, color: Color(0xFF1B5E20), fontWeight: FontWeight.w500),
                children: [
                  const TextSpan(text: 'You\'ll earn '),
                  TextSpan(text: '$coins Green Coins', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: Color(0xFF2E7D32))),
                  const TextSpan(text: ' with this purchase!'),
                ],
              ),
            ),
          ),
          const Icon(Icons.arrow_forward_ios, size: 16, color: Color(0xFF2E7D32)),
        ],
      ),
    );
  }
}

class _CheckoutBottomBar extends StatelessWidget {
  final int itemCount;
  final double totalPrice;
  final VoidCallback? onCheckout;

  const _CheckoutBottomBar({required this.itemCount, required this.totalPrice, required this.onCheckout});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 16, offset: const Offset(0, -4))],
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Total ($itemCount ${itemCount == 1 ? 'item' : 'items'})', 
                      style: const TextStyle(fontFamily: 'Roboto', fontSize: 14, fontWeight: FontWeight.w500, color: Color(0xFF616161))),
                  const SizedBox(height: 4),
                  Text('RM ${totalPrice.toStringAsFixed(2)}', 
                      style: const TextStyle(fontFamily: 'Roboto', fontSize: 28, fontWeight: FontWeight.w800, color: Color(0xFF2E7D32), letterSpacing: -0.5)),
                ],
              ),
            ),
            const SizedBox(width: 16),
            CustomButton(
              text: "Checkout",
              onPressed: onCheckout ?? () {},
              backgroundColor: onCheckout == null ? Colors.grey[400]! : const Color(0xFF2E7D32),
              minimumSize: const Size(150, 56),
              borderRadius: 16,
            ),
          ],
        ),
      ),
    );
  }
}

class _CartItemTile extends StatelessWidget {
  final Map<String, dynamic> item;
  final bool isSelected;
  final VoidCallback onToggle;
  final Function(int) onQuantityChanged;
  final VoidCallback onRemove;

  const _CartItemTile({
    required this.item,
    required this.isSelected,
    required this.onToggle,
    required this.onQuantityChanged,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final quantity = item['quantity'] ?? 1;
    final price = (item['productPrice'] ?? 0).toDouble();
    final isPreowned = item['isPreowned'] ?? false;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: isSelected ? 4 : 1,
      shadowColor: isSelected ? const Color(0xFF2E7D32).withOpacity(0.3) : Colors.black.withOpacity(0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: isSelected ? const BorderSide(color: Color(0xFF2E7D32), width: 2) : BorderSide.none,
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Transform.scale(
              scale: 1.2,
              child: Checkbox(
                value: isSelected,
                onChanged: (_) => onToggle(),
                activeColor: const Color(0xFF2E7D32),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
              ),
            ),
            const SizedBox(width: 8),
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: 90,
                    height: 90,
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      border: Border.all(color: Colors.grey[300]!),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: item['imageUrl'] != null && item['imageUrl'].isNotEmpty
                        ? Image.asset(item['imageUrl'], fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const Icon(Icons.image_outlined, color: Colors.grey, size: 40))
                        : const Icon(Icons.image_outlined, color: Colors.grey, size: 40),
                  ),
                ),
                if (isPreowned)
                  Positioned(
                    top: 6,
                    left: 6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [Color(0xFF1976D2), Color(0xFF2196F3)]),
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [BoxShadow(color: Colors.blue.withOpacity(0.4), blurRadius: 4, offset: const Offset(0, 2))],
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.recycling, size: 11, color: Colors.white),
                          SizedBox(width: 3),
                          Text('Pre-owned', style: TextStyle(fontFamily: 'Roboto', color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 0.3)),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item['productName'] ?? 'Unknown Product',
                    style: const TextStyle(fontFamily: 'Roboto', fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF212121), height: 1.3),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  if (item['seller'] != null)
                    Text('by ${item['seller']}', style: TextStyle(fontFamily: 'Roboto', fontSize: 13, fontWeight: FontWeight.w400, color: Colors.grey[600])),
                  if (isPreowned) ...[
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(color: const Color(0xFFE8F5E9), borderRadius: BorderRadius.circular(8)),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.eco, size: 14, color: Color(0xFF2E7D32)),
                          const SizedBox(width: 4),
                          Text('Earn ${(price * quantity).floor()} coins',
                              style: const TextStyle(fontFamily: 'Roboto', fontSize: 12, color: Color(0xFF2E7D32), fontWeight: FontWeight.w700)),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 8),
                  Text('RM ${price.toStringAsFixed(2)}',
                      style: const TextStyle(fontFamily: 'Roboto', fontSize: 20, fontWeight: FontWeight.w800, color: Color(0xFF2E7D32), letterSpacing: -0.5)),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Container(
                        height: 36,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border.all(color: const Color(0xFFBDBDBD), width: 1.5),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.remove, size: 18),
                              onPressed: quantity > 1 ? () => onQuantityChanged(quantity - 1) : null,
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                              constraints: const BoxConstraints(minWidth: 36),
                              color: quantity > 1 ? const Color(0xFF2E7D32) : Colors.grey[400],
                            ),
                            Container(
                              width: 32,
                              alignment: Alignment.center,
                              child: Text('$quantity', style: const TextStyle(fontFamily: 'Roboto', fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF212121))),
                            ),
                            IconButton(
                              icon: const Icon(Icons.add, size: 18),
                              onPressed: () => onQuantityChanged(quantity + 1),
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                              constraints: const BoxConstraints(minWidth: 36),
                              color: const Color(0xFF2E7D32),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, size: 24),
                        onPressed: onRemove,
                        color: const Color(0xFFD32F2F),
                        tooltip: 'Remove item',
                      ),
                    ],
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