import 'package:flutter/material.dart';
import 'package:flutter_application_1/utils/swiper.dart'; // Ensure this path is correct

class ProductImageHeader extends StatelessWidget {
  final List<String> imageUrls;
  final VoidCallback onBack;
  final VoidCallback onShare;
  final double height;

  const ProductImageHeader({
    super.key,
    required this.imageUrls,
    required this.onBack,
    required this.onShare,
    this.height = 350,
  });

  @override
  Widget build(BuildContext context) {
    // Filter valid images
    final validImages = imageUrls.where((url) => url.isNotEmpty).toList();
    
    // Build image widgets
    final imageWidgets = validImages.isEmpty
        ? [_buildPlaceholder()]
        : validImages.map((url) => _buildImage(url)).toList();

    return Stack(
      children: [
        Container(
          height: height,
          color: Colors.white,
          child: imageWidgets.length > 1
              ? Swiper(pages: imageWidgets, height: height)
              : imageWidgets.first,
        ),
        
        // Back Button
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: _buildCircleBtn(Icons.arrow_back, onBack),
          ),
        ),

        // Share Button
        Positioned(
          top: 16,
          right: 16,
          child: SafeArea(
            child: _buildCircleBtn(Icons.share, onShare, iconColor: const Color(0xFF388E3C)),
          ),
        ),

        // Photo Counter (only for multiple images)
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
                style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildCircleBtn(IconData icon, VoidCallback onTap, {Color iconColor = Colors.black87}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 8)],
      ),
      child: IconButton(
        icon: Icon(icon, color: iconColor),
        onPressed: onTap,
      ),
    );
  }

  Widget _buildImage(String url) {
    return Container(
      width: double.infinity,
      height: height,
      color: Colors.white,
      child: Image.asset(
        url,
        fit: BoxFit.contain,
        errorBuilder: (c, e, s) => _buildPlaceholder(icon: Icons.image_not_supported),
      ),
    );
  }

  Widget _buildPlaceholder({IconData icon = Icons.image}) {
    return Container(
      width: double.infinity,
      height: height,
      color: Colors.grey.shade200,
      child: Center(child: Icon(icon, size: 60, color: Colors.grey.shade400)),
    );
  }
}