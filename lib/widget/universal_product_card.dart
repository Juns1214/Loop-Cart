import 'package:flutter/material.dart';
import '../pages/e-commerce/product_page.dart';
import '../pages/e-commerce/preowned_product_page.dart';

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
    // Pre-owned items usually use 'imageUrl1', regular use 'imageUrl'
    String imageUrl = '';
    if (isPreowned) {
      imageUrl = productData['imageUrl1'] ?? productData['imageUrl'] ?? '';
    } else {
      imageUrl = productData['imageUrl'] ?? productData['image_url'] ?? '';
    }

    final String name = productData['name'] ?? 'Unknown';
    final double price = (productData['price'] ?? 0).toDouble();
    final String category = productData['category'] ?? '';
    
    // Regular specific
    final double rating = (productData['rating'] ?? 0).toDouble();
    
    // Pre-owned specific
    final String location = productData['seller'] ?? productData['location'] ?? '';

    // 2. Dimensions
    final double cardWidth = isGrid ? double.infinity : 160;
    final double imageHeight = isGrid ? 140 : 120;

    Widget content = Container(
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
          // Image
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            child: Container(
              height: imageHeight,
              width: double.infinity,
              color: Colors.white,
              child: imageUrl.isNotEmpty
                  ? Image.asset(
                      imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Center(
                          child: Icon(Icons.image_not_supported, color: Colors.grey)),
                    )
                  : const Center(child: Icon(Icons.image, color: Colors.grey)),
            ),
          ),

          // Info Body
          // In Grid mode, we use Expanded to ensure alignment. In List mode, we don't.
          if (isGrid)
            Expanded(
              child: _buildInfoContent(name, price, category, rating, location),
            )
          else
            _buildInfoContent(name, price, category, rating, location),
        ],
      ),
    );

    return GestureDetector(
      onTap: () {
        if (isPreowned) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => PreownedProductPage(product: productData)),
          );
        } else {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => ProductPage(product: productData)),
          );
        }
      },
      child: content,
    );
  }

  Widget _buildInfoContent(String name, double price, String category, double rating, String location) {
    return Padding(
      padding: const EdgeInsets.all(10.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Category Badge (Only show in Grid mode or if needed)
          if (isGrid && category.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: isPreowned ? Colors.black.withOpacity(0.7) : const Color(0xFF388E3C).withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                category,
                style: TextStyle(
                  fontSize: 10,
                  color: isPreowned ? Colors.white : const Color(0xFF388E3C),
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

          // Secondary Info (Rating vs Location)
          Row(
            children: [
              Icon(
                isPreowned ? Icons.store : Icons.star, 
                color: isPreowned ? Colors.grey.shade600 : Colors.amber, 
                size: 14
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  isPreowned ? location : rating.toStringAsFixed(1),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isPreowned ? Colors.grey.shade700 : Colors.black54,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),

          const SizedBox(height: 4),
          
          // Price
          Text(
            'RM ${price.toStringAsFixed(2)}',
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w900,
              color: Color(0xFF388E3C), // Consistent Green Price
            ),
          ),
        ],
      ),
    );
  }
}