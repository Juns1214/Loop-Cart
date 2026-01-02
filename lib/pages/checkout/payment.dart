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

  String _generateTransactionId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = (timestamp % 10000).toString().padLeft(4, '0');
    return 'TXN$timestamp$random';
  }

  String _generateOrderId() {
    final now = DateTime.now();
    final dateStr = '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}';
    final random = (now.millisecondsSinceEpoch % 10000).toString().padLeft(4, '0');
    return 'ORD$dateStr$random';
  }

  String _generateTrackingNumber() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = (timestamp % 100000000).toString().padLeft(8, '0');
    return 'TRK$random';
  }

  Map<String, dynamic> _cleanItemForFirestore(Map<String, dynamic> item) {
    final cleaned = <String, dynamic>{};
    item.forEach((key, value) {
      if (key != 'updatedAt' && key != 'createdAt' && key != 'docId') {
        cleaned[key] = value;
      }
    });
    return cleaned;
  }

  Future<void> _processPayment() async {
    if (widget.orderData.containsKey('category') && widget.orderData.containsKey('amount') && !widget.orderData.containsKey('items') && !widget.orderData.containsKey('repair_option')) {
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

      List<Map<String, dynamic>> itemsWithSeller = [];
      for (var item in widget.orderData['items']) {
        final cleanedItem = _cleanItemForFirestore(Map<String, dynamic>.from(item));
        
        String sellerName = cleanedItem['seller'] ?? 'Unknown Seller';
        String sellerId = '';
        String sellerProfileImage = '';

        var sellerQuery = await FirebaseFirestore.instance.collection('seller').where('name', isEqualTo: sellerName).limit(1).get();

        if (sellerQuery.docs.isNotEmpty) {
          final data = sellerQuery.docs.first.data();
          sellerId = data['sellerId'] ?? '';
          sellerProfileImage = data['profileImage'] ?? '';
        }

        itemsWithSeller.add({
          ...cleanedItem,
          'sellerId': sellerId,
          'sellerProfileImage': sellerProfileImage,
        });
      }

      final orderDoc = {
        'orderId': orderId, 'userId': currentUser!.uid, 'orderDate': Timestamp.fromDate(now), 'status': 'Delivered', 'currentStatusIndex': 4,
        'items': itemsWithSeller, 'shippingAddress': widget.orderData['shippingAddress'], 'shippingMethod': widget.orderData['shippingMethod'],
        'shippingCost': widget.orderData['shippingCost'], 'packagingCost': widget.orderData['packagingCost'], 'paymentMethod': selectedPayment,
        'paymentStatus': 'Completed', 'transactionId': transactionId, 'itemsTotal': widget.orderData['itemsTotal'], 'discount': widget.orderData['discount'],
        'greenCoinsUsed': widget.orderData['greenCoinsUsed'], 'grandTotal': widget.orderData['grandTotal'], 'greenCoinsToEarn': widget.orderData['greenCoinsToEarn'] ?? 0,
        'trackingNumber': trackingNumber, 'estimatedDelivery': {'from': Timestamp.fromDate(now), 'to': Timestamp.fromDate(now)},
        'statusHistory': _getCompleteStatusHistory(now), 'isReceived': false, 'hasFeedback': false,
      };

      await FirebaseFirestore.instance.collection('orders').doc(orderId).set(orderDoc);

      if (widget.orderData['greenCoinsUsed'] > 0) {
        await _updateGreenCoins(-widget.orderData['greenCoinsUsed']);
        await _recordTransaction(transactionId: '${transactionId}_used', amount: -widget.orderData['greenCoinsUsed'], activity: 'purchase', description: 'Used coins for discount');
      }

      int earnedCoins = widget.orderData['greenCoinsToEarn'] ?? 0;
      if (earnedCoins > 0) {
        await _updateGreenCoins(earnedCoins);
        await _recordTransaction(transactionId: '${transactionId}_earned', amount: earnedCoins, activity: 'purchase_preowned_product', description: 'Earned coins from purchase');
      }

      for (var item in widget.orderData['items']) {
        var cartQuery = await FirebaseFirestore.instance.collection('cart_items').where('userId', isEqualTo: currentUser!.uid).where('productId', isEqualTo: item['productId']).get();
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

      await FirebaseFirestore.instance.collection('donation_record').doc(transactionId).set({
        'userId': currentUser!.uid, 'createdAt': FieldValue.serverTimestamp(), 'amount': amount, 'donationCategory': category,
        'greenCoinsEarned': earnedCoins, 'paymentMethod': selectedPayment, 'transactionId': transactionId, 'status': 'Completed',
      });

      await _updateGreenCoins(earnedCoins);
      await _recordTransaction(transactionId: transactionId, amount: earnedCoins, activity: 'donation', description: 'Earned coins from $category donation');

      if (!mounted) return;
      _navigateToConfirmation(transactionId: transactionId, extraData: {'type': 'donation', 'greenCoinsEarned': earnedCoins});
    } catch (e) {
      _handleError(e);
    }
  }

  Future<void> _processRepairPayment() async {
    if (!_validateUser()) return;
    setState(() => isProcessing = true);

    try {
      final transactionId = _generateTransactionId();
      final repairOption = Map<String, String>.from(widget.orderData['repair_option']);
      final repairType = repairOption['Repair'] ?? 'Repair';
      final priceStr = repairOption['Price'] ?? '0';
      final matches = RegExp(r'\d+').allMatches(priceStr);
      final int price = matches.isNotEmpty ? int.parse(matches.first.group(0)!) : 0;
      final int earnedCoins = price;

      await FirebaseFirestore.instance.collection('repair_record').doc(widget.orderData['repairRecordId']).update({
        'status': 'Completed', 'paymentMethod': selectedPayment, 'transactionId': transactionId, 'paidAt': FieldValue.serverTimestamp(),
      });

      await _updateGreenCoins(earnedCoins);
      await _recordTransaction(transactionId: transactionId, amount: earnedCoins, activity: 'repair', description: 'Earned coins from repair: $repairType');

      if (!mounted) return;
      _navigateToConfirmation(transactionId: transactionId, extraData: {'type': 'repair', 'greenCoinsEarned': earnedCoins});
    } catch (e) {
      _handleError(e);
    }
  }

  bool _validateUser() {
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('User not logged in', style: TextStyle(fontFamily: 'Roboto', fontWeight: FontWeight.w500)),
        backgroundColor: Color(0xFFD32F2F), behavior: SnackBarBehavior.floating,
      ));
      return false;
    }
    return true;
  }

  Future<void> _updateGreenCoins(int amount) async {
    await FirebaseFirestore.instance.collection('user_profile').doc(currentUser!.uid).update({'greenCoins': FieldValue.increment(amount)});
  }

  Future<void> _recordTransaction({required String transactionId, required int amount, required String activity, required String description}) async {
    await FirebaseFirestore.instance.collection('user_profile').doc(currentUser!.uid).collection('green_coin_transactions').add({
      'transactionId': transactionId, 'amount': amount, 'activity': activity, 'description': description, 'createdAt': FieldValue.serverTimestamp(),
    });
  }

  void _handleError(dynamic e) {
    debugPrint('Payment Error: $e');
    if (mounted) {
      setState(() => isProcessing = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Payment failed: ${e.toString()}', style: const TextStyle(fontFamily: 'Roboto', fontWeight: FontWeight.w500)),
        backgroundColor: const Color(0xFFD32F2F), behavior: SnackBarBehavior.floating,
      ));
    }
  }

  void _navigateToConfirmation({String orderId = '', required String transactionId, Map<String, dynamic>? extraData}) {
    final finalOrderData = Map<String, dynamic>.from(widget.orderData);
    if (extraData != null) finalOrderData.addAll(extraData);

    Navigator.pushReplacement(context, MaterialPageRoute(
      builder: (context) => PaymentConfirmation(orderData: finalOrderData, orderId: orderId, transactionId: transactionId, paymentMethod: selectedPayment),
    ));
  }

  List<Map<String, dynamic>> _getCompleteStatusHistory(DateTime now) {
    return [
      {'status': 'Order Placed', 'timestamp': Timestamp.fromDate(now), 'description': 'Order placed successfully.'},
      {'status': 'Processing', 'timestamp': Timestamp.fromDate(now), 'description': 'Order is being processed.'},
      {'status': 'Shipped', 'timestamp': Timestamp.fromDate(now), 'description': 'Order has been shipped.'},
      {'status': 'Out for Delivery', 'timestamp': Timestamp.fromDate(now), 'description': 'Order is out for delivery.'},
      {'status': 'Delivered', 'timestamp': Timestamp.fromDate(now), 'description': 'Order has been delivered.'},
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.white, elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF2E7D32), size: 20), onPressed: () => Navigator.pop(context)),
        title: const Text('Payment', style: TextStyle(fontFamily: 'Roboto', fontWeight: FontWeight.w700, fontSize: 20, color: Color(0xFF212121))),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(color: const Color(0xFF2E7D32), borderRadius: BorderRadius.circular(6)),
                      child: const Icon(Icons.credit_card, color: Colors.white, size: 16),
                    ),
                    const SizedBox(width: 8),
                    const Text('Payment Methods', style: TextStyle(fontFamily: 'Roboto', fontWeight: FontWeight.w700, fontSize: 16, color: Color(0xFF212121))),
                  ],
                ),
                const SizedBox(height: 16),
                _PaymentMethodTile(icon: 'assets/images/icon/VISA.png', label: 'Visa', isSelected: selectedPayment == 'Visa', onTap: () => setState(() => selectedPayment = 'Visa')),
                _PaymentMethodTile(icon: 'assets/images/icon/Paypal.png', label: 'PayPal', isSelected: selectedPayment == 'PayPal', onTap: () => setState(() => selectedPayment = 'PayPal')),
                _PaymentMethodTile(icon: 'assets/images/icon/Online_Transfer.png', label: 'Bank Transfer', isSelected: selectedPayment == 'Bank Transfer', onTap: () => setState(() => selectedPayment = 'Bank Transfer')),
                _PaymentMethodTile(icon: 'assets/images/icon/TNG.png', label: 'Touch n Go', isSelected: selectedPayment == 'Touch n Go', onTap: () => setState(() => selectedPayment = 'Touch n Go')),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(color: const Color(0xFF2E7D32), borderRadius: BorderRadius.circular(6)),
                      child: const Icon(Icons.more_horiz, color: Colors.white, size: 16),
                    ),
                    const SizedBox(width: 8),
                    const Text('Other Methods', style: TextStyle(fontFamily: 'Roboto', fontWeight: FontWeight.w700, fontSize: 16, color: Color(0xFF212121))),
                  ],
                ),
                const SizedBox(height: 16),
                _PaymentMethodTile(icon: 'assets/images/icon/cash-on-delivery-icon.png', label: 'Cash on Delivery', isSelected: selectedPayment == 'Cash on Delivery', onTap: () => setState(() => selectedPayment = 'Cash on Delivery')),
                const SizedBox(height: 32),
                CustomButton(
                  text: isProcessing ? "Processing..." : "Complete Payment",
                  onPressed: isProcessing ? () {} : _processPayment,
                  isLoading: isProcessing,
                  backgroundColor: const Color(0xFF2E7D32),
                  minimumSize: const Size(double.infinity, 54),
                  borderRadius: 12,
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
          if (isProcessing) Container(color: Colors.black12, child: const Center(child: CircularProgressIndicator(color: Color(0xFF2E7D32), strokeWidth: 3))),
        ],
      ),
    );
  }
}

class _PaymentMethodTile extends StatelessWidget {
  final String icon, label;
  final bool isSelected;
  final VoidCallback onTap;

  const _PaymentMethodTile({required this.icon, required this.label, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isSelected ? const Color(0xFF2E7D32) : Colors.grey[300]!, width: 2),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2))],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: Colors.grey[50], borderRadius: BorderRadius.circular(8)),
              child: Image.asset(icon, height: 28, width: 36, fit: BoxFit.contain, errorBuilder: (_, __, ___) => const Icon(Icons.payment, size: 28)),
            ),
            const SizedBox(width: 16),
            Text(label, style: const TextStyle(fontFamily: 'Roboto', fontSize: 16, fontWeight: FontWeight.w500, color: Color(0xFF212121))),
            const Spacer(),
            Container(
              width: 24, height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? const Color(0xFF2E7D32) : Colors.white,
                border: Border.all(color: isSelected ? const Color(0xFF2E7D32) : Colors.grey[400]!, width: 2),
              ),
              child: isSelected ? const Icon(Icons.check, color: Colors.white, size: 16) : null,
            ),
          ],
        ),
      ),
    );
  }
}