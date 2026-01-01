import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ReviewCard extends StatelessWidget {
  final Map<String, dynamic> review;

  const ReviewCard({super.key, required this.review});

  @override
  Widget build(BuildContext context) {
    double rating = (review['rating'] ?? 0).toDouble();
    String reviewTitle = review['reviewTitle'] ?? '';
    String reviewText = review['reviewText'] ?? '';
    String userName = review['userName'] ?? 'Anonymous';
    String userProfileUrl = review['userProfileUrl'] ?? '';
    String reviewDate = review['reviewDate'] ?? '';

    // Date Formatting
    String formattedDate = '';
    if (reviewDate.isNotEmpty) {
      try {
        DateTime date = DateTime.parse(reviewDate);
        formattedDate = DateFormat('MMM dd, yyyy').format(date);
      } catch (e) {
        formattedDate = reviewDate;
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300), // Slightly darker border
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
                backgroundImage: userProfileUrl.isNotEmpty ? AssetImage(userProfileUrl) : null,
                child: userProfileUrl.isEmpty ? const Icon(Icons.person, color: Color(0xFF388E3C), size: 20) : null,
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
                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.black),
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
                        Row(
                          children: List.generate(5, (index) {
                            return Icon(
                              index < rating ? Icons.star : Icons.star_border,
                              color: Colors.amber,
                              size: 16,
                            );
                          }),
                        ),
                        if (formattedDate.isNotEmpty) ...[
                          const SizedBox(width: 8),
                          Text(
                            '• $formattedDate',
                            style: TextStyle(fontSize: 12, color: Colors.black, fontWeight: FontWeight.bold),
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
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black),
            ),
          ],
          if (reviewText.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              reviewText,
              style: TextStyle(fontSize: 15, color: Colors.black, height: 1.5, fontWeight: FontWeight.bold), // Darker text
            ),
          ],
        ],
      ),
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
          Text('Verified', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF388E3C))),
        ],
      ),
    );
  }
}