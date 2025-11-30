import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_application_1/utils/swiper.dart';
import 'package:firebase_core/firebase_core.dart';
import 'product.dart';
import 'package:flutter_application_1/utils/bottom_nav_bar.dart';
import '../../utils/router.dart';
import '../preference/preference_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
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

  // Firebase data
  List<Map<String, dynamic>> productData = [];
  List<Map<String, dynamic>> recommendedProducts = [];
  List<Map<String, dynamic>> gridProducts = [];
  List<Map<String, dynamic>> filteredProductData = [];
  bool isLoading = true;
  String searchQuery = '';
  String selectedFilter = 'All';
  bool showAllProducts = false; // Track if "See All" was clicked
  bool isAscending = true; // Track sort order

  final PreferenceService _preferenceService = PreferenceService();
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initializeBanners();
    _loadProducts();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _initializeBanners() {
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

  // Load products from Firebase with user preference filtering
  Future<void> _loadProducts() async {
    setState(() {
      isLoading = true;
      showAllProducts = false;
      searchQuery = '';
      _searchController.clear();
    });

    try {
      // Get filtered products based on user preferences
      List<Map<String, dynamic>> products = await _preferenceService
          .getFilteredProducts();

      // Shuffle products first
      List<Map<String, dynamic>> shuffledProducts = List.from(products)
        ..shuffle();

      // Split products: first 10 for recommended, rest for grid
      int recommendedCount = shuffledProducts.length > 10
          ? 10
          : shuffledProducts.length;

      setState(() {
        productData = products;
        recommendedProducts = shuffledProducts.take(recommendedCount).toList();
        gridProducts = shuffledProducts.skip(recommendedCount).toList();
        filteredProductData = shuffledProducts.skip(recommendedCount).toList();
        isLoading = false;
      });

      print(
        'Loaded ${products.length} products (${recommendedProducts.length} recommended, ${gridProducts.length} in grid)',
      );
    } catch (e) {
      print('Error loading products: $e');
      setState(() {
        isLoading = false;
      });

      // Show error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading products. Please try again.'),
            backgroundColor: Colors.red,
            action: SnackBarAction(
              label: 'Retry',
              textColor: Colors.white,
              onPressed: _loadProducts,
            ),
          ),
        );
      }
    }
  }

  // Filter products based on search and selected filter
  void _runFilter(String enteredKeyword) {
    setState(() {
      searchQuery = enteredKeyword;
      if (enteredKeyword.isEmpty) {
        showAllProducts = false;
        filteredProductData = gridProducts;
      } else {
        showAllProducts = true;
        _applyFilters();
      }
    });
  }

  void _applyFilters() {
    List<Map<String, dynamic>> results = productData;

    // Apply search filter
    if (searchQuery.isNotEmpty) {
      results = results.where((product) {
        String name = (product['name'] ?? '').toLowerCase();
        String category = (product['category'] ?? '').toLowerCase();
        return name.contains(searchQuery.toLowerCase()) ||
            category.contains(searchQuery.toLowerCase());
      }).toList();
    }

    // Apply sorting based on selected filter
    if (selectedFilter != 'All') {
      if (selectedFilter == 'Price') {
        results.sort((a, b) {
          int comparison = (a['price'] ?? 0).compareTo(b['price'] ?? 0);
          return isAscending ? comparison : -comparison;
        });
      } else if (selectedFilter == 'Rating') {
        results.sort((a, b) {
          int comparison = (a['rating'] ?? 0).compareTo(b['rating'] ?? 0);
          return isAscending ? comparison : -comparison;
        });
      } else if (selectedFilter == 'Best Value') {
        results.sort((a, b) {
          double valueA =
              (a['rating'] ?? 0) /
              ((a['price'] ?? 1) == 0 ? 1 : (a['price'] ?? 1));
          double valueB =
              (b['rating'] ?? 0) /
              ((b['price'] ?? 1) == 0 ? 1 : (b['price'] ?? 1));
          int comparison = valueA.compareTo(valueB);
          return isAscending ? comparison : -comparison;
        });
      }
    }

    setState(() {
      filteredProductData = results;
    });
  }

  void _handleNavigation(int index) {
    setState(() {
      _currentIndex = index;
    });

    switch (index) {
      case 0: // Repair Service
        Navigator.pushNamed(context, '/repair-service');
        break;
      case 1: // Recycle
        Navigator.pushNamed(context, '/recycling-pickup');
        break;
      case 2: // Sell
        Navigator.pushNamed(context, '/sell-second-hand-product');
        break;
      case 3: // Analytics Dashboard
        Navigator.pushNamed(context, '/sustainability-dashboard');
        break;
      case 4: // User Profile
        Navigator.pushNamed(context, '/user-profile');
        break;
    }
  }

  void _showAllProducts() {
    setState(() {
      showAllProducts = true;
      filteredProductData = productData;
    });
  }

  void _clearSearch() {
    setState(() {
      searchQuery = '';
      showAllProducts = false;
      _searchController.clear();
      filteredProductData = gridProducts;
      selectedFilter = 'All';
      isAscending = true;
    });
  }

  void _toggleSortOrder() {
    setState(() {
      isAscending = !isAscending;
      _applyFilters();
    });
  }

  Widget filterButton(String text, {bool isSelected = false}) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ElevatedButton(
        onPressed: () {
          setState(() {
            selectedFilter = text;
            _applyFilters();
          });
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: isSelected ? Color(0xFF388E3C) : Colors.white,
          foregroundColor: isSelected ? Colors.white : Colors.black87,
          elevation: 0,
          side: BorderSide(color: Colors.grey.shade300),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        ),
        child: Text(text, style: TextStyle(fontSize: 13)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(color: Colors.white),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundImage: AssetImage(
                      'assets/images/icon/LogoIcon.png',
                    ),
                  ),
                  SizedBox(width: 16),
                  Text(
                    'Loop Cart',
                    style: TextStyle(
                      fontFamily: 'Manrope',
                      color: Color(0xFF388E3C),
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            ExpansionTile(
              title: Text('Shop'),
              leading: Image.asset(
                'assets/images/icon/shopicon.png',
                fit: BoxFit.fill,
                width: 50,
                height: 50,
              ),
              children: [
                Divider(),
                ListTile(
                  contentPadding: EdgeInsets.symmetric(horizontal: 32),
                  title: Text('Explore'),
                  onTap: () {
                    Navigator.pop(context);
                    _loadProducts();
                  },
                ),
                Divider(),
                ListTile(
                  contentPadding: EdgeInsets.symmetric(horizontal: 32),
                  title: Text('Second Hand Items'),
                  onTap: () => Navigator.pop(context),
                ),
              ],
            ),

            ExpansionTile(
              title: Text('Service'),
              leading: Image.asset(
                'assets/images/icon/serviceicon.png',
                fit: BoxFit.fill,
                width: 50,
                height: 50,
              ),
              children: [
                Divider(),
                ListTile(
                  contentPadding: EdgeInsets.symmetric(horizontal: 32),
                  title: Text('Repair Service'),
                  onTap: () {
                    Navigator.pop(context);
                    _handleNavigation(0);
                  },
                ),
                Divider(),
                ListTile(
                  contentPadding: EdgeInsets.symmetric(horizontal: 32),
                  title: Text('Schedule Recycling Pickup'),
                  onTap: () {
                    Navigator.pop(context);
                    _handleNavigation(1);
                  },
                ),
                Divider(),
                ListTile(
                  contentPadding: EdgeInsets.symmetric(horizontal: 32),
                  title: Text('Basket of Hope'),
                  onTap: () => Navigator.pop(context),
                ),
              ],
            ),

            ExpansionTile(
              title: Text('Sustainability & Impact'),
              leading: Image.asset(
                'assets/images/icon/SustainabilityIcon.png',
                fit: BoxFit.fill,
                width: 50,
                height: 50,
              ),
              children: [
                Divider(),
                ListTile(
                  contentPadding: EdgeInsets.symmetric(horizontal: 32),
                  title: Text('Green Coin'),
                  onTap: () {
                    Navigator.pop(context);
                  },
                ),
                Divider(),
                ListTile(
                  contentPadding: EdgeInsets.symmetric(horizontal: 32),
                  title: Text('Analytics Dashboard'),
                  onTap: () {
                    Navigator.pop(context);
                    _handleNavigation(3);
                  },
                ),
              ],
            ),

            ListTile(
              leading: Image.asset(
                'assets/images/icon/UserProfileIcon.png',
                fit: BoxFit.fill,
                width: 50,
                height: 50,
              ),
              title: Text('User Profile'),
              onTap: () {
                Navigator.pop(context);
                _handleNavigation(4);
              },
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: RefreshIndicator(
              onRefresh: _loadProducts,
              color: Color(0xFF388E3C),
              child: SingleChildScrollView(
                physics: AlwaysScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top bar
                    Container(
                      color: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
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
                                  icon: Icon(
                                    Icons.notifications_outlined,
                                    size: 28,
                                  ),
                                ),
                                IconButton(
                                  onPressed: () {
                                    Navigator.pushNamed(context, '/cart-items');
                                  },
                                  icon: Icon(
                                    Icons.shopping_cart_outlined,
                                    size: 28,
                                  ),
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
                                controller: _searchController,
                                onChanged: (value) => _runFilter(value),
                                onSubmitted: (value) {
                                  if (value.isNotEmpty) {
                                    _runFilter(value);
                                  }
                                },
                                decoration: InputDecoration(
                                  hintText: 'Search products...',
                                  hintStyle: TextStyle(
                                    color: Colors.grey.shade500,
                                  ),
                                  prefixIcon: Icon(
                                    Icons.search,
                                    color: Colors.grey.shade600,
                                  ),
                                  suffixIcon: searchQuery.isNotEmpty
                                      ? IconButton(
                                          icon: Icon(
                                            Icons.clear,
                                            color: Colors.grey.shade600,
                                          ),
                                          onPressed: _clearSearch,
                                        )
                                      : null,
                                  border: InputBorder.none,
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 12,
                                  ),
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
                              onPressed: () async {
                                // Navigate to category filter page
                                final result = await Navigator.pushNamed(
                                  context,
                                  '/category-filter',
                                );

                                // If filters were applied, update the product list
                                if (result != null &&
                                    result is Map<String, dynamic>) {
                                  if (result['filteredProducts'] != null) {
                                    setState(() {
                                      showAllProducts = true;
                                      filteredProductData =
                                          List<Map<String, dynamic>>.from(
                                            result['filteredProducts'],
                                          );
                                    });
                                  }
                                }
                              },
                              icon: Icon(
                                Icons.tune,
                                color: Colors.grey.shade700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Active search/filter indicator
                    if (searchQuery.isNotEmpty || showAllProducts)
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        color: Color(0xFF388E3C).withOpacity(0.1),
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
                                searchQuery.isNotEmpty
                                    ? 'Showing results for "$searchQuery"'
                                    : 'Showing all products',
                                style: TextStyle(
                                  fontFamily: 'Manrope',
                                  fontSize: 13,
                                  color: Color(0xFF388E3C),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            TextButton(
                              onPressed: _clearSearch,
                              style: TextButton.styleFrom(
                                padding: EdgeInsets.symmetric(horizontal: 8),
                                minimumSize: Size(0, 0),
                              ),
                              child: Text(
                                'Clear',
                                style: TextStyle(
                                  fontFamily: 'Manrope',
                                  fontSize: 12,
                                  color: Color(0xFF388E3C),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                    SizedBox(height: 8),

                    // Show banner only when not searching/filtering
                    if (!showAllProducts && searchQuery.isEmpty) ...[
                      // Banner swiper
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: SizedBox(
                          height: 160,
                          child: Swiper(pages: pages),
                        ),
                      ),

                      SizedBox(height: 20),

                      // Recommended section (only show when not searching)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Recommended for You',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            TextButton.icon(
                              onPressed: _showAllProducts,
                              icon: Text(
                                'See All',
                                style: TextStyle(
                                  color: Color(0xFF388E3C),
                                  fontSize: 14,
                                ),
                              ),
                              label: Icon(
                                Icons.arrow_forward_ios,
                                size: 14,
                                color: Color(0xFF388E3C),
                              ),
                            ),
                          ],
                        ),
                      ),

                      SizedBox(height: 8),

                      // Recommended horizontal list
                      isLoading
                          ? Center(
                              child: Padding(
                                padding: const EdgeInsets.all(40.0),
                                child: CircularProgressIndicator(
                                  color: Color(0xFF388E3C),
                                ),
                              ),
                            )
                          : recommendedProducts.isEmpty
                          ? Center(
                              child: Padding(
                                padding: const EdgeInsets.all(40.0),
                                child: Text(
                                  'No products available',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ),
                            )
                          : SizedBox(
                              height: 220,
                              child: ListView.builder(
                                scrollDirection: Axis.horizontal,
                                padding: EdgeInsets.symmetric(horizontal: 8),
                                itemCount: recommendedProducts.length,
                                itemBuilder: (context, index) {
                                  final product = recommendedProducts[index];
                                  return ProductCard(
                                    imageUrl:
                                        product['imageUrl'] ??
                                        product['image_url'] ??
                                        '',
                                    productName: product['name'] ?? 'Unknown',
                                    productPrice: (product['price'] ?? 0)
                                        .toDouble(),
                                    rating: (product['rating'] ?? 0).toDouble(),
                                    productData: product,
                                  );
                                },
                              ),
                            ),

                      SizedBox(height: 16),
                    ],

                    // Filter buttons
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: [
                          filterButton(
                            'All',
                            isSelected: selectedFilter == 'All',
                          ),
                          filterButton(
                            'Price',
                            isSelected: selectedFilter == 'Price',
                          ),
                          filterButton(
                            'Rating',
                            isSelected: selectedFilter == 'Rating',
                          ),

                          // Sort order toggle button
                          if (selectedFilter != 'All')
                            Padding(
                              padding: const EdgeInsets.only(left: 8),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Color(0xFF388E3C),
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Color(0xFF388E3C).withOpacity(0.3),
                                      blurRadius: 4,
                                      offset: Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: IconButton(
                                  onPressed: _toggleSortOrder,
                                  icon: Icon(
                                    isAscending
                                        ? Icons.arrow_upward
                                        : Icons.arrow_downward,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                  tooltip: isAscending
                                      ? 'Sort Ascending'
                                      : 'Sort Descending',
                                  padding: EdgeInsets.all(8),
                                  constraints: BoxConstraints(),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),

                    SizedBox(height: 16),

                    // Section title
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        showAllProducts || searchQuery.isNotEmpty
                            ? 'All Products (${filteredProductData.length})'
                            : 'More Products',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),

                    SizedBox(height: 12),

                    // Grid products
                    isLoading
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.all(40.0),
                              child: CircularProgressIndicator(
                                color: Color(0xFF388E3C),
                              ),
                            ),
                          )
                        : filteredProductData.isEmpty
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.all(40.0),
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.inventory_2_outlined,
                                    size: 60,
                                    color: Colors.grey,
                                  ),
                                  SizedBox(height: 16),
                                  Text(
                                    searchQuery.isEmpty
                                        ? 'No products available'
                                        : 'No products found',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.grey.shade600,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  if (searchQuery.isNotEmpty)
                                    TextButton(
                                      onPressed: _clearSearch,
                                      child: Text('Clear search'),
                                    ),
                                ],
                              ),
                            ),
                          )
                        : GridView.builder(
                            physics: NeverScrollableScrollPhysics(),
                            shrinkWrap: true,
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2,
                                  childAspectRatio: 0.75,
                                  crossAxisSpacing: 8,
                                  mainAxisSpacing: 8,
                                ),
                            itemCount: filteredProductData.length,
                            itemBuilder: (context, index) {
                              final product = filteredProductData[index];
                              return ProductGrid(
                                imageUrl:
                                    product['imageUrl'] ??
                                    product['image_url'] ??
                                    '',
                                productName: product['name'] ?? 'Unknown',
                                productPrice: (product['price'] ?? 0)
                                    .toDouble(),
                                rating: (product['rating'] ?? 0).toDouble(),
                                category: product['category'] ?? '',
                                productData: product,
                              );
                            },
                          ),

                    SizedBox(height: 80),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),

      // Floating Sell button
      floatingActionButton: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            colors: [Color(0xFF66BB6A), Color(0xFF388E3C)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          boxShadow: [
            BoxShadow(
              color: Color(0xFF388E3C).withOpacity(0.4),
              blurRadius: 12,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: FloatingActionButton(
          onPressed: () {
            _handleNavigation(2);
          },
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.add, size: 28),
              Text(
                'Sell',
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,

      // Bottom navigation
      bottomNavigationBar: BottomNavBar(
        currentIndex: _currentIndex,
        onTap: _handleNavigation,
      ),
    );
  }
}
