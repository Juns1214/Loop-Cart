import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

class ReviewService {
  
  static Future<void> submitReview({
    required String userId,
    required String orderId,
    required Map<String, dynamic> item,
    required double rating,
    required String title,
    required String text,
    required List<dynamic> allOrderItems,
  }) async {
    try {
      final String reviewId = 'REV${DateTime.now().millisecondsSinceEpoch}';
      final bool isPreowned = item['isPreowned'] ?? false;
      final String productId = item['productId'];
      final String collection = isPreowned ? 'preowned_reviews' : 'reviews';

      // 1. Get User Data Safely
      final userDoc = await FirebaseFirestore.instance.collection('user_profile').doc(userId).get();
      final userData = userDoc.data() ?? {};
      
      final reviewData = {
        'reviewId': reviewId,
        'productId': productId,
        'rating': rating,
        'reviewTitle': title,
        'reviewText': text,
        'userName': userData['fullName'] ?? userData['name'] ?? 'Anonymous',
        'userProfileUrl': userData['profilePicture'] ?? userData['profileImage'] ?? '',
        'reviewDate': DateTime.now().toIso8601String(),
        'createdAt': FieldValue.serverTimestamp(),
      };

      final batch = FirebaseFirestore.instance.batch();

      // 2. Add Review
      batch.set(FirebaseFirestore.instance.collection(collection).doc(reviewId), reviewData);

      // 3. Mark Order Item as Reviewed
      batch.update(FirebaseFirestore.instance.collection('orders').doc(orderId), {
        'reviewedProductIds': FieldValue.arrayUnion([productId]),
      });

      await batch.commit();

      // 4. Update Order status if all items reviewed
      final updatedOrder = await FirebaseFirestore.instance.collection('orders').doc(orderId).get();
      final List reviewedIds = updatedOrder['reviewedProductIds'] ?? [];
      
      if (reviewedIds.length >= allOrderItems.length) {
        await FirebaseFirestore.instance.collection('orders').doc(orderId).update({'hasFeedback': true});
      }

      // 5. Recalculate Average Rating
      await _recalculateProductRating(productId, isPreowned);

    } catch (e) {
      debugPrint("Review Error: $e");
      rethrow; // UI should handle the error display
    }
  }

  static Future<void> _recalculateProductRating(String productId, bool isPreowned) async {
    try {
      final String reviewCol = isPreowned ? 'preowned_reviews' : 'reviews';
      final String productCol = isPreowned ? 'preowned_products' : 'products';
      
      // Get all reviews for this product
      final snapshots = await FirebaseFirestore.instance
          .collection(reviewCol)
          .where('productId', isEqualTo: productId)
          .get();

      if (snapshots.docs.isEmpty) return;

      final int count = snapshots.docs.length;
      final double totalRating = snapshots.docs.fold(0.0, (sum, doc) => sum + (doc.data()['rating'] as num? ?? 0).toDouble());
      final double avg = double.parse((totalRating / count).toStringAsFixed(1));

      // Update Product
      final productQuery = await FirebaseFirestore.instance
          .collection(productCol)
          .where('id', isEqualTo: productId)
          .limit(1)
          .get();

      if (productQuery.docs.isNotEmpty) {
        await productQuery.docs.first.reference.update({
          'rating': avg,
          'reviewCount': count,
          'ratingUpdatedAt': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      Fluttertoast.showToast(
        msg: "Error updating rating stats: $e",
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
    }
  }
}