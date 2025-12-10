import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import '../../widget/activity_components.dart';
import '../../widget/custom_button.dart';
import '../../utils/review_service.dart';

class MyActivityPage extends StatefulWidget {
  const MyActivityPage({super.key});

  @override
  State<MyActivityPage> createState() => _MyActivityPageState();
}

class _MyActivityPageState extends State<MyActivityPage>
    with SingleTickerProviderStateMixin {
  final User? currentUser = FirebaseAuth.instance.currentUser;
  late TabController _tabController;
  static const Color _primaryColor = Color(0xFF388E3C);

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
    _tabController = TabController(length: 6, vsync: this);
    _loadAllData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // ============= DATA LOADING =============

  Future<void> _loadAllData() async {
    if (currentUser == null) {
      if (mounted) setState(() => isLoading = false);
      return;
    }

    setState(() => isLoading = true);
    await Future.wait([
      _loadCollection(
        'orders',
        (data) => purchaseHistory = data,
        orderBy: 'orderDate',
        userField: 'userId',
      ),
      _loadCollection(
        'repair_record',
        (data) => repairRecords = data,
        orderBy: 'created_at',
        userField: 'user_id',
      ),
      _loadCollection(
        'recycling_record',
        (data) => recyclingRecords = data,
        orderBy: 'created_at',
        userField: 'user_id',
      ),
      _loadCollection(
        'donation_record',
        (data) => donationRecords = data,
        orderBy: 'createdAt',
        userField: 'userId',
      ),
      _loadCollection(
        'sell_items',
        (data) => sellItems = data,
        orderBy: 'posted_at',
        userField: 'user_id',
      ),
      _loadCollection(
        'green_coin_transactions',
        (data) => greenCoinRecords = data,
        orderBy: 'createdAt',
        userField: 'userId',
      ),
    ]);
    if (mounted) setState(() => isLoading = false);
  }

  Future<void> _loadCollection(
    String collection,
    Function(List<Map<String, dynamic>>) onSuccess, {
    required String orderBy,
    required String userField,
  }) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection(collection)
          .where(userField, isEqualTo: currentUser!.uid)
          .orderBy(orderBy, descending: true)
          .get();

      onSuccess(
        snapshot.docs.map((doc) {
          var data = doc.data();
          data['docId'] = doc.id;
          return data;
        }).toList(),
      );
    } catch (e) {
      debugPrint('Error loading $collection: $e');
    }
  }

  // ============= UI BUILDERS =============

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _buildAppBar(),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildPurchaseTab(),
          _buildGenericTab(
            repairRecords,
            _buildRepairCard,
            Icons.build_outlined,
            'No Repair Records',
            'Your bookings will appear here',
            'Repair',
          ),
          _buildGenericTab(
            recyclingRecords,
            _buildRecyclingCard,
            Icons.recycling_outlined,
            'No Recycling Records',
            'Your requests will appear here',
            'Request',
          ),
          _buildGenericTab(
            donationRecords,
            _buildDonationCard,
            Icons.volunteer_activism_outlined,
            'No Donations',
            'Your history will appear here',
            'Donation',
          ),
          _buildGenericTab(
            sellItems,
            _buildSellItemCard,
            Icons.sell_outlined,
            'No Listed Items',
            'Your posted items will appear here',
            'Item',
          ),
          _buildGenericTab(
            greenCoinRecords,
            _buildGreenCoinCard,
            Icons.monetization_on_outlined,
            'No Coin History',
            'Transactions appear here',
            'Transaction',
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      leading: const BackButton(color: Colors.black87),
      title: const Text(
        'My Activity',
        style: TextStyle(fontWeight: FontWeight.w800, color: Colors.black87),
      ),
      centerTitle: true,
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(50),
        child: Container(
          color: Colors.white,
          child: TabBar(
            controller: _tabController,
            isScrollable: true,
            labelColor: _primaryColor,
            unselectedLabelColor: Colors.grey[600],
            indicatorColor: _primaryColor,
            indicatorWeight: 3,
            labelStyle: const TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 14,
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
    );
  }

  Widget _buildPurchaseTab() {
    return ActivityTabBody(
      isLoading: isLoading,
      data: purchaseHistory,
      onRefresh: () => _loadCollection(
        'orders',
        (data) => setState(() => purchaseHistory = data),
        orderBy: 'orderDate',
        userField: 'userId',
      ),
      emptyIcon: Icons.shopping_bag_outlined,
      emptyTitle: 'No Purchase History',
      emptySubtitle: 'Your purchase history will appear here',
      itemCountLabel: 'Order',
      itemBuilder: _buildPurchaseCard,
    );
  }

  Widget _buildGenericTab(
    List<Map<String, dynamic>> data,
    Widget Function(Map<String, dynamic>) builder,
    IconData icon,
    String title,
    String subtitle,
    String label,
  ) {
    return ActivityTabBody(
      isLoading: isLoading,
      data: data,
      onRefresh: _loadAllData,
      emptyIcon: icon,
      emptyTitle: title,
      emptySubtitle: subtitle,
      itemCountLabel: label,
      itemBuilder: builder,
    );
  }

  // ============= CARD BUILDERS =============

  Widget _buildPurchaseCard(Map<String, dynamic> order) {
    final orderId = order['orderId'] ?? '';
    final status = order['status'] ?? 'Unknown';
    final grandTotal = (order['grandTotal'] ?? 0).toDouble();

    // --- FIX START: Explicitly cast these lists to avoid the TypeError ---
    // We use List.from(...) to safely convert the dynamic Firestore data
    final items = List<Map<String, dynamic>>.from(
      order['items']?.map((x) => Map<String, dynamic>.from(x)) ?? [],
    );
    final reviewedIds = List<String>.from(order['reviewedProductIds'] ?? []);
    // --- FIX END ---

    final isReceived = order['isReceived'] ?? false;
    final isDelivered = status == 'Delivered';

    // Now this line works safely because 'items' is known to be a List
    final allReviewed =
        items.isNotEmpty &&
        items.every((item) => reviewedIds.contains(item['productId']));

    final totalQty = items.fold<int>(
      0,
      (sum, item) => sum + (item['quantity'] as int? ?? 1),
    );

    return ActivityCardWrapper(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildOrderHeader(orderId, order['orderDate'], grandTotal, totalQty),
          const SizedBox(height: 12),
          _buildOrderStatusBadges(
            status,
            isReceived,
            allReviewed,
            reviewedIds.length,
            items.length,
          ),
          const Divider(height: 24),
          ...items.take(2).map((item) => _buildOrderItem(item, reviewedIds)),
          if (items.length > 2) _buildMoreItemsText(items.length - 2),
          if (isDelivered)
            _buildOrderActions(orderId, isReceived, allReviewed, order),
        ],
      ),
    );
  }

  Widget _buildOrderHeader(
    String orderId,
    dynamic orderDate,
    double total,
    int qty,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Order #${orderId.length > 8 ? orderId.substring(orderId.length - 8) : orderId}',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: Colors.black87,
              ),
            ),
            Text(
              _formatDate(orderDate),
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[800],
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              'RM ${total.toStringAsFixed(2)}',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: _primaryColor,
              ),
            ),
            Text(
              '$qty items',
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[800],
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildOrderStatusBadges(
    String status,
    bool isReceived,
    bool allReviewed,
    int reviewedCount,
    int totalItems,
  ) {
    return Wrap(
      spacing: 8,
      children: [
        StatusBadge(status: status),
        if (isReceived) const StatusBadge(status: 'Received'),
        if (isReceived)
          StatusBadge(
            status: allReviewed
                ? 'All Reviewed'
                : 'Reviewed $reviewedCount/$totalItems',
            colorOverride: allReviewed ? Colors.amber[800] : Colors.grey[800],
          ),
      ],
    );
  }

  Widget _buildOrderItem(Map<String, dynamic> item, List<dynamic> reviewedIds) {
    final isReviewed = reviewedIds.contains(item['productId']);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          _buildProductImage(item['imageUrl']),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item['productName'] ?? 'Unknown',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    ProductTypeBadge(isPreowned: item['isPreowned'] ?? false),
                    if (isReviewed) ...[
                      const SizedBox(width: 8),
                      const Icon(
                        Icons.check_circle,
                        size: 14,
                        color: Colors.amber,
                      ),
                      Text(
                        ' Reviewed',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.amber[800],
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          Text(
            'x${item['quantity'] ?? 1}',
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 15,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductImage(String? imageUrl) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 50,
        height: 50,
        color: Colors.grey[200],
        child: imageUrl != null
            ? Image.asset(
                imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const Icon(Icons.image),
              )
            : const Icon(Icons.image),
      ),
    );
  }

  Widget _buildMoreItemsText(int count) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Text(
        '+ $count more items',
        style: const TextStyle(
          fontSize: 13,
          color: _primaryColor,
          fontWeight: FontWeight.w700,
          fontStyle: FontStyle.italic,
        ),
      ),
    );
  }

  Widget _buildOrderActions(
    String orderId,
    bool isReceived,
    bool allReviewed,
    Map<String, dynamic> order,
  ) {
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Row(
        children: [
          if (!isReceived)
            Expanded(
              child: CustomButton(
                text: 'Receive Order',
                onPressed: () => _confirmReceiveParcel(orderId),
                backgroundColor: _primaryColor,
                fontSize: 14,
                minimumSize: const Size(double.infinity, 42),
                borderRadius: 8,
              ),
            ),
          if (isReceived && !allReviewed) ...[
            if (!isReceived) const SizedBox(width: 12),
            Expanded(
              child: CustomButton(
                text: (order['reviewedProductIds'] ?? []).isEmpty
                    ? 'Review Items'
                    : 'Review More',
                onPressed: () => _showFeedbackDialog(order),
                backgroundColor: const Color(0xFF2E5BFF),
                fontSize: 14,
                minimumSize: const Size(double.infinity, 42),
                borderRadius: 8,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRepairCard(Map<String, dynamic> record) {
    return ActivityCardWrapper(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildRecordImage(record['image'], Icons.build),
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
                        record['name'] ?? 'Unknown',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                    StatusBadge(status: record['status'] ?? 'Pending'),
                  ],
                ),
                if (record['repair_option'] != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    '${record['repair_option']['Repair']} - ${record['repair_option']['Price']}',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[850],
                    ),
                  ),
                ],
                const SizedBox(height: 8),
                _buildDateTimeRow(
                  record['scheduled_date'],
                  record['scheduled_time'],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecyclingCard(Map<String, dynamic> record) {
    return ActivityCardWrapper(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildRecordImage(record['image'], Icons.recycling),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  record['name'] ?? 'Unknown',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green[50],
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    record['category'] ?? '',
                    style: const TextStyle(
                      color: _primaryColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                _buildDateTimeRow(
                  record['scheduled_date'],
                  record['scheduled_time'],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDonationCard(Map<String, dynamic> record) {
    final amount = (record['amount25'] ?? record['amount'] ?? 0).toDouble();
    return ActivityCardWrapper(
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    record['donationCategory'] ?? 'Donation',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                    ),
                  ),
                  Text(
                    _formatDate(record['createdAt']),
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[800],
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              Text(
                'RM ${amount.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: _primaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              StatusBadge(status: record['status'] ?? 'Completed'),
              if ((record['greenCoinsEarned'] ?? 0) > 0)
                Row(
                  children: [
                    const Icon(Icons.eco, size: 14, color: Colors.amber),
                    Text(
                      ' +${record['greenCoinsEarned']} coins',
                      style: const TextStyle(
                        color: Colors.amber,
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSellItemCard(Map<String, dynamic> item) {
    final price = (double.tryParse(item['price']?.toString() ?? '0') ?? 0)
        .toStringAsFixed(2);
    return ActivityCardWrapper(
      child: Row(
        children: [
          _buildRecordImage(item['image'], Icons.sell),
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
                        item['name'] ?? 'Item',
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                    StatusBadge(
                      status: (item['isDraft'] ?? false) ? 'Draft' : 'Active',
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'RM $price',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: _primaryColor,
                  ),
                ),
                Text(
                  'Posted: ${_formatDate(item['posted_at'])}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[700],
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGreenCoinCard(Map<String, dynamic> record) {
    final isCredit = (record['amount'] ?? 0) > 0;
    return ActivityCardWrapper(
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isCredit ? Colors.green[50] : Colors.red[50],
              shape: BoxShape.circle,
            ),
            child: Icon(
              isCredit ? Icons.add : Icons.remove,
              color: isCredit ? Colors.green[700] : Colors.red[700],
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  record['description'] ?? 'Transaction',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: Colors.black87,
                  ),
                ),
                Text(
                  '${record['activity']?.toUpperCase() ?? ''} • ${_formatDate(record['createdAt'])}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[700],
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '${isCredit ? '+' : ''}${record['amount']}',
            style: TextStyle(
              color: isCredit ? _primaryColor : Colors.red[700],
              fontWeight: FontWeight.w800,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  // ============= HELPER WIDGETS =============

  Widget _buildRecordImage(String? base64String, IconData fallbackIcon) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 80,
        height: 80,
        color: Colors.grey[100],
        child: base64String != null
            ? Image.memory(
                base64Decode(base64String),
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) =>
                    Icon(fallbackIcon, color: Colors.grey[400]),
              )
            : Icon(fallbackIcon, color: Colors.grey[400]),
      ),
    );
  }

  Widget _buildDateTimeRow(String? date, String? time) {
    return Row(
      children: [
        if (date != null) ...[
          Icon(Icons.calendar_today, size: 13, color: Colors.grey[700]),
          const SizedBox(width: 4),
          Text(
            date,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[850],
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
        if (time != null) ...[
          const SizedBox(width: 12),
          Icon(Icons.access_time, size: 13, color: Colors.grey[700]),
          const SizedBox(width: 4),
          Text(
            time,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[850],
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ],
    );
  }

  // ============= ACTIONS =============

  Future<void> _confirmReceiveParcel(String orderId) async {
    try {
      await FirebaseFirestore.instance.collection('orders').doc(orderId).update(
        {'isReceived': true, 'receivedAt': FieldValue.serverTimestamp()},
      );
      _loadAllData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Package received!',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            backgroundColor: _primaryColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error updating status'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _showFeedbackDialog(Map<String, dynamic> order) async {
    final items = order['items'] ?? [];
    final reviewedIds = order['reviewedProductIds'] ?? [];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Select Item to Review',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              final isReviewed = reviewedIds.contains(item['productId']);
              return ListTile(
                leading: ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: item['imageUrl'] != null
                      ? Image.asset(
                          item['imageUrl'],
                          width: 44,
                          height: 44,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const Icon(Icons.image),
                        )
                      : const Icon(Icons.image),
                ),
                title: Text(
                  item['productName'] ?? 'Product',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                subtitle: Row(
                  children: [
                    ProductTypeBadge(isPreowned: item['isPreowned'] ?? false),
                    if (isReviewed) ...[
                      const SizedBox(width: 8),
                      const Icon(
                        Icons.check_circle,
                        size: 12,
                        color: Colors.amber,
                      ),
                      Text(
                        ' Reviewed',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.amber[800],
                        ),
                      ),
                    ],
                  ],
                ),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                enabled: !isReviewed,
                onTap: isReviewed
                    ? null
                    : () {
                        Navigator.pop(context);
                        _showItemReviewDialog(item, order['orderId'], items);
                      },
              );
            },
          ),
        ),
      ),
    );
  }

  Future<void> _showItemReviewDialog(
    Map<String, dynamic> item,
    String orderId,
    List<dynamic> allOrderItems,
  ) async {
    double rating = 5.0;
    final titleCtrl = TextEditingController();
    final textCtrl = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            'Review ${item['productName']}',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    5,
                    (index) => IconButton(
                      icon: Icon(
                        index < rating ? Icons.star : Icons.star_border,
                        color: Colors.amber,
                        size: 36,
                      ),
                      onPressed: () =>
                          setDialogState(() => rating = index + 1.0),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: titleCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Title',
                    border: OutlineInputBorder(),
                    floatingLabelStyle: TextStyle(color: _primaryColor),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: textCtrl,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Review',
                    border: OutlineInputBorder(),
                    floatingLabelStyle: TextStyle(color: _primaryColor),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Cancel',
                style: TextStyle(color: Colors.grey, fontSize: 15),
              ),
            ),
            CustomButton(
              text: 'Submit',
              onPressed: () async {
                if (titleCtrl.text.isEmpty) return;
                Navigator.pop(context);
                await _submitReview(
                  item,
                  orderId,
                  rating,
                  titleCtrl.text,
                  textCtrl.text,
                  allOrderItems,
                );
              },
              backgroundColor: _primaryColor,
              fontSize: 15,
              minimumSize: const Size(100, 40),
              borderRadius: 8,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submitReview(
    Map<String, dynamic> item,
    String orderId,
    double rating,
    String title,
    String text,
    List<dynamic> allOrderItems,
  ) async {
    try {
      await ReviewService.submitReview(
        userId: currentUser!.uid,
        orderId: orderId,
        item: item,
        rating: rating,
        title: title,
        text: text,
        allOrderItems: allOrderItems,
      );
      _loadAllData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Review Submitted!'),
            backgroundColor: _primaryColor,
          ),
        );
      }
    } catch (e) {
      debugPrint('Review Error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error submitting review'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // ============= UTILITIES =============

  String _formatDate(dynamic timestamp) {
    if (timestamp == null) return '';
    if (timestamp is Timestamp) {
      return DateFormat('MMM dd, yyyy').format(timestamp.toDate());
    }
    return timestamp.toString();
  }
}
