// lib/pages/product_page.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../feature/best_value_comparison.dart';
import 'package:share_plus/share_plus.dart';

class ProductPage extends StatefulWidget {
  final Map<String, dynamic> product;

  const ProductPage({super.key, required this.product});

  @override
  State<ProductPage> createState() => _ProductPageState();
}

class _ProductPageState extends State<ProductPage> {
  Map<String, dynamic>? sellerData;
  List<Map<String, dynamic>> reviews = [];
  int sellerItemCount = 0;
  bool isLoading = true;
  bool showAllReviews = false;
  bool isAddingToCart = false;

  // Honest Assessment state
  Map<String, dynamic>? honestAssessment;
  bool isLoadingAssessment = true;

  final User? currentUser = FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    _loadProductDetails();
  }

  // UPDATED: Load product details including reviews from 'reviews' collection
  Future<void> _loadProductDetails() async {
    setState(() {
      isLoading = true;
    });

    try {
      // Fetch seller information
      String sellerName = widget.product['seller'] ?? '';
      if (sellerName.isNotEmpty) {
        QuerySnapshot sellerSnapshot = await FirebaseFirestore.instance
            .collection('sellers')
            .where('name', isEqualTo: sellerName)
            .limit(1)
            .get();

        if (sellerSnapshot.docs.isNotEmpty) {
          sellerData = sellerSnapshot.docs.first.data() as Map<String, dynamic>;
        }

        // Count seller's total items
        QuerySnapshot productCount = await FirebaseFirestore.instance
            .collection('products')
            .where('seller', isEqualTo: sellerName)
            .get();
        sellerItemCount = productCount.docs.length;
      }

      // Fetch reviews from 'reviews' collection with new structure
      String productId = widget.product['id'] ?? '';
      if (productId.isNotEmpty) {
        QuerySnapshot reviewSnapshot = await FirebaseFirestore.instance
            .collection('reviews')
            .where('productId', isEqualTo: productId)
            .get();

        List<Map<String, dynamic>> loadedReviews = reviewSnapshot.docs.map((
          doc,
        ) {
          Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

          // Ensure all required fields exist with new structure
          return {
            'reviewId': data['reviewId'] ?? doc.id,
            'productId': data['productId'] ?? '',
            'rating': data['rating'] ?? 0,
            'reviewTitle': data['reviewTitle'] ?? '',
            'reviewText': data['reviewText'] ?? '',
            'userName': data['userName'] ?? 'Anonymous',
            'userProfileUrl': data['userProfileUrl'] ?? '',
            'reviewDate': data['reviewDate'] ?? '',
          };
        }).toList();

        // Sort by date (newest first)
        loadedReviews.sort((a, b) {
          String dateA = a['reviewDate'] ?? '';
          String dateB = b['reviewDate'] ?? '';
          return dateB.compareTo(dateA);
        });

        reviews = loadedReviews;
      }

      setState(() {
        isLoading = false;
      });
    } catch (e) {
      print('Error loading product details: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _shareAndEarnCoins() async {
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please login to earn Green Coins for sharing!'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      // 1. Trigger Native Share
      String productName = widget.product['name'] ?? 'Product';
      double price = (widget.product['price'] ?? 0).toDouble();

      final shareParams = ShareParams(
        text:
            'Check out $productName for RM ${price.toStringAsFixed(2)} on our App!',
        subject: 'Check out this eco-friendly find!',
      );

      await SharePlus.instance.share(shareParams);
      // 2. Update Firestore Green Coins
      await FirebaseFirestore.instance
          .collection('user_profile')
          .doc(currentUser!.uid)
          .update({'greenCoins': FieldValue.increment(5)});

      // 3. Show Success Message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.monetization_on, color: Colors.white),
                SizedBox(width: 10),
                Expanded(child: Text('Shared! You earned 5 Green Coins!')),
              ],
            ),
            backgroundColor: Color(0xFF388E3C),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } catch (e) {
      print('Error sharing: $e');
    }
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
        itemData['quantity'] = newQuantity;
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
          'imageUrl':
              widget.product['imageUrl'] ?? widget.product['image_url'] ?? '',
          'seller': widget.product['seller'] ?? '',
          'sellerProfileImage': sellerData?['profileImage'] ?? '',
          'category': widget.product['category'] ?? '',
          'isPreowned': false, // Regular products are not pre-owned
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
          'selectedItems': [singleItem],
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

  // Build star rating widget
  Widget _buildStarRating(double rating) {
    List<Widget> stars = [];
    for (int i = 1; i <= 5; i++) {
      if (rating >= i) {
        stars.add(Icon(Icons.star, color: Colors.amber, size: 18));
      } else if (rating >= i - 0.5) {
        stars.add(Icon(Icons.star_half, color: Colors.amber, size: 18));
      } else {
        stars.add(Icon(Icons.star_border, color: Colors.amber, size: 18));
      }
    }
    return Row(children: stars);
  }

  // UPDATED: Build review card with new structure
  Widget _buildReviewCard(Map<String, dynamic> review) {
    double rating = (review['rating'] ?? 0).toDouble();
    String reviewTitle = review['reviewTitle'] ?? '';
    String reviewText = review['reviewText'] ?? '';
    String userName = review['userName'] ?? 'Anonymous';
    String userProfileUrl = review['userProfileUrl'] ?? '';
    String reviewDate = review['reviewDate'] ?? '';

    // Format date from ISO string
    String formattedDate = '';
    if (reviewDate.isNotEmpty) {
      try {
        DateTime date = DateTime.parse(reviewDate);
        formattedDate = DateFormat('MMM dd, yyyy').format(date);
      } catch (e) {
        formattedDate = reviewDate;
      }
    }

    return Container(
      margin: EdgeInsets.only(bottom: 16),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: Color(0xFF388E3C).withOpacity(0.1),
                backgroundImage: userProfileUrl.isNotEmpty
                    ? AssetImage(userProfileUrl)
                    : null,
                child: userProfileUrl.isEmpty
                    ? Icon(Icons.person, color: Color(0xFF388E3C), size: 20)
                    : null,
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            userName,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        SizedBox(width: 8),
                        // Verified Buyer Badge
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Color(0xFF388E3C).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.verified,
                                size: 10,
                                color: Color(0xFF388E3C),
                              ),
                              SizedBox(width: 2),
                              Text(
                                'Verified',
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF388E3C),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 2),
                    Row(
                      children: [
                        // Rating stars
                        Row(
                          children: List.generate(5, (index) {
                            return Icon(
                              index < rating ? Icons.star : Icons.star_border,
                              color: Colors.amber,
                              size: 16,
                            );
                          }),
                        ),
                        if (formattedDate.isNotEmpty) ...[
                          SizedBox(width: 8),
                          Text(
                            '• $formattedDate',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),

          if (reviewTitle.isNotEmpty) ...[
            SizedBox(height: 12),
            Text(
              reviewTitle,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ],

          if (reviewText.isNotEmpty) ...[
            SizedBox(height: 8),
            Text(
              reviewText,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade700,
                height: 1.5,
              ),
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    double avgRating = widget.product['rating']?.toDouble() ?? 0.0;

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: isLoading
          ? Center(child: CircularProgressIndicator(color: Color(0xFF388E3C)))
          : Stack(
              children: [
                // Main scrollable content
                SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Product Image
                      Stack(
                        children: [
                          Container(
                            width: double.infinity,
                            height: 300,
                            color: Colors.white,
                            child:
                                widget.product['imageUrl'] != null &&
                                    widget.product['imageUrl'].isNotEmpty
                                ? Image.asset(
                                    widget.product['imageUrl'],
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Center(
                                        child: Icon(
                                          Icons.image_not_supported,
                                          size: 60,
                                          color: Colors.grey,
                                        ),
                                      );
                                    },
                                  )
                                : Center(
                                    child: Icon(
                                      Icons.image,
                                      size: 60,
                                      color: Colors.grey,
                                    ),
                                  ),
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
                          Positioned(
                            top: 16,
                            right: 16,
                            child: SafeArea(
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
                                  icon: Icon(
                                    Icons.share,
                                    color: Color(0xFF388E3C),
                                  ),
                                  tooltip: 'Share & Earn 5 Coins',
                                  onPressed: _shareAndEarnCoins,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),

                      // Product Info Section
                      Container(
                        color: Colors.white,
                        padding: EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Category badge
                            if (widget.product['category'] != null &&
                                widget.product['category'].isNotEmpty)
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: Color(0xFF388E3C).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(20),
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
                            SizedBox(height: 12),

                            // Product Name
                            Text(
                              widget.product['name'] ?? 'Unknown Product',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 12),

                            // Price
                            Text(
                              'RM ${(widget.product['price'] ?? 0).toStringAsFixed(2)}',
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF388E3C),
                              ),
                            ),
                            SizedBox(height: 16),

                            // Rating summary
                            Row(
                              children: [
                                _buildStarRating(avgRating),
                                SizedBox(width: 8),
                                Text(
                                  '${avgRating.toStringAsFixed(1)}/5',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Text(
                                  ' (${reviews.length} reviews)',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 16),

                            // Description
                            Text(
                              'Description',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              widget.product['description'] ??
                                  'No description available.',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade700,
                                height: 1.5,
                              ),
                            ),
                          ],
                        ),
                      ),

                      SizedBox(height: 8),

                      // Seller Information Section
                      if (sellerData != null)
                        Container(
                          color: Colors.white,
                          padding: EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Seller Information',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 16),
                              Row(
                                children: [
                                  CircleAvatar(
                                    radius: 30,
                                    backgroundImage:
                                        sellerData!['profileImage'] != null &&
                                            sellerData!['profileImage']
                                                .isNotEmpty
                                        ? AssetImage(
                                            sellerData!['profileImage'],
                                          )
                                        : null,
                                    child:
                                        sellerData!['profileImage'] == null ||
                                            sellerData!['profileImage'].isEmpty
                                        ? Icon(Icons.store, size: 30)
                                        : null,
                                  ),
                                  SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          sellerData!['name'] ??
                                              'Unknown Seller',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        SizedBox(height: 4),
                                        Row(
                                          children: [
                                            Icon(
                                              Icons.star,
                                              color: Colors.amber,
                                              size: 16,
                                            ),
                                            SizedBox(width: 4),
                                            Text(
                                              '${(sellerData!['ratings'] ?? 0).toStringAsFixed(1)}',
                                              style: TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                            SizedBox(width: 12),
                                            Text(
                                              'Items: $sellerItemCount',
                                              style: TextStyle(
                                                fontSize: 13,
                                                color: Colors.grey.shade600,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                      SizedBox(height: 8),

                      // Reviews Section
                      Container(
                        color: Colors.white,
                        padding: EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Customer Reviews',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                if (reviews.isNotEmpty)
                                  Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Color(0xFF388E3C).withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      '${reviews.length} reviews',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Color(0xFF388E3C),
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            SizedBox(height: 16),

                            // Honest Assessment Widget
                            SmartValueButton(
                              productId: widget.product['id'] ?? '',
                              isPreowned: false,
                            ),

                            // Reviews List
                            if (reviews.isEmpty)
                              Center(
                                child: Padding(
                                  padding: const EdgeInsets.all(32.0),
                                  child: Column(
                                    children: [
                                      Icon(
                                        Icons.rate_review_outlined,
                                        size: 60,
                                        color: Colors.grey.shade400,
                                      ),
                                      SizedBox(height: 12),
                                      Text(
                                        'No reviews yet',
                                        style: TextStyle(
                                          fontSize: 16,
                                          color: Colors.grey.shade600,
                                        ),
                                      ),
                                      SizedBox(height: 4),
                                      Text(
                                        'Be the first to review this product',
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: Colors.grey.shade500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              )
                            else if (showAllReviews)
                              Column(
                                children: reviews
                                    .map((review) => _buildReviewCard(review))
                                    .toList(),
                              )
                            else
                              _buildReviewCard(reviews[0]),

                            if (reviews.length > 1 && !showAllReviews)
                              Center(
                                child: TextButton(
                                  onPressed: () {
                                    setState(() {
                                      showAllReviews = true;
                                    });
                                  },
                                  style: TextButton.styleFrom(
                                    backgroundColor: Color(
                                      0xFF388E3C,
                                    ).withOpacity(0.1),
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 24,
                                      vertical: 12,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  child: Text(
                                    'View All Reviews (${reviews.length})',
                                    style: TextStyle(
                                      color: Color(0xFF388E3C),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
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
                  right: 20,
                  child: FloatingActionButton.extended(
                    onPressed: isAddingToCart ? null : _addToCart,
                    backgroundColor: Color(0xFF388E3C),
                    icon: isAddingToCart
                        ? SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : Icon(Icons.shopping_cart),
                    label: Text(
                      isAddingToCart ? 'Adding...' : 'Add to Cart',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                    elevation: 4,
                  ),
                ),
              ],
            ),
    );
  }
}
