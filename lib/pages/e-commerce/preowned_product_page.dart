import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:share_plus/share_plus.dart';
import '../feature/best_value_comparison.dart';
import '../../widget/section_container.dart';
import '../../widget/review_card.dart';
import '../../widget/seller_info_card.dart';
import '../../widget/product_image_header.dart';

class PreownedProductPage extends StatefulWidget {
  final Map<String, dynamic> product;
  const PreownedProductPage({super.key, required this.product});

  @override
  State<PreownedProductPage> createState() => _PreownedProductPageState();
}

class _PreownedProductPageState extends State<PreownedProductPage> {
  bool isAddingToCart = false;
  final User? currentUser = FirebaseAuth.instance.currentUser;
  
  // Reviews state
  List<Map<String, dynamic>> reviews = [];
  bool isLoadingReviews = true;

  @override
  void initState() {
    super.initState();
    _loadReviews();
  }

  @override
  Widget build(BuildContext context) {
    int greenCoinsToEarn = ((widget.product['price'] ?? 0).toDouble()).floor();
    List<String> images = [
      widget.product['imageUrl1'],
      widget.product['imageUrl2'],
      widget.product['imageUrl3']
    ].whereType<String>().toList();

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Header with Swiper
                ProductImageHeader(
                  imageUrls: images,
                  onBack: () => Navigator.pop(context),
                  onShare: _shareAndEarnCoins,
                ),

                // 2. Green Coins Banner (Specific to Preowned)
                _buildGreenCoinsBanner(greenCoinsToEarn),

                // 3. Product Info
                SectionContainer(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'RM ${(widget.product['price'] ?? 0).toStringAsFixed(2)}',
                        style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: Color(0xFF1B5E20)),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        widget.product['name'] ?? 'Unknown Product',
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          _buildBadge(
                            icon: Icons.recycling, 
                            text: 'Pre-owned', 
                            color: const Color(0xFF2E5BFF)
                          ),
                          if (widget.product['category'] != null) ...[
                            const SizedBox(width: 8),
                            _buildBadge(text: widget.product['category'], color: const Color(0xFF388E3C)),
                          ]
                        ],
                      ),
                    ],
                  ),
                ),

                // 4. Description
                SectionContainer(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Description', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 12),
                      Text(
                        widget.product['description'] ?? 'No description available.',
                        style: TextStyle(fontSize: 16, color: Colors.grey.shade800, height: 1.6),
                      ),
                    ],
                  ),
                ),

                // 5. Seller Info
                SectionContainer(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Seller Information', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 16),
                      SellerInfoCard(
                        name: widget.product['seller'] ?? 'Unknown Seller',
                        image: '', // Preowned usually doesn't have seller image in product data
                        subtitle: Text(
                          'Pre-owned Seller',
                          style: TextStyle(fontSize: 14, color: Colors.grey.shade600, fontWeight: FontWeight.w500),
                        ),
                      ),
                    ],
                  ),
                ),

                // 6. Reviews & Assessment
                SectionContainer(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Customer Reviews', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          if (!isLoadingReviews && reviews.isNotEmpty)
                            _buildBadge(text: '${reviews.length} reviews', color: const Color(0xFF388E3C)),
                        ],
                      ),
                      const SizedBox(height: 16),
                      
                      SmartValueButton(productId: widget.product['id'] ?? '', isPreowned: true),
                      
                      if (isLoadingReviews)
                        const Center(child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator(color: Color(0xFF388E3C))))
                      else if (reviews.isEmpty)
                        _buildEmptyReviewState()
                      else
                        Column(children: reviews.map((r) => ReviewCard(review: r)).toList()),
                    ],
                  ),
                ),
                const SizedBox(height: 100), // Space for FAB
              ],
            ),
          ),
          
          // FAB
          Positioned(
            bottom: 20, left: 20, right: 20,
            child: _buildAddToCartButton(),
          ),
        ],
      ),
    );
  }

  // --- Widgets ---
  
  Widget _buildGreenCoinsBanner(int coins) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFFF0FDF4), Color(0xFFDCFCE7)]),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF388E3C).withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
            child: const Icon(Icons.eco, color: Color(0xFF388E3C), size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Earn Green Coins!', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF388E3C))),
                Text('Buy this to help the planet', style: TextStyle(fontSize: 13, color: const Color(0xFF388E3C).withOpacity(0.8))),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(color: const Color(0xFF388E3C), borderRadius: BorderRadius.circular(20)),
            child: Text('+$coins', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildBadge({IconData? icon, required String text, required Color color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[Icon(icon, size: 14, color: color), const SizedBox(width: 4)],
          Text(text, style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildEmptyReviewState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          children: [
            Icon(Icons.rate_review_outlined, size: 60, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            Text('No reviews yet', style: TextStyle(fontSize: 16, color: Colors.grey.shade600)),
          ],
        ),
      ),
    );
  }

  Widget _buildAddToCartButton() {
    return Container(
      decoration: BoxDecoration(
        boxShadow: [BoxShadow(color: const Color(0xFF388E3C).withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 10))],
      ),
      child: ElevatedButton(
        onPressed: isAddingToCart ? null : _addToCart,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF388E3C),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: isAddingToCart
            ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
            : const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [Icon(Icons.shopping_cart, size: 24), SizedBox(width: 12), Text('Add to Cart', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17))],
              ),
      ),
    );
  }

  // --- Logic Methods (Identical to original but cleaned) ---

  Future<void> _shareAndEarnCoins() async {
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please login to earn Green Coins!'), backgroundColor: Colors.red));
      return;
    }
    try {
      double price = (widget.product['price'] ?? 0).toDouble();
      await SharePlus.instance.share(ShareParams(
        text: 'Check out ${widget.product['name']} for RM ${price.toStringAsFixed(2)}!',
        subject: 'Eco-friendly find!',
      ));
      await FirebaseFirestore.instance.collection('user_profile').doc(currentUser!.uid).update({'greenCoins': FieldValue.increment(5)});
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Shared! You earned 5 Green Coins!'), backgroundColor: Color(0xFF388E3C)));
    } catch (e) {
      print('Error: $e');
    }
  }

  Future<void> _loadReviews() async {
    setState(() => isLoadingReviews = true);
    try {
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('preowned_reviews')
          .where('productId', isEqualTo: widget.product['id'])
          .get();
      
      var loaded = snapshot.docs.map((d) => d.data() as Map<String, dynamic>).toList();
      loaded.sort((a, b) => (b['reviewDate'] ?? '').compareTo(a['reviewDate'] ?? ''));
      
      setState(() {
        reviews = loaded;
        isLoadingReviews = false;
      });
    } catch (e) {
      setState(() => isLoadingReviews = false);
    }
  }

  Future<void> _addToCart() async {
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please login to add items.'), backgroundColor: Colors.red));
      return;
    }
    setState(() => isAddingToCart = true);

    try {
      String uid = currentUser!.uid;
      String pid = widget.product['id'] ?? '';
      
      var cartQuery = await FirebaseFirestore.instance.collection('cart_items')
          .where('userId', isEqualTo: uid).where('productId', isEqualTo: pid).limit(1).get();

      Map<String, dynamic> checkoutItem;

      if (cartQuery.docs.isNotEmpty) {
        var doc = cartQuery.docs.first;
        int newQty = (doc['quantity'] ?? 1) + 1;
        await doc.reference.update({'quantity': newQty, 'updatedAt': FieldValue.serverTimestamp()});
        checkoutItem = doc.data();
        checkoutItem['quantity'] = newQty;
        checkoutItem['docId'] = doc.id;
      } else {
        var newItem = {
          'userId': uid,
          'productId': pid,
          'productName': widget.product['name'] ?? 'Unknown',
          'productPrice': (widget.product['price'] ?? 0).toDouble(),
          'quantity': 1,
          'imageUrl': widget.product['imageUrl1'] ?? '',
          'seller': widget.product['seller'] ?? '',
          'category': widget.product['category'] ?? '',
          'isPreowned': true,
          'dateAdded': FieldValue.serverTimestamp(),
        };
        var ref = await FirebaseFirestore.instance.collection('cart_items').add(newItem);
        checkoutItem = newItem;
        checkoutItem['docId'] = ref.id;
      }

      setState(() => isAddingToCart = false);
      
      if (mounted) {
         // Fetch user address
        var userDoc = await FirebaseFirestore.instance.collection('user_profile').doc(uid).get();
        Map<String, dynamic>? address = userDoc.exists ? (userDoc.data() as Map<String, dynamic>)['address'] : null;

        Navigator.pushNamed(context, '/checkout', arguments: {
          'selectedItems': [checkoutItem],
          'userAddress': address,
        });
      }
    } catch (e) {
      setState(() => isAddingToCart = false);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to add to cart'), backgroundColor: Colors.red));
    }
  }
}