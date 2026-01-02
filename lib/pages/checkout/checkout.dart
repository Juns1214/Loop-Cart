import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../checkout/payment.dart';
import '../../widget/custom_button.dart';

class Checkout extends StatefulWidget {
  final List<Map<String, dynamic>> selectedItems;
  final Map<String, dynamic>? userAddress;

  const Checkout({super.key, required this.selectedItems, this.userAddress});

  @override
  State<Checkout> createState() => _CheckoutState();
}

class _CheckoutState extends State<Checkout> {
  final User? currentUser = FirebaseAuth.instance.currentUser;
  bool isLoading = true;
  String selectedShippingMethod = 'Standard';
  String selectedPackaging = 'Standard Packaging';
  bool useGreenCoinDiscount = false;

  double shippingCost = 0.0;
  double packagingCost = 2.0;
  int availableGreenCoins = 0;
  double greenCoinDiscount = 0.0;

  @override
  void initState() {
    super.initState();
    _loadUserGreenCoins();
  }

  Future<void> _loadUserGreenCoins() async {
    if (currentUser == null) return;
    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('user_profile')
          .doc(currentUser!.uid)
          .get();

      if (mounted) {
        setState(() {
          if (userDoc.exists) {
            availableGreenCoins =
                (userDoc.data() as Map<String, dynamic>)['greenCoins'] ?? 0;
          }
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => isLoading = false);
    }
  }

  double _calculateItemsTotal() {
    return widget.selectedItems.fold(0.0, (sum, item) {
      final price = (item['productPrice'] ?? 0).toDouble();
      final quantity = item['quantity'] ?? 1;
      return sum + (price * quantity);
    });
  }

  int _calculateGreenCoinsToEarn() {
    int total = 0;
    for (var item in widget.selectedItems) {
      if (item['isPreowned'] == true) {
        num price = item['productPrice'] ?? 0;
        num quantity = item['quantity'] ?? 1;
        total += (price * quantity).floor();
      }
    }
    return total;
  }

  double _calculateGrandTotal() {
    final discount = useGreenCoinDiscount ? greenCoinDiscount : 0;
    return _calculateItemsTotal() + shippingCost + packagingCost - discount;
  }

  void _toggleGreenCoinDiscount(bool value) {
    setState(() {
      useGreenCoinDiscount = value;
      if (value) {
        final maxFromCoins = availableGreenCoins * 0.10;
        final maxAllowed = _calculateItemsTotal() * 0.5;
        greenCoinDiscount = maxFromCoins < maxAllowed
            ? maxFromCoins
            : maxAllowed;
      } else {
        greenCoinDiscount = 0.0;
      }
    });
  }

  void _onCheckoutPressed() {
    if (widget.userAddress == null || widget.userAddress!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please add your shipping address first',
            style: TextStyle(fontFamily: 'Roboto', fontWeight: FontWeight.w500),
          ),
          backgroundColor: Color(0xFFD32F2F),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Payment(
          orderData: {
            'items': widget.selectedItems,
            'shippingAddress': widget.userAddress!,
            'shippingMethod': selectedShippingMethod,
            'shippingCost': shippingCost,
            'packagingType': selectedPackaging,
            'packagingCost': packagingCost,
            'itemsTotal': _calculateItemsTotal(),
            'discount': useGreenCoinDiscount ? greenCoinDiscount : 0,
            'greenCoinsUsed': useGreenCoinDiscount
                ? (greenCoinDiscount / 0.10).round()
                : 0,
            'grandTotal': _calculateGrandTotal(),
            'greenCoinsToEarn': _calculateGreenCoinsToEarn(),
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final totalItemsCount = widget.selectedItems.fold<int>(
      0,
      (sum, item) => sum + (item['quantity'] as int? ?? 1),
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF1F8F4),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: Color(0xFF1B5E20),
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Checkout',
          style: TextStyle(
            fontFamily: 'Roboto',
            fontWeight: FontWeight.w700,
            fontSize: 20,
            color: Color(0xFF1B5E20),
            letterSpacing: 0.5,
          ),
        ),
        centerTitle: true,
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF2E7D32),
                strokeWidth: 3,
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  _buildAddressCard(),
                  const SizedBox(height: 16),
                  _buildItemsSection(totalItemsCount),
                  const SizedBox(height: 16),
                  _buildShippingSection(),
                  const SizedBox(height: 16),
                  _buildPackagingSection(),
                  const SizedBox(height: 16),
                  _buildDiscountSection(),
                  const SizedBox(height: 16),
                  if (_calculateGreenCoinsToEarn() > 0) ...[
                    _buildEarnCoinsBanner(),
                    const SizedBox(height: 16),
                  ],
                  _buildOrderSummary(),
                  const SizedBox(height: 20),
                  CustomButton(
                    text: 'Proceed to Payment',
                    onPressed: _onCheckoutPressed,
                    minimumSize: const Size(double.infinity, 56),
                    borderRadius: 16,
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
    );
  }

  Widget _buildAddressCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF2E7D32).withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2E7D32).withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.location_on, color: Color(0xFF2E7D32), size: 22),
                  SizedBox(width: 8),
                  Text(
                    'Shipping Address',
                    style: TextStyle(
                      fontFamily: 'Roboto',
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1B5E20),
                    ),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(
                  Icons.edit_outlined,
                  color: Color(0xFF2E7D32),
                  size: 20,
                ),
                onPressed: () => Navigator.pushNamed(context, '/edit_profile'),
                tooltip: 'Edit address',
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (widget.userAddress == null || widget.userAddress!.isEmpty)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFEBEE),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: const Color(0xFFD32F2F).withOpacity(0.3),
                ),
              ),
              child: const Row(
                children: [
                  Icon(
                    Icons.warning_amber_rounded,
                    color: Color(0xFFD32F2F),
                    size: 20,
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'No address found. Please add your address.',
                      style: TextStyle(
                        fontFamily: 'Roboto',
                        color: Color(0xFFD32F2F),
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            )
          else
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.userAddress!['line1'] ?? '',
                  style: const TextStyle(
                    fontFamily: 'Roboto',
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                if (widget.userAddress!['line2']?.isNotEmpty ?? false)
                  Text(
                    widget.userAddress!['line2'],
                    style: TextStyle(
                      fontFamily: 'Roboto',
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                const SizedBox(height: 6),
                Text(
                  '${widget.userAddress!['city']}, ${widget.userAddress!['postal']}',
                  style: TextStyle(
                    fontFamily: 'Roboto',
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                Text(
                  widget.userAddress!['state'] ?? '',
                  style: TextStyle(
                    fontFamily: 'Roboto',
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildItemsSection(int totalItemsCount) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Order Items',
                style: TextStyle(
                  fontFamily: 'Roboto',
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1B5E20),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF2E7D32), Color(0xFF388E3C)],
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '$totalItemsCount ${totalItemsCount == 1 ? 'item' : 'items'}',
                  style: const TextStyle(
                    fontFamily: 'Roboto',
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...widget.selectedItems.map((item) => _buildItemRow(item)),
        ],
      ),
    );
  }

  Widget _buildItemRow(Map<String, dynamic> item) {
    final quantity = item['quantity'] ?? 1;
    final price = (item['productPrice'] ?? 0).toDouble();

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                color: Colors.grey[100],
                border: Border.all(color: Colors.grey[300]!),
                borderRadius: BorderRadius.circular(12),
              ),
              child: item['imageUrl'] != null
                  ? Image.asset(
                      item['imageUrl'],
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Icon(
                        Icons.image_outlined,
                        color: Colors.grey,
                        size: 30,
                      ),
                    )
                  : const Icon(
                      Icons.image_outlined,
                      color: Colors.grey,
                      size: 30,
                    ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item['productName'] ?? 'Unknown',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Roboto',
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Quantity: $quantity',
                  style: TextStyle(
                    fontFamily: 'Roboto',
                    color: Colors.black,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          Text(
            'RM ${(price * quantity).toStringAsFixed(2)}',
            style: const TextStyle(
              fontFamily: 'Roboto',
              fontWeight: FontWeight.w800,
              color: Color(0xFF2E7D32),
              fontSize: 17,
              letterSpacing: -0.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShippingSection() {
    return _buildSectionContainer(
      title: 'Shipping Method',
      icon: Icons.local_shipping_outlined,
      children: [
        _SelectionOption(
          title: 'Standard Delivery',
          subtitle: '5-6 business days',
          price: 'FREE',
          isSelected: selectedShippingMethod == 'Standard',
          onTap: () => setState(() {
            selectedShippingMethod = 'Standard';
            shippingCost = 0.0;
          }),
        ),
        Divider(color: Colors.grey[200], height: 1),
        _SelectionOption(
          title: 'Express Delivery',
          subtitle: '2-3 business days',
          price: 'RM 12.00',
          isSelected: selectedShippingMethod == 'Express',
          onTap: () => setState(() {
            selectedShippingMethod = 'Express';
            shippingCost = 12.0;
          }),
        ),
      ],
    );
  }

  Widget _buildPackagingSection() {
    return _buildSectionContainer(
      title: 'Packaging Options',
      icon: Icons.inventory_2_outlined,
      children: [
        _SelectionOption(
          title: 'Standard Packaging',
          subtitle: 'Regular bubble wrap & box',
          price: 'RM 2.00',
          isSelected: selectedPackaging == 'Standard Packaging',
          onTap: () => setState(() {
            selectedPackaging = 'Standard Packaging';
            packagingCost = 2.0;
          }),
        ),
        Divider(color: Colors.grey[200], height: 1),
        _SelectionOption(
          title: 'Eco-Friendly Packaging',
          subtitle: 'Recycled materials',
          price: 'RM 1.00',
          isSelected: selectedPackaging == 'Eco-friendly Packaging',
          icon: Icons.eco,
          onTap: () => setState(() {
            selectedPackaging = 'Eco-friendly Packaging';
            packagingCost = 1.0;
          }),
        ),
      ],
    );
  }

  Widget _buildDiscountSection() {
    return _buildSectionContainer(
      title: 'Green Coin Discount',
      icon: Icons.discount_outlined,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFE8F5E9), Color(0xFFC8E6C9)],
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFF2E7D32).withOpacity(0.2),
                ),
              ),
              child: Image.asset("assets/images/icon/Green Coin.png", width: 40, height: 40, fit: BoxFit.fill),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Use Green Coins',
                    style: TextStyle(
                      fontFamily: 'Roboto',
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Available: $availableGreenCoins coins',
                    style: const TextStyle(
                      fontFamily: 'Roboto',
                      color: Color(0xFF2E7D32),
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (useGreenCoinDiscount && greenCoinDiscount > 0)
                    Text(
                      'Save: RM ${greenCoinDiscount.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontFamily: 'Roboto',
                        color: Color(0xFFD32F2F),
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                ],
              ),
            ),
            Transform.scale(
              scale: 0.95,
              child: Switch(
                value: useGreenCoinDiscount,
                onChanged: availableGreenCoins > 0
                    ? _toggleGreenCoinDiscount
                    : null,
                activeThumbColor: const Color(0xFF2E7D32),
                activeTrackColor: const Color(0xFF66BB6A),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildEarnCoinsBanner() {
    return Container(
      padding: const EdgeInsets.all(16),
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
            color: const Color(0xFF2E7D32).withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
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
            child: const Icon(Icons.eco, color: Color(0xFF2E7D32), size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'You\'ll Earn Green Coins!',
                  style: TextStyle(
                    fontFamily: 'Roboto',
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1B5E20),
                    fontSize: 16,
                  ),
                ),
                Text(
                  'From pre-owned items purchase',
                  style: TextStyle(
                    fontFamily: 'Roboto',
                    fontSize: 13,
                    color: const Color(0xFF1B5E20).withOpacity(0.8),
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
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Text(
              '+${_calculateGreenCoinsToEarn()}',
              style: const TextStyle(
                fontFamily: 'Roboto',
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 18,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderSummary() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF2E7D32).withOpacity(0.3),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2E7D32).withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Order Summary',
            style: TextStyle(
              fontFamily: 'Roboto',
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1B5E20),
            ),
          ),
          const SizedBox(height: 16),
          _OrderSummaryRow(
            label: 'Items Total',
            amount: _calculateItemsTotal(),
          ),
          _OrderSummaryRow(label: 'Shipping Fee', amount: shippingCost),
          _OrderSummaryRow(label: 'Packaging Fee', amount: packagingCost),
          if (useGreenCoinDiscount && greenCoinDiscount > 0)
            _OrderSummaryRow(
              label: 'Green Coin Discount',
              amount: -greenCoinDiscount,
              isDiscount: true,
            ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Divider(color: Colors.grey[300], thickness: 1.5),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Grand Total',
                style: TextStyle(
                  fontFamily: 'Roboto',
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: Colors.black,
                ),
              ),
              Text(
                'RM ${_calculateGrandTotal().toStringAsFixed(2)}',
                style: const TextStyle(
                  fontFamily: 'Roboto',
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF2E7D32),
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionContainer({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: const Color(0xFF2E7D32), size: 22),
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

class _SelectionOption extends StatelessWidget {
  final String title;
  final String subtitle;
  final String price;
  final bool isSelected;
  final VoidCallback onTap;
  final IconData? icon;

  const _SelectionOption({
    required this.title,
    required this.subtitle,
    required this.price,
    required this.isSelected,
    required this.onTap,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 4),
        child: Row(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected
                      ? const Color(0xFF2E7D32)
                      : Colors.grey[400]!,
                  width: isSelected ? 7 : 2,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontFamily: 'Roboto',
                          fontSize: 16,
                          fontWeight: isSelected
                              ? FontWeight.w700
                              : FontWeight.w600,
                          color: isSelected
                              ? const Color(0xFF212121)
                              : const Color(0xFF424242),
                        ),
                      ),
                      if (icon != null) ...[
                        const SizedBox(width: 6),
                        Icon(icon, color: const Color(0xFF2E7D32), size: 18),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontFamily: 'Roboto',
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              price,
              style: TextStyle(
                fontFamily: 'Roboto',
                fontWeight: FontWeight.w800,
                color: price == 'FREE'
                    ? const Color(0xFF2E7D32)
                    : const Color(0xFF212121),
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OrderSummaryRow extends StatelessWidget {
  final String label;
  final double amount;
  final bool isDiscount;

  const _OrderSummaryRow({
    required this.label,
    required this.amount,
    this.isDiscount = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Roboto',
              color: Colors.black,
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            amount == 0
                ? 'FREE'
                : '${isDiscount ? '-' : ''}RM ${amount.abs().toStringAsFixed(2)}',
            style: TextStyle(
              fontFamily: 'Roboto',
              fontWeight: FontWeight.w700,
              fontSize: 16,
              color: isDiscount
                  ? const Color(0xFFD32F2F)
                  : const Color(0xFF212121),
            ),
          ),
        ],
      ),
    );
  }
}
