import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../feature/best_value_comparison.dart';
import '../../utils/share_product.dart';
import '../../utils/product_page_logic.dart';
import '../../utils/swiper.dart';

class ProductPage extends StatefulWidget {
  final Map<String, dynamic> product;
  final bool isPreowned;

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
    final productData = ProductPageLogic.extractProductData(widget.product);
    final images = ProductPageLogic.getProductImages(widget.product, widget.isPreowned);
    final greenCoinsToEarn = ProductPageLogic.calculateGreenCoins(productData['price']);

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF388E3C)),
            )
          : Stack(
              children: [
                SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Image header (inlined)
                      _buildImageHeader(images),

                      // Green coins banner
                      if (widget.isPreowned) 
                        _buildGreenCoinsBanner(greenCoinsToEarn),

                      // Product info
                      _buildSection(
                        child: _buildProductInfo(productData),
                      ),

                      // Seller info
                      _buildSection(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Seller Information',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            _buildSellerInfo(),
                          ],
                        ),
                      ),

                      // Reviews
                      _buildSection(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Customer Reviews',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            SmartValueButton(
                              productId: productData['id'],
                              isPreowned: widget.isPreowned,
                            ),
                            if (reviews.isEmpty)
                              const Padding(
                                padding: EdgeInsets.all(24),
                                child: Center(
                                  child: Text(
                                    'No reviews yet.',
                                    style: TextStyle(color: Colors.black),
                                  ),
                                ),
                              )
                            else
                              Column(
                                children: reviews
                                    .map((r) => _buildReviewCard(r))
                                    .toList(),
                              ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 100),
                    ],
                  ),
                ),

                // Add to cart button
                _buildAddToCartButton(),
              ],
            ),
    );
  }


  Future<void> _loadData() async {
    setState(() => isLoading = true);

    final data = await ProductPageLogic.loadProductData(
      product: widget.product,
      isPreowned: widget.isPreowned,
    );

    setState(() {
      sellerData = data['sellerData'];
      reviews = data['reviews'];
      isLoading = false;
    });
  }

  Future<void> _handleShare() async {
    await ProductShareHandler.shareProduct(
      context: context,
      product: widget.product,
      isPreowned: widget.isPreowned,
    );
  }

  Future<void> _addToCart() async {
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Login required'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => isAddingToCart = true);

    final result = await ProductPageLogic.addToCart(
      product: widget.product,
      isPreowned: widget.isPreowned,
      currentUser: currentUser!,
    );

    setState(() => isAddingToCart = false);

    if (result != null && mounted) {
      Navigator.pushNamed(
        context,
        '/checkout',
        arguments: {
          'selectedItems': [result['cartItem']],
          'userAddress': result['userAddress'],
        },
      );
    }
  }


  Widget _buildImageHeader(List<String> imageUrls) {
    final validImages = imageUrls.where((url) => url.isNotEmpty).toList();
    final imageWidgets = validImages.isEmpty
        ? [_buildImagePlaceholder()]
        : validImages.map((url) => _buildProductImage(url)).toList();

    return Stack(
      children: [
        // Image swiper or single image
        Container(
          height: 300,
          color: Colors.white,
          child: imageWidgets.length > 1
              ? Swiper(pages: imageWidgets, height: 300)
              : imageWidgets.first,
        ),

        // Back button
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: _buildCircleButton(
              Icons.arrow_back,
              () => Navigator.pop(context),
            ),
          ),
        ),

        // Share button
        Positioned(
          top: 16,
          right: 16,
          child: SafeArea(
            child: _buildCircleButton(
              Icons.share,
              _handleShare,
              iconColor: const Color(0xFF388E3C),
            ),
          ),
        ),

        // Photo counter
        if (imageWidgets.length > 1)
          Positioned(
            bottom: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.7),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${imageWidgets.length} photos',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildCircleButton(
    IconData icon,
    VoidCallback onTap, {
    Color iconColor = Colors.black87,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 8,
          ),
        ],
      ),
      child: IconButton(
        icon: Icon(icon, color: iconColor),
        onPressed: onTap,
      ),
    );
  }

  Widget _buildProductImage(String url) {
    return Container(
      width: double.infinity,
      height: 300,
      color: Colors.white,
      child: Image.asset(
        url,
        fit: BoxFit.contain,
        errorBuilder: (c, e, s) => _buildImagePlaceholder(
          icon: Icons.image_not_supported,
        ),
      ),
    );
  }

  Widget _buildImagePlaceholder({IconData icon = Icons.image}) {
    return Container(
      width: double.infinity,
      height: 300,
      color: Colors.grey.shade200,
      child: Center(
        child: Icon(icon, size: 60, color: Colors.grey.shade400),
      ),
    );
  }


  Widget _buildProductInfo(Map<String, dynamic> data) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Category badge
        if (data['category'] != null) ...[
          _buildCategoryBadge(data['category']),
          const SizedBox(height: 12),
        ],

        // Product name
        Text(
          data['name'],
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),

        // Price
        Text(
          'RM ${data['price'].toStringAsFixed(2)}',
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w900,
            color: Color(0xFF388E3C),
          ),
        ),
        const SizedBox(height: 16),

        // Rating or condition
        if (!widget.isPreowned)
          _buildRatingRow(data['rating'])
        else
          _buildConditionRow(),

        const SizedBox(height: 20),

        // Description
        const Text(
          'Description',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          data['description'],
          style: const TextStyle(
            fontSize: 15,
            color: Colors.black,
            height: 1.6,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildSellerInfo() {
    final name = ProductPageLogic.getSellerName(
      widget.product,
      sellerData,
      widget.isPreowned,
    );
    final image = ProductPageLogic.getSellerImage(sellerData, widget.isPreowned);
    final rating = ProductPageLogic.getSellerRating(sellerData);

    final subtitle = widget.isPreowned
        ? const Text(
            'Verified Seller',
            style: TextStyle(
              color: Colors.green,
              fontWeight: FontWeight.bold,
            ),
          )
        : Row(
            children: [
              const Icon(Icons.star, color: Colors.amber, size: 16),
              const SizedBox(width: 4),
              Text(
                rating.toStringAsFixed(1),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          );

    return Row(
      children: [
        CircleAvatar(
          radius: 28,
          backgroundColor: const Color(0xFF388E3C).withOpacity(0.1),
          backgroundImage: image.isNotEmpty ? AssetImage(image) : null,
          child: image.isEmpty
              ? const Icon(Icons.store, color: Color(0xFF388E3C), size: 28)
              : null,
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 4),
              subtitle,
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildReviewCard(Map<String, dynamic> review) {
    final rating = (review['rating'] ?? 0).toDouble();
    final reviewTitle = review['reviewTitle'] ?? '';
    final reviewText = review['reviewText'] ?? '';
    final userName = review['userName'] ?? 'Anonymous';
    final userProfileUrl = review['userProfileUrl'] ?? 
        'assets/images/icon/anonymous_icon.jpg';
    final formattedDate = ProductPageLogic.formatDate(review['reviewDate'] ?? '');

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 4,
            offset: const Offset(0, 2),
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
                backgroundColor: const Color(0xFF388E3C).withOpacity(0.1),
                backgroundImage: userProfileUrl.isNotEmpty 
                    ? AssetImage(userProfileUrl) 
                    : null,
                child: userProfileUrl.isEmpty
                    ? const Icon(Icons.person, color: Color(0xFF388E3C), size: 20)
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            userName,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        _buildVerifiedBadge(),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        _buildReviewStarRating(rating),
                        if (formattedDate.isNotEmpty) ...[
                          const SizedBox(width: 8),
                          Text(
                            '• $formattedDate',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.black,
                              fontWeight: FontWeight.bold,
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
            const SizedBox(height: 12),
            Text(
              reviewTitle,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
          ],
          if (reviewText.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              reviewText,
              style: const TextStyle(
                fontSize: 15,
                color: Colors.black,
                height: 1.5,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ],
      ),
    );
  }


  Widget _buildSection({required Widget child}) {
    return Container(
      width: double.infinity,
      color: Colors.white,
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.only(bottom: 8),
      child: child,
    );
  }

  Widget _buildCategoryBadge(String category) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF388E3C).withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        category,
        style: const TextStyle(
          fontSize: 12,
          color: Color(0xFF388E3C),
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildRatingRow(double rating) {
    return Row(
      children: [
        _buildStarRating(rating),
        const SizedBox(width: 8),
        Text(
          rating.toStringAsFixed(1),
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        Text(
          ' (${reviews.length} reviews)',
          style: const TextStyle(
            color: Colors.black,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildConditionRow() {
    return Row(
      children: const [
        Icon(Icons.recycling, size: 16, color: Colors.blue),
        SizedBox(width: 4),
        Text(
          'Pre-owned Condition',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildStarRating(double rating) {
    return Row(
      children: List.generate(5, (i) {
        if (rating >= i + 1) {
          return const Icon(Icons.star, color: Colors.amber, size: 20);
        }
        if (rating >= i + 0.5) {
          return const Icon(Icons.star_half, color: Colors.amber, size: 20);
        }
        return const Icon(Icons.star_border, color: Colors.amber, size: 20);
      }),
    );
  }

  Widget _buildReviewStarRating(double rating) {
    return Row(
      children: List.generate(5, (index) {
        return Icon(
          index < rating ? Icons.star : Icons.star_border,
          color: Colors.amber,
          size: 16,
        );
      }),
    );
  }

  Widget _buildVerifiedBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0xFF388E3C).withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.verified, size: 10, color: Color(0xFF388E3C)),
          SizedBox(width: 2),
          Text(
            'Verified',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: Color(0xFF388E3C),
            ),
          ),
        ],
      ),
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
            child: Text(
              'Earn $coins Green Coins with this purchase!',
              style: TextStyle(
                color: Colors.green.shade800,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddToCartButton() {
    return Positioned(
      bottom: 20,
      right: 20,
      left: 20,
      child: FloatingActionButton.extended(
        onPressed: isAddingToCart ? null : _addToCart,
        backgroundColor: const Color(0xFF388E3C),
        icon: isAddingToCart
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : const Icon(Icons.shopping_cart, color: Colors.white),
        label: Text(
          isAddingToCart ? 'Adding...' : 'Add to Cart',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}