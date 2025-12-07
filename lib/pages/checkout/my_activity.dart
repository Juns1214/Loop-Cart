import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'dart:convert';

class MyActivityPage extends StatefulWidget {
  const MyActivityPage({super.key});

  @override
  State<MyActivityPage> createState() => _MyActivityPageState();
}

class _MyActivityPageState extends State<MyActivityPage>
    with SingleTickerProviderStateMixin {
  final User? currentUser = FirebaseAuth.instance.currentUser;
  late TabController _tabController;

  bool isLoading = true;
  List<Map<String, dynamic>> purchaseHistory = [];
  List<Map<String, dynamic>> repairRecords = [];
  List<Map<String, dynamic>> recyclingRecords = [];
  List<Map<String, dynamic>> donationRecords = [];
  List<Map<String, dynamic>> sellItems = [];
  List<Map<String, dynamic>> greenCoinRecords = [];

  @override
  void initState() {
    super.initState();
    // CHANGED: Increased length to 6
    _tabController = TabController(length: 6, vsync: this);
    _loadAllData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAllData() async {
    if (currentUser == null) {
      setState(() => isLoading = false);
      return;
    }

    setState(() => isLoading = true);

    try {
      await Future.wait([
        _loadPurchaseHistory(),
        _loadRepairRecords(),
        _loadRecyclingRecords(),
        _loadDonationRecords(),
        _loadSellItems(),
        _loadGreenCoinRecords(), // NEW: Load Green Coins
      ]);
    } catch (e) {
      print('Error loading data: $e');
    }

    setState(() => isLoading = false);
  }

  // ... [Existing Load Functions: Purchase, Recycling, Donation, Sell] ...
  Future<void> _loadPurchaseHistory() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('orders')
        .where('userId', isEqualTo: currentUser!.uid)
        .orderBy('orderDate', descending: true)
        .get();

    purchaseHistory = snapshot.docs.map((doc) {
      var data = doc.data();
      data['docId'] = doc.id;
      return data;
    }).toList();
  }

  Future<void> _loadRecyclingRecords() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('recycling_record')
        .where('user_id', isEqualTo: currentUser!.uid)
        .orderBy('created_at', descending: true)
        .get();

    recyclingRecords = snapshot.docs.map((doc) {
      var data = doc.data();
      data['docId'] = doc.id;
      return data;
    }).toList();
  }

  Future<void> _loadDonationRecords() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('donation_record')
        .where('userId', isEqualTo: currentUser!.uid)
        .orderBy('createdAt', descending: true)
        .get();

    donationRecords = snapshot.docs.map((doc) {
      var data = doc.data();
      data['docId'] = doc.id;
      return data;
    }).toList();
  }

  Future<void> _loadSellItems() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('sell_items')
        .where('user_id', isEqualTo: currentUser!.uid)
        .orderBy('posted_at', descending: true)
        .get();

    sellItems = snapshot.docs.map((doc) {
      var data = doc.data();
      data['docId'] = doc.id;
      return data;
    }).toList();
  }

  // EXISTING: Load Repair Records
  Future<void> _loadRepairRecords() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('repair_record')
        .where('user_id', isEqualTo: currentUser!.uid)
        .orderBy('created_at', descending: true)
        .get();

    repairRecords = snapshot.docs.map((doc) {
      var data = doc.data();
      data['docId'] = doc.id;
      return data;
    }).toList();
  }

  // Add this method to _MyActivityPageState class

  Future<void> _confirmReceiveParcel(String orderId) async {
    try {
      await FirebaseFirestore.instance.collection('orders').doc(orderId).update(
        {'isReceived': true, 'receivedAt': FieldValue.serverTimestamp()},
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Package received! You can now provide feedback.'),
          backgroundColor: Color(0xFF388E3C),
        ),
      );

      _loadPurchaseHistory(); // Reload data
    } catch (e) {
      print('Error confirming receipt: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to confirm receipt. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // PART 1: Replace the entire _showFeedbackDialog method in my_activity.dart with this:

Future<void> _showFeedbackDialog(Map<String, dynamic> order) async {
  // Get user info from user_profile collection
  String userName = 'Anonymous';
  String userProfileUrl = '';
  
  try {
    DocumentSnapshot userDoc = await FirebaseFirestore.instance
        .collection('user_profile')
        .doc(currentUser!.uid)
        .get();
    
    if (userDoc.exists) {
      Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
      userName = userData['fullName'] ?? userData['name'] ?? 'Anonymous';
      userProfileUrl = userData['profilePicture'] ?? userData['profileImage'] ?? '';
    }
  } catch (e) {
    print('Error loading user profile: $e');
  }

  // Get all items from order
  List<dynamic> orderItems = order['items'] ?? [];
  
  // Show dialog to select which item to review
  await showDialog(
    context: context,
    builder: (context) => AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      title: Row(
        children: [
          Icon(Icons.rate_review, color: Color(0xFF388E3C)),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'Select Item to Review',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Choose which item you want to review:',
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
            SizedBox(height: 16),
            ...orderItems.map((item) {
              bool isPreowned = item['isPreowned'] ?? false;
              String productName = item['productName'] ?? 'Unknown Product';
              String imageUrl = item['imageUrl'] ?? '';
              
              return Card(
                margin: EdgeInsets.only(bottom: 12),
                child: InkWell(
                  onTap: () {
                    Navigator.pop(context);
                    _showItemReviewDialog(
                      item: item,
                      orderId: order['orderId'],
                      userName: userName,
                      userProfileUrl: userProfileUrl,
                    );
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: EdgeInsets.all(12),
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: imageUrl.isNotEmpty
                              ? Image.asset(
                                  imageUrl,
                                  width: 60,
                                  height: 60,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Container(
                                    width: 60,
                                    height: 60,
                                    color: Colors.grey[300],
                                    child: Icon(Icons.image, color: Colors.grey),
                                  ),
                                )
                              : Container(
                                  width: 60,
                                  height: 60,
                                  color: Colors.grey[300],
                                  child: Icon(Icons.image, color: Colors.grey),
                                ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                productName,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              SizedBox(height: 4),
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: isPreowned 
                                      ? Color(0xFF2E5BFF).withOpacity(0.1)
                                      : Color(0xFF388E3C).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  isPreowned ? 'Pre-owned' : 'Regular',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: isPreowned 
                                        ? Color(0xFF2E5BFF)
                                        : Color(0xFF388E3C),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.arrow_forward_ios,
                          size: 16,
                          color: Colors.grey,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(
            'Cancel',
            style: TextStyle(color: Colors.grey[600], fontSize: 16),
          ),
        ),
      ],
    ),
  );
}

// NEW METHOD: Show review dialog for specific item
Future<void> _showItemReviewDialog({
  required Map<String, dynamic> item,
  required String orderId,
  required String userName,
  required String userProfileUrl,
}) async {
  double rating = 5.0;
  TextEditingController titleController = TextEditingController();
  TextEditingController textController = TextEditingController();
  
  bool isPreowned = item['isPreowned'] ?? false;
  String productId = item['productId'] ?? '';
  String productName = item['productName'] ?? 'Unknown Product';

  await showDialog(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.rate_review, color: Color(0xFF388E3C)),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Review Product',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            SizedBox(height: 8),
            Text(
              productName,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.normal,
                color: Colors.grey[600],
              ),
            ),
            SizedBox(height: 4),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: isPreowned 
                    ? Color(0xFF2E5BFF).withOpacity(0.1)
                    : Color(0xFF388E3C).withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                isPreowned ? 'Pre-owned Product' : 'Regular Product',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: isPreowned ? Color(0xFF2E5BFF) : Color(0xFF388E3C),
                ),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Your Rating',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[800],
                ),
              ),
              SizedBox(height: 12),
              Center(
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(5, (index) {
                        return IconButton(
                          icon: Icon(
                            index < rating ? Icons.star : Icons.star_border,
                            color: Colors.amber,
                            size: 40,
                          ),
                          onPressed: () {
                            setState(() {
                              rating = (index + 1).toDouble();
                            });
                          },
                        );
                      }),
                    ),
                    Text(
                      '${rating.toInt()} out of 5 stars',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF388E3C),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 24),
              
              // Review Title
              Text(
                'Review Title',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[800],
                ),
              ),
              SizedBox(height: 8),
              TextField(
                controller: titleController,
                maxLength: 100,
                decoration: InputDecoration(
                  hintText: 'Summarize your experience',
                  hintStyle: TextStyle(color: Colors.grey[400]),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: Color(0xFF388E3C),
                      width: 2,
                    ),
                  ),
                  filled: true,
                  fillColor: Colors.grey[50],
                  counterText: '',
                ),
              ),
              SizedBox(height: 16),
              
              // Review Text
              Text(
                'Your Review',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[800],
                ),
              ),
              SizedBox(height: 8),
              TextField(
                controller: textController,
                maxLines: 5,
                maxLength: 500,
                decoration: InputDecoration(
                  hintText: 'Share your thoughts about the product...',
                  hintStyle: TextStyle(color: Colors.grey[400]),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: Color(0xFF388E3C),
                      width: 2,
                    ),
                  ),
                  filled: true,
                  fillColor: Colors.grey[50],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(color: Colors.grey[600], fontSize: 16),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              if (titleController.text.trim().isEmpty || 
                  textController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please fill in all fields'),
                    backgroundColor: Colors.orange,
                  ),
                );
                return;
              }

              try {
                // Generate unique review ID
                String reviewId = 'REV${DateTime.now().millisecondsSinceEpoch}';
                
                // Determine which collection to use
                String collectionName = isPreowned ? 'preowned_reviews' : 'reviews';
                
                // Create review document with exact structure you specified
                Map<String, dynamic> reviewData = {
                  'reviewId': reviewId,
                  'productId': productId,
                  'rating': rating.toInt(),
                  'reviewTitle': titleController.text.trim(),
                  'reviewText': textController.text.trim(),
                  'userName': userName,
                  'userProfileUrl': userProfileUrl,
                  'reviewDate': DateTime.now().toIso8601String(),
                };

                // Save to appropriate collection
                await FirebaseFirestore.instance
                    .collection(collectionName)
                    .doc(reviewId)
                    .set(reviewData);

                // Mark item as reviewed in the order
                // Update order to track which items have been reviewed
                await _markItemAsReviewed(orderId, productId);

                Navigator.pop(context);

                // Show success message with option to view review
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Thank you for your review!'),
                    backgroundColor: Color(0xFF388E3C),
                    action: SnackBarAction(
                      label: 'View Review',
                      textColor: Colors.white,
                      onPressed: () {
                        _showSubmittedReviewDialog(reviewData, isPreowned);
                      },
                    ),
                    duration: Duration(seconds: 4),
                  ),
                );

                _loadPurchaseHistory();
              } catch (e) {
                print('Error submitting review: $e');
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Failed to submit review'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF388E3C),
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text('Submit Review', style: TextStyle(fontSize: 16)),
          ),
        ],
      ),
    ),
  );
}

// NEW METHOD: Mark item as reviewed
Future<void> _markItemAsReviewed(String orderId, String productId) async {
  try {
    DocumentSnapshot orderDoc = await FirebaseFirestore.instance
        .collection('orders')
        .doc(orderId)
        .get();
    
    if (orderDoc.exists) {
      Map<String, dynamic> orderData = orderDoc.data() as Map<String, dynamic>;
      List<dynamic> items = orderData['items'] ?? [];
      
      // Add reviewedProductIds field if it doesn't exist
      List<dynamic> reviewedProducts = orderData['reviewedProductIds'] ?? [];
      
      if (!reviewedProducts.contains(productId)) {
        reviewedProducts.add(productId);
        
        // Check if all items have been reviewed
        bool allReviewed = true;
        for (var item in items) {
          String itemProductId = item['productId'] ?? '';
          if (!reviewedProducts.contains(itemProductId)) {
            allReviewed = false;
            break;
          }
        }
        
        await FirebaseFirestore.instance
            .collection('orders')
            .doc(orderId)
            .update({
              'reviewedProductIds': reviewedProducts,
              'hasFeedback': allReviewed,
            });
      }
    }
  } catch (e) {
    print('Error marking item as reviewed: $e');
  }
}

// NEW METHOD: Show submitted review in a dialog
Future<void> _showSubmittedReviewDialog(
  Map<String, dynamic> reviewData,
  bool isPreowned,
) async {
  await showDialog(
    context: context,
    builder: (context) => AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      title: Row(
        children: [
          Icon(
            Icons.check_circle,
            color: Color(0xFF388E3C),
            size: 28,
          ),
          SizedBox(width: 12),
          Text(
            'Your Review',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Product Type Badge
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: isPreowned 
                    ? Color(0xFF2E5BFF).withOpacity(0.1)
                    : Color(0xFF388E3C).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isPreowned ? Icons.recycling : Icons.shopping_bag,
                    size: 14,
                    color: isPreowned ? Color(0xFF2E5BFF) : Color(0xFF388E3C),
                  ),
                  SizedBox(width: 6),
                  Text(
                    isPreowned ? 'Pre-owned Product' : 'Regular Product',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: isPreowned ? Color(0xFF2E5BFF) : Color(0xFF388E3C),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 16),
            
            // Rating
            Row(
              children: List.generate(5, (index) {
                return Icon(
                  index < reviewData['rating'] ? Icons.star : Icons.star_border,
                  color: Colors.amber,
                  size: 24,
                );
              }),
            ),
            SizedBox(height: 16),
            
            // Title
            Text(
              reviewData['reviewTitle'],
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            SizedBox(height: 12),
            
            // Review Text
            Text(
              reviewData['reviewText'],
              style: TextStyle(
                fontSize: 15,
                color: Colors.grey[700],
                height: 1.5,
              ),
            ),
            SizedBox(height: 16),
            
            // Metadata
            Divider(),
            SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.person, size: 16, color: Colors.grey[600]),
                SizedBox(width: 8),
                Text(
                  reviewData['userName'],
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
            SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                SizedBox(width: 8),
                Text(
                  _formatReviewDate(reviewData['reviewDate']),
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
            SizedBox(height: 8),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Color(0xFFF0FDF4),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Color(0xFF388E3C).withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 16,
                    color: Color(0xFF388E3C),
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Saved to ${isPreowned ? "pre-owned" : "regular"} products collection',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF388E3C),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        ElevatedButton(
          onPressed: () => Navigator.pop(context),
          style: ElevatedButton.styleFrom(
            backgroundColor: Color(0xFF388E3C),
            foregroundColor: Colors.white,
            padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: Text('Close', style: TextStyle(fontSize: 16)),
        ),
      ],
    ),
  );
}

// Helper method to format review date
String _formatReviewDate(String isoDate) {
  try {
    DateTime date = DateTime.parse(isoDate);
    return DateFormat('MMM dd, yyyy').format(date);
  } catch (e) {
    return isoDate;
  }
}

// PART 2: Replace the _buildPurchaseCard method in my_activity.dart with this:

Widget _buildPurchaseCard(Map<String, dynamic> order) {
  String orderId = order['orderId'] ?? '';
  String status = order['status'] ?? 'Unknown';
  Timestamp? orderDate = order['orderDate'];
  double grandTotal = (order['grandTotal'] ?? 0).toDouble();
  List<dynamic> items = order['items'] ?? [];
  bool isReceived = order['isReceived'] ?? false;
  bool isDelivered = status == 'Delivered';
  
  // Get list of reviewed product IDs
  List<dynamic> reviewedProductIds = order['reviewedProductIds'] ?? [];
  
  // Check if all items have been reviewed
  bool allItemsReviewed = items.isNotEmpty && 
      items.every((item) => reviewedProductIds.contains(item['productId']));
  
  // Count reviewed vs total items
  int reviewedCount = reviewedProductIds.length;
  int totalItemCount = items.length;

  int totalQuantity = items.fold(
    0,
    (sum, item) => sum + (item['quantity'] as int? ?? 1),
  );

  return Card(
    margin: const EdgeInsets.only(bottom: 12),
    elevation: 2,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Order Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Order #${orderId.substring(orderId.length > 8 ? orderId.length - 8 : 0)}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatDate(orderDate),
                    style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'RM ${grandTotal.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF388E3C),
                    ),
                  ),
                  Text(
                    '$totalQuantity items',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
            ],
          ),
          
          const SizedBox(height: 12),

          // Status Badges Row
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              // Order Status
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: _getStatusColor(status),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  status,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              
              // Received Badge
              if (isReceived)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.blue),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check_circle, size: 14, color: Colors.blue),
                      SizedBox(width: 4),
                      Text(
                        'Received',
                        style: TextStyle(
                          color: Colors.blue,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              
              // Review Status Badge
              if (isReceived)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: allItemsReviewed 
                        ? Colors.amber[50] 
                        : Colors.grey[100],
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: allItemsReviewed ? Colors.amber : Colors.grey[400]!,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        allItemsReviewed ? Icons.star : Icons.star_border,
                        size: 14,
                        color: allItemsReviewed ? Colors.amber : Colors.grey[600],
                      ),
                      SizedBox(width: 4),
                      Text(
                        allItemsReviewed 
                            ? 'All Reviewed' 
                            : 'Reviewed $reviewedCount/$totalItemCount',
                        style: TextStyle(
                          color: allItemsReviewed 
                              ? Colors.amber[800] 
                              : Colors.grey[700],
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),

          // Product Items Preview (show first 2 items)
          if (items.isNotEmpty) ...[
            SizedBox(height: 12),
            Divider(),
            SizedBox(height: 8),
            Text(
              'Items in Order:',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
            SizedBox(height: 8),
            ...items.take(2).map((item) {
              bool isPreowned = item['isPreowned'] ?? false;
              String productId = item['productId'] ?? '';
              bool isItemReviewed = reviewedProductIds.contains(productId);
              
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    // Product Image
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: item['imageUrl'] != null && item['imageUrl'].isNotEmpty
                          ? Image.asset(
                              item['imageUrl'],
                              width: 50,
                              height: 50,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                width: 50,
                                height: 50,
                                color: Colors.grey[300],
                                child: Icon(Icons.image, size: 24, color: Colors.grey),
                              ),
                            )
                          : Container(
                              width: 50,
                              height: 50,
                              color: Colors.grey[300],
                              child: Icon(Icons.image, size: 24, color: Colors.grey),
                            ),
                    ),
                    SizedBox(width: 12),
                    
                    // Product Info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item['productName'] ?? 'Unknown',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          SizedBox(height: 4),
                          Row(
                            children: [
                              // Product Type Badge
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: isPreowned 
                                      ? Color(0xFF2E5BFF).withOpacity(0.1)
                                      : Color(0xFF388E3C).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  isPreowned ? 'Pre-owned' : 'Regular',
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                    color: isPreowned 
                                        ? Color(0xFF2E5BFF)
                                        : Color(0xFF388E3C),
                                  ),
                                ),
                              ),
                              
                              // Reviewed Badge
                              if (isItemReviewed) ...[
                                SizedBox(width: 6),
                                Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.amber[50],
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.check_circle,
                                        size: 9,
                                        color: Colors.amber[800],
                                      ),
                                      SizedBox(width: 2),
                                      Text(
                                        'Reviewed',
                                        style: TextStyle(
                                          fontSize: 9,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.amber[800],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                    
                    // Quantity
                    Text(
                      'x${item['quantity'] ?? 1}',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
            
            // Show "and X more items" if there are more than 2 items
            if (items.length > 2)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  '+ ${items.length - 2} more ${items.length - 2 == 1 ? "item" : "items"}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFF388E3C),
                    fontWeight: FontWeight.w600,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
          ],

          // Action buttons for delivered orders
          if (isDelivered) ...[
            SizedBox(height: 12),
            Divider(),
            SizedBox(height: 8),
            
            // Buttons Row
            Row(
              children: [
                // Receive Parcel Button (if not received yet)
                if (!isReceived)
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _confirmReceiveParcel(orderId),
                      icon: Icon(Icons.inventory_2, size: 18),
                      label: Text('Receive Parcel'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFF388E3C),
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                
                // Give Feedback Button (if received but not all items reviewed)
                if (isReceived && !allItemsReviewed) ...[
                  if (!isReceived) SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _showFeedbackDialog(order),
                      icon: Icon(Icons.rate_review, size: 18),
                      label: Text(
                        reviewedCount == 0 
                            ? 'Review Items' 
                            : 'Review More',
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFF2E5BFF),
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
            
            // View Details Button (always shown)
            SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.pushNamed(
                    context,
                    '/order-status',
                    arguments: {'orderId': orderId},
                  );
                },
                icon: Icon(Icons.info_outline, size: 18),
                label: Text('View Order Details'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Color(0xFF388E3C),
                  padding: EdgeInsets.symmetric(vertical: 10),
                  side: BorderSide(color: Color(0xFF388E3C)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    ),
  );
}

  // NEW: Load Green Coin Records
  Future<void> _loadGreenCoinRecords() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('green_coin_transactions')
        .where('userId', isEqualTo: currentUser!.uid)
        .orderBy('createdAt', descending: true)
        .get();

    greenCoinRecords = snapshot.docs.map((doc) {
      var data = doc.data();
      data['docId'] = doc.id;
      return data;
    }).toList();
  }

  String _formatDate(dynamic timestamp) {
    if (timestamp == null) return '';
    if (timestamp is Timestamp) {
      return DateFormat('MMM dd, yyyy').format(timestamp.toDate());
    }
    return timestamp.toString();
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
          'My Activity',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
        ),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Container(
            color: Colors.white,
            child: TabBar(
              controller: _tabController,
              isScrollable: true,
              labelColor: const Color(0xFF388E3C),
              unselectedLabelColor: Colors.grey,
              indicatorColor: const Color(0xFF388E3C),
              indicatorWeight: 3,
              labelStyle: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
              tabs: const [
                Tab(text: 'Purchases'),
                Tab(text: 'Repairs'),
                Tab(text: 'Recycling'),
                Tab(text: 'Donations'),
                Tab(text: 'Listed Items'),
                Tab(text: 'Green Coins'),
              ],
            ),
          ),
        ),
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF388E3C)),
            )
          : TabBarView(
              controller: _tabController,
              children: [
                _buildPurchaseHistoryTab(),
                _buildRepairRecordsTab(),
                _buildRecyclingRecordsTab(),
                _buildDonationRecordsTab(),
                _buildSellItemsTab(),
                _buildGreenCoinHistoryTab(), // NEW VIEW
              ],
            ),
    );
  }

  // -------------------- REPAIR TAB (UPDATED) --------------------
  Widget _buildRepairRecordsTab() {
    if (repairRecords.isEmpty) {
      return _buildEmptyState(
        icon: Icons.build_outlined,
        title: 'No Repair Records',
        subtitle: 'Your repair service bookings will appear here',
      );
    }

    return RefreshIndicator(
      color: const Color(0xFF388E3C),
      onRefresh: _loadRepairRecords,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              '${repairRecords.length} ${repairRecords.length == 1 ? 'Repair' : 'Repairs'}',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
          ),
          ...repairRecords.map((record) => _buildRepairCard(record)),
        ],
      ),
    );
  }

  Widget _buildRepairCard(Map<String, dynamic> record) {
    String name = record['name'] ?? 'Unknown Item';
    String description = record['description'] ?? '';
    String scheduledDate = record['scheduled_date'] ?? '';
    String scheduledTime = record['scheduled_time'] ?? '';
    Map<String, dynamic>? repairOption = record['repair_option'];
    String? image = record['image'];
    // NEW: Get Status
    String status = record['status'] ?? 'Pending';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (image != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.memory(
                      base64Decode(image),
                      width: 80,
                      height: 80,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        width: 80,
                        height: 80,
                        color: Colors.grey[300],
                        child: const Icon(
                          Icons.build,
                          size: 40,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                  ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              name,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          // NEW: Status Chip
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: status == 'Pending Review'
                                  ? Colors.orange[100]
                                  : Colors.blue[50],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              status,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: status == 'Pending Review'
                                    ? Colors.orange[800]
                                    : Colors.blue,
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (description.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          description,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[600],
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      const SizedBox(height: 8),
                      if (repairOption != null) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${repairOption['Repair']} - ${repairOption['Price']}',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[800],
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                      ],
                      Row(
                        children: [
                          const Icon(
                            Icons.calendar_today,
                            size: 14,
                            color: Colors.grey,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            scheduledDate,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[700],
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Icon(
                            Icons.access_time,
                            size: 14,
                            color: Colors.grey,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            scheduledTime,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[700],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // -------------------- NEW: GREEN COIN TAB --------------------
  Widget _buildGreenCoinHistoryTab() {
    if (greenCoinRecords.isEmpty) {
      return _buildEmptyState(
        icon: Icons.monetization_on_outlined,
        title: 'No Coin History',
        subtitle: 'Your Green Coin transactions will appear here',
      );
    }

    return RefreshIndicator(
      color: const Color(0xFF388E3C),
      onRefresh: _loadGreenCoinRecords,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF388E3C), Color(0xFF66BB6A)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.green.withOpacity(0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.eco, color: Colors.white, size: 30),
                ),
                const SizedBox(width: 16),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Green Coin History',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Track your earnings and spendings',
                      style: TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                  ],
                ),
              ],
            ),
          ),
          ...greenCoinRecords.map((record) => _buildGreenCoinCard(record)),
        ],
      ),
    );
  }

  Widget _buildGreenCoinCard(Map<String, dynamic> record) {
    int amount = record['amount'] ?? 0;
    String description = record['description'] ?? 'Transaction';
    Timestamp? createdAt = record['createdAt'];
    String activity = record['activity'] ?? '';
    bool isCredit = amount > 0;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isCredit ? Colors.green[50] : Colors.red[50],
            shape: BoxShape.circle,
          ),
          child: Icon(
            isCredit ? Icons.add : Icons.remove,
            color: isCredit ? Colors.green : Colors.red,
            size: 20,
          ),
        ),
        title: Text(
          description,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Row(
            children: [
              Text(
                activity.toUpperCase(),
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                _formatDate(createdAt),
                style: TextStyle(fontSize: 11, color: Colors.grey[400]),
              ),
            ],
          ),
        ),
        trailing: Text(
          '${isCredit ? '+' : ''}$amount',
          style: TextStyle(
            color: isCredit ? const Color(0xFF388E3C) : Colors.red,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),
    );
  }

  // -------------------- EXISTING TABS (KEEP AS IS) --------------------

  Widget _buildPurchaseHistoryTab() {
    if (purchaseHistory.isEmpty) {
      return _buildEmptyState(
        icon: Icons.shopping_bag_outlined,
        title: 'No Purchase History',
        subtitle: 'Your purchase history will appear here',
      );
    }
    return RefreshIndicator(
      color: const Color(0xFF388E3C),
      onRefresh: _loadPurchaseHistory,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              '${purchaseHistory.length} ${purchaseHistory.length == 1 ? 'Order' : 'Orders'}',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
          ),
          ...purchaseHistory.map((order) => _buildPurchaseCard(order)),
        ],
      ),
    );
  }

  Widget _buildRecyclingRecordsTab() {
    if (recyclingRecords.isEmpty) {
      return _buildEmptyState(
        icon: Icons.recycling_outlined,
        title: 'No Recycling Records',
        subtitle: 'Your recycling pickup requests will appear here',
      );
    }
    return RefreshIndicator(
      color: const Color(0xFF388E3C),
      onRefresh: _loadRecyclingRecords,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              '${recyclingRecords.length} ${recyclingRecords.length == 1 ? 'Request' : 'Requests'}',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
          ),
          ...recyclingRecords.map((record) => _buildRecyclingCard(record)),
        ],
      ),
    );
  }

  Widget _buildRecyclingCard(Map<String, dynamic> record) {
    String name = record['name'] ?? 'Unknown Item';
    String category = record['category'] ?? '';
    String description = record['description'] ?? '';
    String scheduledDate = record['scheduled_date'] ?? '';
    String scheduledTime = record['scheduled_time'] ?? '';
    String? image = record['image'];

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (image != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.memory(
                  base64Decode(image),
                  width: 80,
                  height: 80,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    width: 80,
                    height: 80,
                    color: Colors.grey[300],
                    child: const Icon(
                      Icons.recycling,
                      size: 40,
                      color: Colors.grey,
                    ),
                  ),
                ),
              ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green[50],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      category,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF388E3C),
                      ),
                    ),
                  ),
                  if (description.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      description,
                      style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                    ),
                  ],
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(
                        Icons.calendar_today,
                        size: 14,
                        color: Colors.grey,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        scheduledDate,
                        style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                      ),
                      const SizedBox(width: 12),
                      const Icon(
                        Icons.access_time,
                        size: 14,
                        color: Colors.grey,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        scheduledTime,
                        style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDonationRecordsTab() {
    if (donationRecords.isEmpty) {
      return _buildEmptyState(
        icon: Icons.volunteer_activism_outlined,
        title: 'No Donations',
        subtitle: 'Your donation history will appear here',
      );
    }
    return RefreshIndicator(
      color: const Color(0xFF388E3C),
      onRefresh: _loadDonationRecords,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              '${donationRecords.length} ${donationRecords.length == 1 ? 'Donation' : 'Donations'}',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
          ),
          ...donationRecords.map((record) => _buildDonationCard(record)),
        ],
      ),
    );
  }

  Widget _buildDonationCard(Map<String, dynamic> record) {
    double amount = (record['amount25'] ?? 0).toDouble();
    if (amount == 0 && record['amount'] != null) {
      amount = (record['amount']).toDouble();
    }
    String category = record['donationCategory'] ?? '';
    String status = record['status'] ?? '';
    int greenCoins = record['greenCoinsEarned'] ?? 0;
    Timestamp? createdAt = record['createdAt'];
    String transactionId = record['transactionId'] ?? '';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      category,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatDate(createdAt),
                      style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                    ),
                  ],
                ),
                Text(
                  'RM ${amount.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF388E3C),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: status == 'Completed'
                        ? Colors.green[50]
                        : Colors.orange[50],
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    status,
                    style: TextStyle(
                      color: status == 'Completed'
                          ? const Color(0xFF388E3C)
                          : Colors.orange,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.amber[50],
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.eco, size: 14, color: Colors.amber),
                      const SizedBox(width: 4),
                      Text(
                        '+$greenCoins coins',
                        style: const TextStyle(
                          color: Colors.amber,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (transactionId.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                'Transaction: ${transactionId.substring(transactionId.length > 12 ? transactionId.length - 12 : 0)}',
                style: TextStyle(fontSize: 11, color: Colors.grey[500]),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSellItemsTab() {
    if (sellItems.isEmpty) {
      return _buildEmptyState(
        icon: Icons.sell_outlined,
        title: 'No Listed Items',
        subtitle: 'Your posted second-hand items will appear here',
      );
    }
    return RefreshIndicator(
      color: const Color(0xFF388E3C),
      onRefresh: _loadSellItems,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              '${sellItems.length} ${sellItems.length == 1 ? 'Item' : 'Items'}',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
          ),
          ...sellItems.map((item) => _buildSellItemCard(item)),
        ],
      ),
    );
  }

  Widget _buildSellItemCard(Map<String, dynamic> item) {
    String name = item['name'] ?? 'Unknown Item';
    String description = item['description'] ?? '';
    double price = double.tryParse(item['price']?.toString() ?? '0') ?? 0;
    bool isDraft = item['isDraft'] ?? false;
    Timestamp? postedAt = item['posted_at'];
    String? image = item['image'];

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (image != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.memory(
                  base64Decode(image),
                  width: 100,
                  height: 100,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    width: 100,
                    height: 100,
                    color: Colors.grey[300],
                    child: const Icon(
                      Icons.image,
                      size: 40,
                      color: Colors.grey,
                    ),
                  ),
                ),
              ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: isDraft ? Colors.orange[50] : Colors.green[50],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          isDraft ? 'Draft' : 'Active',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: isDraft
                                ? Colors.orange
                                : const Color(0xFF388E3C),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'RM ${price.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF388E3C),
                    ),
                  ),
                  if (description.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      description,
                      style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 8),
                  Text(
                    'Posted: ${_formatDate(postedAt)}',
                    style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            title,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Delivered':
        return const Color(0xFF388E3C);
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
}
