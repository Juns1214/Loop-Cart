import 'package:flutter/material.dart';
import '../../utils/bar_chart.dart';
import '../../utils/router.dart';

void main() {
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
  final List<double> donationAmount = [100, 200, 150, 300, 250, 400];
  int recycleAmount = 32;
  int repairCount = 12;
  int totalDonation = 1400;
  int greenCoin = 250;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFFD6F7C3),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1B5E20)),
          onPressed: () {
            Navigator.pop(context);
          },
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
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header Section
            Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                color: Color(0xFFD6F7C3),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
              ),
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 30),
              child: const Text(
                "Track your sustainability impact and discover how your choices help create a greener, cleaner world.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  color: Color(0xFF1B5E20),
                  height: 1.4,
                ),
              ),
            ),

            const SizedBox(height: 30),

            // Donation Chart Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  const Text(
                    "Donation Breakdown by Category",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1B5E20),
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    "Total: RM $totalDonation",
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Bar Chart
                  SizedBox(
                    height: 300,
                    child: MyBarGraph(donationAmount: donationAmount),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            // Green Coin Balance
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFFF0FDF4),
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: const Color(0xFFBBF7D0)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: const BoxDecoration(
                      color: Color(0xFF22C55E),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.eco,
                      color: Colors.white,
                      size: 30,
                    ),
                  ),
                  const SizedBox(width: 20),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Green Coin Balance",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF166534),
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        "$greenCoin Coins",
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF166534),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            // Sustainability Metrics Section - FIXED!
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFFF5F5F5),
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Sustainability Metrics",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1B5E20),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Recycling Goal - SEPARATE ROW
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Recycling Goal",
                        style: TextStyle(fontSize: 15),
                      ),
                      Text(
                        "$recycleAmount recycled",
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: recycleAmount >= 50
                              ? Colors.green
                              : const Color(0xFF1B5E20),
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 15),

                  // Repair Goal - SEPARATE ROW
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Repair Goal",
                        style: TextStyle(fontSize: 15),
                      ),
                      Text(
                        "$repairCount repaired",
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: repairCount >= 20  // ✅ FIXED: Check repairCount!
                              ? Colors.green
                              : const Color(0xFF1B5E20),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 15),

                  // Donation Goal - SEPARATE ROW
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Donation Goal",
                        style: TextStyle(fontSize: 15),
                      ),
                      Text(
                        "RM $totalDonation donated",  // ✅ FIXED: Use totalDonation!
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: totalDonation >= 2000
                              ? Colors.green
                              : const Color(0xFF1B5E20),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}