import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../checkout/payment.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: const Checkout(selectedItems: [], userAddress: null),
    );
  }
}

class Checkout extends StatefulWidget {
  final List<Map<String, dynamic>> selectedItems;
  final Map<String, dynamic>? userAddress;

  const Checkout({super.key, required this.selectedItems, this.userAddress});

  @override
  State<Checkout> createState() => _CheckoutState();
}

class _CheckoutState extends State<Checkout> {
  final User? currentUser = FirebaseAuth.instance.currentUser;

  String selectedShippingMethod = 'Standard';
  String selectedPackaging = 'Standard Packaging';
  bool useGreenCoinDiscount = false;

  double shippingCost = .0;
  double packagingCost = 2.0;
  int availableGreenCoins = 0;
  double greenCoinDiscount = 0.0;

  bool isLoading = true;

  final Map<String, double> shippingCosts = {'Standard': 0.0, 'Express': 12.0};

  final Map<String, double> packagingCosts = {
    'Standard Packaging': 2.0,
    'Eco-friendly Packaging': 1.0,
  };

  @override
  void initState() {
    super.initState();
    _loadUserGreenCoins();
  }

  Future<void> _loadUserGreenCoins() async {
    if (currentUser == null) return;

    setState(() {
      isLoading = true;
    });

    try {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('user_profile')
          .doc(currentUser!.uid)
          .get();

      if (userDoc.exists) {
        Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
        setState(() {
          availableGreenCoins = userData['greenCoins'] ?? 0;
          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading green coins: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  double _calculateItemsTotal() {
    double total = 0;
    for (var item in widget.selectedItems) {
      total += (item['productPrice'] ?? 0) * (item['quantity'] ?? 1);
    }
    return total;
  }

  double _calculateGrandTotal() {
    double itemsTotal = _calculateItemsTotal();
    double shipping = shippingCost;
    double packaging = packagingCost;
    double discount = useGreenCoinDiscount ? greenCoinDiscount : 0;

    return itemsTotal + shipping + packaging - discount;
  }

  void _updateShippingMethod(String method) {
    setState(() {
      selectedShippingMethod = method;
      shippingCost = shippingCosts[method] ?? 0.0;
    });
  }

  void _updatePackaging(String packaging) {
    setState(() {
      selectedPackaging = packaging;
      packagingCost = packagingCosts[packaging] ?? 2.0;
    });
  }

  void _toggleGreenCoinDiscount(bool value) {
    setState(() {
      useGreenCoinDiscount = value;
      if (value) {
        // 1 green coin = RM 0.10
        // Maximum discount is 50% of items total or available green coins
        double maxDiscountFromCoins = availableGreenCoins * 0.10;
        double maxDiscountAllowed = _calculateItemsTotal() * 0.5;
        greenCoinDiscount = maxDiscountFromCoins < maxDiscountAllowed
            ? maxDiscountFromCoins
            : maxDiscountAllowed;
      } else {
        greenCoinDiscount = 0.0;
      }
    });
  }

  Widget _buildItemRow(Map<String, dynamic> item) {
    int quantity = item['quantity'] ?? 1;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          // Product Image with quantity badge
          Stack(
            clipBehavior: Clip.none,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: item['imageUrl'] != null && item['imageUrl'].isNotEmpty
                    ? Image.asset(
                        item['imageUrl'],
                        width: 60,
                        height: 60,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            width: 60,
                            height: 60,
                            color: Colors.grey[300],
                            child: Icon(
                              Icons.image,
                              size: 30,
                              color: Colors.grey,
                            ),
                          );
                        },
                      )
                    : Container(
                        width: 60,
                        height: 60,
                        color: Colors.grey[300],
                        child: Icon(Icons.image, size: 30, color: Colors.grey),
                      ),
              ),
              if (quantity > 1)
                Positioned(
                  top: -8,
                  right: -8,
                  child: Container(
                    padding: EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Color(0xFF388E3C),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: Text(
                      '$quantity',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          SizedBox(width: 12),

          // Product name
          Expanded(
            child: Text(
              item['productName'] ?? 'Unknown Product',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),

          // Price
          Text(
            'RM ${((item['productPrice'] ?? 0) * quantity).toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Color(0xFF388E3C),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOptionRow(
    String optionName,
    String optionValue,
    bool isSelected,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isSelected ? Color(0xFF388E3C) : Colors.white,
                    border: Border.all(
                      color: isSelected ? Color(0xFF388E3C) : Colors.grey[400]!,
                      width: 2,
                    ),
                  ),
                  child: isSelected
                      ? Icon(Icons.check, color: Colors.white, size: 16)
                      : null,
                ),
                SizedBox(width: 12),
                Text(
                  optionName,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: isSelected
                        ? FontWeight.w600
                        : FontWeight.normal,
                  ),
                ),
              ],
            ),
            Text(
              optionValue,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Color(0xFF388E3C),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddressSection() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Shipping Address',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              IconButton(
                icon: Icon(Icons.edit, color: Color(0xFF388E3C), size: 20),
                onPressed: () {
                  Navigator.pushNamed(context, '/edit_profile');
                },
              ),
            ],
          ),
          SizedBox(height: 8),
          if (widget.userAddress == null || widget.userAddress!.isEmpty)
            Text(
              'No address found. Please add your address.',
              style: TextStyle(fontSize: 14, color: Colors.red[700]),
            )
          else
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.userAddress!['line1'] ?? '',
                  style: TextStyle(fontSize: 14),
                ),
                if (widget.userAddress!['line2'] != null &&
                    widget.userAddress!['line2'].isNotEmpty)
                  Text(
                    widget.userAddress!['line2'],
                    style: TextStyle(fontSize: 14),
                  ),
                Text(
                  '${widget.userAddress!['city'] ?? ''}, ${widget.userAddress!['postal'] ?? ''}',
                  style: TextStyle(fontSize: 14),
                ),
                Text(
                  widget.userAddress!['state'] ?? '',
                  style: TextStyle(fontSize: 14),
                ),
              ],
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    int totalItems = widget.selectedItems.fold(
      0,
      (sum, item) => sum + (item['quantity'] as int? ?? 1),
    );

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Checkout',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
        ),
        centerTitle: true,
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator(color: Color(0xFF388E3C)))
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Shipping Address
                    _buildAddressSection(),

                    SizedBox(height: 20),

                    // Items Section
                    Container(
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                'Items',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(width: 12),
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Color(0xFF388E3C),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  '$totalItems',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 16),
                          ...widget.selectedItems.map(
                            (item) => _buildItemRow(item),
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: 20),

                    // Shipping Method
                    Container(
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Shipping Method',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 8),
                          _buildOptionRow(
                            'Standard (5-6 days)',
                            'FREE',
                            selectedShippingMethod == 'Standard',
                            () => _updateShippingMethod('Standard'),
                          ),
                          Divider(),
                          _buildOptionRow(
                            'Express (2-3 days)',
                            'RM 12.00',
                            selectedShippingMethod == 'Express',
                            () => _updateShippingMethod('Express'),
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: 20),

                    // Packaging Options
                    Container(
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Packaging Options',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 8),
                          _buildOptionRow(
                            'Standard Packaging',
                            'RM 2.00',
                            selectedPackaging == 'Standard Packaging',
                            () => _updatePackaging('Standard Packaging'),
                          ),
                          Divider(),
                          _buildOptionRow(
                            'Eco-friendly Packaging',
                            'RM 1.00',
                            selectedPackaging == 'Eco-friendly Packaging',
                            () => _updatePackaging('Eco-friendly Packaging'),
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: 20),

                    // Green Coin Discount
                    Container(
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Discount',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 12),
                          Row(
                            children: [
                              Container(
                                padding: EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Color(0xFF388E3C).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Image.asset(
                                  'assets/images/icon/Green Coin.png',
                                  width: 24,
                                  height: 24,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Icon(
                                      Icons.monetization_on,
                                      color: Color(0xFF388E3C),
                                      size: 24,
                                    );
                                  },
                                ),
                              ),
                              SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Green Coin Discount',
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    Text(
                                      'Available: $availableGreenCoins coins',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                    if (useGreenCoinDiscount)
                                      Text(
                                        '-RM ${greenCoinDiscount.toStringAsFixed(2)}',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.red,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              Switch(
                                value: useGreenCoinDiscount,
                                onChanged: availableGreenCoins > 0
                                    ? _toggleGreenCoinDiscount
                                    : null,
                                activeThumbColor: Color(0xFF388E3C),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: 30),

                    // Order Summary
                    Container(
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Color(0xFF388E3C), width: 2),
                      ),
                      child: Column(
                        children: [
                          _buildSummaryRow(
                            'Items Total',
                            _calculateItemsTotal(),
                          ),
                          _buildSummaryRow('Shipping', shippingCost),
                          _buildSummaryRow('Packaging', packagingCost),
                          if (useGreenCoinDiscount)
                            _buildSummaryRow(
                              'Discount',
                              -greenCoinDiscount,
                              isDiscount: true,
                            ),
                          Divider(thickness: 2),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Total',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                'RM ${_calculateGrandTotal().toStringAsFixed(2)}',
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

                    SizedBox(height: 20),

                    // Pay Now Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          if (widget.userAddress == null ||
                              widget.userAddress!.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Please add your shipping address first',
                                ),
                                backgroundColor: Colors.red,
                              ),
                            );
                            return;
                          }

                          // Calculate green coins used (how many coins = discount amount)
                          int greenCoinsUsed = useGreenCoinDiscount
                              ? (greenCoinDiscount / 0.10).round()
                              : 0;

                          // Pass complete order data to Payment page
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
                                  'discount': useGreenCoinDiscount
                                      ? greenCoinDiscount
                                      : 0,
                                  'greenCoinsUsed': greenCoinsUsed,
                                  'grandTotal': _calculateGrandTotal(),
                                },
                              ),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFF388E3C),
                          padding: EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 2,
                        ),
                        child: Text(
                          'Pay Now',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),

                    SizedBox(height: 20),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildSummaryRow(
    String label,
    double amount, {
    bool isDiscount = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 15, color: Colors.grey[700])),
          Text(
            amount == 0 ? 'FREE' : 'RM ${amount.abs().toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: isDiscount ? Colors.red : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}
