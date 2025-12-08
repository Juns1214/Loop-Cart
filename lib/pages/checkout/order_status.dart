import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

// Constant for consistent coloring
const Color kPrimaryGreen = Color(0xFF388E3C);

class OrderStatus extends StatefulWidget {
  final String orderId;
  const OrderStatus({super.key, required this.orderId});

  @override
  State<OrderStatus> createState() => _OrderStatusState();
}

class _OrderStatusState extends State<OrderStatus> {
  Map<String, dynamic>? orderData;
  bool isLoading = true;
  
  // Data Logic
  final List<Map<String, dynamic>> statusConfig = [
    {'status': 'Order Placed', 'description': 'Your order has been placed successfully.'},
    {'status': 'Processing', 'description': 'Your order is being processed.'},
    {'status': 'Shipped', 'description': 'Your order has been shipped.'},
    {'status': 'Out for Delivery', 'description': 'Your order is out for delivery.'},
    {'status': 'Delivered', 'description': 'Your order has been delivered.'},
  ];

  @override
  void initState() {
    super.initState();
    _loadOrderStatus();
  }

  Future<void> _loadOrderStatus() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('orders')
          .doc(widget.orderId)
          .get();

      if (mounted) {
        setState(() {
          orderData = doc.exists ? doc.data() : null;
          isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading order: $e');
      if (mounted) setState(() => isLoading = false);
    }
  }

  String _formatDate(Timestamp? timestamp) {
    if (timestamp == null) return '';
    return DateFormat('MMM dd, yyyy - hh:mm a').format(timestamp.toDate());
  }

  String _formatDateShort(dynamic timestamp) {
    if (timestamp == null) return '';
    // Handle both Timestamp (Firestore) and pure DateTime if needed
    final date = timestamp is Timestamp ? timestamp.toDate() : timestamp as DateTime;
    return DateFormat('MMMM dd, yyyy').format(date);
  }

  @override
  Widget build(BuildContext context) {
    // 1. Loading State
    if (isLoading) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(child: CircularProgressIndicator(color: kPrimaryGreen)),
      );
    }

    // 2. Error/Not Found State
    if (orderData == null) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: kPrimaryGreen,
          iconTheme: const IconThemeData(color: Colors.white),
          title: const Text('Order Not Found', style: TextStyle(color: Colors.white)),
        ),
        body: const Center(child: Text("Order not found")),
      );
    }

    // 3. Main Data Preparation
    final List<dynamic> statusHistory = orderData!['statusHistory'] ?? [];
    final String currentStatus = orderData!['status'] ?? 'Delivered';
    final String trackingNumber = orderData!['trackingNumber'] ?? 'N/A';
    
    // Format Address
    final addrMap = orderData!['shippingAddress'] as Map<String, dynamic>?;
    final String addressText = addrMap != null 
        ? '${addrMap['line1'] ?? ''}\n${addrMap['line2'] ?? ''}\n${addrMap['city'] ?? ''}, ${addrMap['postal'] ?? ''}\n${addrMap['state'] ?? ''}'
            .replaceAll('\n\n', '\n') // Remove empty lines
        : 'No Address Provided';

    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            expandedHeight: 100,
            backgroundColor: kPrimaryGreen,
            foregroundColor: Colors.white,
            flexibleSpace: const FlexibleSpaceBar(
              title: Text('Order Status', style: TextStyle(fontWeight: FontWeight.bold)),
              centerTitle: true,
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // --- Section 1: Header Card ---
                  _DeliveryHeader(
                    orderDate: _formatDateShort(orderData!['orderDate']),
                    currentStatus: currentStatus,
                  ),
                  
                  const SizedBox(height: 24),

                  // --- Section 2: Timeline ---
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: _boxDecoration(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                         const Text('Order Timeline', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                         const SizedBox(height: 16),
                         // Loop through status config
                         for (int i = 0; i < statusConfig.length; i++)
                           _TimelineItem(
                             status: statusConfig[i]['status'],
                             description: statusConfig[i]['description'],
                             date: i < statusHistory.length 
                                 ? _formatDate(statusHistory[i]['timestamp']) 
                                 : (i == 0 ? _formatDate(orderData!['orderDate'] as Timestamp?) : ''),
                             isCompleted: true, // Logic from original code assumed all displayed are complete
                             isFirst: i == 0,
                             isLast: i == statusConfig.length - 1,
                           ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // --- Section 3: Delivery Details ---
                  _DeliveryDetails(
                    trackingNumber: trackingNumber,
                    addressText: addressText,
                  ),
                  
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Helper for common shadow style
  BoxDecoration _boxDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      boxShadow: [
        BoxShadow(
          color: Colors.grey.withOpacity(0.2),
          spreadRadius: 1,
          blurRadius: 6,
          offset: const Offset(0, 3),
        ),
      ],
    );
  }
}

// ==============================================================================
// SUB-WIDGETS (Extracted for readability and cleaner code)
// ==============================================================================

class _DeliveryHeader extends StatelessWidget {
  final String orderDate;
  final String currentStatus;

  const _DeliveryHeader({required this.orderDate, required this.currentStatus});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF66BB6A), kPrimaryGreen],
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.3),
            spreadRadius: 2,
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          const Icon(Icons.check_circle, color: Colors.white, size: 64),
          const SizedBox(height: 12),
          const Text(
            'Package Delivered!',
            style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            orderDate,
            style: const TextStyle(fontSize: 16, color: Colors.white70, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              currentStatus,
              style: const TextStyle(color: kPrimaryGreen, fontWeight: FontWeight.bold, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}

class _TimelineItem extends StatelessWidget {
  final String status;
  final String date;
  final String description;
  final bool isCompleted;
  final bool isFirst;
  final bool isLast;

  const _TimelineItem({
    required this.status,
    required this.date,
    required this.description,
    this.isCompleted = false,
    this.isFirst = false,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    // VISUAL UPDATE: Darker colors for readability
    final Color lineColor = isCompleted ? kPrimaryGreen : Colors.grey[300]!;
    final Color titleColor = isCompleted ? kPrimaryGreen : Colors.grey[600]!;
    
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline Logic (Lines and Dots)
          SizedBox(
            width: 50,
            child: Column(
              children: [
                if (!isFirst)
                  Container(width: 2, height: 20, color: lineColor),
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isCompleted ? kPrimaryGreen : Colors.grey[300],
                    border: Border.all(color: lineColor),
                  ),
                  child: isCompleted ? const Icon(Icons.check, color: Colors.white, size: 16) : null,
                ),
                if (!isLast)
                  Expanded(child: Container(width: 2, color: lineColor)),
              ],
            ),
          ),
          // Text Content
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(10, 0, 0, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    status,
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: titleColor),
                  ),
                  if (date.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      date,
                      // UPDATED: Darker color for date
                      style: const TextStyle(fontSize: 13, color: Colors.black87, fontWeight: FontWeight.w500),
                    ),
                  ],
                  const SizedBox(height: 4),
                  Text(
                    description,
                    // UPDATED: Darker color for description
                    style: TextStyle(fontSize: 14, color: isCompleted ? Colors.black87 : Colors.grey[800]),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DeliveryDetails extends StatelessWidget {
  final String trackingNumber;
  final String addressText;

  const _DeliveryDetails({required this.trackingNumber, required this.addressText});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 1,
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Delivery Details', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          _detailRow(Icons.local_shipping_outlined, 'Tracking Number', trackingNumber),
          const SizedBox(height: 20),
          const Divider(),
          const SizedBox(height: 20),
          _detailRow(Icons.location_on_outlined, 'Delivery Address', addressText),
        ],
      ),
    );
  }

  Widget _detailRow(IconData icon, String title, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: kPrimaryGreen.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: kPrimaryGreen, size: 24),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black)),
              const SizedBox(height: 4),
              // UPDATED: Darker color for value (tracking/address)
              Text(value, style: const TextStyle(fontSize: 15, color: Colors.black87, height: 1.4)),
            ],
          ),
        ),
      ],
    );
  }
}