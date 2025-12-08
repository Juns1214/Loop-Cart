import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:intl/intl.dart';
import '../checkout/order_status.dart';
import '../../widget/custom_button.dart'; // Ensure this import path is correct

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
  
  // --- Data Helpers ---
  String _getPaymentType() => widget.orderData['type'] ?? 'purchase';

  // --- Main Build ---
  @override
  Widget build(BuildContext context) {
    final type = _getPaymentType();
    
    // Determine content based on type
    String title = 'Payment Successful!';
    String subtitle = 'Your transaction has been completed.';
    Color primaryColor = const Color(0xFF388E3C); // Default Green
    List<Widget> summaryChildren = [];
    int greenCoinsEarned = widget.orderData['greenCoinsEarned'] ?? widget.orderData['greenCoinsToEarn'] ?? 0;

    // Logic Switch
    if (type == 'donation') {
      primaryColor = const Color(0xFF2E5BFF); // Blue
      title = 'Donation Successful!';
      subtitle = 'Thank you for making a difference!\nYour contribution helps save our planet.';
      summaryChildren = _buildDonationSummaryRows();
    } else if (type == 'repair') {
      primaryColor = const Color(0xFF2E5BFF); // Blue
      subtitle = 'Your repair service has been confirmed.\nWe\'ll contact you soon!';
      summaryChildren = _buildRepairSummaryRows();
    } else {
      // Purchase
      subtitle = 'Your order has been placed successfully.\nThank you for your purchase!';
      summaryChildren = _buildPurchaseSummaryRows();
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.black),
          onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Column(
          children: [
            // 1. Success Animation & Header
            _SuccessHeader(
              title: title,
              subtitle: subtitle,
              color: primaryColor,
            ),
            
            const SizedBox(height: 30),

            // 2. Summary Card
            _SummaryCard(
              title: type == 'donation' ? 'Donation Summary' : 
                     type == 'repair' ? 'Service Summary' : 'Order Summary',
              children: [
                _LabelValueRow('Transaction ID:', widget.transactionId),
                _LabelValueRow('Date:', DateFormat('MMM dd, yyyy').format(DateTime.now())),
                _LabelValueRow('Payment Method:', widget.paymentMethod),
                const Divider(height: 24),
                ...summaryChildren,
              ],
            ),

            // 3. Green Coins (Conditional)
            if (greenCoinsEarned > 0) ...[
              const SizedBox(height: 20),
              _GreenCoinsEarnedCard(coins: greenCoinsEarned),
            ],

            const SizedBox(height: 30),

            // 4. Action Buttons
            if (type == 'purchase')
              CustomButton(
                text: "View Order Status",
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => OrderStatus(orderId: widget.orderId),
                    ),
                  );
                },
                backgroundColor: primaryColor,
                minimumSize: const Size(double.infinity, 54),
              ),

            const SizedBox(height: 12),

            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
                icon: Icon(type == 'purchase' ? Icons.shopping_bag_outlined : Icons.home_outlined),
                label: Text(type == 'purchase' ? "Continue Shopping" : "Back to Home"),
                style: OutlinedButton.styleFrom(
                  foregroundColor: primaryColor,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  side: BorderSide(color: primaryColor, width: 2),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // --- Specific Logic Builders ---

  List<Widget> _buildPurchaseSummaryRows() {
    int totalItems = 0;
    if (widget.orderData['items'] != null) {
      for (var item in widget.orderData['items']) {
        totalItems += (item['quantity'] as int? ?? 1);
      }
    }
    
    final shippingDisplay = widget.orderData['shippingMethod'] == 'Express' ? 'Express (2-3 days)' : 'Standard (5-6 days)';
    
    return [
      _LabelValueRow('Order ID:', widget.orderId),
      _LabelValueRow('Items ($totalItems):', 'RM ${widget.orderData['itemsTotal'].toStringAsFixed(2)}'),
      _LabelValueRow(
        'Shipping ($shippingDisplay):', 
        widget.orderData['shippingCost'] == 0 ? 'FREE' : 'RM ${widget.orderData['shippingCost'].toStringAsFixed(2)}'
      ),
      _LabelValueRow('Packaging:', 'RM ${widget.orderData['packagingCost'].toStringAsFixed(2)}'),
      if (widget.orderData['discount'] > 0)
        _LabelValueRow('Discount:', '-RM ${widget.orderData['discount'].toStringAsFixed(2)}', valueColor: Colors.red),
      
      const Divider(height: 24, thickness: 1.5),
      
      _TotalRow(
        label: 'Total Paid', 
        amount: widget.orderData['grandTotal'], 
        color: const Color(0xFF388E3C),
      ),
    ];
  }

  List<Widget> _buildDonationSummaryRows() {
    return [
      _LabelValueRow('Category:', widget.orderData['category'] ?? 'General'),
      const Divider(height: 24, thickness: 1.5),
      _TotalRow(
        label: 'Donation Amount', 
        amount: widget.orderData['amount'], 
        color: const Color(0xFF2E5BFF),
      ),
    ];
  }

  List<Widget> _buildRepairSummaryRows() {
    return [
      _LabelValueRow('Service Type:', widget.orderData['repairType'] ?? 'General Repair'),
      const Divider(height: 24, thickness: 1.5),
      _TotalRow(
        label: 'Service Fee', 
        amount: widget.orderData['amount'], 
        color: const Color(0xFF2E5BFF),
      ),
    ];
  }
}

// ==============================================================================
// REUSABLE WIDGETS (Extracted to clean up the main logic)
// ==============================================================================

class _SuccessHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final Color color;

  const _SuccessHeader({required this.title, required this.subtitle, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Lottie.asset(
          'assets/lottie/Success.json',
          width: 180,
          height: 180,
          repeat: false,
        ),
        const SizedBox(height: 10),
        Text(
          title,
          style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: color),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          subtitle,
          style: TextStyle(fontSize: 16, color: Colors.grey[800], height: 1.4),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _SummaryCard({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black)),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }
}

class _LabelValueRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _LabelValueRow(this.label, this.value, {this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 15, color: Colors.grey[700], fontWeight: FontWeight.w500)),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 15, 
                color: valueColor ?? Colors.black87, 
                fontWeight: FontWeight.bold
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}

class _TotalRow extends StatelessWidget {
  final String label;
  final dynamic amount; // can be int or double
  final Color color;

  const _TotalRow({required this.label, required this.amount, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          '$label:',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black),
        ),
        Text(
          'RM ${(amount is int ? amount.toDouble() : amount).toStringAsFixed(2)}',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color),
        ),
      ],
    );
  }
}

class _GreenCoinsEarnedCard extends StatelessWidget {
  final int coins;

  const _GreenCoinsEarnedCard({required this.coins});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFF0FDF4), Color(0xFFDCFCE7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF388E3C).withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
            child: Center(
              child: Image.asset(
                'assets/images/icon/Green Coin.png',
                width: 28, height: 28,
                errorBuilder: (_, __, ___) => const Icon(Icons.eco, color: Color(0xFF388E3C)),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Green Coins Earned',
                  style: TextStyle(color: Color(0xFF388E3C), fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Text(
                  'You earned $coins coins!',
                  style: TextStyle(color: const Color(0xFF388E3C).withOpacity(0.9), fontSize: 14),
                ),
              ],
            ),
          ),
          Text(
            '+$coins',
            style: const TextStyle(color: Color(0xFF388E3C), fontSize: 24, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}