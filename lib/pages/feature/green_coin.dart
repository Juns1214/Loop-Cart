import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class GreenCoinPage extends StatefulWidget {
  const GreenCoinPage({super.key});

  @override
  State<GreenCoinPage> createState() => _GreenCoinPageState();
}

class _GreenCoinPageState extends State<GreenCoinPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool isLoading = false;
  int greenCoin = 0;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    if (!mounted) return;
    setState(() => isLoading = true);
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return;

      final userDoc = await FirebaseFirestore.instance
          .collection('user_profile')
          .doc(userId)
          .get();

      if (userDoc.exists) {
        final data = userDoc.data() as Map<String, dynamic>;
        setState(() {
          greenCoin = data['greenCoins'] ?? 0;
        });
      }
    } catch (e) {
      debugPrint("Error loading data: $e");
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50], // Clean background
      appBar: AppBar(
        title: const Text(
          "Green Wallet",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFFD6F7C3),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF1B5E20)))
          : SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSummaryHeader(),
                  const SizedBox(height: 20),
                  
                  // --- Earn Section ---
                  _buildSectionTitle("How to Earn Green Coins"),
                  _buildEarnList(),
                  
                  const SizedBox(height: 20),

                  // --- Redeem Section ---
                  _buildSectionTitle("How to Redeem Green Coins"),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: ActionCard(
                      title: "E-commerce Discounts",
                      description: "Use GC for discounts (Max 50% off).",
                      rewardText: "1 GC = RM 0.10 OFF",
                      icon: Icons.shopping_bag_outlined,
                      buttonText: "Redeem",
                      isRedeem: true, // Special styling for redeem
                      onTap: () {
                        // TODO: Navigate to Shop
                      },
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
    );
  }

  Widget _buildSummaryHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 30),
      decoration: const BoxDecoration(
        color: Color(0xFFD6F7C3),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: Column(
        children: [
          const Text(
            "Impact Balance",
            style: TextStyle(
              color: Color(0xFF1B5E20),
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF1B5E20),
              borderRadius: BorderRadius.circular(30),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF1B5E20).withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.monetization_on_rounded, // Rounded variant looks softer
                  color: Colors.yellowAccent,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Text(
                  "$greenCoin GC",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            "Every action counts towards a greener future.",
            textAlign: TextAlign.center,
            style: TextStyle(color: Color(0xFF2E7D32), fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Color(0xFF1B5E20),
        ),
      ),
    );
  }

  Widget _buildEarnList() {
    // List of actions data
    final actions = [
      {
        'title': 'Daily Quiz',
        'desc': 'Test your eco-knowledge daily.',
        'reward': 'Earn 5 GC',
        'icon': Icons.quiz_outlined,
      },
      {
        'title': 'Recycling Pickup',
        'desc': 'Schedule a pickup for recyclables.',
        'reward': 'Varies by Category',
        'icon': Icons.recycling_outlined,
      },
      {
        'title': 'Repair Service',
        'desc': 'Fix instead of replace.',
        'reward': 'RM 1 = 1 GC',
        'icon': Icons.build_circle_outlined,
      },
      {
        'title': 'Donation',
        'desc': 'Support eco-friendly causes.',
        'reward': 'RM 1 = 1 GC',
        'icon': Icons.volunteer_activism_outlined,
      },
      {
        'title': 'Share Product',
        'desc': 'Spread the word on social media.',
        'reward': '5 GC per Share',
        'icon': Icons.share_outlined,
      },
      {
        'title': 'Buy Pre-owned',
        'desc': 'Give items a second life.',
        'reward': '1 GC per RM 1 Spent',
        'icon': Icons.shopping_cart_checkout,
      },
      {
        'title': 'Sell Second-hand',
        'desc': 'Extend product lifecycles.',
        'reward': '1 GC per RM 1 Earned',
        'icon': Icons.storefront_outlined,
      },
    ];

    return ListView.separated(
      physics: const NeverScrollableScrollPhysics(), // Disable internal scroll
      shrinkWrap: true, // Take only needed space
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: actions.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final item = actions[index];
        return ActionCard(
          title: item['title'] as String,
          description: item['desc'] as String,
          rewardText: item['reward'] as String,
          icon: item['icon'] as IconData,
          buttonText: "Earn Now",
          onTap: () {
            // TODO: Navigate to respective feature
          },
        );
      },
    );
  }
}

// --- REUSABLE WIDGET ---

class ActionCard extends StatelessWidget {
  final String title;
  final String description;
  final String rewardText;
  final IconData icon;
  final String buttonText;
  final VoidCallback onTap;
  final bool isRedeem;

  const ActionCard({
    super.key,
    required this.title,
    required this.description,
    required this.rewardText,
    required this.icon,
    required this.buttonText,
    required this.onTap,
    this.isRedeem = false,
  });

  @override
  Widget build(BuildContext context) {
    // Styling variables based on Type (Earn vs Redeem)
    final bgColor = isRedeem ? const Color(0xFFFFF3E0) : const Color(0xFFE8F5E9); // Orange tint for redeem, Green for earn
    final iconColor = isRedeem ? Colors.orange[800] : const Color(0xFF2E7D32);
    final btnColor = isRedeem ? Colors.orange[700] : const Color(0xFF1B5E20);

    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Icon / Image Placeholder
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: iconColor!.withOpacity(0.2)),
                  ),
                  child: Icon(icon, color: iconColor, size: 28),
                ),
                const SizedBox(width: 16),

                // 2. Texts
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        description,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[700],
                          height: 1.3,
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Reward Badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.6),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: iconColor.withOpacity(0.3)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.monetization_on, size: 14, color: Colors.amber[700]),
                            const SizedBox(width: 4),
                            Text(
                              rewardText,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // 3. Button
                Align(
                  alignment: Alignment.bottomRight,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 20.0), // Push button down slightly
                    child: SizedBox(
                      height: 32,
                      child: ElevatedButton(
                        onPressed: onTap,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: btnColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                        child: Text(
                          buttonText,
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}