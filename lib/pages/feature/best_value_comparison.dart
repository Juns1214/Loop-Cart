import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class SmartValueDisplay extends StatefulWidget {
  final String productId;
  final bool isPreowned;

  const SmartValueDisplay({
    super.key,
    required this.productId,
    required this.isPreowned,
  });

  @override
  State<SmartValueDisplay> createState() => _SmartValueDisplayState();
}

class _SmartValueDisplayState extends State<SmartValueDisplay> {
  String? analysisResult;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAnalysis();
  }

  Future<void> _loadAnalysis() async {
    try {
      String collection = widget.isPreowned ? 'preowned_products' : 'products';
      String reviewCollection = widget.isPreowned
          ? 'preowned_reviews'
          : 'reviews';

      QuerySnapshot query;

      query = await FirebaseFirestore.instance
          .collection(collection)
          .where('id', isEqualTo: widget.productId)
          .limit(1)
          .get();

      if (query.docs.isEmpty) {
        query = await FirebaseFirestore.instance
            .collection(collection)
            .where('productId', isEqualTo: widget.productId)
            .limit(1)
            .get();
      }

      if (query.docs.isEmpty) {
        var docSnapshot = await FirebaseFirestore.instance
            .collection(collection)
            .doc(widget.productId)
            .get();
        if (docSnapshot.exists) {
          query = await FirebaseFirestore.instance
              .collection(collection)
              .where(FieldPath.documentId, isEqualTo: widget.productId)
              .get();
        }
      }

      if (query.docs.isEmpty) {
        setState(() {
          analysisResult = 'Product info unavailable';
          isLoading = false;
        });
        return;
      }

      var doc = query.docs.first;
      var data = doc.data() as Map<String, dynamic>;

      var reviewsSnapshot = await FirebaseFirestore.instance
          .collection(reviewCollection)
          .where('productId', isEqualTo: widget.productId)
          .get();

      int currentReviewCount = reviewsSnapshot.docs.length;

      if (currentReviewCount == 0) {
        setState(() {
          analysisResult = 'No reviews yet. Be the first to review!';
          isLoading = false;
        });
        return;
      }

      int cachedReviewCount = (data['lastReviewCount'] ?? 0) as int;
      bool hasNewReviews = currentReviewCount != cachedReviewCount;

      if (data.containsKey('aiSummary') &&
          data['aiSummary'] != null &&
          (data['aiSummary'] as String).isNotEmpty &&
          !hasNewReviews) {
        setState(() {
          analysisResult = data['aiSummary'];
          isLoading = false;
        });
        return;
      }

      String name = data['name'] ?? data['productName'] ?? 'Item';
      double price = ((data['price'] ?? 0) as num).toDouble();

      List<Map<String, dynamic>> allReviews = reviewsSnapshot.docs
          .map((d) => d.data())
          .toList();

      String reviewTexts = allReviews
          .map(
            (r) =>
                '${r['rating']}/5: "${r['reviewText'] ?? r['reviewTitle'] ?? ''}"',
          )
          .join('\n');

      String conditionNote = widget.isPreowned ? 'pre-owned/used' : 'brand new';

      String prompt =
          '''
You're a smart shopping assistant. Analyze this $conditionNote product:

Product: "$name"
Price: RM${price.toStringAsFixed(0)}

ALL Customer Reviews:
$reviewTexts

Task: Compare price vs quality based only on these reviews. Write 2-3 SHORT sentences that:
1. Mention if it's worth the price or overpriced based on review quality
2. Give honest advice (e.g., "Great value despite higher price" or "Cheaper but quality concerns mentioned")

Be direct and specific.
''';

      const String apiKey = 'AIzaSyAyK99yDMqz2IBwrr4KqrVnVmfEdq9atbA';

      try {
        final response = await http.post(
          Uri.parse(
            'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key=$apiKey',
          ),
          headers: {'Content-Type': 'application/json'},
          body: json.encode({
            'contents': [
              {
                'parts': [
                  {'text': prompt},
                ],
              },
            ],
            'generationConfig': {'temperature': 0.7, 'maxOutputTokens': 120},
          }),
        );

        if (response.statusCode == 200) {
          var result = json.decode(response.body);
          String aiResponse =
              result['candidates'][0]['content']['parts'][0]['text'].trim();

          await FirebaseFirestore.instance
              .collection(collection)
              .doc(doc.id)
              .update({
                'aiSummary': aiResponse,
                'lastReviewCount': currentReviewCount,
                'lastAnalyzedAt': FieldValue.serverTimestamp(),
              });

          setState(() {
            analysisResult = aiResponse;
            isLoading = false;
          });
        } else {
          throw Exception('AI API failed: ${response.statusCode}');
        }
      } catch (e) {
        setState(() {
          analysisResult =
              'Analysis temporarily unavailable. Please check reviews manually.';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        analysisResult = 'Unable to load analysis.';
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return _AnalysisCard(
        child: Row(
          children: [
            _IconBadge(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF2E7D32)),
                ),
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'Analyzing value...',
              style: TextStyle(
                fontFamily: 'Roboto',
                fontSize: 15,
                color: Color(0xFF1B5E20),
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      );
    }

    return _AnalysisCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _IconBadge(
                child: Icon(
                  Icons.lightbulb,
                  color: Color(0xFF2E7D32),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Value Analysis',
                  style: TextStyle(
                    fontFamily: 'Roboto',
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1B5E20),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              analysisResult ?? 'No analysis available',
              style: const TextStyle(
                fontFamily: 'Roboto',
                fontSize: 15,
                height: 1.6,
                color: Color(0xFF212121),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Icon(Icons.auto_awesome, size: 14, color: Color(0xFF424242)),
              const SizedBox(width: 6),
              const Expanded(
                child: Text(
                  'AI-powered price vs quality insight',
                  style: TextStyle(
                    fontFamily: 'Roboto',
                    fontSize: 12,
                    color: Color(0xFF424242),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AnalysisCard extends StatelessWidget {
  final Widget child;

  const _AnalysisCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFE8F5E9), Color(0xFFC8E6C9)],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Color(0xFF66BB6A), width: 2),
      ),
      child: child,
    );
  }
}

class _IconBadge extends StatelessWidget {
  final Widget child;

  const _IconBadge({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Color(0xFF2E7D32).withOpacity(0.2),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }
}

class SmartValueButton extends StatelessWidget {
  final String productId;
  final bool isPreowned;

  const SmartValueButton({
    super.key,
    required this.productId,
    required this.isPreowned,
  });

  @override
  Widget build(BuildContext context) {
    return SmartValueDisplay(productId: productId, isPreowned: isPreowned);
  }
}
