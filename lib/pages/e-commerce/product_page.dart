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
  final User? currentUser = FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    _loadProductDetails();
  }

  @override
  Widget build(BuildContext context) {
    double avgRating = (widget.product['rating'] ?? 0).toDouble();

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: isLoading 
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF388E3C)))
          : Stack(
              children: [
                SingleChildScrollView(
                  child: Column(
                    children: [
                      // 1. Header
                      ProductImageHeader(
                        imageUrls: [widget.product['imageUrl'] ?? widget.product['image_url'] ?? ''],
                        onBack: () => Navigator.pop(context),
                        onShare: _shareAndEarnCoins,
                        height: 300,
                      ),

                      // 2. Product Info
                      SectionContainer(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (widget.product['category'] != null)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(color: const Color(0xFF388E3C).withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
                                child: Text(widget.product['category'], style: const TextStyle(fontSize: 12, color: Color(0xFF388E3C), fontWeight: FontWeight.bold)),
                              ),
                            const SizedBox(height: 12),
                            Text(widget.product['name'] ?? 'Unknown', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87)),
                            const SizedBox(height: 8),
                            Text('RM ${(widget.product['price'] ?? 0).toStringAsFixed(2)}', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Color(0xFF388E3C))),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                _buildStarRating(avgRating),
                                const SizedBox(width: 8),
                                Text(avgRating.toStringAsFixed(1), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                Text(' (${reviews.length} reviews)', style: TextStyle(color: Colors.grey.shade600, fontSize: 14)),
                              ],
                            ),
                            const SizedBox(height: 20),
                            const Text('Description', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 8),
                            Text(widget.product['description'] ?? 'No description.', style: TextStyle(fontSize: 15, color: Colors.grey.shade800, height: 1.6)),
                          ],
                        ),
                      ),

                      // 3. Seller Info
                      if (sellerData != null)
                        SectionContainer(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Seller Information', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 16),
                              SellerInfoCard(
                                name: sellerData!['name'] ?? '',
                                image: sellerData!['profileImage'] ?? '',
                                subtitle: Row(
                                  children: [
                                    const Icon(Icons.star, color: Colors.amber, size: 16),
                                    const SizedBox(width: 4),
                                    Text('${(sellerData!['ratings'] ?? 0).toStringAsFixed(1)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                                    const SizedBox(width: 12),
                                    Text('Items: $sellerItemCount', style: TextStyle(color: Colors.grey.shade600)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                      // 4. Reviews
                      SectionContainer(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Customer Reviews', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 16),
                            
                            SmartValueButton(productId: widget.product['id'] ?? '', isPreowned: false),
                            
                            if (reviews.isEmpty)
                               Padding(
                                 padding: const EdgeInsets.all(24),
                                 child: Center(child: Text('No reviews yet. Be the first!', style: TextStyle(color: Colors.grey.shade600))),
                               )
                            else ...[
                              if (showAllReviews)
                                ...reviews.map((r) => ReviewCard(review: r))
                              else
                                ReviewCard(review: reviews.first),
                              
                              if (reviews.length > 1 && !showAllReviews)
                                Center(
                                  child: TextButton(
                                    onPressed: () => setState(() => showAllReviews = true),
                                    child: const Text('View All Reviews', style: TextStyle(color: Color(0xFF388E3C), fontWeight: FontWeight.bold)),
                                  ),
                                )
                            ]
                          ],
                        ),
                      ),
                      const SizedBox(height: 100),
                    ],
                  ),
                ),
                Positioned(
                  bottom: 20, right: 20,
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

  // --- Helpers & Logic ---

  Widget _buildStarRating(double rating) {
    return Row(
      children: List.generate(5, (i) {
         if (rating >= i + 1) return const Icon(Icons.star, color: Colors.amber, size: 20);
         if (rating >= i + 0.5) return const Icon(Icons.star_half, color: Colors.amber, size: 20);
         return const Icon(Icons.star_border, color: Colors.amber, size: 20);
      }),
    );
  }

  Future<void> _loadProductDetails() async {
    setState(() => isLoading = true);
    try {
      String sellerName = widget.product['seller'] ?? '';
      if (sellerName.isNotEmpty) {
        var sellerQ = await FirebaseFirestore.instance.collection('sellers').where('name', isEqualTo: sellerName).limit(1).get();
        if (sellerQ.docs.isNotEmpty) sellerData = sellerQ.docs.first.data();
        
        var countQ = await FirebaseFirestore.instance.collection('products').where('seller', isEqualTo: sellerName).get();
        sellerItemCount = countQ.docs.length;
      }

      String pid = widget.product['id'] ?? '';
      if (pid.isNotEmpty) {
        var reviewQ = await FirebaseFirestore.instance.collection('reviews').where('productId', isEqualTo: pid).get();
        var list = reviewQ.docs.map((d) => d.data()).toList();
        list.sort((a, b) => (b['reviewDate'] ?? '').compareTo(a['reviewDate'] ?? ''));
        reviews = list;
      }
      
      setState(() => isLoading = false);
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  Future<void> _shareAndEarnCoins() async {
     if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Login to earn coins!'), backgroundColor: Colors.red));
      return;
    }
    await SharePlus.instance.share(ShareParams(
        text: 'Check out ${widget.product['name']}!',
        subject: 'Eco-friendly find!',
    ));
    await FirebaseFirestore.instance.collection('user_profile').doc(currentUser!.uid).update({'greenCoins': FieldValue.increment(5)});
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Shared! You earned 5 coins!'), backgroundColor: Color(0xFF388E3C)));
  }

  Future<void> _addToCart() async {
    // Similar logic to Preowned, but sets isPreowned: false and checks 'products' collection logic
    if (currentUser == null) return;
    setState(() => isAddingToCart = true);

    try {
      String uid = currentUser!.uid;
      String pid = widget.product['id'] ?? '';
      var cartQuery = await FirebaseFirestore.instance.collection('cart_items').where('userId', isEqualTo: uid).where('productId', isEqualTo: pid).limit(1).get();
      
      Map<String, dynamic> item;
      
      if (cartQuery.docs.isNotEmpty) {
        var doc = cartQuery.docs.first;
        await doc.reference.update({'quantity': (doc['quantity'] ?? 1) + 1});
        item = doc.data();
        item['quantity'] = (doc['quantity'] ?? 1) + 1;
        item['docId'] = doc.id;
      } else {
        item = {
          'userId': uid,
          'productId': pid,
          'productName': widget.product['name'],
          'productPrice': (widget.product['price'] ?? 0).toDouble(),
          'quantity': 1,
          'imageUrl': widget.product['imageUrl'] ?? '',
          'seller': widget.product['seller'],
          'isPreowned': false,
          'dateAdded': FieldValue.serverTimestamp(),
        };
        var ref = await FirebaseFirestore.instance.collection('cart_items').add(item);
        item['docId'] = ref.id;
      }

      setState(() => isAddingToCart = false);
      if (mounted) {
         // Fetch user address to pass
         var uDoc = await FirebaseFirestore.instance.collection('user_profile').doc(uid).get();
         Navigator.pushNamed(context, '/checkout', arguments: {'selectedItems': [item], 'userAddress': uDoc.exists ? uDoc['address'] : null});
      }
    } catch (e) {
      setState(() => isAddingToCart = false);
    }
  }
}