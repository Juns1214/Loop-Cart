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
          Text(label, style: TextStyle(fontSize: 16, color: Colors.grey[600])),
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

  String _getPaymentType() {
    if (widget.orderData.containsKey('type')) {
      return widget.orderData['type'];
    }
    return 'purchase';
  }

  Widget _buildPurchaseConfirmation() {
    int totalItems = 0;
    for (var item in widget.orderData['items']) {
      totalItems += (item['quantity'] as int? ?? 1);
    }

    String formattedDate = DateFormat('MMM dd, yyyy').format(DateTime.now());
    String shippingDisplay = widget.orderData['shippingMethod'] == 'Express'
        ? 'Express (2-3 days)'
        : 'Standard (5-6 days)';

    return Column(
      children: [
        // Success Animation
        Center(
          child: Lottie.asset(
            'assets/lottie/Success.json',
            width: 200,
            height: 200,
            fit: BoxFit.fill,
            repeat: true,
            animate: true,
          ),
        ),
        const SizedBox(height: 20),

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

              labelValueRow(
                'Items ($totalItems):',
                'RM ${widget.orderData['itemsTotal'].toStringAsFixed(2)}',
              ),
              labelValueRow(
                'Shipping ($shippingDisplay):',
                widget.orderData['shippingCost'] == 0
                    ? 'FREE'
                    : 'RM ${widget.orderData['shippingCost'].toStringAsFixed(2)}',
              ),
              labelValueRow(
                'Packaging:',
                'RM ${widget.orderData['packagingCost'].toStringAsFixed(2)}',
              ),

              if (widget.orderData['discount'] > 0)
                labelValueRow(
                  'Discount:',
                  '-RM ${widget.orderData['discount'].toStringAsFixed(2)}',
                ),

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
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[600],
                            ),
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
      ],
    );
  }

  Widget _buildDonationConfirmation() {
    String formattedDate = DateFormat('MMM dd, yyyy').format(DateTime.now());
    double amount = widget.orderData['amount'] ?? 0.0;
    String category = widget.orderData['category'] ?? 'General';
    int greenCoins = widget.orderData['greenCoinsEarned'] ?? 0;

    return Column(
      children: [
        Center(
          child: Lottie.asset(
            'assets/lottie/Success.json',
            width: 200,
            height: 200,
            fit: BoxFit.fill,
            repeat: true,
            animate: true,
          ),
        ),
        const SizedBox(height: 20),

        Text(
          'Donation Successful!',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2E5BFF),
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 10),

        Text(
          'Thank you for making a difference!\nYour contribution helps save our planet.',
          style: TextStyle(fontSize: 16, color: Colors.grey[700]),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 30),

        // Donation Summary Card
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
                'Donation Summary',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              SizedBox(height: 16),
              Divider(),

              labelValueRow('Transaction ID:', widget.transactionId),
              labelValueRow('Date:', formattedDate),
              labelValueRow('Payment Method:', widget.paymentMethod),
              labelValueRow('Category:', category),

              SizedBox(height: 8),
              Divider(thickness: 2),
              SizedBox(height: 8),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Donation Amount:',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  Text(
                    'RM ${amount.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2E5BFF),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Green Coins Earned
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Color(0xFFF0FDF4),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Color(0xFF1B6839).withOpacity(0.2)),
          ),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  image: DecorationImage(
                    image: AssetImage('assets/images/icon/Green Coin.png'),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Green Coins Earned',
                      style: TextStyle(
                        color: Color(0xFF1B6839),
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'You earned $greenCoins Green Coins!',
                      style: TextStyle(color: Color(0xFF1B6839), fontSize: 14),
                    ),
                  ],
                ),
              ),
              Text(
                '+$greenCoins',
                style: TextStyle(
                  color: Color(0xFF1B6839),
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRepairConfirmation() {
    String formattedDate = DateFormat('MMM dd, yyyy').format(DateTime.now());
    double amount = widget.orderData['amount'] ?? 0.0;
    String repairType = widget.orderData['repairType'] ?? 'Repair Service';
    int greenCoins = widget.orderData['greenCoinsEarned'] ?? 0;

    return Column(
      children: [
        Center(
          child: Lottie.asset(
            'assets/lottie/Success.json',
            width: 200,
            height: 200,
            fit: BoxFit.fill,
            repeat: true,
            animate: true,
          ),
        ),
        const SizedBox(height: 20),

        Text(
          'Payment Successful!',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2E5BFF),
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 10),

        Text(
          'Your repair service has been confirmed.\nWe\'ll contact you soon!',
          style: TextStyle(fontSize: 16, color: Colors.grey[700]),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 30),

        // Repair Summary Card
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
                'Repair Service Summary',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              SizedBox(height: 16),
              Divider(),

              labelValueRow('Transaction ID:', widget.transactionId),
              labelValueRow('Date:', formattedDate),
              labelValueRow('Payment Method:', widget.paymentMethod),
              labelValueRow('Service:', repairType),

              SizedBox(height: 8),
              Divider(thickness: 2),
              SizedBox(height: 8),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Service Fee:',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  Text(
                    'RM ${amount.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2E5BFF),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Green Coins Earned
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Color(0xFFF0FDF4),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Color(0xFF1B6839).withOpacity(0.2)),
          ),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  image: DecorationImage(
                    image: AssetImage('assets/images/icon/Green Coin.png'),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Green Coins Earned',
                      style: TextStyle(
                        color: Color(0xFF1B6839),
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'You earned $greenCoins Green Coins!',
                      style: TextStyle(color: Color(0xFF1B6839), fontSize: 14),
                    ),
                  ],
                ),
              ),
              Text(
                '+$greenCoins',
                style: TextStyle(
                  color: Color(0xFF1B6839),
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    String paymentType = _getPaymentType();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.black),
          onPressed: () {
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

            // Show appropriate confirmation based on type
            if (paymentType == 'donation')
              _buildDonationConfirmation()
            else if (paymentType == 'repair')
              _buildRepairConfirmation()
            else
              _buildPurchaseConfirmation(),

            const SizedBox(height: 12),

            // Continue Shopping/Home Button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.of(context).popUntil((route) => route.isFirst);
                },
                icon: Icon(
                  paymentType == 'purchase'
                      ? Icons.shopping_bag_outlined
                      : Icons.home_outlined,
                ),
                label: Text(
                  paymentType == 'purchase'
                      ? "Continue Shopping"
                      : "Back to Home",
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: paymentType == 'purchase'
                      ? const Color(0xFF388E3C)
                      : const Color(0xFF2E5BFF),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  side: BorderSide(
                    color: paymentType == 'purchase'
                        ? Color(0xFF388E3C)
                        : Color(0xFF2E5BFF),
                    width: 2,
                  ),
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
