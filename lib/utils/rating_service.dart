// lib/utils/rating_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';

class RatingService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Calculate average rating for a product based on reviews
  static Future<double> calculateAverageRating(String productId) async {
    try {
      QuerySnapshot reviewSnapshot = await _firestore
          .collection('reviews')
          .where('productId', isEqualTo: productId)
          .get();

      if (reviewSnapshot.docs.isEmpty) {
        return 0.0;
      }

      double totalRating = 0.0;
      int reviewCount = 0;

      for (var doc in reviewSnapshot.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        int rating = data['rating'] ?? 0;
        totalRating += rating;
        reviewCount++;
      }

      double averageRating = reviewCount > 0 ? totalRating / reviewCount : 0.0;
      return double.parse(averageRating.toStringAsFixed(1));
    } catch (e) {
      print('Error calculating average rating: $e');
      return 0.0;
    }
  }

  /// Update product rating in products collection using custom 'id' field
  static Future<void> updateProductRating(String productId) async {
    try {
      // Calculate new average rating
      double averageRating = await calculateAverageRating(productId);

      // Get review count
      QuerySnapshot reviewSnapshot = await _firestore
          .collection('reviews')
          .where('productId', isEqualTo: productId)
          .get();

      int reviewCount = reviewSnapshot.docs.length;

      // Find the product document by the custom 'id' field
      QuerySnapshot productSnapshot = await _firestore
          .collection('products')
          .where('id', isEqualTo: productId)
          .limit(1)
          .get();

      if (productSnapshot.docs.isEmpty) {
        print('⚠️ Product not found with id: $productId');
        return;
      }

      // Get the actual document ID
      String docId = productSnapshot.docs.first.id;

      // Update the product document
      await _firestore.collection('products').doc(docId).update({
        'rating': averageRating,
        'reviewCount': reviewCount,
        'ratingUpdatedAt': FieldValue.serverTimestamp(),
      });

      print('✅ Updated rating for product $productId: $averageRating ($reviewCount reviews)');
    } catch (e) {
      print('❌ Error updating product rating: $e');
    }
  }

  /// Add a new review and update product rating
  static Future<bool> addReviewAndUpdateRating({
    required String productId,
    required String reviewId,
    required int rating,
    required String reviewTitle,
    required String reviewText,
    required String userName,
    String userProfileUrl = '',
  }) async {
    try {
      // Add the review
      await _firestore.collection('reviews').doc(reviewId).set({
        'reviewId': reviewId,
        'productId': productId,
        'rating': rating,
        'reviewTitle': reviewTitle,
        'reviewText': reviewText,
        'userName': userName,
        'userProfileUrl': userProfileUrl,
        'reviewDate': DateTime.now().toIso8601String(),
      });

      print('✅ Review added: $reviewId');

      // Update product rating
      await updateProductRating(productId);

      return true;
    } catch (e) {
      print('❌ Error adding review: $e');
      return false;
    }
  }

  /// Delete a review and update product rating
  static Future<bool> deleteReviewAndUpdateRating({
    required String reviewId,
    required String productId,
  }) async {
    try {
      // Delete the review
      await _firestore.collection('reviews').doc(reviewId).delete();

      print('✅ Review deleted: $reviewId');

      // Update product rating
      await updateProductRating(productId);

      return true;
    } catch (e) {
      print('❌ Error deleting review: $e');
      return false;
    }
  }

  /// Update an existing review and recalculate product rating
  static Future<bool> updateReviewAndRecalculateRating({
    required String reviewId,
    required String productId,
    required int newRating,
    String? newReviewTitle,
    String? newReviewText,
  }) async {
    try {
      Map<String, dynamic> updateData = {
        'rating': newRating,
      };

      if (newReviewTitle != null) {
        updateData['reviewTitle'] = newReviewTitle;
      }

      if (newReviewText != null) {
        updateData['reviewText'] = newReviewText;
      }

      // Update the review
      await _firestore.collection('reviews').doc(reviewId).update(updateData);

      print('✅ Review updated: $reviewId');

      // Recalculate and update product rating
      await updateProductRating(productId);

      return true;
    } catch (e) {
      print('❌ Error updating review: $e');
      return false;
    }
  }

  /// Get rating statistics for a product
  static Future<Map<String, dynamic>> getRatingStatistics(String productId) async {
    try {
      QuerySnapshot reviewSnapshot = await _firestore
          .collection('reviews')
          .where('productId', isEqualTo: productId)
          .get();

      if (reviewSnapshot.docs.isEmpty) {
        return {
          'averageRating': 0.0,
          'totalReviews': 0,
          'ratingDistribution': {5: 0, 4: 0, 3: 0, 2: 0, 1: 0},
        };
      }

      Map<int, int> distribution = {5: 0, 4: 0, 3: 0, 2: 0, 1: 0};
      double totalRating = 0.0;

      for (var doc in reviewSnapshot.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        int rating = data['rating'] ?? 0;
        totalRating += rating;
        if (rating >= 1 && rating <= 5) {
          distribution[rating] = (distribution[rating] ?? 0) + 1;
        }
      }

      double averageRating = totalRating / reviewSnapshot.docs.length;

      return {
        'averageRating': double.parse(averageRating.toStringAsFixed(1)),
        'totalReviews': reviewSnapshot.docs.length,
        'ratingDistribution': distribution,
      };
    } catch (e) {
      print('❌ Error getting rating statistics: $e');
      return {
        'averageRating': 0.0,
        'totalReviews': 0,
        'ratingDistribution': {5: 0, 4: 0, 3: 0, 2: 0, 1: 0},
      };
    }
  }
}