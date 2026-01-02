import 'package:flutter/material.dart';

class ProductCard extends StatelessWidget {
  final Map<String, dynamic> productData;
  final bool isGrid;
  final bool isPreowned;

  const ProductCard({
    super.key,
    required this.productData,
    this.isGrid = false,
    this.isPreowned = false,
  });

  @override
  Widget build(BuildContext context) {
    final imageUrl = _getImageUrl();
    final name = productData['name'] ?? 'Unknown';
    final price = (productData['price'] ?? 0).toDouble();
    final category = productData['category'] ?? '';
    final rating = (productData['rating'] ?? 0).toDouble();

    final cardWidth = isGrid ? null : 160.0;
    final imageHeight = isGrid ? 140.0 : 120.0;

    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(
          context,
          '/product-details',
          arguments: {'product': productData, 'isPreowned': isPreowned},
        );
      },
      child: Container(
        width: cardWidth,
        margin: isGrid
            ? EdgeInsets.zero
            : const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product Image
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(12),
              ),
              child: Container(
                height: imageHeight,
                width: double.infinity,
                color: Colors.grey.shade100,
                child: imageUrl.isNotEmpty
                    ? Image.asset(
                        imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Center(
                          child: Icon(
                            Icons.image_not_supported,
                            color: Colors.grey,
                          ),
                        ),
                      )
                    : const Center(
                        child: Icon(Icons.image, color: Colors.grey),
                      ),
              ),
            ),

            // Product Info
            isGrid
                ? Expanded(child: _buildInfo(name, price, category, rating))
                : _buildInfo(name, price, category, rating),
          ],
        ),
      ),
    );
  }

  Widget _buildInfo(String name, double price, String category, double rating) {
    return Padding(
      padding: const EdgeInsets.all(10.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          if (isGrid && category.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: (isPreowned ? Colors.blue : const Color(0xFF388E3C))
                    .withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                category,
                style: TextStyle(
                  fontSize: 10,
                  color: isPreowned ? Colors.blue : const Color(0xFF388E3C),
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 1,
              ),
            ),
            const SizedBox(height: 6),
          ],

          // Product name
          Text(
            name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),

          // Spacer
          isGrid ? const Spacer() : const SizedBox(height: 4),

          // Rating
          if (!isPreowned) ...[
            Row(
              children: [
                const Icon(Icons.star, color: Colors.amber, size: 14),
                const SizedBox(width: 4),
                Text(
                  rating.toStringAsFixed(1),
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.black54,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
          ] else ...[
            const SizedBox(height: 8),
          ],

          // Price
          Text(
            'RM ${price.toStringAsFixed(2)}',
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w900,
              color: Color(0xFF388E3C),
            ),
          ),
        ],
      ),
    );
  }

  String _getImageUrl() {
    if (isPreowned) {
      return productData['imageUrl1'] ?? productData['imageUrl'] ?? '';
    }
    return productData['imageUrl'] ?? productData['image_url'] ?? '';
  }
}
