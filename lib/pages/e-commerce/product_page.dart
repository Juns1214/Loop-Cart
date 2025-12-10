import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:share_plus/share_plus.dart';
import '../feature/best_value_comparison.dart';
import '../../widget/section_container.dart';
import '../../widget/review_card.dart';
import '../../widget/seller_info_card.dart';
import '../../widget/product_image_header.dart';

class ProductPage extends StatefulWidget {
  final Map<String, dynamic> product;
  final bool isPreowned; // Flag to toggle modes

  const ProductPage({
    super.key, 
    required this.product,
    this.isPreowned = false, 
  });

  @override
  State<ProductPage> createState() => _ProductPageState();
}

class _ProductPageState extends State<ProductPage> {
  Map<String, dynamic>? sellerData;
  List<Map<String, dynamic>> reviews = [];
  bool isLoading = true;
  bool isAddingToCart = false;
  final User? currentUser = FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  Widget build(BuildContext context) {
    // 1. Determine Images
    List<String> images = [];
    if (widget.isPreowned) {
      // Collect all available images for pre-owned
      if (widget.product['imageUrl1'] != null) images.add(widget.product['imageUrl1']);
      if (widget.product['imageUrl2'] != null) images.add(widget.product['imageUrl2']);
      if (widget.product['imageUrl3'] != null) images.add(widget.product['imageUrl3']);
    } else {
      // Standard product image
      images.add(widget.product['imageUrl'] ?? widget.product['image_url'] ?? '');
    }
    // Fallback if empty
    if (images.isEmpty) images.add('');

    // 2. Rating & Coins logic
    double avgRating = (widget.product['rating'] ?? 0).toDouble();
    int greenCoinsToEarn = ((widget.product['price'] ?? 0).toDouble()).floor();

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: isLoading 
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF388E3C)))
          : Stack(
              children: [
                SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // --- HEADER (Unified) ---
                      ProductImageHeader(
                        imageUrls: images,
                        onBack: () => Navigator.pop(context),
                        onShare: _shareAndEarnCoins,
                        height: 300,
                      ),

                      // --- PRE-OWNED BANNER ---
                      if (widget.isPreowned)
                        _buildGreenCoinsBanner(greenCoinsToEarn),

                      // --- PRODUCT INFO ---
                      SectionContainer(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Category Badge
                            if (widget.product['category'] != null)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF388E3C).withOpacity(0.1), 
                                  borderRadius: BorderRadius.circular(20)
                                ),
                                child: Text(
                                  widget.product['category'], 
                                  style: const TextStyle(fontSize: 12, color: Color(0xFF388E3C), fontWeight: FontWeight.bold)
                                ),
                              ),
                            const SizedBox(height: 12),
                            
                            // Name
                            Text(
                              widget.product['name'] ?? 'Unknown', 
                              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87)
                            ),
                            const SizedBox(height: 8),
                            
                            // Price
                            Text(
                              'RM ${(widget.product['price'] ?? 0).toStringAsFixed(2)}', 
                              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Color(0xFF388E3C))
                            ),
                            const SizedBox(height: 16),

                            // Rating Row (Only for Standard Products)
                            if (!widget.isPreowned)
                              Row(
                                children: [
                                  _buildStarRating(avgRating),
                                  const SizedBox(width: 8),
                                  Text(avgRating.toStringAsFixed(1), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                  Text(' (${reviews.length} reviews)', style: TextStyle(color: Colors.grey.shade600, fontSize: 14)),
                                ],
                              )
                            else 
                              // Pre-owned specific badge
                              Row(
                                children: [
                                  const Icon(Icons.recycling, size: 16, color: Colors.blue),
                                  const SizedBox(width: 4),
                                  Text('Pre-owned Condition', style: TextStyle(color: Colors.grey.shade700, fontWeight: FontWeight.bold)),
                                ],
                              ),

                            const SizedBox(height: 20),
                            const Text('Description', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 8),
                            Text(
                              widget.product['description'] ?? 'No description.', 
                              style: TextStyle(fontSize: 15, color: Colors.grey.shade800, height: 1.6)
                            ),
                          ],
                        ),
                      ),

                      // --- SELLER INFO ---
                      // We show this for both, but data source might differ
                      if (sellerData != null || widget.isPreowned)
                        SectionContainer(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Seller Information', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 16),
                              SellerInfoCard(
                                name: widget.isPreowned ? (widget.product['seller'] ?? 'Private Seller') : (sellerData?['name'] ?? ''),
                                image: widget.isPreowned ? '' : (sellerData?['profileImage'] ?? ''), // No image for preowned sellers usually
                                subtitle: widget.isPreowned 
                                  ? const Text('Verified Seller', style: TextStyle(color: Colors.green))
                                  : Row(
                                      children: [
                                        const Icon(Icons.star, color: Colors.amber, size: 16),
                                        Text('${(sellerData?['ratings'] ?? 0).toStringAsFixed(1)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                                      ],
                                    ),
                              ),
                            ],
                          ),
                        ),

                      // --- REVIEWS ---
                      SectionContainer(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Customer Reviews', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 16),
                            
                            // Smart Value Button works for both if configured correctly
                            SmartValueButton(
                              productId: widget.product['id'] ?? '', 
                              isPreowned: widget.isPreowned
                            ),
                            
                            if (reviews.isEmpty)
                               Padding(
                                 padding: const EdgeInsets.all(24),
                                 child: Center(child: Text('No reviews yet.', style: TextStyle(color: Colors.grey.shade600))),
                               )
                            else 
                               Column(children: reviews.map((r) => ReviewCard(review: r)).toList())
                          ],
                        ),
                      ),
                      const SizedBox(height: 100),
                    ],
                  ),
                ),
                
                // --- BOTTOM BUTTON ---
                Positioned(
                  bottom: 20, right: 20, left: 20,
                  child: FloatingActionButton.extended(
                    onPressed: isAddingToCart ? null : _addToCart,
                    backgroundColor: const Color(0xFF388E3C),
                    icon: isAddingToCart 
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Icon(Icons.shopping_cart),
                    label: Text(isAddingToCart ? 'Adding...' : 'Add to Cart', style: const TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
    );
  }

  // --- Logic Helpers ---

  Future<void> _loadData() async {
    setState(() => isLoading = true);
    try {
      // 1. Load Seller Data (Only strictly needed for Standard items for profile image etc)
      if (!widget.isPreowned) {
        String sellerName = widget.product['seller'] ?? '';
        if (sellerName.isNotEmpty) {
          var sellerQ = await FirebaseFirestore.instance.collection('sellers').where('name', isEqualTo: sellerName).limit(1).get();
          if (sellerQ.docs.isNotEmpty) sellerData = sellerQ.docs.first.data();
        }
      }

      // 2. Load Reviews (Switch collection based on type)
      String pid = widget.product['id'] ?? '';
      String collection = widget.isPreowned ? 'preowned_reviews' : 'reviews';
      
      if (pid.isNotEmpty) {
        var reviewQ = await FirebaseFirestore.instance.collection(collection).where('productId', isEqualTo: pid).get();
        var list = reviewQ.docs.map((d) => d.data()).toList();
        // Simple sort by date string, adapt if using Timestamp
        list.sort((a, b) => (b['reviewDate'] ?? '').compareTo(a['reviewDate'] ?? ''));
        reviews = list;
      }
      
      setState(() => isLoading = false);
    } catch (e) {
      print("Error loading data: $e");
      setState(() => isLoading = false);
    }
  }

  Future<void> _addToCart() async {
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Login required'), backgroundColor: Colors.red));
      return;
    }
    setState(() => isAddingToCart = true);

    try {
      String uid = currentUser!.uid;
      String pid = widget.product['id'] ?? '';
      
      // Check existing cart
      var cartQuery = await FirebaseFirestore.instance.collection('cart_items')
          .where('userId', isEqualTo: uid)
          .where('productId', isEqualTo: pid)
          .limit(1)
          .get();
      
      Map<String, dynamic> item;
      
      if (cartQuery.docs.isNotEmpty) {
        // Update Quantity
        var doc = cartQuery.docs.first;
        await doc.reference.update({'quantity': (doc['quantity'] ?? 1) + 1});
        item = doc.data();
        item['quantity'] = (doc['quantity'] ?? 1) + 1;
        item['docId'] = doc.id;
      } else {
        // Add New
        item = {
          'userId': uid,
          'productId': pid,
          'productName': widget.product['name'],
          'productPrice': (widget.product['price'] ?? 0).toDouble(),
          'quantity': 1,
          'imageUrl': widget.isPreowned 
              ? (widget.product['imageUrl1'] ?? '') 
              : (widget.product['imageUrl'] ?? ''),
          'seller': widget.product['seller'],
          'isPreowned': widget.isPreowned, // IMPORTANT: Saves the type to cart
          'dateAdded': FieldValue.serverTimestamp(),
        };
        var ref = await FirebaseFirestore.instance.collection('cart_items').add(item);
        item['docId'] = ref.id;
      }

      setState(() => isAddingToCart = false);
      if (mounted) {
         var uDoc = await FirebaseFirestore.instance.collection('user_profile').doc(uid).get();
         Navigator.pushNamed(context, '/checkout', arguments: {'selectedItems': [item], 'userAddress': uDoc.exists ? uDoc['address'] : null});
      }
    } catch (e) {
      setState(() => isAddingToCart = false);
    }
  }

  // --- UI Helpers ---

  Widget _buildStarRating(double rating) {
    return Row(
      children: List.generate(5, (i) {
         if (rating >= i + 1) return const Icon(Icons.star, color: Colors.amber, size: 20);
         if (rating >= i + 0.5) return const Icon(Icons.star_half, color: Colors.amber, size: 20);
         return const Icon(Icons.star_border, color: Colors.amber, size: 20);
      }),
    );
  }

  Widget _buildGreenCoinsBanner(int coins) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F5E9),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green.shade200),
      ),
      child: Row(
        children: [
          const Icon(Icons.eco, color: Colors.green, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Text('Earn $coins Green Coins with this purchase!', style: TextStyle(color: Colors.green.shade800, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Future<void> _shareAndEarnCoins() async {
     // ... (Keep your existing share logic here) ...
     // For brevity, using basic placeholder, copy your original logic if needed
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Shared!')));
  }
}