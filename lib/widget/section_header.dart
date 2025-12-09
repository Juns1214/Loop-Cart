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
            fontSize: 18, // Slightly larger for better visibility
            fontWeight: FontWeight.w800,
            color: Color(0xFF1A1A1A), // Darker black for contrast
            fontFamily: 'Manrope',
          ),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 4),
          Text(
            subtitle!,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade700, // Darker grey, not faded
              height: 1.4,
            ),
          ),
        ],
        const SizedBox(height: 16),
      ],
    );
  }
}