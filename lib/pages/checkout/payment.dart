import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class Payment extends StatefulWidget {
  final Map<String, dynamic> orderData;

  const Payment({super.key, required this.orderData});

  @override
  State<Payment> createState() => _PaymentState();
}

class _PaymentState extends State<Payment> {
  String selectedPayment = 'Visa';
  bool isProcessing = false;

  // Get current user safely
  User? get currentUser => FirebaseAuth.instance.currentUser;

  // Generate unique transaction ID
  String _generateTransactionId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = (timestamp % 10000).toString().padLeft(4, '0');
    return 'TXN$timestamp$random';
  }

  // Generate unique order ID
  String _generateOrderId() {
    final now = DateTime.now();
    final dateStr =
        '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}';
    final random = (now.millisecondsSinceEpoch % 10000).toString().padLeft(4, '0');
    return 'ORD$dateStr$random';
  }

  // Generate tracking number
  String _generateTrackingNumber() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = (timestamp % 100000000).toString().padLeft(8, '0');
    return 'TRK$random';
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

      // Get donation amount and category from orderData
      final double donationAmount = widget.orderData['amount'] ?? 0.0;
      final String donationCategory = widget.orderData['category'] ?? 'General';

      // Calculate green coins earned (20 coins per RM10)
      final int greenCoinsEarned = ((donationAmount / 10) * 20).floor();

      // Create donation record in Firestore
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

      // Save donation to Firestore
      await FirebaseFirestore.instance
          .collection('donation_record')
          .doc(transactionId)
          .set(donationDocument);

      // Update user's green coins
      await FirebaseFirestore.instance
          .collection('user_profile')
          .doc(currentUser!.uid)
          .update({'greenCoins': FieldValue.increment(greenCoinsEarned)});

      if (!mounted) return;
      
      setState(() {
        isProcessing = false;
      });

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Donation successful! You earned $greenCoinsEarned Green Coins.',
          ),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 3),
        ),
      );

      // Navigate back
      Navigator.pop(context);
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

  // Process regular order payment
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

      // Calculate estimated delivery dates
      int deliveryDays = widget.orderData['shippingMethod'] == 'Express' ? 3 : 6;
      final estimatedDeliveryFrom = now.add(Duration(days: deliveryDays));
      final estimatedDeliveryTo = estimatedDeliveryFrom.add(const Duration(days: 1));

      // Prepare items with seller info
      List<Map<String, dynamic>> itemsWithSeller = [];

      for (var item in widget.orderData['items']) {
        String sellerName = item['seller'] ?? 'Unknown Seller';

        // Fetch seller info
        QuerySnapshot sellerQuery = await FirebaseFirestore.instance
            .collection('seller')
            .where('name', isEqualTo: sellerName)
            .limit(1)
            .get();

        String sellerId = '';
        String sellerProfileImage = '';

        if (sellerQuery.docs.isNotEmpty) {
          var sellerData = sellerQuery.docs.first.data() as Map<String, dynamic>;
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
        });
      }

      // Create order document
      Map<String, dynamic> orderDocument = {
        'orderId': orderId,
        'userId': currentUser!.uid,
        'orderDate': Timestamp.fromDate(now),
        'status': 'Order Placed',
        'currentStatusIndex': 0,
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
        'trackingNumber': trackingNumber,
        'estimatedDelivery': {
          'from': Timestamp.fromDate(estimatedDeliveryFrom),
          'to': Timestamp.fromDate(estimatedDeliveryTo),
        },
        'statusHistory': [
          {
            'status': 'Order Placed',
            'timestamp': Timestamp.fromDate(now),
            'description': 'Your order has been placed successfully.',
          },
        ],
        'lastStatusUpdate': Timestamp.fromDate(now),
      };

      // Save order to Firestore
      await FirebaseFirestore.instance
          .collection('orders')
          .doc(orderId)
          .set(orderDocument);

      // Deduct green coins
      if (widget.orderData['greenCoinsUsed'] > 0) {
        await FirebaseFirestore.instance
            .collection('user_profile')
            .doc(currentUser!.uid)
            .update({
              'greenCoins': FieldValue.increment(-widget.orderData['greenCoinsUsed']),
            });
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

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Order placed successfully!'),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pop(context);
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
    // Check if this is a donation payment
    if (widget.orderData.containsKey('category') &&
        widget.orderData.containsKey('amount') &&
        !widget.orderData.containsKey('items')) {
      await _processDonationPayment();
    } else {
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
                  color: isSelected ? const Color(0xFF2E5BFF) : Colors.grey[400]!,
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

          // Loading overlay
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