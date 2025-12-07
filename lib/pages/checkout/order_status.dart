import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class OrderStatus extends StatefulWidget {
  final String orderId;
  
  const OrderStatus({super.key, required this.orderId});

  @override
  State<OrderStatus> createState() => _OrderStatusState();
}

class _OrderStatusState extends State<OrderStatus> {
  Map<String, dynamic>? orderData;
  bool isLoading = true;
  
  // All statuses for display
  final List<Map<String, dynamic>> statusConfig = [
    {
      'status': 'Order Placed',
      'description': 'Your order has been placed successfully.',
    },
    {
      'status': 'Processing',
      'description': 'Your order is being processed.',
    },
    {
      'status': 'Shipped',
      'description': 'Your order has been shipped.',
    },
    {
      'status': 'Out for Delivery',
      'description': 'Your order is out for delivery.',
    },
    {
      'status': 'Delivered',
      'description': 'Your order has been delivered.',
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadOrderStatus();
  }

  Future<void> _loadOrderStatus() async {
    try {
      DocumentSnapshot orderDoc = await FirebaseFirestore.instance
          .collection('orders')
          .doc(widget.orderId)
          .get();

      if (!orderDoc.exists) {
        setState(() {
          isLoading = false;
        });
        return;
      }
      
      setState(() {
        orderData = orderDoc.data() as Map<String, dynamic>;
        isLoading = false;
      });

    } catch (e) {
      print('Error loading order: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  String _formatDate(Timestamp? timestamp) {
    if (timestamp == null) return '';
    DateTime date = timestamp.toDate();
    return DateFormat('MMM dd, yyyy - hh:mm a').format(date);
  }

  String _formatDateShort(Timestamp? timestamp) {
    if (timestamp == null) return '';
    DateTime date = timestamp.toDate();
    return DateFormat('MMMM dd, yyyy').format(date);
  }

  Widget buildOrderStatusCard({
    required String status,
    required String date,
    required String description,
    required bool isCompleted,
    bool isFirst = false,
    bool isLast = false,
  }) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      elevation: isCompleted ? 2 : 0,
      child: IntrinsicHeight(
        child: Row(
          children: [
            SizedBox(
              width: 60,
              child: Column(
                children: [
                  if (!isFirst)
                    Container(
                      width: 2,
                      height: 20,
                      color: isCompleted ? Color(0xFF388E3C) : Colors.grey[300],
                    ),

                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isCompleted ? Color(0xFF388E3C) : Colors.grey[300],
                      border: Border.all(
                        color: isCompleted ? Color(0xFF388E3C) : Colors.grey[300]!,
                      ),
                    ),
                    child: isCompleted
                        ? Icon(Icons.check, color: Colors.white, size: 16)
                        : null,
                  ),

                  if (!isLast)
                    Expanded(
                      child: Container(
                        width: 2,
                        color: isCompleted ? Color(0xFF388E3C) : Colors.grey[300],
                      ),
                    ),
                ],
              ),
            ),
            Expanded(
              child: Container(
                margin: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      status,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isCompleted ? Color(0xFF388E3C) : Colors.grey,
                      ),
                    ),
                    if (date.isNotEmpty) ...[
                      SizedBox(height: 4),
                      Text(
                        date,
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                    SizedBox(height: 4),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 14,
                        color: isCompleted ? Colors.black87 : Colors.grey[500],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Color(0xFF388E3C),
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          title: const Text(
            'Order Status',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          centerTitle: true,
        ),
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFF388E3C)),
        ),
      );
    }

    if (orderData == null) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Color(0xFF388E3C),
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          title: const Text(
            'Order Status',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          centerTitle: true,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.grey),
              SizedBox(height: 16),
              Text(
                'Order not found',
                style: TextStyle(fontSize: 18, color: Colors.grey[700]),
              ),
            ],
          ),
        ),
      );
    }

    int currentStatusIndex = orderData!['currentStatusIndex'] ?? 4; // Default to delivered
    List<dynamic> statusHistory = orderData!['statusHistory'] ?? [];
    
    String currentStatus = orderData!['status'] ?? 'Delivered';
    String trackingNumber = orderData!['trackingNumber'] ?? 'N/A';
    
    // Get estimated delivery
    Map<String, dynamic>? estimatedDelivery = orderData!['estimatedDelivery'];
    String estimatedDeliveryText = 'Delivered';
    if (estimatedDelivery != null) {
      String from = _formatDateShort(estimatedDelivery['from']);
      String to = _formatDateShort(estimatedDelivery['to']);
      estimatedDeliveryText = '$from - $to';
    }

    // Get shipping address
    Map<String, dynamic>? address = orderData!['shippingAddress'];
    String addressText = '';
    if (address != null) {
      addressText = '${address['line1'] ?? ''}\n';
      if (address['line2'] != null && address['line2'].isNotEmpty) {
        addressText += '${address['line2']}\n';
      }
      addressText += '${address['city'] ?? ''}, ${address['postal'] ?? ''}\n';
      addressText += address['state'] ?? '';
    }

    // Status badge color (always green for delivered)
    Color statusBadgeColor = Color(0xFF388E3C);

    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            expandedHeight: 120,
            foregroundColor: Colors.white,
            backgroundColor: Color(0xFF388E3C),
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                'Order Status',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              centerTitle: true,
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Delivery Status Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFF66BB6A), Color(0xFF388E3C)],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.3),
                          spreadRadius: 2,
                          blurRadius: 8,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.check_circle,
                          color: Colors.white,
                          size: 64,
                        ),
                        SizedBox(height: 12),
                        Text(
                          'Package Delivered!',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          _formatDateShort(orderData!['orderDate']),
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Colors.white,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 16),
                        Container(
                          padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            currentStatus,
                            style: TextStyle(
                              color: Color(0xFF388E3C),
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: 24),

                  // Status Timeline
                  Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.2),
                          spreadRadius: 1,
                          blurRadius: 6,
                          offset: Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Order Timeline',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 16),
                        
                        // Build all status cards as completed
                        for (int i = 0; i < statusConfig.length; i++)
                          buildOrderStatusCard(
                            status: statusConfig[i]['status'] ?? '',
                            date: i < statusHistory.length 
                                ? _formatDate(statusHistory[i]['timestamp']) 
                                : _formatDate(orderData!['orderDate']),
                            description: statusConfig[i]['description'] ?? '',
                            isCompleted: true,
                            isFirst: i == 0,
                            isLast: i == statusConfig.length - 1,
                          ),
                      ],
                    ),
                  ),

                  SizedBox(height: 24),

                  // Delivery Details
                  Container(
                    padding: EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.2),
                          spreadRadius: 1,
                          blurRadius: 6,
                          offset: Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Delivery Details',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 20),
                        
                        // Tracking Number
                        Row(
                          children: [
                            Container(
                              padding: EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Color(0xFF388E3C).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                Icons.local_shipping_outlined,
                                color: Color(0xFF388E3C),
                                size: 28,
                              ),
                            ),
                            SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Tracking Number',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    trackingNumber,
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey[700],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        
                        SizedBox(height: 20),
                        Divider(),
                        SizedBox(height: 20),

                        // Delivery Address
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Color(0xFF388E3C).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                Icons.location_on_outlined,
                                color: Color(0xFF388E3C),
                                size: 28,
                              ),
                            ),
                            SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Delivery Address',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    addressText,
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.grey[700],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  
                  SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}