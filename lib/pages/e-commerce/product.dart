import 'package:flutter/material.dart';
import 'product_page.dart'; // Import the product page

// Product Card Widget for horizontal list
class ProductCard extends StatelessWidget {
  final String imageUrl;
  final String productName;
  final double productPrice;
  final double rating;
  final Map<String, dynamic>? productData; // Full product data

  const ProductCard({
    super.key,
    required this.imageUrl,
    required this.productName,
    required this.productPrice,
    required this.rating,
    this.productData,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (productData != null) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ProductPage(product: productData!),
            ),
          );
        }
      },
      child: Container(
        width: 160,
        margin: EdgeInsets.symmetric(horizontal: 8),
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
            // Product Image
            ClipRRect(
              borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
              child: imageUrl.isNotEmpty
                  ? Image.asset(
                      imageUrl,
                      width: double.infinity,
                      height: 120,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        print('Error loading image: $imageUrl');
                        print('Error: $error');
                        return Container(
                          width: double.infinity,
                          height: 120,
                          color: Colors.white,
                          child: Icon(
                            Icons.image_not_supported,
                            color: Colors.grey,
                          ),
                        );
                      },
                    )
                  : Container(
                      width: double.infinity,
                      height: 120,
                      color: Colors.white,
                      child: Icon(Icons.image, color: Colors.grey),
                    ),
            ),

            // Product Info
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    productName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                  SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.star, color: Colors.amber, size: 14),
                      SizedBox(width: 2),
                      Text(
                        rating.toStringAsFixed(1),
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.black,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 4),
                  Text(
                    'RM ${productPrice.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF388E3C),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Product Grid Widget
class ProductGrid extends StatelessWidget {
  final String imageUrl;
  final String productName;
  final double productPrice;
  final double rating;
  final String category;
  final Map<String, dynamic>? productData; // Full product data

  const ProductGrid({
    super.key,
    required this.imageUrl,
    required this.productName,
    required this.productPrice,
    required this.rating,
    this.category = '',
    this.productData,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (productData != null) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ProductPage(product: productData!),
            ),
          );
        }
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey[200],
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
            // Product Image
            ClipRRect(
              borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
              child: imageUrl.isNotEmpty
                  ? Image.asset(
                      imageUrl,
                      width: double.infinity,
                      height: 140,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        print('Error loading image: $imageUrl');
                        print('Error: $error');
                        return Container(
                          width: double.infinity,
                          height: 140,
                          color: Colors.grey.shade200,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.image_not_supported,
                                color: Colors.grey,
                                size: 40,
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Image not found',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    )
                  : Container(
                      width: double.infinity,
                      height: 140,
                      color: Colors.grey.shade200,
                      child: Icon(Icons.image, color: Colors.grey, size: 40),
                    ),
            ),

            // Product Info
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (category.isNotEmpty)
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Color(0xFF388E3C).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          category,
                          style: TextStyle(
                            fontSize: 9,
                            color: Color(0xFF388E3C),
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    SizedBox(height: 4),
                    Text(
                      productName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Spacer(),
                    Row(
                      children: [
                        Icon(Icons.star, color: Colors.amber, size: 14),
                        SizedBox(width: 2),
                        Text(
                          rating.toStringAsFixed(1),
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.black,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 2),
                    Text(
                      'RM ${productPrice.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF388E3C),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
