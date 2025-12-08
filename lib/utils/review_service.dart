import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:flutter/material.dart';

class ReviewService {
  // Static method so you don't need to create an instance to use it
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
      String reviewId = 'REV${DateTime.now().millisecondsSinceEpoch}';
      bool isPreowned = item['isPreowned'] ?? false;
      String productId = item['productId'];
      String collection = isPreowned ? 'preowned_reviews' : 'reviews';

      // 1. Get User Details
      var userDoc = await FirebaseFirestore.instance
          .collection('user_profile')
          .doc(userId)
          .get();
      Map<String, dynamic> userData = userDoc.data() ?? {};
      String userName = userData['fullName'] ?? userData['name'] ?? 'Anonymous';
      String userProfileUrl = userData['profilePicture'] ?? userData['profileImage'] ?? '';

      // 2. Save Review
      await FirebaseFirestore.instance.collection(collection).doc(reviewId).set({
        'reviewId': reviewId,
        'productId': productId,
        'rating': rating,
        'reviewTitle': title,
        'reviewText': text,
        'userName': userName,
        'userProfileUrl': userProfileUrl,
        'reviewDate': DateTime.now().toIso8601String(),
      });

      // 3. Update Order (Mark item as reviewed)
      await FirebaseFirestore.instance.collection('orders').doc(orderId).update({
        'reviewedProductIds': FieldValue.arrayUnion([productId]),
      });

      // 4. Check if Order is Fully Reviewed
      DocumentSnapshot updatedOrder = await FirebaseFirestore.instance.collection('orders').doc(orderId).get();
      List<dynamic> reviewedIds = updatedOrder['reviewedProductIds'] ?? [];
      
      if (reviewedIds.length >= allOrderItems.length) {
        await FirebaseFirestore.instance.collection('orders').doc(orderId).update({'hasFeedback': true});
      }

      // 5. Recalculate Rating (The function we fixed earlier)
      await recalculateProductRating(productId, isPreowned);

    } catch (e) {
      throw e; // Throw error so UI knows it failed
    }
  }

  static Future<void> recalculateProductRating(String productId, bool isPreowned) async {
    try {
      String reviewCollection = isPreowned ? 'preowned_reviews' : 'reviews';
      String productCollection = isPreowned ? 'preowned_products' : 'products';

      var reviewsSnapshot = await FirebaseFirestore.instance
          .collection(reviewCollection)
          .where('productId', isEqualTo: productId)
          .get();

      if (reviewsSnapshot.docs.isEmpty) return;

      int count = reviewsSnapshot.docs.length;
      double sumRatings = reviewsSnapshot.docs.fold(0.0, (sum, doc) {
        return sum + (doc.data()['rating'] as num? ?? 0).toDouble();
      });

      double averageRating = double.parse((sumRatings / count).toStringAsFixed(1));

      var productQuery = await FirebaseFirestore.instance
          .collection(productCollection)
          .where('id', isEqualTo: productId)
          .limit(1)
          .get();

      if (productQuery.docs.isNotEmpty) {
        await productQuery.docs.first.reference.update({
          'rating': averageRating,
          'reviewCount': count,
          'ratingUpdatedAt': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      Fluttertoast.showToast(
        msg: "Error updating rating: $e",
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
    }
  }
}