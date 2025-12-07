import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../checkout/payment_confirmation.dart';

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

  // Record green coin transaction
  Future<void> _recordGreenCoinTransaction({
    required String transactionId,
    required int amount,
    required String activity,
    required String description,
    Map<String, dynamic>? activityDetails,
  }) async {
    if (currentUser == null) return;

    try {
      // Get current balance
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('user_profile')
          .doc(currentUser!.uid)
          .get();

      int currentBalance = 0;
      if (userDoc.exists) {
        Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
        currentBalance = userData['greenCoins'] ?? 0;
      }

      int newBalance = currentBalance + amount;

      // Record transaction
      await FirebaseFirestore.instance
          .collection('green_coin_transactions')
          .doc(transactionId)
          .set({
            'transactionId': transactionId,
            'userId': currentUser!.uid,
            'amount': amount,
            'balanceAfter': newBalance,
            'activity': activity,
            'activityDetails': activityDetails ?? {},
            'description': description,
            'createdAt': FieldValue.serverTimestamp(),
            'status': 'completed',
          });

      print(
        'Green coin transaction recorded: $amount coins, activity: $activity',
      );
    } catch (e) {
      print('Error recording green coin transaction: $e');
    }
  }

  // Process donation payment
  Future<void> _processDonationPayment() async {
    if (currentUser == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please login to continue'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      isProcessing = true;
    });

    try {
      final transactionId = _generateTransactionId();
      final now = DateTime.now();

      final double donationAmount = widget.orderData['amount'] ?? 0.0;
      final String donationCategory = widget.orderData['category'] ?? 'General';

      // Calculate green coins earned: RM1 = 1 coin
      final int greenCoinsEarned = donationAmount.floor();

      // Create donation record
      Map<String, dynamic> donationDocument = {
        'userId': currentUser!.uid,
        'createdAt': Timestamp.fromDate(now),
        'paymentMadeAt': Timestamp.fromDate(now),
        'amount': donationAmount,
        'donationCategory': donationCategory,
        'greenCoinsEarned': greenCoinsEarned,
        'paymentMethod': selectedPayment,
        'transactionId': transactionId,
        'status': 'Completed',
      };

      await FirebaseFirestore.instance
          .collection('donation_record')
          .doc(transactionId)
          .set(donationDocument);

      // Update user's green coins
      await FirebaseFirestore.instance
          .collection('user_profile')
          .doc(currentUser!.uid)
          .update({'greenCoins': FieldValue.increment(greenCoinsEarned)});

      // Record green coin transaction
      await _recordGreenCoinTransaction(
        transactionId: transactionId,
        amount: greenCoinsEarned,
        activity: 'donation',
        description:
            'Earned $greenCoinsEarned Green Coins from $donationCategory donation',
        activityDetails: {
          'donationAmount': donationAmount,
          'category': donationCategory,
        },
      );

      if (!mounted) return;

      setState(() {
        isProcessing = false;
      });

      // Navigate to payment confirmation
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => PaymentConfirmation(
            orderData: {
              'type': 'donation',
              'amount': donationAmount,
              'category': donationCategory,
              'greenCoinsEarned': greenCoinsEarned,
            },
            orderId: '',
            transactionId: transactionId,
            paymentMethod: selectedPayment,
          ),
        ),
      );
    } catch (e) {
      print('Error processing donation payment: $e');

      if (!mounted) return;

      setState(() {
        isProcessing = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to process donation. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _processRepairPayment() async {
    if (currentUser == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please login to continue'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      isProcessing = true;
    });

    try {
      final transactionId = _generateTransactionId();
      final now = DateTime.now();

      final Map<String, String> repairOption = Map<String, String>.from(
        widget.orderData['repair_option'],
      );
      final String repairType = repairOption['Repair'] ?? 'Custom Repair';
      final String priceStr = repairOption['Price'] ?? 'RM0';

      // Extract price
      final matches = RegExp(r'\d+').allMatches(priceStr);
      final numbers = matches.map((m) => int.parse(m.group(0)!)).toList();
      final int repairPrice = numbers.isNotEmpty
          ? numbers.reduce((a, b) => a > b ? a : b)
          : 0;

      final int greenCoinsEarned = repairPrice;

      // Get repair record ID from orderData
      String repairRecordId = widget.orderData['repairRecordId'];

      // Update specific repair record
      await FirebaseFirestore.instance
          .collection('repair_record')
          .doc(repairRecordId)
          .update({
            'paymentStatus': 'Completed',
            'paymentMethod': selectedPayment,
            'transactionId': transactionId,
            'paymentMadeAt': Timestamp.fromDate(now),
            'greenCoinsEarned': greenCoinsEarned,
          });

      // Update user's green coins
      await FirebaseFirestore.instance
          .collection('user_profile')
          .doc(currentUser!.uid)
          .update({'greenCoins': FieldValue.increment(greenCoinsEarned)});

      // Record green coin transaction
      await _recordGreenCoinTransaction(
        transactionId: transactionId,
        amount: greenCoinsEarned,
        activity: 'repair_service',
        description:
            'Earned $greenCoinsEarned Green Coins from $repairType service',
        activityDetails: {'repairType': repairType, 'repairPrice': repairPrice},
      );

      if (!mounted) return;

      setState(() {
        isProcessing = false;
      });

      // Navigate to payment confirmation
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => PaymentConfirmation(
            orderData: {
              'type': 'repair',
              'repairType': repairType,
              'amount': repairPrice.toDouble(),
              'greenCoinsEarned': greenCoinsEarned,
            },
            orderId: '',
            transactionId: transactionId,
            paymentMethod: selectedPayment,
          ),
        ),
      );
    } catch (e) {
      print('Error processing repair payment: $e');
      print('Stack trace: ${StackTrace.current}');

      if (!mounted) return;

      setState(() {
        isProcessing = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Payment failed: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Update the _processOrderPayment method in payment.dart
  // Replace the existing method with this updated version

  Future<void> _processOrderPayment() async {
    if (currentUser == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please login to continue'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      isProcessing = true;
    });

    try {
      final orderId = _generateOrderId();
      final transactionId = _generateTransactionId();
      final trackingNumber = _generateTrackingNumber();
      final now = DateTime.now();

      List<Map<String, dynamic>> itemsWithSeller = [];

      for (var item in widget.orderData['items']) {
        String sellerName = item['seller'] ?? 'Unknown Seller';

        QuerySnapshot sellerQuery = await FirebaseFirestore.instance
            .collection('seller')
            .where('name', isEqualTo: sellerName)
            .limit(1)
            .get();

        String sellerId = '';
        String sellerProfileImage = '';

        if (sellerQuery.docs.isNotEmpty) {
          var sellerData =
              sellerQuery.docs.first.data() as Map<String, dynamic>;
          sellerId = sellerData['sellerId'] ?? '';
          sellerProfileImage = sellerData['profileImage'] ?? '';
        }

        itemsWithSeller.add({
          'productId': item['productId'] ?? '',
          'productName': item['productName'] ?? '',
          'productPrice': item['productPrice'] ?? 0,
          'quantity': item['quantity'] ?? 1,
          'imageUrl': item['imageUrl'] ?? '',
          'seller': sellerName,
          'sellerId': sellerId,
          'sellerProfileImage': sellerProfileImage,
          'isPreowned': item['isPreowned'] ?? false,
        });
      }

      // Create complete status history for all stages
      List<Map<String, dynamic>> completeStatusHistory = [
        {
          'status': 'Order Placed',
          'timestamp': Timestamp.fromDate(now),
          'description': 'Your order has been placed successfully.',
        },
        {
          'status': 'Processing',
          'timestamp': Timestamp.fromDate(now),
          'description': 'Your order is being processed.',
        },
        {
          'status': 'Shipped',
          'timestamp': Timestamp.fromDate(now),
          'description': 'Your order has been shipped.',
        },
        {
          'status': 'Out for Delivery',
          'timestamp': Timestamp.fromDate(now),
          'description': 'Your order is out for delivery.',
        },
        {
          'status': 'Delivered',
          'timestamp': Timestamp.fromDate(now),
          'description': 'Your order has been delivered.',
        },
      ];

      Map<String, dynamic> orderDocument = {
        'orderId': orderId,
        'userId': currentUser!.uid,
        'orderDate': Timestamp.fromDate(now),
        'status': 'Delivered', // Set as delivered immediately
        'currentStatusIndex': 4, // Index 4 = Delivered
        'items': itemsWithSeller,
        'shippingAddress': widget.orderData['shippingAddress'],
        'shippingMethod': widget.orderData['shippingMethod'],
        'shippingCost': widget.orderData['shippingCost'],
        'packagingType': widget.orderData['packagingType'],
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
        'deliveredAt': Timestamp.fromDate(now), // Add delivery timestamp
        'statusHistory': completeStatusHistory, // Complete history
        'lastStatusUpdate': Timestamp.fromDate(now),
        'isReceived': false, // Track if user confirmed receipt
        'hasFeedback': false, // Track if user provided feedback
      };

      await FirebaseFirestore.instance
          .collection('orders')
          .doc(orderId)
          .set(orderDocument);

      // Deduct green coins if used
      if (widget.orderData['greenCoinsUsed'] > 0) {
        await FirebaseFirestore.instance
            .collection('user_profile')
            .doc(currentUser!.uid)
            .update({
              'greenCoins': FieldValue.increment(
                -widget.orderData['greenCoinsUsed'],
              ),
            });

        await _recordGreenCoinTransaction(
          transactionId: '${transactionId}_used',
          amount: -widget.orderData['greenCoinsUsed'],
          activity: 'purchase',
          description:
              'Used ${widget.orderData['greenCoinsUsed']} Green Coins for order discount',
          activityDetails: {
            'orderId': orderId,
            'discountAmount': widget.orderData['discount'],
          },
        );
      }

      // Add green coins for pre-owned purchases
      int greenCoinsToEarn = widget.orderData['greenCoinsToEarn'] ?? 0;
      if (greenCoinsToEarn > 0) {
        await FirebaseFirestore.instance
            .collection('user_profile')
            .doc(currentUser!.uid)
            .update({'greenCoins': FieldValue.increment(greenCoinsToEarn)});

        await _recordGreenCoinTransaction(
          transactionId: '${transactionId}_earned',
          amount: greenCoinsToEarn,
          activity: 'purchase_preowned_product',
          description:
              'Earned $greenCoinsToEarn Green Coins from purchasing pre-owned items',
          activityDetails: {
            'orderId': orderId,
            'itemsTotal': widget.orderData['itemsTotal'],
            'grandTotal': widget.orderData['grandTotal'],
          },
        );
      }

      // Delete items from cart
      for (var item in widget.orderData['items']) {
        QuerySnapshot cartQuery = await FirebaseFirestore.instance
            .collection('cart_items')
            .where('userId', isEqualTo: currentUser!.uid)
            .where('productId', isEqualTo: item['productId'])
            .get();

        for (var doc in cartQuery.docs) {
          await doc.reference.delete();
        }
      }

      if (!mounted) return;

      setState(() {
        isProcessing = false;
      });

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => PaymentConfirmation(
            orderData: widget.orderData,
            orderId: orderId,
            transactionId: transactionId,
            paymentMethod: selectedPayment,
          ),
        ),
      );
    } catch (e) {
      print('Error processing payment: $e');

      if (!mounted) return;

      setState(() {
        isProcessing = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to process payment. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Main payment processing method
  Future<void> _processPayment() async {
    // Check payment type and route accordingly
    if (widget.orderData.containsKey('category') &&
        widget.orderData.containsKey('amount') &&
        !widget.orderData.containsKey('items') &&
        !widget.orderData.containsKey('repair_option')) {
      // Donation
      await _processDonationPayment();
    } else if (widget.orderData.containsKey('repair_option')) {
      // Repair service
      await _processRepairPayment();
    } else {
      // Regular order
      await _processOrderPayment();
    }
  }

  Widget paymentMethodContainer(
    String paymentLogo,
    String paymentMethod,
    bool isSelected,
  ) {
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedPayment = paymentMethod;
        });
      },
      child: Container(
        height: 60,
        width: 350,
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.3),
              spreadRadius: 2,
              blurRadius: 5,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            const SizedBox(width: 20),
            Image.asset(paymentLogo, height: 50, width: 55, fit: BoxFit.fill),
            const SizedBox(width: 40),
            Text(paymentMethod),
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
                      : Colors.grey[400]!,
                  width: 2,
                ),
              ),
              child: isSelected
                  ? const Icon(Icons.check, color: Colors.white, size: 16)
                  : null,
            ),
            const SizedBox(width: 20),
          ],
        ),
      ),
    );
  }

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
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Select Payment Method',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
                const SizedBox(height: 20),
                Center(
                  child: Column(
                    children: [
                      paymentMethodContainer(
                        'assets/images/icon/VISA.png',
                        'Visa',
                        selectedPayment == 'Visa',
                      ),
                      paymentMethodContainer(
                        'assets/images/icon/Paypal.png',
                        'PayPal',
                        selectedPayment == 'PayPal',
                      ),
                      paymentMethodContainer(
                        'assets/images/icon/Online_Transfer.png',
                        'Bank Transfer',
                        selectedPayment == 'Bank Transfer',
                      ),
                      paymentMethodContainer(
                        'assets/images/icon/TNG.png',
                        'Touch n Go',
                        selectedPayment == 'Touch n Go',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 40),
                const Text(
                  'Other Methods',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
                const SizedBox(height: 16),
                Center(
                  child: paymentMethodContainer(
                    'assets/images/icon/cash-on-delivery-icon.png',
                    'Cash on Delivery',
                    selectedPayment == 'Cash on Delivery',
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: isProcessing ? null : _processPayment,
                    icon: const Icon(Icons.payments_outlined),
                    label: Text(
                      isProcessing ? "Processing..." : "Make Payment",
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2E5BFF),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          if (isProcessing)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: Center(
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        CircularProgressIndicator(color: Color(0xFF2E5BFF)),
                        SizedBox(height: 16),
                        Text(
                          'Processing Payment...',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
