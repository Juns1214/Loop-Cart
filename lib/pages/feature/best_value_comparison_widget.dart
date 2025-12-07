// lib/feature/best_value_comparison_widget.dart
// THIS WIDGET WORKS FOR BOTH REGULAR AND PRE-OWNED PRODUCTS

import 'package:flutter/material.dart';

class HonestAssessmentWidget extends StatelessWidget {
  final Map<String, dynamic>? assessment;
  final bool isLoading;

  const HonestAssessmentWidget({
    super.key,
    this.assessment,
    this.isLoading = false,
  });

  Color _getScoreColor(double score) {
    if (score >= 8.0) return Color(0xFF388E3C); // Green - Excellent
    if (score >= 6.5) return Color(0xFF66BB6A); // Light Green - Good
    if (score >= 5.0) return Colors.orange; // Orange - Average
    return Colors.red; // Red - Poor
  }

  String _getScoreLabel(double score) {
    if (score >= 8.5) return 'Excellent Value';
    if (score >= 7.5) return 'Great Value';
    if (score >= 6.5) return 'Good Value';
    if (score >= 5.5) return 'Fair Value';
    if (score >= 4.0) return 'Average Value';
    return 'Consider Carefully';
  }

  @override
  Widget build(BuildContext context) {
    // If loading, show loading state
    if (isLoading) {
      return Container(
        margin: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        padding: EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 12,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Center(
          child: Column(
            children: [
              CircularProgressIndicator(
                color: Color(0xFF388E3C),
                strokeWidth: 2,
              ),
              SizedBox(height: 12),
              Text(
                'Analyzing reviews...',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      );
    }

    // If no assessment data, don't show anything
    if (assessment == null) {
      return SizedBox.shrink();
    }

    double valueScore = (assessment!['valueScore'] ?? 0).toDouble();
    String priceCategory = assessment!['priceCategory'] ?? '';
    String summary = assessment!['summary'] ?? '';
    int totalReviews = assessment!['totalReviews'] ?? 0;

    Color scoreColor = _getScoreColor(valueScore);
    String scoreLabel = _getScoreLabel(valueScore);

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 0, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.white,
            scoreColor.withOpacity(0.03),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: scoreColor.withOpacity(0.3),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: scoreColor.withOpacity(0.1),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with icon and title
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: scoreColor.withOpacity(0.08),
              borderRadius: BorderRadius.vertical(top: Radius.circular(14)),
            ),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: scoreColor.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.verified,
                    color: scoreColor,
                    size: 22,
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Honest Product Assessment',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      Text(
                        'AI-analyzed from $totalReviews verified reviews',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Score Section
          Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Value Score
                Row(
                  children: [
                    // Score circle
                    Container(
                      width: 70,
                      height: 70,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: scoreColor.withOpacity(0.1),
                        border: Border.all(
                          color: scoreColor,
                          width: 3,
                        ),
                      ),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              valueScore.toStringAsFixed(1),
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: scoreColor,
                              ),
                            ),
                            Text(
                              '/10',
                              style: TextStyle(
                                fontSize: 11,
                                color: scoreColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(width: 16),

                    // Score label and price category
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            scoreLabel,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          SizedBox(height: 6),
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: Colors.grey[300]!,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.local_offer,
                                  size: 14,
                                  color: Colors.grey[700],
                                ),
                                SizedBox(width: 6),
                                Text(
                                  priceCategory,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey[700],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                SizedBox(height: 20),

                // AI Summary
                Container(
                  padding: EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.grey[200]!,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.format_quote,
                            size: 18,
                            color: scoreColor,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'What Customers Say',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 10),
                      Text(
                        summary,
                        style: TextStyle(
                          fontSize: 14,
                          height: 1.5,
                          color: Colors.grey[800],
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 12),

                // Footer note
                Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 14,
                      color: Colors.grey[500],
                    ),
                    SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Based on verified customer reviews and product analysis',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey[500],
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Optional: Separate widget name for pre-owned to avoid confusion in imports
// But it uses the exact same implementation
class PreownedHonestAssessmentWidget extends HonestAssessmentWidget {
  const PreownedHonestAssessmentWidget({
    super.key,
    super.assessment,
    super.isLoading = false,
  });
}