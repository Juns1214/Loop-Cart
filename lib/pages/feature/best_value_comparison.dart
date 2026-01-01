// lib/feature/smart_value_analyzer.dart
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

      print('🔍 Searching in collection: $collection');
      print('🔍 Looking for productId: ${widget.productId}');

      // 1. Get product data - TRY MULTIPLE FIELD NAMES
      QuerySnapshot query;

      // First try with 'id' field
      query = await FirebaseFirestore.instance
          .collection(collection)
          .where('id', isEqualTo: widget.productId)
          .limit(1)
          .get();

      // If not found, try with 'productId' field
      if (query.docs.isEmpty) {
        print('⚠️ Not found with "id" field, trying "productId"...');
        query = await FirebaseFirestore.instance
            .collection(collection)
            .where('productId', isEqualTo: widget.productId)
            .limit(1)
            .get();
      }

      // If still not found, try direct document fetch (if productId IS the document ID)
      if (query.docs.isEmpty) {
        print(
          '⚠️ Not found with "productId" field, trying direct document fetch...',
        );
        var docSnapshot = await FirebaseFirestore.instance
            .collection(collection)
            .doc(widget.productId)
            .get();

        if (docSnapshot.exists) {
          // Convert to QuerySnapshot format for consistency
          query = await FirebaseFirestore.instance
              .collection(collection)
              .where(FieldPath.documentId, isEqualTo: widget.productId)
              .get();
        }
      }

      if (query.docs.isEmpty) {
        print('❌ Product not found in $collection');
        setState(() {
          analysisResult = 'Product info unavailable';
          isLoading = false;
        });
        return;
      }

      print('✅ Product found in $collection');
      var doc = query.docs.first;
      var data = doc.data() as Map<String, dynamic>;
      print('📦 Product data: ${data.keys}');

      // 2. Get ALL reviews to check count
      var reviewsSnapshot = await FirebaseFirestore.instance
          .collection(reviewCollection)
          .where('productId', isEqualTo: widget.productId)
          .get();

      int currentReviewCount = reviewsSnapshot.docs.length;
      print('📊 Found $currentReviewCount reviews in $reviewCollection');

      if (currentReviewCount == 0) {
        setState(() {
          analysisResult = 'No reviews yet. Be the first to review!';
          isLoading = false;
        });
        return;
      }

      // 3. CHECK CACHE - compare review count
      int cachedReviewCount = (data['lastReviewCount'] ?? 0) as int;
      bool hasNewReviews = currentReviewCount != cachedReviewCount;

      if (data.containsKey('aiSummary') &&
          data['aiSummary'] != null &&
          (data['aiSummary'] as String).isNotEmpty &&
          !hasNewReviews) {
        print('✓ Using cached summary (no new reviews)');
        setState(() {
          analysisResult = data['aiSummary'];
          isLoading = false;
        });
        return;
      }

      print(
        '⟳ Generating new analysis (review count changed: $cachedReviewCount → $currentReviewCount)',
      );

      // 4. Get product details with fallback field names
      String name = data['name'] ?? data['productName'] ?? 'Item';
      double price = ((data['price'] ?? 0) as num).toDouble();

      print('💰 Product: $name, Price: RM$price');

      // 5. Build ALL review texts for AI
      List<Map<String, dynamic>> allReviews = reviewsSnapshot.docs
          .map((d) => d.data())
          .toList();

      String reviewTexts = allReviews
          .map(
            (r) =>
                '${r['rating']}/5: "${r['reviewText'] ?? r['reviewTitle'] ?? ''}"',
          )
          .join('\n');

      print('📝 Processing ${allReviews.length} reviews');

      // 6. Enhanced prompt focusing on price-quality comparison
      String conditionNote = widget.isPreowned ? 'pre-owned/used' : 'brand new';

      String prompt =
          '''
You're a smart shopping assistant. Analyze this $conditionNote product:

Product: "$name"
Price: RM${price.toStringAsFixed(0)}

ALL Customer Reviews:
$reviewTexts

Task: Compare price vs quality based ONLY on these reviews. Write 2-3 SHORT sentences that:
1. Mention if it's worth the price or overpriced based on review quality
2. Give honest advice (e.g., "Great value despite higher price" or "Cheaper but quality concerns mentioned")

Be direct and specific. No fluff.
''';

      // 7. Call AI
      const String apiKey = 'AIzaSyAyK99yDMqz2IBwrr4KqrVnVmfEdq9atbA';

      try {
        final response = await http
            .post(
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
                'generationConfig': {
                  'temperature': 0.7,
                  'maxOutputTokens': 120,
                },
              }),
            );
        if (response.statusCode == 200) {
          var result = json.decode(response.body);
          String aiResponse =
              result['candidates'][0]['content']['parts'][0]['text'].trim();

          print('✅ AI Response received');

          // 8. Save summary + review count to product collection
          await FirebaseFirestore.instance
              .collection(collection)
              .doc(doc.id)
              .update({
                'aiSummary': aiResponse,
                'lastReviewCount': currentReviewCount,
                'lastAnalyzedAt': FieldValue.serverTimestamp(),
              });

          print('✓ Saved summary to Firestore');

          setState(() {
            analysisResult = aiResponse;
            isLoading = false;
          });
        } else {
          throw Exception('AI API failed: ${response.statusCode}');
        }
      } catch (e) {
        print('❌ AI Error: $e');
        setState(() {
          analysisResult =
              'Analysis temporarily unavailable. Please check reviews manually.';
          isLoading = false;
        });
      }
    } catch (e) {
      print('❌ Fatal Error: $e');
      setState(() {
        analysisResult = 'Unable to load analysis.';
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Container(
        margin: EdgeInsets.symmetric(vertical: 12),
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF388E3C).withOpacity(0.05),
              Color(0xFF388E3C).withOpacity(0.1),
            ],
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Color(0xFF388E3C).withOpacity(0.3),
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Color(0xFF388E3C).withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF388E3C)),
                ),
              ),
            ),
            SizedBox(width: 12),
            Text(
              'Analyzing value...',
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF388E3C),
                fontWeight: FontWeight.bold
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      margin: EdgeInsets.symmetric(vertical: 12),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFF388E3C).withOpacity(0.05),
            Color(0xFF388E3C).withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Color(0xFF388E3C).withOpacity(0.3),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Color(0xFF388E3C).withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.verified_outlined,
                  color: Color(0xFF388E3C),
                  size: 20,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Value Analysis',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF388E3C),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              analysisResult ?? 'No analysis available',
              style: TextStyle(
                fontSize: 14,
                height: 1.5,
                color: Colors.black,
                fontWeight: FontWeight.bold
              ),
            ),
          ),
          SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.auto_awesome, size: 11, color: Colors.black),
              SizedBox(width: 4),
              Expanded(
                child: Text(
                  'AI-powered price vs quality insight',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.black,
                    fontStyle: FontStyle.italic,
                    fontWeight: FontWeight.bold
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

// Backward compatibility wrapper
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
