import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lottie/lottie.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:intl/intl.dart';
import '../checkout/order_status.dart';

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
      home: PaymentConfirmation(
        orderData: {},
        orderId: '',
        transactionId: '',
        paymentMethod: '',
      ),
    );
  }
}

class PaymentConfirmation extends StatefulWidget {
  final Map<String, dynamic> orderData;
  final String orderId;
  final String transactionId;
  final String paymentMethod;

  const PaymentConfirmation({
    super.key,
    required this.orderData,
    required this.orderId,
    required this.transactionId,
    required this.paymentMethod,
  });

  @override
  State<PaymentConfirmation> createState() => _PaymentConfirmationState();
}

class _PaymentConfirmationState extends State<PaymentConfirmation> {
  Widget labelValueRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 16,
                color: Colors.black87,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Calculate total items
    int totalItems = 0;
    for (var item in widget.orderData['items']) {
      totalItems += (item['quantity'] as int? ?? 1);
    }

    // Format date
    String formattedDate = DateFormat('MMM dd, yyyy').format(DateTime.now());
    
    // Get shipping method display text
    String shippingDisplay = widget.orderData['shippingMethod'] == 'Express' 
        ? 'Express (2-3 days)' 
        : 'Standard (5-6 days)';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.black),
          onPressed: () {
            // Navigate back to home or shopping page
            Navigator.of(context).popUntil((route) => route.isFirst);
          },
        ),
        title: const Text(
          'Payment Confirmation',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(height: 10),

            // Success Animation
            Center(
              child: Lottie.asset(
                'assets/lottie/success.json',
                width: 200,
                height: 200,
                fit: BoxFit.fill,
                repeat: false,
                animate: true,
              ),
            ),

            const SizedBox(height: 20),

            // Success Message
            Text(
              'Payment Successful!',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Color(0xFF388E3C),
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 10),

            Text(
              'Your order has been placed successfully.\nThank you for your purchase!',
              style: TextStyle(fontSize: 16, color: Colors.grey[700]),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 30),

            // Order Summary Card
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Order Summary',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  SizedBox(height: 16),
                  Divider(),
                  
                  labelValueRow('Order ID:', widget.orderId),
                  labelValueRow('Date:', formattedDate),
                  labelValueRow('Payment Method:', widget.paymentMethod),
                  labelValueRow('Transaction ID:', widget.transactionId),
                  
                  SizedBox(height: 8),
                  Divider(),
                  SizedBox(height: 8),
                  
                  labelValueRow('Items ($totalItems):', 'RM ${widget.orderData['itemsTotal'].toStringAsFixed(2)}'),
                  labelValueRow('Shipping ($shippingDisplay):', 
                      widget.orderData['shippingCost'] == 0 
                          ? 'FREE' 
                          : 'RM ${widget.orderData['shippingCost'].toStringAsFixed(2)}'),
                  labelValueRow('Packaging:', 'RM ${widget.orderData['packagingCost'].toStringAsFixed(2)}'),
                  
                  if (widget.orderData['discount'] > 0)
                    labelValueRow('Discount:', '-RM ${widget.orderData['discount'].toStringAsFixed(2)}'),
                  
                  if (widget.orderData['greenCoinsUsed'] > 0)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Image.asset(
                                'assets/images/icon/Green Coin.png',
                                width: 20,
                                height: 20,
                                errorBuilder: (context, error, stackTrace) {
                                  return Icon(
                                    Icons.monetization_on,
                                    color: Color(0xFF388E3C),
                                    size: 20,
                                  );
                                },
                              ),
                              SizedBox(width: 8),
                              Text(
                                'Green Coins Used:',
                                style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                              ),
                            ],
                          ),
                          Text(
                            '${widget.orderData['greenCoinsUsed']} coins',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.black87,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  
                  SizedBox(height: 8),
                  Divider(thickness: 2),
                  SizedBox(height: 8),
                  
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Total Paid:',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      Text(
                        'RM ${widget.orderData['grandTotal'].toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF388E3C),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            // View Order Status Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => OrderStatus(orderId: widget.orderId),
                    ),
                  );
                },
                icon: const Icon(Icons.local_shipping_outlined),
                label: const Text("View Order Status"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF388E3C),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Continue Shopping Button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  // Navigate back to home/shopping page
                  Navigator.of(context).popUntil((route) => route.isFirst);
                },
                icon: const Icon(Icons.shopping_bag_outlined),
                label: const Text("Continue Shopping"),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF388E3C),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  side: BorderSide(color: Color(0xFF388E3C), width: 2),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}