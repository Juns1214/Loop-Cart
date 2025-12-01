import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../utils/bar_chart.dart';
import '../../utils/router.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/services.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      initialRoute: "/sustainability-dashboard",
      onGenerateRoute: onGenerateRoute,
    );
  }
}

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  List<double> donationAmount = [0, 0, 0, 0, 0, 0];
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
    setState(() {
      isLoading = true;
    });

    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) {
        setState(() {
          isLoading = false;
        });
        return;
      }

      // Fetch user profile for green coins
      final userDoc = await _firestore.collection('user_profile').doc(userId).get();
      if (userDoc.exists) {
        setState(() {
          greenCoin = userDoc.data()?['greenCoins'] ?? 0;
        });
      }

      // Fetch donation records
      final donationsSnapshot = await _firestore
          .collection('donation_record')
          .where('userId', isEqualTo: userId)
          .get();

      Map<String, double> categoryTotals = {
        'Low Income': 0,
        'Orphanage': 0,
        'Old Folk': 0,
        'Cancer NGO': 0,
        'MMF': 0,
        'CETDEM': 0,
      };

      double total = 0;
      for (var doc in donationsSnapshot.docs) {
        final data = doc.data();
        final amount = (data['amount'] ?? 0).toDouble();
        final category = data['donationCategory'] ?? '';
        
        total += amount;
        
        // Map categories to chart labels
        if (category.toLowerCase().contains('orphanage')) {
          categoryTotals['Orphanage'] = (categoryTotals['Orphanage'] ?? 0) + amount;
        } else if (category.toLowerCase().contains('cancer')) {
          categoryTotals['Cancer NGO'] = (categoryTotals['Cancer NGO'] ?? 0) + amount;
        } else if (category.toLowerCase().contains('wildlife') || 
                   category.toLowerCase().contains('mmf')) {
          categoryTotals['MMF'] = (categoryTotals['MMF'] ?? 0) + amount;
        } else if (category.toLowerCase().contains('environment') || 
                   category.toLowerCase().contains('cetdem')) {
          categoryTotals['CETDEM'] = (categoryTotals['CETDEM'] ?? 0) + amount;
        } else if (category.toLowerCase().contains('old') || 
                   category.toLowerCase().contains('elderly') ||
                   category.toLowerCase().contains('folk')) {
          categoryTotals['Old Folk'] = (categoryTotals['Old Folk'] ?? 0) + amount;
        } else if (category.toLowerCase().contains('low income') ||
                   category.toLowerCase().contains('poverty')) {
          categoryTotals['Low Income'] = (categoryTotals['Low Income'] ?? 0) + amount;
        } else {
          // Default to Low Income if category doesn't match
          categoryTotals['Low Income'] = (categoryTotals['Low Income'] ?? 0) + amount;
        }
      }

      // Fetch recycling records
      final recyclingSnapshot = await _firestore
          .collection('recycling_record')
          .where('user_id', isEqualTo: userId)
          .get();

      // Fetch repair records
      final repairSnapshot = await _firestore
          .collection('repair_record')
          .where('user_id', isEqualTo: userId)
          .get();

      setState(() {
        donationAmount = [
          categoryTotals['Low Income']!,
          categoryTotals['Orphanage']!,
          categoryTotals['Old Folk']!,
          categoryTotals['Cancer NGO']!,
          categoryTotals['MMF']!,
          categoryTotals['CETDEM']!,
        ];
        totalDonation = total;
        recycleAmount = recyclingSnapshot.docs.length;
        repairCount = repairSnapshot.docs.length;
        isLoading = false;
      });
    } catch (e) {
      print('Error loading dashboard data: $e');
      setState(() {
        isLoading = false;
      });
      // Show error snackbar
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading data: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFFD6F7C3),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1B5E20)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Sustainability Dashboard',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFF1B5E20),
          ),
        ),
        centerTitle: true,
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF22C55E),
              ),
            )
          : RefreshIndicator(
              onRefresh: _loadDashboardData,
              color: const Color(0xFF22C55E),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  children: [
                    // Header Section with gradient
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFD6F7C3), Color(0xFFBBF7D0)],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                        borderRadius: const BorderRadius.only(
                          bottomLeft: Radius.circular(30),
                          bottomRight: Radius.circular(30),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.green.withOpacity(0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.fromLTRB(20, 10, 20, 30),
                      child: Column(
                        children: [
                          const Icon(
                            Icons.eco,
                            color: Color(0xFF1B5E20),
                            size: 40,
                          ),
                          const SizedBox(height: 10),
                          const Text(
                            "Track your sustainability impact and discover how your choices help create a greener, cleaner world.",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 15,
                              color: Color(0xFF1B5E20),
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Quick Stats Cards
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        children: [
                          Expanded(
                            child: _buildStatCard(
                              icon: Icons.recycling,
                              title: 'Items Recycled',
                              value: recycleAmount.toString(),
                              color: const Color(0xFF10B981),
                              iconColor: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildStatCard(
                              icon: Icons.build,
                              title: 'Items Repaired',
                              value: repairCount.toString(),
                              color: const Color(0xFF3B82F6),
                              iconColor: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Green Coin Balance - Enhanced Design
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 20),
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF22C55E), Color(0xFF16A34A)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF22C55E).withOpacity(0.4),
                            blurRadius: 15,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.monetization_on,
                              color: Colors.white,
                              size: 35,
                            ),
                          ),
                          const SizedBox(width: 20),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  "Green Coin Balance",
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 5),
                                Text(
                                  "$greenCoin Coins",
                                  style: const TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            Icons.arrow_forward_ios,
                            color: Colors.white.withOpacity(0.7),
                            size: 20,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 30),

                    // Donation Chart Section - Enhanced
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 20),
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Donation Breakdown",
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF1B5E20),
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    "by Category",
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF0FDF4),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: const Color(0xFFBBF7D0),
                                  ),
                                ),
                                child: Text(
                                  "RM ${totalDonation.toStringAsFixed(2)}",
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF166534),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          SizedBox(
                            height: 300,
                            child: MyBarGraph(donationAmount: donationAmount),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 30),

                    // Sustainability Metrics Section - Enhanced
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 20),
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            const Color(0xFFF0FDF4),
                            Colors.white,
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: const Color(0xFFBBF7D0),
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.green.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF22C55E),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(
                                  Icons.trending_up,
                                  color: Colors.white,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 12),
                              const Text(
                                "Sustainability Goals",
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1B5E20),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),

                          _buildGoalProgress(
                            title: "Recycling Goal",
                            current: recycleAmount,
                            target: 50,
                            unit: "items",
                            icon: Icons.recycling,
                            color: const Color(0xFF10B981),
                          ),

                          const SizedBox(height: 20),

                          _buildGoalProgress(
                            title: "Repair Goal",
                            current: repairCount,
                            target: 20,
                            unit: "items",
                            icon: Icons.build_circle,
                            color: const Color(0xFF3B82F6),
                          ),

                          const SizedBox(height: 20),

                          _buildGoalProgress(
                            title: "Donation Goal",
                            current: totalDonation,
                            target: 2000,
                            unit: "RM",
                            icon: Icons.volunteer_activism,
                            color: const Color(0xFFF59E0B),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
    required Color iconColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: iconColor, size: 32),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.white.withOpacity(0.9),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGoalProgress({
    required String title,
    required num current,
    required num target,
    required String unit,
    required IconData icon,
    required Color color,
  }) {
    final progress = (current / target).clamp(0.0, 1.0);
    final isCompleted = current >= target;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1B5E20),
              ),
            ),
            const Spacer(),
            if (isCompleted)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.check, color: Colors.white, size: 14),
                    SizedBox(width: 4),
                    Text(
                      'Completed',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Text(
              unit == "RM" 
                ? "$unit ${current is double ? current.toStringAsFixed(2) : current}" 
                : "$current $unit",
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: isCompleted ? const Color(0xFF10B981) : color,
              ),
            ),
            Text(
              " / ${unit == "RM" ? "$unit $target" : "$target $unit"}",
              style: const TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 8,
            backgroundColor: Colors.grey[200],
            valueColor: AlwaysStoppedAnimation<Color>(
              isCompleted ? const Color(0xFF10B981) : color,
            ),
          ),
        ),
      ],
    );
  }
}