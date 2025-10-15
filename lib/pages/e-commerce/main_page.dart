import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_application_1/utils/swiper.dart';
import 'product.dart';
import 'package:flutter_application_1/utils/bottom_nav_bar.dart';
import '../../utils/router.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      initialRoute: "/mainpage",
      onGenerateRoute: onGenerateRoute,
      home: const MainPage(),
    );
  }
}

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _currentIndex = 0;

  List<Widget> pages = [];
  
  List<Map<String, dynamic>> productData = [
    {
      'imageUrl': 'assets/images/icon/Green Coin.png',
      'productName': 'Green Coin',
      'productPrice': 79.99,
      'bestValue': 4.2,
    },
    {
      'imageUrl': 'assets/images/icon/Green Coin.png',
      'productName': 'Red Coin',
      'productPrice': 59.99,
      'bestValue': 3.8,
    },
    {
      'imageUrl': 'assets/images/icon/Green Coin.png',
      'productName': 'Blue Coin',
      'productPrice': 49.99,
      'bestValue': 4.5,
    },
    {
      'imageUrl': 'assets/images/icon/Green Coin.png',
      'productName': 'Yellow Coin',
      'productPrice': 39.99,
      'bestValue': 3.7,
    },
  ];

  @override
  void initState() {
    super.initState();
    pages = [
      Center(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.asset(
            'assets/images/banner/Main_Banner_1.jpg',
            width: double.infinity,
            height: 160,
            fit: BoxFit.cover,
          ),
        ),
      ),
      Center(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.asset(
            'assets/images/banner/Main_Banner_4.jpg',
            width: double.infinity,
            height: 160,
            fit: BoxFit.cover,
          ),
        ),
      ),
      Center(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.asset(
            'assets/images/banner/Main_Banner_2.jpg',
            width: double.infinity,
            height: 160,
            fit: BoxFit.cover,
          ),
        ),
      ),
      Center(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.asset(
            'assets/images/banner/Main_Banner_3.jpg',
            width: double.infinity,
            height: 160,
            fit: BoxFit.cover,
          ),
        ),
      ),
    ];
  }

  void _runFilter(String enteredKeyword) {
    // Implement search filter logic
  }

  Widget filterButton(String text, {bool isSelected = false}) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ElevatedButton(
        onPressed: () {
          // Handle filter selection
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: isSelected ? Colors.green : Colors.white,
          foregroundColor: isSelected ? Colors.white : Colors.black87,
          elevation: 0,
          side: BorderSide(color: Colors.grey.shade300),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        ),
        child: Text(
          text,
          style: TextStyle(fontSize: 13),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(color: Colors.green),
              child: Text(
                'Menu',
                style: TextStyle(color: Colors.white, fontSize: 24),
              ),
            ),
            ListTile(
              leading: Icon(Icons.home),
              title: Text('Home'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: Icon(Icons.person),
              title: Text('Profile'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: Icon(Icons.settings),
              title: Text('Settings'),
              onTap: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top bar
                  Container(
                    color: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: SafeArea(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Builder(
                            builder: (context) => IconButton(
                              icon: Icon(Icons.menu, size: 28),
                              onPressed: () {
                                Scaffold.of(context).openDrawer();
                              },
                            ),
                          ),
                          Row(
                            children: [
                              IconButton(
                                onPressed: () {},
                                icon: Icon(Icons.notifications_outlined, size: 28),
                              ),
                              IconButton(
                                onPressed: () {},
                                icon: Icon(Icons.shopping_cart_outlined, size: 28),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Search bar
                  Container(
                    color: Colors.white,
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: Row(
                      children: [
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: TextField(
                              onChanged: (value) => _runFilter(value),
                              decoration: InputDecoration(
                                hintText: 'Search here',
                                hintStyle: TextStyle(color: Colors.grey.shade500),
                                prefixIcon: Icon(Icons.search, color: Colors.grey.shade600),
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: 8),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: IconButton(
                            onPressed: () {},
                            icon: Icon(Icons.tune, color: Colors.grey.shade700),
                          ),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: 8),

                  // Banner swiper
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: SizedBox(
                      height: 160,
                      child: Swiper(pages: pages),
                    ),
                  ),

                  SizedBox(height: 20),

                  // Most Popular section with See All
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Most Popular',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        TextButton.icon(
                          onPressed: () {},
                          icon: Text(
                            'See All',
                            style: TextStyle(
                              color: Colors.blue,
                              fontSize: 14,
                            ),
                          ),
                          label: Icon(
                            Icons.arrow_forward_ios,
                            size: 14,
                            color: Colors.blue,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  SizedBox(height: 8),

                  // Popular Products horizontal list
                  SizedBox(
                    height: 200,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: EdgeInsets.symmetric(horizontal: 8),
                      itemCount: productData.length,
                      itemBuilder: (context, index) => ProductCard(
                        imageUrl: productData[index]['imageUrl'],
                        productName: productData[index]['productName'],
                        productPrice: productData[index]['productPrice'],
                        bestValue: productData[index]['bestValue'],
                      ),
                    ),
                  ),

                  SizedBox(height: 16),

                  // Filter buttons horizontal scroll
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        filterButton('All'),
                        filterButton('Price'),
                        filterButton('Rating', isSelected: true),
                        filterButton('Best Value Comparison'),
                      ],
                    ),
                  ),

                  SizedBox(height: 16),

                  // Grid products
                  GridView.builder(
                    physics: NeverScrollableScrollPhysics(),
                    shrinkWrap: true,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.75,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                    ),
                    itemCount: productData.length,
                    itemBuilder: (context, index) => ProductGrid(
                      imageUrl: productData[index]['imageUrl'],
                      productName: productData[index]['productName'],
                      productPrice: productData[index]['productPrice'],
                      bestValue: productData[index]['bestValue'],
                    ),
                  ),

                  SizedBox(height: 100), // space for bottom nav
                ],
              ),
            ),
          ),
        ],
      ),

      // Floating Sell button
      floatingActionButton: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            colors: [Colors.green.shade400, Colors.green.shade600],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.green.withOpacity(0.3),
              blurRadius: 8,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: FloatingActionButton(
          onPressed: () {
            setState(() {
              _currentIndex = 2; // Sell tab
            });
          },
          child: Icon(Icons.add, size: 32),
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,

      // Bottom navigation
      bottomNavigationBar: BottomNavBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
      ),
    );
  }
}