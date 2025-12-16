import 'package:flutter/material.dart';
import '../utils/waste_classification.dart';

class ResultCard extends StatelessWidget {
  final ClassificationResult result;

  const ResultCard({
    super.key,
    required this.result,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: result.isRecyclable 
              ? const Color(0xFF4CAF50) 
              : const Color(0xFFFF5252),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: (result.isRecyclable 
                ? const Color(0xFF4CAF50) 
                : const Color(0xFFFF5252)).withOpacity(0.15),
            blurRadius: 12,
            offset: const Offset(0, 4),
          )
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Category and confidence
          Row(
            children: [
              // Icon
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: (result.isRecyclable 
                      ? const Color(0xFF4CAF50) 
                      : const Color(0xFFFF5252)).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  result.isRecyclable ? Icons.recycling : Icons.delete_outline,
                  color: result.isRecyclable 
                      ? const Color(0xFF4CAF50) 
                      : const Color(0xFFFF5252),
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              // Category name
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      result.category,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${result.confidence.toStringAsFixed(1)}% confident',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.black54,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 20),
          
          // Divider
          Container(
            height: 1,
            color: Colors.grey.shade200,
          ),
          
          const SizedBox(height: 20),
          
          // Recyclable status
          Row(
            children: [
              Icon(
                result.isRecyclable ? Icons.check_circle : Icons.cancel,
                color: result.isRecyclable 
                    ? const Color(0xFF4CAF50) 
                    : const Color(0xFFFF5252),
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                result.isRecyclable ? 'Recyclable' : 'Non-Recyclable',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: result.isRecyclable 
                      ? const Color(0xFF4CAF50) 
                      : const Color(0xFFFF5252),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Tips section header
          const Text(
            'Recycling Tips:',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          
          const SizedBox(height: 8),
          
          // Tips content
          Text(
            result.tips,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.black87,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}