import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../checkout/checkout.dart';

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
      setState(() {
        isLoading = false;
      });
      return;
    }

    try {
      QuerySnapshot cartSnapshot = await FirebaseFirestore.instance
          .collection('cart_items')
          .where('userId', isEqualTo: currentUser!.uid)
          .get();

      List<Map<String, dynamic>> loadedItems = [];
      
      for (var doc in cartSnapshot.docs) {
        Map<String, dynamic> itemData = doc.data() as Map<String, dynamic>;
        itemData['docId'] = doc.id;
        loadedItems.add(itemData);
      }

      setState(() {
        cartItems = loadedItems;
        isLoading = false;
      });
    } catch (e) {
      print('Error loading cart: $e');
      setState(() {
        isLoading = false;
      });
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
        int index = cartItems.indexWhere((item) => item['docId'] == docId);
        if (index != -1) {
          cartItems[index]['quantity'] = newQuantity;
        }
      });
    } catch (e) {
      print('Error updating quantity: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update quantity'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _removeItem(String docId) async {
    try {
      await FirebaseFirestore.instance
          .collection('cart_items')
          .doc(docId)
          .delete();

      setState(() {
        cartItems.removeWhere((item) => item['docId'] == docId);
        selectedItems.remove(docId);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Item removed from cart'),
          backgroundColor: Color(0xFF388E3C),
        ),
      );
    } catch (e) {
      print('Error removing item: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to remove item'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<Map<String, dynamic>?> _loadUserAddress() async {
    if (currentUser == null) return null;

    try {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('user_profile')
          .doc(currentUser!.uid)
          .get();

      if (userDoc.exists) {
        Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
        return userData['address'] as Map<String, dynamic>?;
      }
    } catch (e) {
      print('Error loading user address: $e');
    }
    return null;
  }

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
        if (selectedItems.length == cartItems.length) {
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

  Future<void> _proceedToCheckout() async {
    if (selectedItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please select items to checkout'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Load user address
    Map<String, dynamic>? userAddress = await _loadUserAddress();

    // Get selected items data
    List<Map<String, dynamic>> selectedItemsData = cartItems
        .where((item) => selectedItems.contains(item['docId']))
        .toList();

    // Navigate to checkout
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Checkout(
          selectedItems: selectedItemsData,
          userAddress: userAddress,
        ),
      ),
    ).then((_) {
      // Reload cart when returning from checkout
      _loadCartItems();
    });
  }

  Widget _buildCartItem(Map<String, dynamic> item) {
    String docId = item['docId'];
    bool isSelected = selectedItems.contains(docId);
    int quantity = item['quantity'] ?? 1;
    double price = (item['productPrice'] ?? 0).toDouble();

    return Card(
      margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Padding(
        padding: EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Checkbox
            Checkbox(
              value: isSelected,
              onChanged: (value) => _toggleItemSelection(docId),
              activeColor: Color(0xFF388E3C),
            ),

            // Product Image
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: item['imageUrl'] != null && item['imageUrl'].isNotEmpty
                  ? Image.asset(
                      item['imageUrl'],
                      width: 80,
                      height: 80,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          width: 80,
                          height: 80,
                          color: Colors.grey[300],
                          child: Icon(Icons.image, size: 40, color: Colors.grey),
                        );
                      },
                    )
                  : Container(
                      width: 80,
                      height: 80,
                      color: Colors.grey[300],
                      child: Icon(Icons.image, size: 40, color: Colors.grey),
                    ),
            ),

            SizedBox(width: 12),

            // Product Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item['productName'] ?? 'Unknown Product',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 4),
                  if (item['seller'] != null && item['seller'].isNotEmpty)
                    Text(
                      'By ${item['seller']}',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[600],
                      ),
                    ),
                  SizedBox(height: 8),
                  Text(
                    'RM ${price.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF388E3C),
                    ),
                  ),
                  SizedBox(height: 12),

                  // Quantity controls
                  Row(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey[300]!),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            IconButton(
                              icon: Icon(Icons.remove, size: 18),
                              onPressed: quantity > 1
                                  ? () => _updateQuantity(docId, quantity - 1)
                                  : null,
                              padding: EdgeInsets.all(4),
                              constraints: BoxConstraints(),
                            ),
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 12),
                              child: Text(
                                '$quantity',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            IconButton(
                              icon: Icon(Icons.add, size: 18),
                              onPressed: () => _updateQuantity(docId, quantity + 1),
                              padding: EdgeInsets.all(4),
                              constraints: BoxConstraints(),
                            ),
                          ],
                        ),
                      ),
                      Spacer(),
                      IconButton(
                        icon: Icon(Icons.delete_outline, color: Colors.red),
                        onPressed: () => _removeItem(docId),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Shopping Cart',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        centerTitle: true,
        actions: [
          if (cartItems.isNotEmpty)
            TextButton(
              onPressed: _toggleSelectAll,
              child: Text(
                selectAll ? 'Deselect All' : 'Select All',
                style: TextStyle(
                  color: Color(0xFF388E3C),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
      body: isLoading
          ? Center(
              child: CircularProgressIndicator(color: Color(0xFF388E3C)),
            )
          : cartItems.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.shopping_cart_outlined,
                        size: 100,
                        color: Colors.grey[400],
                      ),
                      SizedBox(height: 16),
                      Text(
                        'Your cart is empty',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[600],
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Add items to get started',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    Expanded(
                      child: RefreshIndicator(
                        color: Color(0xFF388E3C),
                        onRefresh: _loadCartItems,
                        child: ListView.builder(
                          itemCount: cartItems.length,
                          itemBuilder: (context, index) {
                            return _buildCartItem(cartItems[index]);
                          },
                        ),
                      ),
                    ),

                    // Bottom Checkout Bar
                    Container(
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 8,
                            offset: Offset(0, -2),
                          ),
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
                                    'Total (${selectedItems.length} items)',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    'RM ${_calculateSelectedTotal().toStringAsFixed(2)}',
                                    style: TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF388E3C),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(width: 16),
                            ElevatedButton(
                              onPressed: selectedItems.isEmpty ? null : _proceedToCheckout,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Color(0xFF388E3C),
                                padding: EdgeInsets.symmetric(
                                  horizontal: 32,
                                  vertical: 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: Text(
                                'Checkout',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }
}