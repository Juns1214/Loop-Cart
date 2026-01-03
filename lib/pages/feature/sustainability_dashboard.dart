import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:share_plus/share_plus.dart';
import '../../utils/bar_chart.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});
  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  static const Color _primaryGreen = Color(0xFF2E7D32);

  static const List<_Category> _recyclingCategories = [
    _Category(name: 'Plastic', icon: Icons.water_drop_outlined, color: Color(0xFF4CAF50), coins: 15),
    _Category(name: 'Paper', icon: Icons.description_outlined, color: Color(0xFF8D6E63), coins: 10),
    _Category(name: 'Glass', icon: Icons.wine_bar_outlined, color: Color(0xFF00BCD4), coins: 20),
    _Category(name: 'Metal', icon: Icons.recycling, color: Color(0xFF9E9E9E), coins: 25),
    _Category(name: 'Electronics', icon: Icons.devices_outlined, color: Color(0xFFFF9800), coins: 30),
    _Category(name: 'Cardboard', icon: Icons.inventory_2_outlined, color: Color(0xFF795548), coins: 10),
  ];

  List<ChartData> chartData = [];
  Map<String, int> recyclingStats = {};
  List<Map<String, dynamic>> badges = [];
  int recycleAmount = 0;
  int repairCount = 0;
  double totalDonation = 0;
  int greenCoin = 0;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    setState(() => isLoading = true);
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return;

      final results = await Future.wait([
        FirebaseFirestore.instance.collection('user_profile').doc(userId).get(),
        FirebaseFirestore.instance.collection('donation_record').where('userId', isEqualTo: userId).get(),
        FirebaseFirestore.instance.collection('recycling_record').where('user_id', isEqualTo: userId).get(),
        FirebaseFirestore.instance.collection('repair_record').where('user_id', isEqualTo: userId).get(),
      ]);

      final userDoc = results[0] as DocumentSnapshot;
      final coins = (userDoc.data() as Map<String, dynamic>?)?['greenCoins'] ?? 0;

      final donationDocs = (results[1] as QuerySnapshot).docs;
      Map<String, double> tempTotals = {'Low Income': 0, 'Orphanage': 0, 'Old Folk': 0, 'Cancer NGO': 0, 'Wildlife': 0, 'Environment': 0};

      double totalDonated = 0;
      for (var doc in donationDocs) {
        final data = doc.data() as Map<String, dynamic>;
        final amount = (data['amount'] ?? 0).toDouble();
        final cat = (data['donationCategory'] ?? '').toString().toLowerCase();
        totalDonated += amount;

        if (cat.contains('orphanage')) {
          tempTotals['Orphanage'] = tempTotals['Orphanage']! + amount;
        } else if (cat.contains('cancer')) {
          tempTotals['Cancer NGO'] = tempTotals['Cancer NGO']! + amount;
        } else if (cat.contains('wildlife') || cat.contains('mmf')) {
          tempTotals['Wildlife'] = tempTotals['Wildlife']! + amount;
        } else if (cat.contains('environment') || cat.contains('cetdem')) {
          tempTotals['Environment'] = tempTotals['Environment']! + amount;
        } else if (cat.contains('old') || cat.contains('folk')) {
          tempTotals['Old Folk'] = tempTotals['Old Folk']! + amount;
        } else {
          tempTotals['Low Income'] = tempTotals['Low Income']! + amount;
        }
      }

      final recyclingDocs = (results[2] as QuerySnapshot).docs;
      Map<String, int> tempRecyclingStats = {};
      for (var cat in _recyclingCategories) {
        tempRecyclingStats[cat.name] = 0;
      }

      for (var doc in recyclingDocs) {
        final category = (doc.data() as Map<String, dynamic>)['item_category'] as String?;
        if (category != null && tempRecyclingStats.containsKey(category)) {
          tempRecyclingStats[category] = tempRecyclingStats[category]! + 1;
        }
      }

      final recycled = recyclingDocs.length;
      final repaired = (results[3] as QuerySnapshot).size;

      _calculateBadges(recycled, repaired, totalDonated);

      if (mounted) {
        setState(() {
          greenCoin = coins;
          recycleAmount = recycled;
          repairCount = repaired;
          totalDonation = totalDonated;
          recyclingStats = tempRecyclingStats;
          chartData = tempTotals.entries.map((e) => ChartData(e.key, e.value)).toList();
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => isLoading = false);
    }
  }

  void _calculateBadges(int recycled, int repaired, double donated) {
    badges = [
      {'name': 'Green Starter', 'icon': Icons.eco, 'color': Colors.lightGreen, 'unlocked': recycled >= 1, 'desc': 'Recycle your first item'},
      {'name': 'Earth Guardian', 'icon': Icons.public, 'color': Colors.blue, 'unlocked': recycled >= 10 && repaired >= 5, 'desc': 'Recycle 10 items & Repair 5 items'},
      {'name': 'Generous Heart', 'icon': Icons.favorite, 'color': Colors.redAccent, 'unlocked': donated >= 100, 'desc': 'Donate over RM 100'},
      {'name': 'Sustainability Hero', 'icon': Icons.workspace_premium, 'color': Colors.amber, 'unlocked': donated >= 500 && recycled >= 50, 'desc': 'Donate RM 500 & Recycle 50 items'},
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: const Color(0xFFE8F5E9),
        elevation: 0,
        leading: const BackButton(color: _primaryGreen),
        title: const Text('Impact Dashboard', style: TextStyle(fontFamily: 'Roboto', fontSize: 20, fontWeight: FontWeight.w800, color: _primaryGreen)),
        centerTitle: true,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: _primaryGreen))
          : RefreshIndicator(
              color: _primaryGreen,
              onRefresh: _loadDashboardData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.only(bottom: 30),
                child: Column(
                  children: [
                    _buildSummaryHeader(),
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(child: _StatCard(icon: Icons.recycling, label: "Recycled", value: "$recycleAmount", color: _primaryGreen)),
                              const SizedBox(width: 12),
                              Expanded(child: _StatCard(icon: Icons.build_circle_outlined, label: "Repaired", value: "$repairCount", color: Colors.blue)),
                            ],
                          ),
                          const SizedBox(height: 24),
                          _buildSectionHeader('Recycling Breakdown', 'Items recycled by category'),
                          _buildRecyclingBreakdown(),
                          const SizedBox(height: 24),
                          _buildSectionHeader('Donation Overview', 'Where your contributions are going'),
                          _buildDonationChart(),
                          const SizedBox(height: 24),
                          _buildSectionHeader('Achievements', 'Unlock badges by reaching milestones'),
                          _buildAchievements(),
                          const SizedBox(height: 24),
                          _buildSectionHeader('Monthly Goals', 'Track your progress targets'),
                          _buildGoals(),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildSectionHeader(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontFamily: 'Roboto', fontSize: 20, fontWeight: FontWeight.w800, color: Color(0xFF212121))),
        const SizedBox(height: 4),
        Text(subtitle, style: const TextStyle(fontFamily: 'Roboto', fontSize: 15, fontWeight: FontWeight.w500, color: Color(0xFF424242))),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildSummaryHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 30),
      decoration: const BoxDecoration(color: Color(0xFFE8F5E9), borderRadius: BorderRadius.only(bottomLeft: Radius.circular(30), bottomRight: Radius.circular(30))),
      child: Column(
        children: [
          const Text('Impact Balance', style: TextStyle(fontFamily: 'Roboto', fontSize: 18, fontWeight: FontWeight.w700, color: _primaryGreen)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(30), boxShadow: [BoxShadow(color: _primaryGreen.withOpacity(0.2), blurRadius: 8, offset: const Offset(0, 4))]),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset('assets/images/icon/Green Coin.png', width: 48, height: 48),
                const SizedBox(width: 12),
                Text('$greenCoin Green Coins', style: const TextStyle(fontFamily: 'Roboto', fontSize: 24, fontWeight: FontWeight.w800, color: _primaryGreen)),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Text('Every action counts towards a greener future', textAlign: TextAlign.center, style: TextStyle(fontFamily: 'Roboto', fontSize: 15, fontWeight: FontWeight.w600, color: _primaryGreen)),
        ],
      ),
    );
  }

  Widget _buildRecyclingBreakdown() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)]),
      child: Column(
        children: _recyclingCategories.map((category) {
          final count = recyclingStats[category.name] ?? 0;
          final totalCoins = count * category.coins;
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Row(
              children: [
                Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: category.color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)), child: Icon(category.icon, color: category.color, size: 24)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(category.name, style: const TextStyle(fontFamily: 'Roboto', fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF212121))),
                          Text('$count items', style: TextStyle(fontFamily: 'Roboto', fontSize: 14, fontWeight: FontWeight.w700, color: category.color)),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('${category.coins} coins each', style: const TextStyle(fontFamily: 'Roboto', fontSize: 13, fontWeight: FontWeight.w500, color: Color(0xFF424242))),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(color: _primaryGreen.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                            child: Row(mainAxisSize: MainAxisSize.min, children: [const Icon(Icons.eco, size: 12, color: _primaryGreen), const SizedBox(width: 4), Text('$totalCoins', style: const TextStyle(fontFamily: 'Roboto', fontSize: 12, fontWeight: FontWeight.w700, color: _primaryGreen))]),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildDonationChart() {
    return Container(
      height: 320,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)]),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Total: RM ${totalDonation.toStringAsFixed(0)}', style: const TextStyle(fontFamily: 'Roboto', fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF212121))),
              const Icon(Icons.bar_chart, color: Color(0xFF424242)),
            ],
          ),
          const SizedBox(height: 20),
          Expanded(child: SustainabilityBarChart(data: chartData)),
        ],
      ),
    );
  }

  Widget _buildAchievements() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)]),
      child: Column(
        children: [
          SizedBox(
            height: 140,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: badges.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (context, index) => _BadgeCard(badge: badges[index]),
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                final unlockedBadges = badges.where((b) => b['unlocked'] == true).map((b) => b['name']).join(', ');
                if (unlockedBadges.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Unlock badges to share your achievements!', style: TextStyle(fontFamily: 'Roboto', fontWeight: FontWeight.w600))));
                } else {
                  Share.share('I unlocked these badges: $unlockedBadges on the Sustainability App! 🌍✨ #GoGreen');
                }
              },
              icon: const Icon(Icons.share, size: 20),
              label: const Text('Share Achievements', style: TextStyle(fontFamily: 'Roboto', fontSize: 15, fontWeight: FontWeight.w700)),
              style: ElevatedButton.styleFrom(backgroundColor: _primaryGreen, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGoals() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFE0E0E0))),
      child: Column(
        children: [
          _GoalRow(icon: Icons.recycling, color: _primaryGreen, title: 'Recycle 50 Items', current: recycleAmount, target: 50),
          const Divider(height: 30),
          _GoalRow(icon: Icons.volunteer_activism, color: Colors.orange, title: 'Donate RM 2,000', current: totalDonation.toInt(), target: 2000, isCurrency: true),
        ],
      ),
    );
  }
}

class _Category {
  final String name;
  final IconData icon;
  final Color color;
  final int coins;
  const _Category({required this.name, required this.icon, required this.color, required this.coins});
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatCard({required this.icon, required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: color.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 4))], border: Border.all(color: color.withOpacity(0.1))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle), child: Icon(icon, color: color, size: 24)),
          const SizedBox(height: 12),
          Text(value, style: const TextStyle(fontFamily: 'Roboto', fontSize: 22, fontWeight: FontWeight.w800, color: Color(0xFF212121))),
          Text(label, style: const TextStyle(fontFamily: 'Roboto', fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF424242))),
        ],
      ),
    );
  }
}

class _BadgeCard extends StatelessWidget {
  final Map<String, dynamic> badge;

  const _BadgeCard({required this.badge});

  @override
  Widget build(BuildContext context) {
    final bool unlocked = badge['unlocked'];
    return GestureDetector(
      onTap: () {
        if (!unlocked) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Locked: ${badge['desc']}', style: const TextStyle(fontFamily: 'Roboto', fontWeight: FontWeight.w600)), duration: const Duration(seconds: 2)));
        }
      },
      child: Container(
        width: 110,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: unlocked ? Colors.white : const Color(0xFFF5F5F5), borderRadius: BorderRadius.circular(16), border: Border.all(color: unlocked ? badge['color'] : const Color(0xFFE0E0E0), width: unlocked ? 2 : 1)),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(badge['icon'], color: unlocked ? badge['color'] : const Color(0xFF9E9E9E), size: 36),
            const SizedBox(height: 10),
            Text(badge['name'], textAlign: TextAlign.center, maxLines: 2, style: TextStyle(fontFamily: 'Roboto', fontSize: 12, fontWeight: FontWeight.w700, color: unlocked ? const Color(0xFF212121) : const Color(0xFF9E9E9E))),
          ],
        ),
      ),
    );
  }
}

class _GoalRow extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final int current;
  final int target;
  final bool isCurrency;

  const _GoalRow({required this.icon, required this.color, required this.title, required this.current, required this.target, this.isCurrency = false});

  @override
  Widget build(BuildContext context) {
    final double progress = (current / target).clamp(0.0, 1.0);
    final String currentStr = isCurrency ? 'RM $current' : '$current';
    final String targetStr = isCurrency ? 'RM $target' : '$target';

    return Row(
      children: [
        Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)), child: Icon(icon, color: color, size: 20)),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(title, style: const TextStyle(fontFamily: 'Roboto', fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF212121))),
                  Text('$currentStr / $targetStr', style: const TextStyle(fontFamily: 'Roboto', fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF424242))),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(borderRadius: BorderRadius.circular(4), child: LinearProgressIndicator(value: progress, backgroundColor: const Color(0xFFE0E0E0), valueColor: AlwaysStoppedAnimation(color), minHeight: 6)),
            ],
          ),
        ),
      ],
    );
  }
}