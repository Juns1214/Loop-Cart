import 'package:flutter/material.dart';

class SellerInfoCard extends StatelessWidget {
  final String name;
  final String image;
  final Widget subtitle; // Widget to allow flexibility (rating vs "Pre-owned seller")

  const SellerInfoCard({
    super.key,
    required this.name,
    required this.image,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        CircleAvatar(
          radius: 28,
          backgroundColor: const Color(0xFF388E3C).withOpacity(0.1),
          backgroundImage: image.isNotEmpty ? AssetImage(image) : null,
          child: image.isEmpty ? const Icon(Icons.store, color: Color(0xFF388E3C), size: 28) : null,
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name.isNotEmpty ? name : 'Unknown Seller',
                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.black87),
              ),
              const SizedBox(height: 4),
              subtitle,
            ],
          ),
        ),
      ],
    );
  }
}