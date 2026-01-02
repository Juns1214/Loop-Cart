import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:fluttertoast/fluttertoast.dart';

class ProductPageLogic {
  
  /// Load seller and review data
  static Future<Map<String, dynamic>> loadProductData({
    required Map<String, dynamic> product,
    required bool isPreowned,
  }) async {
    Map<String, dynamic>? sellerData;
    List<Map<String, dynamic>> reviews = [];

    try {
      // Load seller data (standard products only)
      if (!isPreowned) {
        String sellerName = product['seller'] ?? '';
        
        if (sellerName.isNotEmpty) {
          // Try querying by name
          var sellerQuery = await FirebaseFirestore.instance
              .collection('seller')
              .where('name', isEqualTo: sellerName)
              .limit(1)
              .get();

          if (sellerQuery.docs.isNotEmpty) {
            sellerData = sellerQuery.docs.first.data();
          } else {
            // Fallback: try by sellerId
            sellerQuery = await FirebaseFirestore.instance
                .collection('seller')
                .where('sellerId', isEqualTo: sellerName)
                .limit(1)
                .get();

            if (sellerQuery.docs.isNotEmpty) {
              sellerData = sellerQuery.docs.first.data();
            }
          }
        }
      }

      // Load reviews
      String productId = product['id'] ?? '';
      String collection = isPreowned ? 'preowned_reviews' : 'reviews';

      if (productId.isNotEmpty) {
        var reviewQuery = await FirebaseFirestore.instance
            .collection(collection)
            .where('productId', isEqualTo: productId)
            .get();

        var reviewList = reviewQuery.docs.map((d) => d.data()).toList();
        reviewList.sort((a, b) =>
            (b['reviewDate'] ?? '').compareTo(a['reviewDate'] ?? ''));
        reviews = reviewList;
      }
    } catch (e) {
      Fluttertoast.showToast(msg: e.toString());
    }

    return {
      'sellerData': sellerData,
      'reviews': reviews,
    };
  }

  /// Add product to cart
  static Future<Map<String, dynamic>?> addToCart({
    required Map<String, dynamic> product,
    required bool isPreowned,
    required User currentUser,
  }) async {
    try {
      String userId = currentUser.uid;
      String productId = product['id'] ?? '';

      // Check if product already in cart
      var cartQuery = await FirebaseFirestore.instance
          .collection('cart_items')
          .where('userId', isEqualTo: userId)
          .where('productId', isEqualTo: productId)
          .limit(1)
          .get();

      Map<String, dynamic> cartItem;

      if (cartQuery.docs.isNotEmpty) {
        // Update quantity
        var doc = cartQuery.docs.first;
        int newQuantity = (doc['quantity'] ?? 1) + 1;

        await doc.reference.update({'quantity': newQuantity});

        cartItem = doc.data();
        cartItem['quantity'] = newQuantity;
        cartItem['docId'] = doc.id;
      } else {
        // Add new item
        cartItem = {
          'userId': userId,
          'productId': productId,
          'productName': product['name'],
          'productPrice': (product['price'] ?? 0).toDouble(),
          'quantity': 1,
          'imageUrl': isPreowned
              ? (product['imageUrl1'] ?? '')
              : (product['imageUrl'] ?? ''),
          'seller': product['seller'],
          'isPreowned': isPreowned,
          'dateAdded': FieldValue.serverTimestamp(),
        };

        var ref = await FirebaseFirestore.instance
            .collection('cart_items')
            .add(cartItem);
        cartItem['docId'] = ref.id;
      }

      // Get user address
      var userDoc = await FirebaseFirestore.instance
          .collection('user_profile')
          .doc(userId)
          .get();

      return {
        'cartItem': cartItem,
        'userAddress': userDoc.exists ? userDoc['address'] : null,
      };
    } catch (e) {
      return null;
    }
  }


  /// Get product images based on type
  static List<String> getProductImages(
    Map<String, dynamic> product,
    bool isPreowned,
  ) {
    List<String> images = [];

    if (isPreowned) {
      if (product['imageUrl1'] != null) images.add(product['imageUrl1']);
      if (product['imageUrl2'] != null) images.add(product['imageUrl2']);
      if (product['imageUrl3'] != null) images.add(product['imageUrl3']);
    } else {
      images.add(product['imageUrl'] ?? product['image_url'] ?? '');
    }

    if (images.isEmpty) images.add('');
    return images;
  }

  /// Get seller name
  static String getSellerName(
    Map<String, dynamic> product,
    Map<String, dynamic>? sellerData,
    bool isPreowned,
  ) {
    if (isPreowned) {
      return product['seller'] ?? 'Private Seller';
    }
    return sellerData?['name'] ?? product['seller'] ?? 'Unknown Seller';
  }

  /// Get seller image
  static String getSellerImage(
    Map<String, dynamic>? sellerData,
    bool isPreowned,
  ) {
    if (isPreowned) return '';
    return sellerData?['profileImage'] ?? '';
  }

  /// Get seller rating
  static double getSellerRating(Map<String, dynamic>? sellerData) {
    return (sellerData?['ratings'] ?? 0.0).toDouble();
  }

  /// Calculate green coins to earn
  static int calculateGreenCoins(double price) {
    return price.floor();
  }

  /// Format review date
  static String formatDate(String dateString) {
    if (dateString.isEmpty) return '';

    try {
      DateTime date = DateTime.parse(dateString);
      return DateFormat('MMM dd, yyyy').format(date);
    } catch (e) {
      return dateString;
    }
  }

  /// Extract product data for easy access
  static Map<String, dynamic> extractProductData(Map<String, dynamic> product) {
    return {
      'name': product['name'] ?? 'Unknown',
      'price': (product['price'] ?? 0).toDouble(),
      'category': product['category'],
      'description': product['description'] ?? 'No description.',
      'rating': (product['rating'] ?? 0).toDouble(),
      'id': product['id'] ?? '',
    };
  }
}