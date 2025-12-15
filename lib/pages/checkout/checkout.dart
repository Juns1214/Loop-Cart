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
  // --- Colors ---
  final Color _backgroundColor = const Color(0xFFF0FDF4); // Fade Green Background
  final Color _primaryColor = const Color(0xFF388E3C);
  
  // --- High Contrast Text Styles ---
  final TextStyle _headerStyle = const TextStyle(fontSize: 19, fontWeight: FontWeight.w800, color: Colors.black87);
  final TextStyle _labelStyle = const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.black87);
  final TextStyle _subLabelStyle = const TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: Color(0xFF424242)); 

  // --- State ---
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
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('user_profile')
          .doc(currentUser!.uid)
          .get();

      if (mounted) {
        setState(() {
          if (userDoc.exists) {
            final data = userDoc.data() as Map<String, dynamic>;
            availableGreenCoins = data['greenCoins'] ?? 0;
          }
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => isLoading = false);
    }
  }

  // --- Calculations ---
  double _calculateItemsTotal() {
    return widget.selectedItems.fold(0, (sum, item) {
      num price = item['productPrice'] ?? 0;
      num quantity = item['quantity'] ?? 1;
      return sum + (price * quantity).toDouble();
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
    double discount = useGreenCoinDiscount ? greenCoinDiscount : 0;
    return _calculateItemsTotal() + shippingCost + packagingCost - discount;
  }

  void _toggleGreenCoinDiscount(bool value) {
    setState(() {
      useGreenCoinDiscount = value;
      if (value) {
        double maxFromCoins = availableGreenCoins * 0.10;
        double maxAllowed = _calculateItemsTotal() * 0.5;
        greenCoinDiscount = maxFromCoins < maxAllowed ? maxFromCoins : maxAllowed;
      } else {
        greenCoinDiscount = 0.0;
      }
    });
  }

  void _onCheckoutPressed() {
    if (widget.userAddress == null || widget.userAddress!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add your shipping address first'), backgroundColor: Colors.red),
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
            'greenCoinsUsed': useGreenCoinDiscount ? (greenCoinDiscount / 0.10).round() : 0,
            'grandTotal': _calculateGrandTotal(),
            'greenCoinsToEarn': _calculateGreenCoinsToEarn(),
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    int totalItemsCount = widget.selectedItems.fold(0, (sum, item) => sum + (item['quantity'] as int? ?? 1));

    return Scaffold(
      backgroundColor: _backgroundColor, // The Fade Green Background
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: const BackButton(color: Colors.black87),
        title: const Text('Checkout', style: TextStyle(fontWeight: FontWeight.w800, color: Colors.black87)),
        centerTitle: true,
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator(color: _primaryColor))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  _buildAddressCard(),
                  const SizedBox(height: 20),
                  
                  // Items Section
                  _buildSection(
                    title: 'Items',
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(color: _primaryColor, borderRadius: BorderRadius.circular(12)),
                      child: Text('$totalItemsCount', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                    child: Column(
                      children: widget.selectedItems.map((item) => _buildItemRow(item)).toList(),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Shipping
                  _buildSection(
                    title: 'Shipping Method',
                    child: Column(
                      children: [
                        _SelectionOption(
                          title: 'Standard (5-6 days)',
                          price: 'FREE',
                          isSelected: selectedShippingMethod == 'Standard',
                          onTap: () => setState(() { selectedShippingMethod = 'Standard'; shippingCost = 0.0; }),
                        ),
                        Divider(color: Colors.grey[200]),
                        _SelectionOption(
                          title: 'Express (2-3 days)',
                          price: 'RM 12.00',
                          isSelected: selectedShippingMethod == 'Express',
                          onTap: () => setState(() { selectedShippingMethod = 'Express'; shippingCost = 12.0; }),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Packaging
                  _buildSection(
                    title: 'Packaging Options',
                    child: Column(
                      children: [
                        _SelectionOption(
                          title: 'Standard Packaging',
                          price: 'RM 2.00',
                          isSelected: selectedPackaging == 'Standard Packaging',
                          onTap: () => setState(() { selectedPackaging = 'Standard Packaging'; packagingCost = 2.0; }),
                        ),
                        Divider(color: Colors.grey[200]),
                        _SelectionOption(
                          title: 'Eco-friendly Packaging',
                          price: 'RM 1.00',
                          isSelected: selectedPackaging == 'Eco-friendly Packaging',
                          onTap: () => setState(() { selectedPackaging = 'Eco-friendly Packaging'; packagingCost = 1.0; }),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Discount
                  _buildDiscountSection(),
                  const SizedBox(height: 20),

                  if (_calculateGreenCoinsToEarn() > 0) _buildEarnCoinsBanner(),
                  const SizedBox(height: 30),

                  // Summary
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: _primaryColor.withOpacity(0.5), width: 1.5),
                      boxShadow: [BoxShadow(color: _primaryColor.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 4))],
                    ),
                    child: Column(
                      children: [
                        _OrderSummaryRow(label: 'Items Total', amount: _calculateItemsTotal()),
                        _OrderSummaryRow(label: 'Shipping', amount: shippingCost),
                        _OrderSummaryRow(label: 'Packaging', amount: packagingCost),
                        if (useGreenCoinDiscount)
                          _OrderSummaryRow(label: 'Discount', amount: -greenCoinDiscount, isRed: true),
                        const Divider(thickness: 1, height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Total', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87)),
                            Text('RM ${_calculateGrandTotal().toStringAsFixed(2)}', 
                              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: _primaryColor)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Using the General CustomButton (Full Width)
                  CustomButton(
                    text: 'Pay Now',
                    onPressed: _onCheckoutPressed,
                    minimumSize: const Size(double.infinity, 54),
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
    );
  }

  // --- Helpers ---
  Widget _buildSection({required String title, required Widget child, Widget? trailing}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: _headerStyle),
              if (trailing != null) trailing,
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _buildAddressCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Shipping Address', style: _headerStyle),
              IconButton(
                icon: Icon(Icons.edit, color: _primaryColor, size: 22),
                onPressed: () => Navigator.pushNamed(context, '/edit_profile'),
              ),
            ],
          ),
          if (widget.userAddress == null || widget.userAddress!.isEmpty)
            Text('No address found.', style: TextStyle(color: Colors.red[700], fontWeight: FontWeight.bold))
          else
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.userAddress!['line1'] ?? '', style: _labelStyle),
                if (widget.userAddress!['line2']?.isNotEmpty ?? false)
                  Text(widget.userAddress!['line2'], style: _subLabelStyle),
                const SizedBox(height: 4),
                Text('${widget.userAddress!['city']}, ${widget.userAddress!['postal']}', style: _subLabelStyle),
                Text(widget.userAddress!['state'] ?? '', style: _subLabelStyle),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildDiscountSection() {
    return _buildSection(
      title: 'Discount',
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: _primaryColor.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
            child: Icon(Icons.monetization_on, color: _primaryColor, size: 28),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Green Coin Discount', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87)),
                Text('Available: $availableGreenCoins coins', style: TextStyle(color: Colors.grey[800], fontSize: 13, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          Transform.scale(
            scale: 0.9,
            child: Switch(
              value: useGreenCoinDiscount,
              onChanged: availableGreenCoins > 0 ? _toggleGreenCoinDiscount : null,
              activeThumbColor: _primaryColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEarnCoinsBanner() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFFE8F5E9), Color(0xFFC8E6C9)]),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _primaryColor.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          CircleAvatar(backgroundColor: Colors.white, child: Icon(Icons.eco, color: _primaryColor)),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('You\'ll Earn Green Coins!', style: TextStyle(fontWeight: FontWeight.w800, color: _primaryColor, fontSize: 15)),
                Text('Buy pre-owned items and earn rewards', style: TextStyle(fontSize: 12, color: _primaryColor.withOpacity(1.0), fontWeight: FontWeight.w700)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(color: _primaryColor, borderRadius: BorderRadius.circular(20)),
            child: Text('+${_calculateGreenCoinsToEarn()}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
          ),
        ],
      ),
    );
  }

  Widget _buildItemRow(Map<String, dynamic> item) {
    int quantity = item['quantity'] ?? 1;
    num price = item['productPrice'] ?? 0;
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Container(
            width: 64, height: 64,
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(10), color: Colors.grey[100]),
            child: item['imageUrl'] != null 
              ? ClipRRect(borderRadius: BorderRadius.circular(10), child: Image.asset(item['imageUrl'], fit: BoxFit.cover))
              : const Icon(Icons.image, color: Colors.grey),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item['productName'] ?? 'Unknown', maxLines: 2, overflow: TextOverflow.ellipsis, 
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: Colors.black87)),
                const SizedBox(height: 4),
                Text('Qty: $quantity', style: TextStyle(color: Colors.grey[800], fontSize: 13, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          Text('RM ${(price * quantity).toStringAsFixed(2)}', style: TextStyle(fontWeight: FontWeight.w800, color: _primaryColor, fontSize: 16)),
        ],
      ),
    );
  }
}

class _SelectionOption extends StatelessWidget {
  final String title;
  final String price;
  final bool isSelected;
  final VoidCallback onTap;

  const _SelectionOption({required this.title, required this.price, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Icon(isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked, 
                 color: isSelected ? const Color(0xFF388E3C) : Colors.grey[500]),
            const SizedBox(width: 14),
            Expanded(child: Text(title, style: TextStyle(fontSize: 15, fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600, color: Colors.black87))),
            Text(price, style: const TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF388E3C), fontSize: 15)),
          ],
        ),
      ),
    );
  }
}

class _OrderSummaryRow extends StatelessWidget {
  final String label;
  final double amount;
  final bool isRed;

  const _OrderSummaryRow({required this.label, required this.amount, this.isRed = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[800], fontSize: 15, fontWeight: FontWeight.w600)), 
          Text(
            amount == 0 ? 'FREE' : 'RM ${amount.abs().toStringAsFixed(2)}',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: isRed ? Colors.red : Colors.black87),
          ),
        ],
      ),
    );
  }
}