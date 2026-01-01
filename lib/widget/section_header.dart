import 'package:flutter/material.dart';

class SectionHeader extends StatelessWidget {
  final String title;
  final String? subtitle;

  const SectionHeader({super.key, required this.title, this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1A1A1A),
            fontFamily: 'Manrope',
          ),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 4),
          Text(
            subtitle!,
            style: const TextStyle( // Changed to const
              fontSize: 15,
              fontWeight: FontWeight.bold, // This should now work
              color: Colors.black,
              fontFamily: 'Manrope', // Added fontFamily
              height: 1.4,
            ),
          ),
        ],
        const SizedBox(height: 16),
      ],
    );
  }
}