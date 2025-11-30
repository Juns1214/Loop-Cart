import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../checkout/checkout.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: const CartItems(),
    );
  }
}

class CartItems extends StatefulWidget {
  const CartItems({super.key});

  @override
  State<CartItems> createState() => _CartItemsState();
}

class _CartItemsState extends State<CartItems> {
  final User? currentUser = FirebaseAuth.instance.currentUser;
  
  Map<String, dynamic>? userAddress;
  Map<String, List<Map<String, dynamic>>> groupedCartItems = {};
  Map<String, bool> selectedSellers = {};
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCartData();
  }

  Future<void> _loadCartData() async {
    if (currentUser == null) return;

    setState(() {
      isLoading = true;
    });

    try {
      // Load user address
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('user_profile')
          .doc(currentUser!.uid)
          .get();

      if (userDoc.exists) {
        userAddress = (userDoc.data() as Map<String, dynamic>)['address'];
      }

      // Load cart items
      QuerySnapshot cartSnapshot = await FirebaseFirestore.instance
          .collection('shopping_cart')
          .where('userId', isEqualTo: currentUser!.uid)
          .get();

      // Group items by seller
      Map<String, List<Map<String, dynamic>>> grouped = {};
      
      for (var doc in cartSnapshot.docs) {
        Map<String, dynamic> item = doc.data() as Map<String, dynamic>;
        item['cartId'] = doc.id; // Add document ID for updates/deletes
        
        String sellerName = item['sellerName'] ?? 'Unknown Seller';
        
        if (!grouped.containsKey(sellerName)) {
          grouped[sellerName] = [];
          selectedSellers[sellerName] = false;
        }
        
        grouped[sellerName]!.add(item);
      }

      setState(() {
        groupedCartItems = grouped;
        isLoading = false;
      });
    } catch (e) {
      print('Error loading cart data: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _updateQuantity(String cartId, int newQuantity) async {
    if (newQuantity < 1) return;

    try {
      await FirebaseFirestore.instance
          .collection('shopping_cart')
          .doc(cartId)
          .update({'quantity': newQuantity});
      
      _loadCartData(); // Reload cart
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

  Future<void> _deleteItem(String cartId) async {
    try {
      await FirebaseFirestore.instance
          .collection('shopping_cart')
          .doc(cartId)
          .delete();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Item removed from cart'),
          backgroundColor: Color(0xFF388E3C),
        ),
      );
      
      _loadCartData(); // Reload cart
    } catch (e) {
      print('Error deleting item: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to remove item'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  double _calculateSellerSubtotal(List<Map<String, dynamic>> items) {
    double subtotal = 0;
    for (var item in items) {
      subtotal += (item['productPrice'] ?? 0) * (item['quantity'] ?? 1);
    }
    return subtotal;
  }

  void _navigateToCheckout() {
    // Get selected sellers and their items
    List<Map<String, dynamic>> selectedItems = [];
    
    selectedSellers.forEach((seller, isSelected) {
      if (isSelected && groupedCartItems.containsKey(seller)) {
        selectedItems.addAll(groupedCartItems[seller]!);
      }
    });

    if (selectedItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please select items to checkout'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Navigate to checkout with selected items
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Checkout(
          selectedItems: selectedItems,
          userAddress: userAddress,
        ),
      ),
    );
  }

  Widget _buildProductRow(Map<String, dynamic> item) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
                        child: Icon(Icons.image, color: Colors.grey),
                      );
                    },
                  )
                : Container(
                    width: 80,
                    height: 80,
                    color: Colors.grey[300],
                    child: Icon(Icons.image, color: Colors.grey),
                  ),
          ),
          SizedBox(width: 12),

          // Middle Section (name + price + qty selector)
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Product Name
                Text(
                  item['productName'] ?? 'Unknown Product',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 8),

                // Product Price
                Text(
                  'RM ${(item['productPrice'] ?? 0).toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[700],
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 12),

                // Quantity selector
                Row(
                  children: [
                    // Decrement Button
                    InkWell(
                      onTap: () {
                        int currentQty = item['quantity'] ?? 1;
                        if (currentQty > 1) {
                          _updateQuantity(item['cartId'], currentQty - 1);
                        }
                      },
                      child: Container(
                        padding: EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey[400]!),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Icon(Icons.remove, size: 18),
                      ),
                    ),

                    // Quantity Display
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        '${item['quantity'] ?? 1}',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),

                    // Increment Button
                    InkWell(
                      onTap: () {
                        int currentQty = item['quantity'] ?? 1;
                        _updateQuantity(item['cartId'], currentQty + 1);
                      },
                      child: Container(
                        padding: EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey[400]!),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Icon(Icons.add, size: 18),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Delete Icon
          IconButton(
            onPressed: () {
              _deleteItem(item['cartId']);
            },
            icon: Icon(Icons.delete_outline, color: Colors.red),
          ),
        ],
      ),
    );
  }

  Widget _buildSellerCard(String sellerName, List<Map<String, dynamic>> items) {
    double subtotal = _calculateSellerSubtotal(items);
    bool isSelected = selectedSellers[sellerName] ?? false;
    String sellerImage = items.isNotEmpty ? (items[0]['sellerProfileImage'] ?? '') : '';

    return Card(
      margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          // Seller Header
          ListTile(
            leading: CircleAvatar(
              radius: 25,
              backgroundImage: sellerImage.isNotEmpty
                  ? AssetImage(sellerImage)
                  : null,
              child: sellerImage.isEmpty
                  ? Icon(Icons.store, size: 25)
                  : null,
            ),
            title: Text(
              sellerName,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            subtitle: Text(
              '${items.length} item${items.length > 1 ? 's' : ''}',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[700],
              ),
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Checkbox(
                  value: isSelected,
                  onChanged: (value) {
                    setState(() {
                      selectedSellers[sellerName] = value ?? false;
                    });
                  },
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
                  activeColor: Color(0xFF388E3C),
                ),
              ],
            ),
          ),
          Divider(height: 1),

          // Products under this seller
          ...items.map((item) => _buildProductRow(item)),

          // Subtotal
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Subtotal',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                Text(
                  'RM ${subtotal.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF388E3C),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddressSection() {
    return Container(
      margin: EdgeInsets.all(16),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Shipping Address',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                icon: Icon(Icons.edit, color: Color(0xFF388E3C)),
                onPressed: () {
                  Navigator.pushNamed(context, '/edit_profile').then((_) {
                    _loadCartData(); // Reload after editing
                  });
                },
              ),
            ],
          ),
          SizedBox(height: 8),
          if (userAddress == null || userAddress!.isEmpty)
            Text(
              'No address found. Please add your address.',
              style: TextStyle(
                fontSize: 14,
                color: Colors.red[700],
              ),
            )
          else
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  userAddress!['line1'] ?? '',
                  style: TextStyle(fontSize: 14),
                ),
                if (userAddress!['line2'] != null && userAddress!['line2'].isNotEmpty)
                  Text(
                    userAddress!['line2'],
                    style: TextStyle(fontSize: 14),
                  ),
                Text(
                  '${userAddress!['city'] ?? ''}, ${userAddress!['postal'] ?? ''}',
                  style: TextStyle(fontSize: 14),
                ),
                Text(
                  userAddress!['state'] ?? '',
                  style: TextStyle(fontSize: 14),
                ),
              ],
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    double totalAmount = 0;
    selectedSellers.forEach((seller, isSelected) {
      if (isSelected && groupedCartItems.containsKey(seller)) {
        totalAmount += _calculateSellerSubtotal(groupedCartItems[seller]!);
      }
    });

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
          'Cart Items',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        centerTitle: true,
      ),
      body: isLoading
          ? Center(
              child: CircularProgressIndicator(color: Color(0xFF388E3C)),
            )
          : groupedCartItems.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image.asset(
                        'assets/images/icon/Empty Cart.png',
                        width: 200,
                        height: 200,
                        errorBuilder: (context, error, stackTrace) {
                          return Icon(
                            Icons.shopping_cart_outlined,
                            size: 100,
                            color: Colors.grey[400],
                          );
                        },
                      ),
                      SizedBox(height: 16),
                      Text(
                        'Your cart is empty',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[700],
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Add some items to get started',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        child: Column(
                          children: [
                            // Shipping Address
                            _buildAddressSection(),

                            // Cart items grouped by seller
                            ...groupedCartItems.entries.map((entry) {
                              return _buildSellerCard(entry.key, entry.value);
                            }),

                            SizedBox(height: 100), // Space for bottom bar
                          ],
                        ),
                      ),
                    ),

                    // Bottom checkout bar
                    Container(
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 10,
                            offset: Offset(0, -2),
                          ),
                        ],
                      ),
                      child: SafeArea(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Total',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                Text(
                                  'RM ${totalAmount.toStringAsFixed(2)}',
                                  style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF388E3C),
                                  ),
                                ),
                              ],
                            ),
                            ElevatedButton(
                              onPressed: _navigateToCheckout,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Color(0xFF388E3C),
                                padding: EdgeInsets.symmetric(
                                  horizontal: 32,
                                  vertical: 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 2,
                              ),
                              child: Text(
                                'CHECKOUT',
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