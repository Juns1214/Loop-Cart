import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../checkout/payment_confirmation.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Payment(orderData: {}),
    );
  }
}

class Payment extends StatefulWidget {
  final Map<String, dynamic> orderData;
  
  const Payment({super.key, required this.orderData});

  @override
  State<Payment> createState() => _PaymentState();
}

class _PaymentState extends State<Payment> {
  final User? currentUser = FirebaseAuth.instance.currentUser;
  String selectedPayment = 'Visa';
  bool isProcessing = false;

  // Generate unique transaction ID
  String _generateTransactionId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = (timestamp % 10000).toString().padLeft(4, '0');
    return 'TXN$timestamp$random';
  }

  // Generate unique order ID
  String _generateOrderId() {
    final now = DateTime.now();
    final dateStr = '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}';
    final random = (now.millisecondsSinceEpoch % 10000).toString().padLeft(4, '0');
    return 'ORD$dateStr$random';
  }

  // Generate tracking number
  String _generateTrackingNumber() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = (timestamp % 100000000).toString().padLeft(8, '0');
    return 'TRK$random';
  }

  Future<void> _processPayment() async {
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
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

      // Calculate estimated delivery dates based on shipping method
      int deliveryDays = widget.orderData['shippingMethod'] == 'Express' ? 3 : 6;
      final estimatedDeliveryFrom = now.add(Duration(days: deliveryDays));
      final estimatedDeliveryTo = estimatedDeliveryFrom.add(Duration(days: 1));

      // Prepare items with seller info
      List<Map<String, dynamic>> itemsWithSeller = [];
      
      for (var item in widget.orderData['items']) {
        String sellerName = item['seller'] ?? 'Unknown Seller';
        
        // Fetch seller info from seller collection by matching name
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

      // Create order document in Firestore
      Map<String, dynamic> orderDocument = {
        'orderId': orderId,
        'userId': currentUser!.uid,
        'orderDate': Timestamp.fromDate(now),
        'status': 'Order Placed',
        'currentStatusIndex': 0,
        
        // Items
        'items': itemsWithSeller,
        
        // Shipping & Address
        'shippingAddress': widget.orderData['shippingAddress'],
        'shippingMethod': widget.orderData['shippingMethod'],
        'shippingCost': widget.orderData['shippingCost'],
        
        // Packaging
        'packagingType': widget.orderData['packagingType'],
        'packagingCost': widget.orderData['packagingCost'],
        
        // Payment
        'paymentMethod': selectedPayment,
        'paymentStatus': 'Completed',
        'transactionId': transactionId,
        
        // Pricing
        'itemsTotal': widget.orderData['itemsTotal'],
        'discount': widget.orderData['discount'],
        'greenCoinsUsed': widget.orderData['greenCoinsUsed'],
        'grandTotal': widget.orderData['grandTotal'],
        
        // Tracking
        'trackingNumber': trackingNumber,
        'estimatedDelivery': {
          'from': Timestamp.fromDate(estimatedDeliveryFrom),
          'to': Timestamp.fromDate(estimatedDeliveryTo),
        },
        
        // Status History
        'statusHistory': [
          {
            'status': 'Order Placed',
            'timestamp': Timestamp.fromDate(now),
            'description': 'Your order has been placed successfully.',
          }
        ],
        
        // For progressive status updates
        'lastStatusUpdate': Timestamp.fromDate(now),
      };

      // Save order to Firestore
      await FirebaseFirestore.instance
          .collection('orders')
          .doc(orderId)
          .set(orderDocument);

      // Deduct green coins from user profile
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
        // Query cart_items where userId and productId match
        QuerySnapshot cartQuery = await FirebaseFirestore.instance
            .collection('cart_items')
            .where('userId', isEqualTo: currentUser!.uid)
            .where('productId', isEqualTo: item['productId'])
            .get();
        
        // Delete all matching documents
        for (var doc in cartQuery.docs) {
          await doc.reference.delete();
        }
      }

      setState(() {
        isProcessing = false;
      });

      // Navigate to Payment Confirmation page
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
      setState(() {
        isProcessing = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to process payment. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
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
                      paymentMethodContainer('assets/images/icon/VISA.png', 'Visa', selectedPayment == 'Visa'),
                      paymentMethodContainer('assets/images/icon/Paypal.png', 'PayPal', selectedPayment == 'PayPal'),
                      paymentMethodContainer('assets/images/icon/Online_Transfer.png', 'Bank Transfer', selectedPayment == 'Bank Transfer'),
                      paymentMethodContainer('assets/images/icon/TNG.png', 'Touch n Go', selectedPayment == 'Touch n Go'),
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
                    label: Text(isProcessing ? "Processing..." : "Make Payment"),
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
                      children: [
                        CircularProgressIndicator(color: Color(0xFF2E5BFF)),
                        SizedBox(height: 16),
                        Text(
                          'Processing Payment...',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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