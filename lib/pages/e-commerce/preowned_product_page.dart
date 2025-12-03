import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_application_1/utils/swiper.dart';

class PreownedProductPage extends StatefulWidget {
  final Map<String, dynamic> product;

  const PreownedProductPage({super.key, required this.product});

  @override
  State<PreownedProductPage> createState() => _PreownedProductPageState();
}

class _PreownedProductPageState extends State<PreownedProductPage> {
  bool isAddingToCart = false;
  final User? currentUser = FirebaseAuth.instance.currentUser;

  // Calculate Green Coins to earn
  int _calculateGreenCoinsToEarn() {
    double price = (widget.product['price'] ?? 0).toDouble();
    return price.floor(); // RM1 = 1 Green Coin
  }

  // Build image pages for swiper
  List<Widget> _buildImagePages() {
    List<Widget> pages = [];
    
    // Add imageUrl1
    if (widget.product['imageUrl1'] != null && 
        widget.product['imageUrl1'].isNotEmpty) {
      pages.add(_buildImageWidget(widget.product['imageUrl1']));
    }
    
    // Add imageUrl2
    if (widget.product['imageUrl2'] != null && 
        widget.product['imageUrl2'].isNotEmpty) {
      pages.add(_buildImageWidget(widget.product['imageUrl2']));
    }
    
    // Add imageUrl3
    if (widget.product['imageUrl3'] != null && 
        widget.product['imageUrl3'].isNotEmpty) {
      pages.add(_buildImageWidget(widget.product['imageUrl3']));
    }
    
    // If no images, show placeholder
    if (pages.isEmpty) {
      pages.add(
        Container(
          width: double.infinity,
          height: 350,
          color: Colors.grey.shade200,
          child: Center(
            child: Icon(
              Icons.image,
              size: 80,
              color: Colors.grey,
            ),
          ),
        ),
      );
    }
    
    return pages;
  }

  Widget _buildImageWidget(String imageUrl) {
    return Container(
      width: double.infinity,
      height: 350,
      color: Colors.white,
      child: Image.asset(
        imageUrl,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          return Center(
            child: Icon(
              Icons.image_not_supported,
              size: 60,
              color: Colors.grey,
            ),
          );
        },
      ),
    );
  }

  Future<void> _addToCart() async {
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please login to add items to cart'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      isAddingToCart = true;
    });

    try {
      String productId = widget.product['id'] ?? '';
      String userId = currentUser!.uid;

      // Check if product already exists in cart
      QuerySnapshot existingCart = await FirebaseFirestore.instance
          .collection('cart_items')
          .where('userId', isEqualTo: userId)
          .where('productId', isEqualTo: productId)
          .limit(1)
          .get();

      Map<String, dynamic> itemToCheckout;
      String itemDocId;

      if (existingCart.docs.isNotEmpty) {
        // Product exists, increase quantity
        DocumentSnapshot cartItem = existingCart.docs.first;
        int currentQuantity = cartItem['quantity'] ?? 1;
        int newQuantity = currentQuantity + 1;

        await FirebaseFirestore.instance
            .collection('cart_items')
            .doc(cartItem.id)
            .update({
              'quantity': newQuantity,
              'updatedAt': FieldValue.serverTimestamp(),
            });

        itemDocId = cartItem.id;

        // Get the updated item data
        Map<String, dynamic> itemData = cartItem.data() as Map<String, dynamic>;
        itemData['quantity'] = newQuantity; // Update with new quantity
        itemData['docId'] = itemDocId;
        itemToCheckout = itemData;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Quantity updated in cart!'),
            backgroundColor: Color(0xFF388E3C),
            duration: Duration(seconds: 1),
          ),
        );
      } else {
        // Add new item to cart
        Map<String, dynamic> newItem = {
          'userId': userId,
          'productId': productId,
          'productName': widget.product['name'] ?? 'Unknown',
          'productPrice': (widget.product['price'] ?? 0).toDouble(),
          'quantity': 1,
          'imageUrl': widget.product['imageUrl1'] ?? '',
          'seller': widget.product['seller'] ?? '',
          'sellerProfileImage': '',
          'category': widget.product['category'] ?? '',
          'isPreowned': true, // Mark as pre-owned
          'dateAdded': FieldValue.serverTimestamp(),
        };

        DocumentReference docRef = await FirebaseFirestore.instance
            .collection('cart_items')
            .add(newItem);

        itemDocId = docRef.id;
        newItem['docId'] = itemDocId;
        itemToCheckout = newItem;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Added to cart!'),
            backgroundColor: Color(0xFF388E3C),
            duration: Duration(seconds: 1),
          ),
        );
      }

      setState(() {
        isAddingToCart = false;
      });

      // Wait a moment for the snackbar to show
      await Future.delayed(Duration(milliseconds: 500));

      // Navigate to checkout with ONLY this item
      await _navigateToCheckout(itemToCheckout);
    } catch (e) {
      print('Error adding to cart: $e');
      setState(() {
        isAddingToCart = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to add to cart. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _navigateToCheckout(Map<String, dynamic> singleItem) async {
    if (currentUser == null) return;

    try {
      // Load user address
      Map<String, dynamic>? userAddress;
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('user_profile')
          .doc(currentUser!.uid)
          .get();

      if (userDoc.exists) {
        Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
        userAddress = userData['address'] as Map<String, dynamic>?;
      }

      // Navigate to checkout with only the single item
      Navigator.pushNamed(
        context,
        '/checkout',
        arguments: {
          'selectedItems': [singleItem], // Only pass the single item as a list
          'userAddress': userAddress,
        },
      );
    } catch (e) {
      print('Error navigating to checkout: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to load checkout. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> imagePages = _buildImagePages();
    int greenCoinsToEarn = _calculateGreenCoinsToEarn();

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: Stack(
        children: [
          // Main scrollable content
          SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Product Images with Swiper
                Stack(
                  children: [
                    Container(
                      height: 350,
                      color: Colors.white,
                      child: imagePages.length > 1
                          ? Swiper(
                              pages: imagePages,
                              height: 350,
                            )
                          : imagePages[0],
                    ),
                    
                    // Back button
                    SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 8,
                              ),
                            ],
                          ),
                          child: IconButton(
                            icon: Icon(Icons.arrow_back),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ),
                      ),
                    ),
                    
                    // Image counter (if multiple images)
                    if (imagePages.length > 1)
                      Positioned(
                        bottom: 16,
                        right: 16,
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.6),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '${imagePages.length} photos',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),

                // Green Coins Earning Banner
                Container(
                  margin: EdgeInsets.all(16),
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFFF0FDF4), Color(0xFFDCFCE7)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Color(0xFF388E3C).withOpacity(0.3),
                      width: 2,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Color(0xFF388E3C).withOpacity(0.2),
                              blurRadius: 8,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Image.asset(
                          'assets/images/icon/Green Coin.png',
                          width: 32,
                          height: 32,
                          errorBuilder: (context, error, stackTrace) {
                            return Icon(
                              Icons.eco,
                              color: Color(0xFF388E3C),
                              size: 32,
                            );
                          },
                        ),
                      ),
                      SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Earn Green Coins!',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF388E3C),
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Buy this pre-owned item and help the planet',
                              style: TextStyle(
                                fontSize: 13,
                                color: Color(0xFF388E3C).withOpacity(0.8),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Color(0xFF388E3C),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '+$greenCoinsToEarn',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Product Info Section
                Container(
                  color: Colors.white,
                  padding: EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Price
                      Text(
                        'RM ${(widget.product['price'] ?? 0).toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      SizedBox(height: 16),

                      // Product Name
                      Text(
                        widget.product['name'] ?? 'Unknown Product',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      SizedBox(height: 12),

                      // Category and Pre-owned badges
                      Row(
                        children: [
                          // Pre-owned badge
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Color(0xFF2E5BFF).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: Color(0xFF2E5BFF).withOpacity(0.3),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.recycling,
                                  size: 14,
                                  color: Color(0xFF2E5BFF),
                                ),
                                SizedBox(width: 4),
                                Text(
                                  'Pre-owned',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF2E5BFF),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          
                          // Category badge
                          if (widget.product['category'] != null &&
                              widget.product['category'].isNotEmpty) ...[
                            SizedBox(width: 8),
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Color(0xFF388E3C).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: Color(0xFF388E3C).withOpacity(0.3),
                                ),
                              ),
                              child: Text(
                                widget.product['category'],
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF388E3C),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 8),

                // Description Section
                Container(
                  color: Colors.white,
                  padding: EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Description',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 12),
                      Text(
                        widget.product['description'] ??
                            'No description available.',
                        style: TextStyle(
                          fontSize: 15,
                          color: Colors.grey.shade700,
                          height: 1.6,
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 8),

                // Seller Information Section
                Container(
                  color: Colors.white,
                  padding: EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Seller Information',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 16),
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 28,
                            backgroundColor: Color(0xFF388E3C).withOpacity(0.1),
                            child: Icon(
                              Icons.store,
                              color: Color(0xFF388E3C),
                              size: 28,
                            ),
                          ),
                          SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.product['seller'] ?? 'Unknown Seller',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'Pre-owned Seller',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 100),
              ],
            ),
          ),

          // Floating Add to Cart Button
          Positioned(
            bottom: 20,
            left: 20,
            right: 20,
            child: Container(
              decoration: BoxDecoration(
                boxShadow: [
                  BoxShadow(
                    color: Color(0xFF388E3C).withOpacity(0.3),
                    blurRadius: 20,
                    offset: Offset(0, 10),
                  ),
                ],
              ),
              child: ElevatedButton(
                onPressed: isAddingToCart ? null : _addToCart,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF388E3C),
                  padding: EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: isAddingToCart
                    ? SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.shopping_cart,
                            size: 24,
                          ),
                          SizedBox(width: 12),
                          Text(
                            'Add to Cart',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 17,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}