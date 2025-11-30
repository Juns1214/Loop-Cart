import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../checkout/order_status.dart';

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
      home: const PurchaseHistory(),
    );
  }
}

class PurchaseHistory extends StatefulWidget {
  const PurchaseHistory({super.key});

  @override
  State<PurchaseHistory> createState() => _PurchaseHistoryState();
}

class _PurchaseHistoryState extends State<PurchaseHistory> {
  final User? currentUser = FirebaseAuth.instance.currentUser;
  List<Map<String, dynamic>> orders = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    if (currentUser == null) {
      setState(() {
        isLoading = false;
      });
      return;
    }

    try {
      QuerySnapshot orderSnapshot = await FirebaseFirestore.instance
          .collection('orders')
          .where('userId', isEqualTo: currentUser!.uid)
          .orderBy('orderDate', descending: true)
          .get();

      List<Map<String, dynamic>> loadedOrders = [];
      
      for (var doc in orderSnapshot.docs) {
        Map<String, dynamic> orderData = doc.data() as Map<String, dynamic>;
        orderData['docId'] = doc.id;
        loadedOrders.add(orderData);
      }

      setState(() {
        orders = loadedOrders;
        isLoading = false;
      });

    } catch (e) {
      print('Error loading orders: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  String _formatDate(Timestamp? timestamp) {
    if (timestamp == null) return '';
    DateTime date = timestamp.toDate();
    return DateFormat('MMM dd, yyyy').format(date);
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Delivered':
        return Color(0xFF388E3C);
      case 'Out for Delivery':
      case 'Shipped':
        return Colors.orange;
      case 'Processing':
        return Colors.blue;
      case 'Order Placed':
        return Colors.grey[700]!;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'Delivered':
        return Icons.check_circle;
      case 'Out for Delivery':
        return Icons.local_shipping;
      case 'Shipped':
        return Icons.flight_takeoff;
      case 'Processing':
        return Icons.hourglass_empty;
      case 'Order Placed':
        return Icons.shopping_bag;
      default:
        return Icons.info;
    }
  }

  Widget _buildOrderCard(Map<String, dynamic> order) {
    String orderId = order['orderId'] ?? '';
    String status = order['status'] ?? 'Unknown';
    Timestamp? orderDate = order['orderDate'];
    double grandTotal = (order['grandTotal'] ?? 0).toDouble();
    List<dynamic> items = order['items'] ?? [];
    
    int totalItems = 0;
    for (var item in items) {
      totalItems += (item['quantity'] as int? ?? 1);
    }

    // Group items by seller
    Map<String, List<Map<String, dynamic>>> itemsBySeller = {};
    for (var item in items) {
      String seller = item['seller'] ?? 'Unknown Seller';
      if (!itemsBySeller.containsKey(seller)) {
        itemsBySeller[seller] = [];
      }
      itemsBySeller[seller]!.add(item as Map<String, dynamic>);
    }

    return Card(
      margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: EdgeInsets.all(16),
          childrenPadding: EdgeInsets.zero,
          leading: Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _getStatusColor(status).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              _getStatusIcon(status),
              color: _getStatusColor(status),
              size: 28,
            ),
          ),
          title: Text(
            'Order #${orderId.substring(orderId.length > 8 ? orderId.length - 8 : 0)}',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 4),
              Text(
                _formatDate(orderDate),
                style: TextStyle(fontSize: 13, color: Colors.grey[600]),
              ),
              SizedBox(height: 6),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getStatusColor(status),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  status,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          trailing: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'RM ${grandTotal.toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF388E3C),
                ),
              ),
              Text(
                '$totalItems items',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ],
          ),
          children: [
            Divider(height: 1),
            
            // Display items grouped by seller
            ...itemsBySeller.entries.map((entry) {
              String sellerName = entry.key;
              List<Map<String, dynamic>> sellerItems = entry.value;
              String sellerProfileImage = sellerItems[0]['sellerProfileImage'] ?? '';
              
              return Column(
                children: [
                  // Seller Header
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    color: Colors.grey[50],
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 18,
                          backgroundColor: Color(0xFF388E3C).withOpacity(0.1),
                          backgroundImage: sellerProfileImage.isNotEmpty
                              ? AssetImage(sellerProfileImage)
                              : null,
                          child: sellerProfileImage.isEmpty
                              ? Icon(Icons.store, size: 20, color: Color(0xFF388E3C))
                              : null,
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            sellerName,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Items from this seller
                  ...sellerItems.map((item) => _buildProductRow(item)),
                ],
              );
            }),
            
            // Action Buttons
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => OrderStatus(orderId: orderId),
                          ),
                        );
                      },
                      icon: Icon(Icons.local_shipping_outlined, size: 18),
                      label: Text('Order Status'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Color(0xFF388E3C),
                        side: BorderSide(color: Color(0xFF388E3C)),
                        padding: EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        // Placeholder for review functionality
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Review feature coming soon!'),
                            backgroundColor: Color(0xFF388E3C),
                          ),
                        );
                      },
                      icon: Icon(Icons.rate_review_outlined, size: 18),
                      label: Text('Leave Review'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.grey[700],
                        side: BorderSide(color: Colors.grey[300]!),
                        padding: EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductRow(Map<String, dynamic> item) {
    String productName = item['productName'] ?? 'Unknown Product';
    double productPrice = (item['productPrice'] ?? 0).toDouble();
    int quantity = item['quantity'] ?? 1;
    String imageUrl = item['imageUrl'] ?? '';

    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.grey[200]!, width: 1),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Product Image
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: imageUrl.isNotEmpty
                ? Image.asset(
                    imageUrl,
                    width: 70,
                    height: 70,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: 70,
                        height: 70,
                        color: Colors.grey[300],
                        child: Icon(Icons.image, size: 30, color: Colors.grey),
                      );
                    },
                  )
                : Container(
                    width: 70,
                    height: 70,
                    color: Colors.grey[300],
                    child: Icon(Icons.image, size: 30, color: Colors.grey),
                  ),
          ),
          SizedBox(width: 16),

          // Product Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  productName,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 6),
                Text(
                  'RM ${productPrice.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[700],
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Qty: $quantity',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),

          // Item Total
          Text(
            'RM ${(productPrice * quantity).toStringAsFixed(2)}',
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

  @override
  Widget build(BuildContext context) {
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
          'Purchase History',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
        ),
        centerTitle: true,
      ),
      body: isLoading
          ? Center(
              child: CircularProgressIndicator(color: Color(0xFF388E3C)),
            )
          : orders.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.shopping_bag_outlined,
                        size: 80,
                        color: Colors.grey[400],
                      ),
                      SizedBox(height: 16),
                      Text(
                        'No Purchase History',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[600],
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Your purchase history will appear here',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  color: Color(0xFF388E3C),
                  onRefresh: _loadOrders,
                  child: ListView(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: Text(
                          '${orders.length} ${orders.length == 1 ? 'Order' : 'Orders'}',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[700],
                          ),
                        ),
                      ),
                      ...orders.map((order) => _buildOrderCard(order)),
                      SizedBox(height: 20),
                    ],
                  ),
                ),
    );
  }
}