import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:intl/intl.dart';
import '../../widget/custom_button.dart';

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
  String get _paymentType => widget.orderData['type'] ?? 'purchase';
  int get _greenCoinsEarned =>
      widget.orderData['greenCoinsEarned'] ??
      widget.orderData['greenCoinsToEarn'] ??
      0;

  @override
  Widget build(BuildContext context) {
    final type = _paymentType;
    final isPurchase = type == 'purchase';
    final isDonation = type == 'donation';
    final isRepair = type == 'repair';

    final primaryColor = isPurchase
        ? const Color(0xFF2E7D32)
        : const Color(0xFF1976D2);
    final title = isDonation
        ? 'Donation Successful!'
        : isRepair
        ? 'Service Confirmed!'
        : 'Payment Successful!';
    final subtitle = isDonation
        ? 'Thank you for making a difference!\nYour contribution helps save our planet.'
        : isRepair
        ? 'Your repair service has been confirmed.\nWe\'ll contact you soon!'
        : 'Your order has been placed successfully.\nThank you for your purchase!';

    return Scaffold(
      backgroundColor: const Color(0xFFF1F8F4),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Color(0xFF1B5E20), size: 24),
          onPressed: () =>
              Navigator.of(context).popUntil((route) => route.isFirst),
        ),
        title: const Text(
          'Confirmation',
          style: TextStyle(
            fontFamily: 'Roboto',
            fontWeight: FontWeight.w700,
            fontSize: 20,
            color: Color(0xFF1B5E20),
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _SuccessHeader(
              title: title,
              subtitle: subtitle,
              color: primaryColor,
            ),
            const SizedBox(height: 24),
            _SummaryCard(
              title: isDonation
                  ? 'Donation Summary'
                  : isRepair
                  ? 'Service Summary'
                  : 'Order Summary',
              children: [
                _LabelValueRow('Transaction ID', widget.transactionId),
                _LabelValueRow(
                  'Date',
                  DateFormat('MMM dd, yyyy').format(DateTime.now()),
                ),
                _LabelValueRow('Payment Method', widget.paymentMethod),
                const Divider(height: 24, thickness: 1.5),
                if (isPurchase)
                  ..._buildPurchaseSummary()
                else if (isDonation)
                  ..._buildDonationSummary()
                else
                  ..._buildRepairSummary(),
              ],
            ),
            if (_greenCoinsEarned > 0) ...[
              const SizedBox(height: 16),
              _GreenCoinsEarnedCard(coins: _greenCoinsEarned),
            ],
            const SizedBox(height: 24),
            CustomButton(
              text: "View My Activity",
              onPressed: () => Navigator.of(context).pushNamedAndRemoveUntil(
                '/my-activity',
                (route) => route.isFirst,
              ),
              backgroundColor: primaryColor,
              minimumSize: const Size(double.infinity, 56),
              borderRadius: 16,
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () =>
                    Navigator.of(context).popUntil((route) => route.isFirst),
                icon: Icon(
                  isPurchase
                      ? Icons.shopping_bag_outlined
                      : Icons.home_outlined,
                  size: 20,
                ),
                label: Text(
                  isPurchase ? "Continue Shopping" : "Back to Home",
                  style: const TextStyle(
                    fontFamily: 'Roboto',
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: primaryColor,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  side: BorderSide(color: primaryColor, width: 2),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
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

  List<Widget> _buildPurchaseSummary() {
    int totalItems = 0;
    double calculatedItemsTotal = 0.0;

    if (widget.orderData['items'] != null) {
      for (var item in widget.orderData['items']) {
        int qty = (item['quantity'] as int? ?? 1);
        double price = (item['productPrice'] ?? item['price'] ?? 0).toDouble();
        totalItems += qty;
        calculatedItemsTotal += (price * qty);
      }
    }

    final finalItemsTotal = widget.orderData['itemsTotal'] != null
        ? (widget.orderData['itemsTotal'] as num).toDouble()
        : calculatedItemsTotal;
    final shippingDisplay = widget.orderData['shippingMethod'] == 'Express'
        ? 'Express (2-3 days)'
        : 'Standard (5-6 days)';
    final shippingCost = (widget.orderData['shippingCost'] as num? ?? 0)
        .toDouble();
    final packagingCost = (widget.orderData['packagingCost'] as num? ?? 0)
        .toDouble();
    final discount = (widget.orderData['discount'] as num? ?? 0).toDouble();
    final grandTotal =
        (widget.orderData['grandTotal'] as num? ??
                (finalItemsTotal + shippingCost + packagingCost - discount))
            .toDouble();

    return [
      _LabelValueRow('Order ID', widget.orderId),
      _LabelValueRow(
        'Items ($totalItems)',
        'RM ${finalItemsTotal.toStringAsFixed(2)}',
      ),
      _LabelValueRow(
        'Shipping ($shippingDisplay)',
        shippingCost == 0 ? 'FREE' : 'RM ${shippingCost.toStringAsFixed(2)}',
      ),
      _LabelValueRow('Packaging', 'RM ${packagingCost.toStringAsFixed(2)}'),
      if (discount > 0)
        _LabelValueRow(
          'Discount',
          '-RM ${discount.toStringAsFixed(2)}',
          valueColor: const Color(0xFFD32F2F),
        ),
      const Divider(height: 24, thickness: 1.5),
      _TotalRow(
        label: 'Total Paid',
        amount: grandTotal,
        color: const Color(0xFF2E7D32),
      ),
    ];
  }

  List<Widget> _buildDonationSummary() {
    return [
      _LabelValueRow('Category', widget.orderData['category'] ?? 'General'),
      const Divider(height: 24, thickness: 1.5),
      _TotalRow(
        label: 'Donation Amount',
        amount: widget.orderData['amount'],
        color: const Color(0xFF1976D2),
      ),
    ];
  }

  List<Widget> _buildRepairSummary() {
    return [
      _LabelValueRow(
        'Service Type',
        widget.orderData['repairType'] ?? 'General Repair',
      ),
      const Divider(height: 24, thickness: 1.5),
      _TotalRow(
        label: 'Service Fee',
        amount: widget.orderData['amount'],
        color: const Color(0xFF1976D2),
      ),
    ];
  }
}

class _SuccessHeader extends StatelessWidget {
  final String title, subtitle;
  final Color color;

  const _SuccessHeader({
    required this.title,
    required this.subtitle,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Lottie.asset(
            'assets/lottie/Success.json',
            width: 160,
            height: 160,
            repeat: true,
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              fontFamily: 'Roboto',
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: color,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: TextStyle(
              fontFamily: 'Roboto',
              fontSize: 15,
              color: Colors.black,
              height: 1.5,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF2E7D32).withOpacity(0.2),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2E7D32).withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.receipt_long,
                color: Color(0xFF2E7D32),
                size: 22,
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontFamily: 'Roboto',
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1B5E20),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }
}

class _LabelValueRow extends StatelessWidget {
  final String label, value;
  final Color? valueColor;

  const _LabelValueRow(this.label, this.value, {this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Roboto',
              fontSize: 15,
              color: Colors.black,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontFamily: 'Roboto',
                fontSize: 15,
                color: valueColor ?? const Color(0xFF212121),
                fontWeight: FontWeight.w700,
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
  final dynamic amount;
  final Color color;

  const _TotalRow({
    required this.label,
    required this.amount,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '$label:',
            style: const TextStyle(
              fontFamily: 'Roboto',
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: Color(0xFF212121),
            ),
          ),
          Text(
            'RM ${(amount is int ? amount.toDouble() : amount).toStringAsFixed(2)}',
            style: TextStyle(
              fontFamily: 'Roboto',
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: color,
              letterSpacing: -0.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _GreenCoinsEarnedCard extends StatelessWidget {
  final int coins;

  const _GreenCoinsEarnedCard({required this.coins});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFE8F5E9), Color(0xFFC8E6C9)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF66BB6A), width: 2),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2E7D32).withOpacity(0.15),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF2E7D32).withOpacity(0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Center(
              child: Image.asset(
                'assets/images/icon/Green Coin.png',
                width: 32,
                height: 32,
                errorBuilder: (_, __, ___) =>
                    const Icon(Icons.eco, color: Color(0xFF2E7D32), size: 32),
              ),
            ),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Green Coins Earned!',
                  style: TextStyle(
                    fontFamily: 'Roboto',
                    color: Color(0xFF1B5E20),
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Added to your account',
                  style: TextStyle(
                    fontFamily: 'Roboto',
                    color: Color(0xFF2E7D32),
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF2E7D32), Color(0xFF388E3C)],
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF2E7D32).withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Text(
              '+$coins',
              style: const TextStyle(
                fontFamily: 'Roboto',
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
