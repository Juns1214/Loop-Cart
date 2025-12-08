import 'package:flutter/material.dart';

// ============= TAB BODY =============

class ActivityTabBody<T> extends StatelessWidget {
  final bool isLoading;
  final List<T> data;
  final Future<void> Function() onRefresh;
  final Widget Function(T item) itemBuilder;
  final String emptyTitle;
  final String emptySubtitle;
  final IconData emptyIcon;
  final String itemCountLabel;

  const ActivityTabBody({
    super.key,
    required this.isLoading,
    required this.data,
    required this.onRefresh,
    required this.itemBuilder,
    required this.emptyTitle,
    required this.emptySubtitle,
    required this.emptyIcon,
    this.itemCountLabel = 'Items',
  });

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty && !isLoading) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      color: const Color(0xFF388E3C),
      onRefresh: onRefresh,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: data.length + 1,
        itemBuilder: (context, index) {
          if (index == 0) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                '${data.length} ${data.length == 1 ? itemCountLabel : '${itemCountLabel}s'}',
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: Colors.black87,
                ),
              ),
            );
          }
          return itemBuilder(data[index - 1]);
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              shape: BoxShape.circle,
            ),
            child: Icon(emptyIcon, size: 60, color: Colors.grey[500]),
          ),
          const SizedBox(height: 20),
          Text(
            emptyTitle,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            emptySubtitle,
            style: TextStyle(fontSize: 15, color: Colors.grey[700]),
          ),
        ],
      ),
    );
  }
}

// ============= STATUS BADGE =============

class StatusBadge extends StatelessWidget {
  final String status;
  final Color? colorOverride;

  const StatusBadge({super.key, required this.status, this.colorOverride});

  Color _getStatusColor() {
    if (colorOverride != null) return colorOverride!;
    
    final statusMap = {
      'Delivered': const Color(0xFF2E7D32),
      'Completed': const Color(0xFF2E7D32),
      'Active': const Color(0xFF2E7D32),
      'Out for Delivery': const Color(0xFFE65100),
      'Shipped': const Color(0xFFE65100),
      'Processing': const Color(0xFF1565C0),
      'Received': const Color(0xFF1565C0),
      'Draft': const Color(0xFFD84315),
      'Order Placed': const Color(0xFF424242),
    };
    
    return statusMap[status] ?? const Color(0xFF616161);
  }

  @override
  Widget build(BuildContext context) {
    final color = _getStatusColor();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

// ============= PRODUCT TYPE BADGE =============

class ProductTypeBadge extends StatelessWidget {
  final bool isPreowned;

  const ProductTypeBadge({super.key, required this.isPreowned});

  @override
  Widget build(BuildContext context) {
    final color = isPreowned 
        ? const Color(0xFF1565C0)  // Darker blue
        : const Color(0xFF2E7D32);  // Darker green
        
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isPreowned) ...[
            Icon(Icons.recycling, size: 12, color: color),
            const SizedBox(width: 4),
          ],
          Text(
            isPreowned ? 'Pre-owned' : 'Regular',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

// ============= ACTIVITY CARD WRAPPER =============

class ActivityCardWrapper extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;

  const ActivityCardWrapper({super.key, required this.child, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200, width: 1.5),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: child,
        ),
      ),
    );
  }
}