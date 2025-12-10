import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../checkout/payment_confirmation.dart';
import '../../widget/custom_button.dart';

class Payment extends StatefulWidget {
  final Map<String, dynamic> orderData;

  const Payment({super.key, required this.orderData});

  @override
  State<Payment> createState() => _PaymentState();
}

class _PaymentState extends State<Payment> {
  String selectedPayment = 'Visa';
  bool isProcessing = false;

  User? get currentUser => FirebaseAuth.instance.currentUser;

  // --- ID Generators ---
  String _generateTransactionId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = (timestamp % 10000).toString().padLeft(4, '0');
    return 'TXN$timestamp$random';
  }

  String _generateOrderId() {
    final now = DateTime.now();
    final dateStr =
        '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}';
    final random = (now.millisecondsSinceEpoch % 10000).toString().padLeft(
      4,
      '0',
    );
    return 'ORD$dateStr$random';
  }

  String _generateTrackingNumber() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = (timestamp % 100000000).toString().padLeft(8, '0');
    return 'TRK$random';
  }

  // --- Logic: Processing ---

  // Routes to specific payment handler
  Future<void> _processPayment() async {
    if (widget.orderData.containsKey('category') &&
        widget.orderData.containsKey('amount') &&
        !widget.orderData.containsKey('items') &&
        !widget.orderData.containsKey('repair_option')) {
      await _processDonationPayment();
    } else if (widget.orderData.containsKey('repair_option')) {
      await _processRepairPayment();
    } else {
      await _processOrderPayment();
    }
  }

  Future<void> _processOrderPayment() async {
    if (!_validateUser()) return;
    setState(() => isProcessing = true);

    try {
      final now = DateTime.now();
      final orderId = _generateOrderId();
      final transactionId = _generateTransactionId();
      final trackingNumber = _generateTrackingNumber();

      // 1. Prepare Items with Seller Data
      List<Map<String, dynamic>> itemsWithSeller = [];
      for (var item in widget.orderData['items']) {
        String sellerName = item['seller'] ?? 'Unknown Seller';
        String sellerId = '';
        String sellerProfileImage = '';

        // Fetch seller details (Optimized: could be batched, but keeping logic safe)
        var sellerQuery = await FirebaseFirestore.instance
            .collection('seller')
            .where('name', isEqualTo: sellerName)
            .limit(1)
            .get();

        if (sellerQuery.docs.isNotEmpty) {
          final data = sellerQuery.docs.first.data();
          sellerId = data['sellerId'] ?? '';
          sellerProfileImage = data['profileImage'] ?? '';
        }

        itemsWithSeller.add({
          ...item, // Copy existing item data
          'sellerId': sellerId,
          'sellerProfileImage': sellerProfileImage,
        });
      }

      // 2. Create Order Document
      final orderDoc = {
        'orderId': orderId,
        'userId': currentUser!.uid,
        'orderDate': Timestamp.fromDate(now),
        'status': 'Delivered', // Immediate delivery as per logic
        'currentStatusIndex': 4,
        'items': itemsWithSeller,
        'shippingAddress': widget.orderData['shippingAddress'],
        'shippingMethod': widget.orderData['shippingMethod'],
        'shippingCost': widget.orderData['shippingCost'],
        'packagingCost': widget.orderData['packagingCost'],
        'paymentMethod': selectedPayment,
        'paymentStatus': 'Completed',
        'transactionId': transactionId,
        'itemsTotal': widget.orderData['itemsTotal'],
        'discount': widget.orderData['discount'],
        'greenCoinsUsed': widget.orderData['greenCoinsUsed'],
        'grandTotal': widget.orderData['grandTotal'],
        'greenCoinsToEarn': widget.orderData['greenCoinsToEarn'] ?? 0,
        'trackingNumber': trackingNumber,
        'estimatedDelivery': {
          'from': Timestamp.fromDate(now),
          'to': Timestamp.fromDate(now),
        },
        'statusHistory': _getCompleteStatusHistory(now),
        'isReceived': false,
        'hasFeedback': false,
      };

      await FirebaseFirestore.instance
          .collection('orders')
          .doc(orderId)
          .set(orderDoc);

      // 3. Handle Green Coins (Deduct Used)
      if (widget.orderData['greenCoinsUsed'] > 0) {
        await _updateGreenCoins(-widget.orderData['greenCoinsUsed']);
        await _recordTransaction(
          transactionId: '${transactionId}_used',
          amount: -widget.orderData['greenCoinsUsed'],
          activity: 'purchase',
          description: 'Used coins for discount',
        );
      }

      // 4. Handle Green Coins (Add Earned)
      int earnedCoins = widget.orderData['greenCoinsToEarn'] ?? 0;
      if (earnedCoins > 0) {
        await _updateGreenCoins(earnedCoins);
        await _recordTransaction(
          transactionId: '${transactionId}_earned',
          amount: earnedCoins,
          activity: 'purchase_preowned_product',
          description: 'Earned coins from purchase',
        );
      }

      // 5. Clear Cart
      for (var item in widget.orderData['items']) {
        var cartQuery = await FirebaseFirestore.instance
            .collection('cart_items')
            .where('userId', isEqualTo: currentUser!.uid)
            .where('productId', isEqualTo: item['productId'])
            .get();
        for (var doc in cartQuery.docs) await doc.reference.delete();
      }

      if (!mounted) return;
      _navigateToConfirmation(orderId: orderId, transactionId: transactionId);
    } catch (e) {
      _handleError(e);
    }
  }

  Future<void> _processDonationPayment() async {
    if (!_validateUser()) return;
    setState(() => isProcessing = true);

    try {
      final transactionId = _generateTransactionId();
      final double amount = widget.orderData['amount'];
      final String category = widget.orderData['category'];
      final int earnedCoins = amount.floor();

      await FirebaseFirestore.instance
          .collection('donation_record')
          .doc(transactionId)
          .set({
            'userId': currentUser!.uid,
            'createdAt': FieldValue.serverTimestamp(),
            'amount': amount,
            'donationCategory': category,
            'greenCoinsEarned': earnedCoins,
            'paymentMethod': selectedPayment,
            'transactionId': transactionId,
            'status': 'Completed',
          });

      await _updateGreenCoins(earnedCoins);
      await _recordTransaction(
        transactionId: transactionId,
        amount: earnedCoins,
        activity: 'donation',
        description: 'Earned coins from $category donation',
      );

      if (!mounted) return;
      _navigateToConfirmation(
        transactionId: transactionId,
        extraData: {'type': 'donation', 'greenCoinsEarned': earnedCoins},
      );
    } catch (e) {
      _handleError(e);
    }
  }

  Future<void> _processRepairPayment() async {
    if (!_validateUser()) return;
    setState(() => isProcessing = true);

    try {
      final transactionId = _generateTransactionId();
      final repairOption = Map<String, String>.from(
        widget.orderData['repair_option'],
      );
      final repairType = repairOption['Repair'] ?? 'Repair';

      // Parse price safely
      final priceStr = repairOption['Price'] ?? '0';
      final matches = RegExp(r'\d+').allMatches(priceStr);
      final int price = matches.isNotEmpty
          ? int.parse(matches.first.group(0)!)
          : 0;
      final int earnedCoins = price;

      await FirebaseFirestore.instance
          .collection('repair_record')
          .doc(widget.orderData['repairRecordId'])
          .update({
            'paymentStatus': 'Completed',
            'paymentMethod': selectedPayment,
            'transactionId': transactionId,
            'greenCoinsEarned': earnedCoins,
            'paymentMadeAt': FieldValue.serverTimestamp(),
          });

      await _updateGreenCoins(earnedCoins);
      await _recordTransaction(
        transactionId: transactionId,
        amount: earnedCoins,
        activity: 'repair_service',
        description: 'Earned coins from $repairType',
      );

      if (!mounted) return;
      _navigateToConfirmation(
        transactionId: transactionId,
        extraData: {
          'type': 'repair',
          'repairType': repairType,
          'amount': price.toDouble(),
          'greenCoinsEarned': earnedCoins,
        },
      );
    } catch (e) {
      _handleError(e);
    }
  }

  // --- Logic: Helpers ---

  bool _validateUser() {
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please login to continue'),
          backgroundColor: Colors.red,
        ),
      );
      return false;
    }
    return true;
  }

  Future<void> _updateGreenCoins(int amount) async {
    await FirebaseFirestore.instance
        .collection('user_profile')
        .doc(currentUser!.uid)
        .update({'greenCoins': FieldValue.increment(amount)});
  }

  Future<void> _recordTransaction({
    required String transactionId,
    required int amount,
    required String activity,
    required String description,
  }) async {
    await FirebaseFirestore.instance
        .collection('green_coin_transactions')
        .doc(transactionId)
        .set({
          'transactionId': transactionId,
          'userId': currentUser!.uid,
          'amount': amount,
          'activity': activity,
          'description': description,
          'createdAt': FieldValue.serverTimestamp(),
        });
  }

  void _handleError(dynamic e) {
    debugPrint('Payment Error: $e');
    if (mounted) {
      setState(() => isProcessing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Payment failed: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _navigateToConfirmation({
    String orderId = '',
    required String transactionId,
    Map<String, dynamic>? extraData,
  }) {
    // Merge existing data with new confirmation data
    final finalOrderData = Map<String, dynamic>.from(widget.orderData);
    if (extraData != null) finalOrderData.addAll(extraData);

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => PaymentConfirmation(
          orderData: finalOrderData,
          orderId: orderId,
          transactionId: transactionId,
          paymentMethod: selectedPayment,
        ),
      ),
    );
  }

  List<Map<String, dynamic>> _getCompleteStatusHistory(DateTime now) {
    return [
      {
        'status': 'Order Placed',
        'timestamp': Timestamp.fromDate(now),
        'description': 'Order placed successfully.',
      },
      {
        'status': 'Processing',
        'timestamp': Timestamp.fromDate(now),
        'description': 'Order is being processed.',
      },
      {
        'status': 'Shipped',
        'timestamp': Timestamp.fromDate(now),
        'description': 'Order has been shipped.',
      },
      {
        'status': 'Out for Delivery',
        'timestamp': Timestamp.fromDate(now),
        'description': 'Order is out for delivery.',
      },
      {
        'status': 'Delivered',
        'timestamp': Timestamp.fromDate(now),
        'description': 'Order has been delivered.',
      },
    ];
  }

  // --- UI Build ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Payment',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Select Payment Method',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
                const SizedBox(height: 20),

                _PaymentMethodTile(
                  icon: 'assets/images/icon/VISA.png',
                  label: 'Visa',
                  isSelected: selectedPayment == 'Visa',
                  onTap: () => setState(() => selectedPayment = 'Visa'),
                ),
                _PaymentMethodTile(
                  icon: 'assets/images/icon/Paypal.png',
                  label: 'PayPal',
                  isSelected: selectedPayment == 'PayPal',
                  onTap: () => setState(() => selectedPayment = 'PayPal'),
                ),
                _PaymentMethodTile(
                  icon: 'assets/images/icon/Online_Transfer.png',
                  label: 'Bank Transfer',
                  isSelected: selectedPayment == 'Bank Transfer',
                  onTap: () =>
                      setState(() => selectedPayment = 'Bank Transfer'),
                ),
                _PaymentMethodTile(
                  icon: 'assets/images/icon/TNG.png',
                  label: 'Touch n Go',
                  isSelected: selectedPayment == 'Touch n Go',
                  onTap: () => setState(() => selectedPayment = 'Touch n Go'),
                ),

                const SizedBox(height: 30),
                const Text(
                  'Other Methods',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
                const SizedBox(height: 16),

                // Group 2
                _PaymentMethodTile(
                  icon: 'assets/images/icon/cash-on-delivery-icon.png',
                  label: 'Cash on Delivery',
                  isSelected: selectedPayment == 'Cash on Delivery',
                  onTap: () =>
                      setState(() => selectedPayment = 'Cash on Delivery'),
                ),

                const SizedBox(height: 30),

                // Action Button using CustomButton
                CustomButton(
                  text: isProcessing ? "Processing..." : "Make Payment",
                  onPressed: isProcessing
                      ? () {}
                      : _processPayment, // Disable press if processing
                  isLoading: isProcessing,
                  backgroundColor: const Color(0xFF2E5BFF),
                  minimumSize: const Size(double.infinity, 54),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),

          // Optional overlay for extra safety during processing
          if (isProcessing)
            Container(
              color: Colors.black12,
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }
}

// Helper Widget for Payment Options
class _PaymentMethodTile extends StatelessWidget {
  final String icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _PaymentMethodTile({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? const Color(0xFF2E5BFF) : Colors.transparent,
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Image.asset(icon, height: 40, width: 50, fit: BoxFit.contain),
            const SizedBox(width: 20),
            Text(
              label,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const Spacer(),
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? const Color(0xFF2E5BFF) : Colors.white,
                border: Border.all(
                  color: isSelected
                      ? const Color(0xFF2E5BFF)
                      : Colors.grey[300]!,
                  width: 2,
                ),
              ),
              child: isSelected
                  ? const Icon(Icons.check, color: Colors.white, size: 16)
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}
