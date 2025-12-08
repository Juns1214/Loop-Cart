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

  // --- Logic Methods ---

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

      List<Map<String, dynamic>> loadedItems = snapshot.docs.map((doc) {
        final data = doc.data();
        data['docId'] = doc.id;
        return data;
      }).toList();

      if (mounted) {
        setState(() {
          cartItems = loadedItems;
          isLoading = false;
          // Reset selection if items change significantly, or keep valid ones
          selectedItems = selectedItems.intersection(
            loadedItems.map((e) => e['docId'] as String).toSet()
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

    try {
      await FirebaseFirestore.instance
          .collection('cart_items')
          .doc(docId)
          .update({
        'quantity': newQuantity,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      setState(() {
        final index = cartItems.indexWhere((item) => item['docId'] == docId);
        if (index != -1) {
          cartItems[index]['quantity'] = newQuantity;
        }
      });
    } catch (e) {
      debugPrint('Error updating quantity: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to update quantity'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _removeItem(String docId) async {
    try {
      await FirebaseFirestore.instance.collection('cart_items').doc(docId).delete();

      setState(() {
        cartItems.removeWhere((item) => item['docId'] == docId);
        selectedItems.remove(docId);
        if (cartItems.isEmpty) selectAll = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Item removed'), backgroundColor: Color(0xFF388E3C)),
        );
      }
    } catch (e) {
      debugPrint('Error removing item: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to remove item'), backgroundColor: Colors.red),
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
      if (doc.exists) {
        return (doc.data()?['address'] as Map<String, dynamic>?);
      }
    } catch (e) {
      debugPrint('Error loading address: $e');
    }
    return null;
  }

  // --- Selection Logic ---

  void _toggleSelectAll() {
    setState(() {
      selectAll = !selectAll;
      if (selectAll) {
        selectedItems = cartItems.map((item) => item['docId'] as String).toSet();
      } else {
        selectedItems.clear();
      }
    });
  }

  void _toggleItemSelection(String docId) {
    setState(() {
      if (selectedItems.contains(docId)) {
        selectedItems.remove(docId);
        selectAll = false;
      } else {
        selectedItems.add(docId);
        if (selectedItems.length == cartItems.length && cartItems.isNotEmpty) {
          selectAll = true;
        }
      }
    });
  }

  double _calculateSelectedTotal() {
    double total = 0;
    for (var item in cartItems) {
      if (selectedItems.contains(item['docId'])) {
        total += (item['productPrice'] ?? 0) * (item['quantity'] ?? 1);
      }
    }
    return total;
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
        const SnackBar(content: Text('Please select items to checkout'), backgroundColor: Colors.orange),
      );
      return;
    }

    final userAddress = await _loadUserAddress();
    final selectedItemsData = cartItems
        .where((item) => selectedItems.contains(item['docId']))
        .toList();

    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => Checkout(
            selectedItems: selectedItemsData,
            userAddress: userAddress,
          ),
        ),
      ).then((_) => _loadCartItems());
    }
  }

  // --- Main Build ---

  @override
  Widget build(BuildContext context) {
    final int greenCoinsToEarn = _calculateGreenCoins();

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Shopping Cart',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
        ),
        centerTitle: true,
        actions: [
          if (cartItems.isNotEmpty)
            TextButton(
              onPressed: _toggleSelectAll,
              child: Text(
                selectAll ? 'Deselect All' : 'Select All',
                style: const TextStyle(color: Color(0xFF388E3C), fontWeight: FontWeight.w600),
              ),
            ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF388E3C)))
          : cartItems.isEmpty
              ? const _EmptyCartView()
              : Column(
                  children: [
                    // 1. Green Coins Banner
                    if (greenCoinsToEarn > 0)
                      _GreenCoinsBanner(coins: greenCoinsToEarn),

                    // 2. Cart List
                    Expanded(
                      child: RefreshIndicator(
                        color: const Color(0xFF388E3C),
                        onRefresh: _loadCartItems,
                        child: ListView.builder(
                          padding: const EdgeInsets.only(bottom: 20),
                          itemCount: cartItems.length,
                          itemBuilder: (context, index) {
                            final item = cartItems[index];
                            return _CartItemTile(
                              item: item,
                              isSelected: selectedItems.contains(item['docId']),
                              onToggle: () => _toggleItemSelection(item['docId']),
                              onQuantityChanged: (qty) => _updateQuantity(item['docId'], qty),
                              onRemove: () => _removeItem(item['docId']),
                            );
                          },
                        ),
                      ),
                    ),

                    // 3. Bottom Checkout Bar
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

// ==============================================================================
// SUB-WIDGETS (Extracted for readability)
// ==============================================================================

class _EmptyCartView extends StatelessWidget {
  const _EmptyCartView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.shopping_cart_outlined, size: 100, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'Your cart is empty',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.grey[800]),
          ),
          const SizedBox(height: 8),
          Text(
            'Add items to get started',
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
          ),
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
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFF0FDF4), Color(0xFFDCFCE7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF388E3C).withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
            child: Image.asset(
              'assets/images/icon/Green Coin.png',
              width: 24, height: 24,
              errorBuilder: (_, __, ___) => const Icon(Icons.eco, color: Color(0xFF388E3C), size: 24),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'You\'ll earn $coins Green Coins with this purchase!',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF388E3C)),
            ),
          ),
        ],
      ),
    );
  }
}

class _CheckoutBottomBar extends StatelessWidget {
  final int itemCount;
  final double totalPrice;
  final VoidCallback? onCheckout;

  const _CheckoutBottomBar({
    required this.itemCount,
    required this.totalPrice,
    required this.onCheckout,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 8, offset: const Offset(0, -2)),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Total ($itemCount items)',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey[800]),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'RM ${totalPrice.toStringAsFixed(2)}',
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF388E3C)),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            CustomButton(
              text: "Checkout",
              onPressed: onCheckout ?? () {},
              // CustomButton doesn't support disabled styling automatically based on null onPressed 
              // like ElevatedButton, so we handle opacity or logic here if strict visual feedback is needed.
              // However, since we are just replacing the widget, we'll rely on the logic passed in.
              // To mimic disabled state visually if onPressed is practically null (handled by parent logic):
              backgroundColor: onCheckout == null ? Colors.grey : const Color(0xFF388E3C),
              minimumSize: const Size(140, 50),
              borderRadius: 12,
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
    final int quantity = item['quantity'] ?? 1;
    final double price = (item['productPrice'] ?? 0).toDouble();
    final bool isPreowned = item['isPreowned'] ?? false;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Checkbox(
              value: isSelected,
              onChanged: (_) => onToggle(),
              activeColor: const Color(0xFF388E3C),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
            ),
            
            // Image with Pre-owned Badge
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    width: 80, height: 80,
                    color: Colors.grey[200],
                    child: item['imageUrl'] != null && item['imageUrl'].isNotEmpty
                        ? Image.asset(item['imageUrl'], fit: BoxFit.cover,
                            errorBuilder: (_,__,___) => const Icon(Icons.image, color: Colors.grey))
                        : const Icon(Icons.image, color: Colors.grey),
                  ),
                ),
                if (isPreowned)
                  Positioned(
                    top: 4, left: 4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2E5BFF),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(Icons.recycling, size: 10, color: Colors.white),
                          SizedBox(width: 2),
                          Text(
                            'Pre-owned',
                            style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
            
            const SizedBox(width: 12),
            
            // Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item['productName'] ?? 'Unknown Product',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  if (item['seller'] != null)
                    Text(
                      'By ${item['seller']}',
                      style: TextStyle(fontSize: 13, color: Colors.grey[800]),
                    ),
                  
                  if (isPreowned) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.eco, size: 14, color: Color(0xFF388E3C)),
                        const SizedBox(width: 4),
                        Text(
                          'Earn ${(price * quantity).floor()} Green Coins',
                          style: const TextStyle(fontSize: 12, color: Color(0xFF388E3C), fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ],
                  
                  const SizedBox(height: 8),
                  Text(
                    'RM ${price.toStringAsFixed(2)}',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF388E3C)),
                  ),
                  
                  const SizedBox(height: 12),
                  
                  // Controls
                  Row(
                    children: [
                      Container(
                        height: 36,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey[300]!),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.remove, size: 16),
                              onPressed: quantity > 1 ? () => onQuantityChanged(quantity - 1) : null,
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                              constraints: const BoxConstraints(),
                            ),
                            Container(
                              width: 32,
                              alignment: Alignment.center,
                              child: Text('$quantity', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                            ),
                            IconButton(
                              icon: const Icon(Icons.add, size: 16),
                              onPressed: () => onQuantityChanged(quantity + 1),
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                              constraints: const BoxConstraints(),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, color: Colors.red),
                        onPressed: onRemove,
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