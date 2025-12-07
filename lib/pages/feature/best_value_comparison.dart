// ====================================================================
// FILE 1: lib/feature/best_value_comparison.dart
// FOR REGULAR PRODUCTS
// ====================================================================

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class HonestAssessmentService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Category benchmark prices for regular products
  static const Map<String, double> categoryBenchmarks = {
    'Clothing': 120.0,
    'Dairy-Free': 20.0,
    'Eco-Friendly': 15.0,
    'Fitness': 200.0,
    'Gluten-Free': 15.0,
    'Gluten': 12.0,
    'Halal Products': 18.0,
    'Non-Halal Products': 22.0,
    'Nut': 18.0,
    'Electronic & Gadget': 1000.0,
    'Vegan Products': 25.0,
  };

  /// Main method: Get or generate honest assessment for regular products
  static Future<Map<String, dynamic>?> getHonestAssessment({
    required String productId,
  }) async {
    try {
      // 1. Get product data from products collection
      DocumentSnapshot productDoc = await _firestore
          .collection('products')
          .doc(productId)
          .get();

      if (!productDoc.exists) {
        print('Product not found: $productId');
        return null;
      }

      Map<String, dynamic> productData = productDoc.data() as Map<String, dynamic>;

      // 2. Check if assessment exists and is still valid
      if (productData.containsKey('honestAssessment')) {
        Map<String, dynamic> existingAssessment = 
            Map<String, dynamic>.from(productData['honestAssessment']);
        
        // Check if new reviews were added since last generation
        bool hasNewReviews = await _hasNewReviews(
          productId: productId,
          lastReviewDate: existingAssessment['lastReviewDate'] as Timestamp?,
        );

        if (!hasNewReviews) {
          // Return cached assessment
          print('Returning cached assessment for: $productId');
          return existingAssessment;
        }
      }

      // 3. Generate new assessment
      print('Generating new assessment for: $productId');
      return await _generateNewAssessment(
        productId: productId,
        productData: productData,
      );

    } catch (e) {
      print('Error getting honest assessment: $e');
      return null;
    }
  }

  /// Check if there are new reviews since last assessment
  static Future<bool> _hasNewReviews({
    required String productId,
    required Timestamp? lastReviewDate,
  }) async {
    if (lastReviewDate == null) return true;

    QuerySnapshot newReviews = await _firestore
        .collection('reviews')
        .where('productId', isEqualTo: productId)
        .where('reviewDate', isGreaterThan: lastReviewDate.toDate().toIso8601String())
        .limit(1)
        .get();

    return newReviews.docs.isNotEmpty;
  }

  /// Generate new assessment with AI and formula
  static Future<Map<String, dynamic>?> _generateNewAssessment({
    required String productId,
    required Map<String, dynamic> productData,
  }) async {
    try {
      // 1. Fetch all reviews for this product
      QuerySnapshot reviewsSnapshot = await _firestore
          .collection('reviews')
          .where('productId', isEqualTo: productId)
          .get();

      if (reviewsSnapshot.docs.isEmpty) {
        print('No reviews found for product: $productId');
        return null;
      }

      List<Map<String, dynamic>> reviews = reviewsSnapshot.docs
          .map((doc) => doc.data() as Map<String, dynamic>)
          .toList();

      print('Found ${reviews.length} reviews for product: $productId');

      // 2. Calculate formula-based metrics
      double avgRating = _calculateAverageRating(reviews);
      double productPrice = (productData['price'] ?? 0).toDouble();
      String category = productData['category'] ?? '';
      double benchmarkPrice = categoryBenchmarks[category] ?? productPrice;
      
      double valueScore = _calculateValueScore(
        avgRating: avgRating,
        productPrice: productPrice,
        benchmarkPrice: benchmarkPrice,
        totalReviews: reviews.length,
      );

      String priceCategory = _getPriceCategory(productPrice, benchmarkPrice);

      // 3. Generate AI summary using Gemini
      String? aiSummary = await _generateGeminiSummary(
        productData: productData,
        reviews: reviews,
        avgRating: avgRating,
        priceCategory: priceCategory,
        isPreowned: false,
      );

      if (aiSummary == null) {
        print('AI summary generation failed');
        return null;
      }

      // 4. Find newest review date
      Timestamp? newestReviewDate = _getNewestReviewDate(reviews);

      // 5. Create assessment object
      Map<String, dynamic> assessment = {
        'summary': aiSummary,
        'valueScore': double.parse(valueScore.toStringAsFixed(1)),
        'priceCategory': priceCategory,
        'totalReviews': reviews.length,
        'lastGenerated': FieldValue.serverTimestamp(),
        'lastReviewDate': newestReviewDate,
      };

      // 6. Save to Firestore
      await _firestore.collection('products').doc(productId).update({
        'honestAssessment': assessment,
      });

      print('Assessment saved successfully for: $productId');
      return assessment;

    } catch (e) {
      print('Error generating assessment: $e');
      return null;
    }
  }

  static double _calculateAverageRating(List<Map<String, dynamic>> reviews) {
    if (reviews.isEmpty) return 0.0;
    double total = 0.0;
    for (var review in reviews) {
      total += (review['rating'] ?? 0).toDouble();
    }
    return total / reviews.length;
  }

  static double _calculateValueScore({
    required double avgRating,
    required double productPrice,
    required double benchmarkPrice,
    required int totalReviews,
  }) {
    double ratingScore = avgRating * 10;
    double priceRatio = productPrice / benchmarkPrice;
    double priceScore = 0;
    
    if (priceRatio < 0.6) {
      priceScore = 20;
    } else if (priceRatio >= 0.6 && priceRatio <= 1.2) {
      priceScore = 30;
    } else if (priceRatio > 1.2 && priceRatio <= 1.5) {
      priceScore = 20;
    } else {
      priceScore = 10;
    }

    double volumeScore = 0;
    if (totalReviews >= 20) {
      volumeScore = 20;
    } else if (totalReviews >= 10) {
      volumeScore = 15;
    } else if (totalReviews >= 5) {
      volumeScore = 10;
    } else {
      volumeScore = 5;
    }

    return ((ratingScore + priceScore + volumeScore) / 100) * 10;
  }

  static String _getPriceCategory(double productPrice, double benchmarkPrice) {
    double ratio = productPrice / benchmarkPrice;
    if (ratio < 0.7) return 'Budget-Friendly';
    if (ratio < 0.9) return 'Good Value';
    if (ratio <= 1.1) return 'Fair Price';
    if (ratio <= 1.3) return 'Slightly Premium';
    return 'Premium Price';
  }

  static Timestamp? _getNewestReviewDate(List<Map<String, dynamic>> reviews) {
    if (reviews.isEmpty) return null;
    DateTime? newest;
    for (var review in reviews) {
      String? dateStr = review['reviewDate'];
      if (dateStr != null) {
        DateTime date = DateTime.parse(dateStr);
        if (newest == null || date.isAfter(newest)) {
          newest = date;
        }
      }
    }
    return newest != null ? Timestamp.fromDate(newest) : null;
  }

  static Future<String?> _generateGeminiSummary({
    required Map<String, dynamic> productData,
    required List<Map<String, dynamic>> reviews,
    required double avgRating,
    required String priceCategory,
    required bool isPreowned,
  }) async {
    try {
      String productName = productData['name'] ?? 'Unknown Product';
      double productPrice = (productData['price'] ?? 0).toDouble();
      String description = productData['description'] ?? '';
      String category = productData['category'] ?? '';

      StringBuffer reviewsText = StringBuffer();
      for (int i = 0; i < reviews.length; i++) {
        var review = reviews[i];
        reviewsText.writeln('Review ${i + 1}:');
        reviewsText.writeln('Rating: ${review['rating']}/5');
        reviewsText.writeln('Title: ${review['reviewTitle']}');
        reviewsText.writeln('Comment: ${review['reviewText']}');
        reviewsText.writeln('Reviewer: ${review['userName']}');
        reviewsText.writeln('---');
      }

      String prompt = '''
You are an honest product reviewer. Analyze this product and its reviews to generate a brief, honest summary.

PRODUCT DETAILS:
- Name: $productName
- Price: RM $productPrice
- Category: $category
- Type: NEW PRODUCT
- Description: $description
- Average Rating: ${avgRating.toStringAsFixed(1)}/5
- Price Category: $priceCategory

CUSTOMER REVIEWS:
$reviewsText

IMPORTANT INSTRUCTIONS:
1. Write ONLY 2-3 sentences maximum
2. Be honest and balanced - mention both positives and concerns if present
3. This is a NEW product, so evaluate quality, features, and value accordingly
4. Focus on: quality, value for money, common themes in reviews
5. Start with what users generally say (e.g., "Users praise...", "Most customers note...", "Buyers appreciate...")
6. DO NOT mention sustainability or environmental benefits
7. Be concise and direct

Generate the honest summary now:''';

      const String GEMINI_API_KEY = 'YOUR_API_KEY_HERE';

      final response = await http.post(
        Uri.parse('https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash-exp:generateContent?key=$GEMINI_API_KEY'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'contents': [
            {
              'parts': [
                {'text': prompt}
              ]
            }
          ],
          'generationConfig': {
            'temperature': 0.7,
            'maxOutputTokens': 150,
          }
        }),
      );

      if (response.statusCode == 200) {
        Map<String, dynamic> data = json.decode(response.body);
        String summary = data['candidates'][0]['content']['parts'][0]['text'];
        return summary.trim();
      } else {
        print('Gemini API error: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Error calling Gemini API: $e');
      return null;
    }
  }
}

// ====================================================================
// FILE 2: lib/feature/best_value_comparison_preowned.dart
// FOR PRE-OWNED PRODUCTS
// ====================================================================

class BestValueComparisonService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Category benchmark prices for pre-owned products
  static const Map<String, double> categoryBenchmarks = {
    'Electronics': 800.0,
    'Home Appliances': 250.0,
    'Furniture': 400.0,
    'Vehicles': 35000.0,
    'Baby and Kids': 80.0,
    'Musical Instruments': 1500.0,
    'Books & Stationery': 40.0,
  };

  /// Main method: Get or generate best value comparison for pre-owned products
  static Future<Map<String, dynamic>?> getBestValueComparison({
    required String productId,
  }) async {
    try {
      // 1. Get product data from preowned_products collection
      DocumentSnapshot productDoc = await _firestore
          .collection('preowned_products')
          .doc(productId)
          .get();

      if (!productDoc.exists) {
        print('Pre-owned product not found: $productId');
        return null;
      }

      Map<String, dynamic> productData = productDoc.data() as Map<String, dynamic>;

      // 2. Check if assessment exists and is still valid
      if (productData.containsKey('honestAssessment')) {
        Map<String, dynamic> existingAssessment = 
            Map<String, dynamic>.from(productData['honestAssessment']);
        
        bool hasNewReviews = await _hasNewReviews(
          productId: productId,
          lastReviewDate: existingAssessment['lastReviewDate'] as Timestamp?,
        );

        if (!hasNewReviews) {
          print('Returning cached assessment for pre-owned: $productId');
          return existingAssessment;
        }
      }

      // 3. Generate new assessment
      print('Generating new assessment for pre-owned: $productId');
      return await _generateNewAssessment(
        productId: productId,
        productData: productData,
      );

    } catch (e) {
      print('Error getting pre-owned assessment: $e');
      return null;
    }
  }

  static Future<bool> _hasNewReviews({
    required String productId,
    required Timestamp? lastReviewDate,
  }) async {
    if (lastReviewDate == null) return true;

    QuerySnapshot newReviews = await _firestore
        .collection('preowned_reviews')
        .where('productId', isEqualTo: productId)
        .where('reviewDate', isGreaterThan: lastReviewDate.toDate().toIso8601String())
        .limit(1)
        .get();

    return newReviews.docs.isNotEmpty;
  }

  static Future<Map<String, dynamic>?> _generateNewAssessment({
    required String productId,
    required Map<String, dynamic> productData,
  }) async {
    try {
      // 1. Fetch all reviews from preowned_reviews collection
      QuerySnapshot reviewsSnapshot = await _firestore
          .collection('preowned_reviews')
          .where('productId', isEqualTo: productId)
          .get();

      if (reviewsSnapshot.docs.isEmpty) {
        print('No reviews found for pre-owned product: $productId');
        return null;
      }

      List<Map<String, dynamic>> reviews = reviewsSnapshot.docs
          .map((doc) => doc.data() as Map<String, dynamic>)
          .toList();

      print('Found ${reviews.length} reviews for pre-owned product: $productId');

      // 2. Calculate metrics (adjusted for pre-owned)
      double avgRating = _calculateAverageRating(reviews);
      double productPrice = (productData['price'] ?? 0).toDouble();
      String category = productData['category'] ?? '';
      double benchmarkPrice = categoryBenchmarks[category] ?? productPrice;
      
      double valueScore = _calculateValueScorePreowned(
        avgRating: avgRating,
        productPrice: productPrice,
        benchmarkPrice: benchmarkPrice,
        totalReviews: reviews.length,
      );

      String priceCategory = _getPriceCategoryPreowned(productPrice, benchmarkPrice);

      // 3. Generate AI summary
      String? aiSummary = await HonestAssessmentService._generateGeminiSummary(
        productData: productData,
        reviews: reviews,
        avgRating: avgRating,
        priceCategory: priceCategory,
        isPreowned: true,
      );

      if (aiSummary == null) {
        print('AI summary generation failed for pre-owned');
        return null;
      }

      // 4. Find newest review date
      Timestamp? newestReviewDate = _getNewestReviewDate(reviews);

      // 5. Create assessment object
      Map<String, dynamic> assessment = {
        'summary': aiSummary,
        'valueScore': double.parse(valueScore.toStringAsFixed(1)),
        'priceCategory': priceCategory,
        'totalReviews': reviews.length,
        'lastGenerated': FieldValue.serverTimestamp(),
        'lastReviewDate': newestReviewDate,
      };

      // 6. Save to Firestore
      await _firestore.collection('preowned_products').doc(productId).update({
        'honestAssessment': assessment,
      });

      print('Assessment saved for pre-owned: $productId');
      return assessment;

    } catch (e) {
      print('Error generating pre-owned assessment: $e');
      return null;
    }
  }

  static double _calculateAverageRating(List<Map<String, dynamic>> reviews) {
    if (reviews.isEmpty) return 0.0;
    double total = 0.0;
    for (var review in reviews) {
      total += (review['rating'] ?? 0).toDouble();
    }
    return total / reviews.length;
  }

  // Pre-owned scoring - adjusted for used items
  static double _calculateValueScorePreowned({
    required double avgRating,
    required double productPrice,
    required double benchmarkPrice,
    required int totalReviews,
  }) {
    double ratingScore = avgRating * 10;
    double priceRatio = productPrice / benchmarkPrice;
    double priceScore = 0;
    
    // Pre-owned items should be cheaper
    if (priceRatio < 0.4) {
      priceScore = 30; // Great deal
    } else if (priceRatio >= 0.4 && priceRatio <= 0.7) {
      priceScore = 25; // Good value
    } else if (priceRatio > 0.7 && priceRatio <= 0.9) {
      priceScore = 20; // Fair
    } else {
      priceScore = 10; // Too expensive for used
    }

    double volumeScore = 0;
    if (totalReviews >= 20) volumeScore = 20;
    else if (totalReviews >= 10) volumeScore = 15;
    else if (totalReviews >= 5) volumeScore = 10;
    else volumeScore = 5;

    return ((ratingScore + priceScore + volumeScore) / 100) * 10;
  }

  static String _getPriceCategoryPreowned(double productPrice, double benchmarkPrice) {
    double ratio = productPrice / benchmarkPrice;
    if (ratio < 0.4) return 'Excellent Deal';
    if (ratio < 0.6) return 'Great Value';
    if (ratio <= 0.8) return 'Fair Price';
    if (ratio <= 0.95) return 'Slightly High';
    return 'Near New Price';
  }

  static Timestamp? _getNewestReviewDate(List<Map<String, dynamic>> reviews) {
    if (reviews.isEmpty) return null;
    DateTime? newest;
    for (var review in reviews) {
      String? dateStr = review['reviewDate'];
      if (dateStr != null) {
        DateTime date = DateTime.parse(dateStr);
        if (newest == null || date.isAfter(newest)) {
          newest = date;
        }
      }
    }
    return newest != null ? Timestamp.fromDate(newest) : null;
  }
}