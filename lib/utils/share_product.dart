import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';

class ProductShareHandler {
  static const int maxSharesPerDay = 5;
  static const int coinsPerShare = 5;

  static String _getTodayDateMalaysia() {
    final now = DateTime.now().toUtc().add(const Duration(hours: 8));
    return DateFormat('yyyy-MM-dd').format(now);
  }

  static String _generateTransactionId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = (timestamp % 10000).toString().padLeft(4, '0');
    return 'TXN$timestamp$random';
  }

  static Future<void> shareProduct({
    required BuildContext context,
    required Map<String, dynamic> product,
    required bool isPreowned,
  }) async {
    final User? currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      _showMessage(
        context,
        'Please login to share and earn coins',
        isError: true,
      );
      return;
    }

    try {
      final todayDate = _getTodayDateMalaysia();
      final shareCountDoc = await FirebaseFirestore.instance
          .collection('user_share_tracking')
          .doc('${currentUser.uid}_$todayDate')
          .get();

      int todayShareCount = 0;
      if (shareCountDoc.exists) {
        todayShareCount = shareCountDoc.data()?['shareCount'] ?? 0;
      }

      bool willEarnCoins = todayShareCount < maxSharesPerDay;

      String productName = product['name'] ?? 'Product';
      String productPrice = 'RM ${(product['price'] ?? 0).toStringAsFixed(2)}';
      String productType = isPreowned ? 'Pre-owned' : 'New';

      String shareMessage =
          '''
Check out this $productType product: $productName
Price: $productPrice

Download our app to shop sustainably!
''';

      final result = await Share.share(
        shareMessage,
        subject: 'Check out $productName',
      );

      if (result.status == ShareResultStatus.success) {
        if (willEarnCoins) {
          await _rewardShareCoins(
            userId: currentUser.uid,
            todayDate: todayDate,
            currentShareCount: todayShareCount,
            productName: productName,
          );

          int remainingShares = maxSharesPerDay - (todayShareCount + 1);

          if (context.mounted) {
            _showMessage(
              context,
              '+$coinsPerShare Green Coins earned! ($remainingShares shares left today)',
              isError: false,
            );
          }
        } else {
          if (context.mounted) {
            _showMessage(
              context,
              'Shared successfully! Daily coin limit reached (5/5). Come back tomorrow!',
              isError: false,
            );
          }
        }
      }
    } catch (e) {
      if (context.mounted) {
        _showMessage(context, 'Error sharing: $e', isError: true);
      }
    }
  }

  static Future<void> _rewardShareCoins({
    required String userId,
    required String todayDate,
    required int currentShareCount,
    required String productName,
  }) async {
    final transactionId = _generateTransactionId();
    final batch = FirebaseFirestore.instance.batch();

    final trackingRef = FirebaseFirestore.instance
        .collection('user_share_tracking')
        .doc('${userId}_$todayDate');

    batch.set(trackingRef, {
      'userId': userId,
      'date': todayDate,
      'shareCount': currentShareCount + 1,
      'lastShareAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    final userRef = FirebaseFirestore.instance
        .collection('user_profile')
        .doc(userId);

    batch.update(userRef, {'greenCoins': FieldValue.increment(coinsPerShare)});

    final transactionRef = FirebaseFirestore.instance
        .collection('green_coin_transactions')
        .doc(transactionId);

    batch.set(transactionRef, {
      'transactionId': transactionId,
      'userId': userId,
      'amount': coinsPerShare,
      'activity': 'share_product',
      'description': 'Shared product: $productName',
      'createdAt': FieldValue.serverTimestamp(),
    });

    await batch.commit();
  }

  static void _showMessage(
    BuildContext context,
    String message, {
    required bool isError,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : const Color(0xFF388E3C),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  static Future<int> getRemainingShares(String userId) async {
    try {
      final todayDate = _getTodayDateMalaysia();
      final shareCountDoc = await FirebaseFirestore.instance
          .collection('user_share_tracking')
          .doc('${userId}_$todayDate')
          .get();

      if (shareCountDoc.exists) {
        int todayShareCount = shareCountDoc.data()?['shareCount'] ?? 0;
        return maxSharesPerDay - todayShareCount;
      }
      return maxSharesPerDay;
    } catch (e) {
      return 0;
    }
  }
}
