import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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

  @override
  void initState() {
    super.initState();
    _loadProductDetails();
  }

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

      // Fetch reviews for this product
      String productId = widget.product['id'] ?? '';
      if (productId.isNotEmpty) {
        QuerySnapshot reviewSnapshot = await FirebaseFirestore.instance
            .collection('reviews')
            .where('productId', isEqualTo: productId)
            .get();

        reviews = reviewSnapshot.docs
            .map((doc) => doc.data() as Map<String, dynamic>)
            .toList();
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

  // Build review card
  Widget _buildReviewCard(Map<String, dynamic> review) {
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
              // User profile picture
              CircleAvatar(
                radius: 20,
                backgroundImage:
                    review['userProfileUrl'] != null &&
                        review['userProfileUrl'].isNotEmpty
                    ? AssetImage(review['userProfileUrl'])
                    : null,
                child:
                    review['userProfileUrl'] == null ||
                        review['userProfileUrl'].isEmpty
                    ? Icon(Icons.person, size: 20)
                    : null,
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      review['userName'] ?? 'Anonymous',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 2),
                    _buildStarRating((review['rating'] ?? 0).toDouble()),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          if (review['reviewTitle'] != null && review['reviewTitle'].isNotEmpty)
            Text(
              review['reviewTitle'],
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
          SizedBox(height: 4),
          if (review['reviewText'] != null && review['reviewText'].isNotEmpty)
            Text(
              review['reviewText'],
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade700,
                height: 1.4,
              ),
            ),
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
                                  // Seller profile image
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
                            Text(
                              'Rating & Reviews',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 16),

                            // Display reviews
                            if (reviews.isEmpty)
                              Center(
                                child: Padding(
                                  padding: const EdgeInsets.all(20.0),
                                  child: Text(
                                    'No reviews yet',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ),
                              )
                            else if (showAllReviews)
                              // Show all reviews
                              Column(
                                children: reviews
                                    .map((review) => _buildReviewCard(review))
                                    .toList(),
                              )
                            else
                              // Show only first review
                              _buildReviewCard(reviews[0]),

                            // View All Reviews button
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

                      // Bottom padding for floating button
                      SizedBox(height: 100),
                    ],
                  ),
                ),

                // Floating Add to Cart Button (Bottom Right)
                Positioned(
                  bottom: 20,
                  right: 20,
                  child: FloatingActionButton.extended(
                    onPressed: () {
                      // Add to cart functionality
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Added to cart!'),
                          backgroundColor: Color(0xFF388E3C),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    },
                    backgroundColor: Color(0xFF388E3C),
                    icon: Icon(Icons.shopping_cart),
                    label: Text(
                      'Add to Cart',
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
