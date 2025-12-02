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

  Widget _buildPurchaseCard(Map<String, dynamic> order) {
    String orderId = order['orderId'] ?? '';
    String status = order['status'] ?? 'Unknown';
    Timestamp? orderDate = order['orderDate'];
    double grandTotal = (order['grandTotal'] ?? 0).toDouble();
    List<dynamic> items = order['items'] ?? [];

    int totalItems = items.fold(
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
                      '$totalItems items',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
          ],
        ),
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
