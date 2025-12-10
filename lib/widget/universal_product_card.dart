import 'package:flutter/material.dart';
import '../pages/e-commerce/product_page.dart';
// Note: Removed preowned_product_page import as it is no longer needed

class UniversalProductCard extends StatelessWidget {
  final Map<String, dynamic> productData;
  final bool isGrid;      
  final bool isPreowned;  

  const UniversalProductCard({
    super.key,
    required this.productData,
    this.isGrid = false,
    this.isPreowned = false,
  });

  @override
  Widget build(BuildContext context) {
    // 1. Extract Data
    String imageUrl = '';
    if (isPreowned) {
      imageUrl = productData['imageUrl1'] ?? productData['imageUrl'] ?? '';
    } else {
      imageUrl = productData['imageUrl'] ?? productData['image_url'] ?? '';
    }

    final String name = productData['name'] ?? 'Unknown';
    final double price = (productData['price'] ?? 0).toDouble();
    final String category = productData['category'] ?? '';
    final double rating = (productData['rating'] ?? 0).toDouble();

    // 2. Dimensions
    final double cardWidth = isGrid ? double.infinity : 160;
    final double imageHeight = isGrid ? 140 : 120;

    return GestureDetector(
      onTap: () {
        // UNIFIED NAVIGATION: Always go to ProductPage, pass the flag
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ProductPage(
              product: productData,
              isPreowned: isPreowned, // Pass the flag
            ),
          ),
        );
      },
      child: Container(
        width: isGrid ? null : cardWidth,
        margin: isGrid ? EdgeInsets.zero : const EdgeInsets.symmetric(horizontal: 8),
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
            // Image Area
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              child: Container(
                height: imageHeight,
                width: double.infinity,
                color: Colors.grey.shade100,
                child: imageUrl.isNotEmpty
                    ? Image.asset( // Or Image.network if using URLs
                        imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Center(
                            child: Icon(Icons.image_not_supported, color: Colors.grey)),
                      )
                    : const Center(child: Icon(Icons.image, color: Colors.grey)),
              ),
            ),

            // Info Body
            if (isGrid)
              Expanded(child: _buildInfoContent(name, price, category, rating))
            else
              _buildInfoContent(name, price, category, rating),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoContent(String name, double price, String category, double rating) {
    return Padding(
      padding: const EdgeInsets.all(10.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Category Badge (Only show in Grid mode)
          if (isGrid && category.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: isPreowned ? Colors.blue.withOpacity(0.1) : const Color(0xFF388E3C).withOpacity(0.1),
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

          // Product Name
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

          // Spacer for Grid alignment
          if (isGrid) const Spacer() else const SizedBox(height: 4),

          // SECONDARY INFO ROW
          // For Pre-owned: We HIDE the seller/location row completely as requested.
          // For Standard: We show the Star Rating.
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
             // Optional: You could add a small spacer here if the card looks too condensed
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
}