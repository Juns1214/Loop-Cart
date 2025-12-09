import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_application_1/utils/swiper.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_application_1/utils/bottom_nav_bar.dart';
import '../../utils/router.dart';
import '../preference/preference_service.dart';
import '../../utils/cart_icon_with_badge.dart';

// NEW IMPORTS
import '../../widget/app_drawer.dart';
import '../../widget/filter_chip_button.dart';
import '../../widget/search_input.dart';
import '../../widget/universal_product_card.dart'; // Unified Widget

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
  List<Widget> bannerPages = [];
  List<Map<String, dynamic>> productData = [];
  List<Map<String, dynamic>> recommendedProducts = [];
  List<Map<String, dynamic>> gridProducts = [];
  List<Map<String, dynamic>> filteredProductData = [];
  
  bool isLoading = true;
  String searchQuery = '';
  String selectedFilter = 'All';
  bool showAllProducts = false; 
  bool isAscending = true; 

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
    final bannerImages = [
      'assets/images/banner/Main_Banner_1.jpg',
      'assets/images/banner/Main_Banner_4.jpg',
      'assets/images/banner/Main_Banner_2.jpg',
      'assets/images/banner/Main_Banner_3.jpg',
    ];
    bannerPages = bannerImages.map((img) => Center(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.asset(img, width: double.infinity, height: 160, fit: BoxFit.cover),
      ),
    )).toList();
  }

  Future<void> _loadProducts() async {
    setState(() {
      isLoading = true;
      showAllProducts = false;
      searchQuery = '';
      _searchController.clear();
    });

    try {
      List<Map<String, dynamic>> products = await _preferenceService.getFilteredProducts();
      List<Map<String, dynamic>> shuffled = List.from(products)..shuffle();
      int recCount = shuffled.length > 10 ? 10 : shuffled.length;

      setState(() {
        productData = products;
        recommendedProducts = shuffled.take(recCount).toList();
        gridProducts = shuffled.skip(recCount).toList();
        filteredProductData = gridProducts;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  void _runFilter(String keyword) {
    setState(() {
      searchQuery = keyword;
      if (keyword.isEmpty) {
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
    if (searchQuery.isNotEmpty) {
      results = results.where((p) => 
        (p['name'] ?? '').toLowerCase().contains(searchQuery.toLowerCase()) ||
        (p['category'] ?? '').toLowerCase().contains(searchQuery.toLowerCase())
      ).toList();
    }
    if (selectedFilter != 'All') {
       results.sort((a, b) {
        int compare = 0;
        if (selectedFilter == 'Price') compare = (a['price'] ?? 0).compareTo(b['price'] ?? 0);
        else if (selectedFilter == 'Rating') compare = (a['rating'] ?? 0).compareTo(b['rating'] ?? 0);
        return isAscending ? compare : -compare;
      });
    }
    setState(() => filteredProductData = results);
  }

  void _handleNavigation(int index) {
    setState(() => _currentIndex = index);
    final routes = {0: '/repair-service', 1: '/recycling-pickup', 2: '/sell-second-hand-product', 3: '/sustainability-dashboard', 4: '/chatbot', 5: '/user-profile'};
    if (routes.containsKey(index)) Navigator.pushNamed(context, routes[index]!);
  }

  void _clearSearch() {
    setState(() {
      searchQuery = '';
      showAllProducts = false;
      _searchController.clear();
      filteredProductData = gridProducts;
      selectedFilter = 'All';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      drawer: AppDrawer(onNavigate: _handleNavigation),
      body: Column(
        children: [
          Expanded(
            child: RefreshIndicator(
              onRefresh: _loadProducts,
              color: const Color(0xFF388E3C),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // --- HEADER ---
                    Container(
                      color: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: SafeArea(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Builder(builder: (c) => IconButton(icon: const Icon(Icons.menu, size: 28), onPressed: () => Scaffold.of(c).openDrawer())),
                            Row(
                              children: [
                                IconButton(onPressed: () {}, icon: const Icon(Icons.notifications_outlined, size: 28)),
                                const CartIconWithBadge(),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),

                    // --- SEARCH ---
                    Container(
                      color: Colors.white,
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      child: SearchInput(
                        controller: _searchController,
                        onChanged: _runFilter,
                        onClear: _clearSearch,
                        onFilterTap: () async {
                           final result = await Navigator.pushNamed(context, '/category-filter');
                           if (result is Map<String, dynamic> && result['filteredProducts'] != null) {
                             setState(() {
                               showAllProducts = true;
                               filteredProductData = List<Map<String, dynamic>>.from(result['filteredProducts']);
                             });
                           }
                        },
                      ),
                    ),

                    // --- INFO BANNER ---
                    if (searchQuery.isNotEmpty || showAllProducts)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        color: const Color(0xFF388E3C).withOpacity(0.1),
                        child: Row(
                          children: [
                            const Icon(Icons.info_outline, size: 16, color: Color(0xFF388E3C)),
                            const SizedBox(width: 8),
                            Expanded(child: Text(searchQuery.isNotEmpty ? 'Results for "$searchQuery"' : 'Showing all products', style: const TextStyle(fontSize: 13, color: Color(0xFF388E3C), fontWeight: FontWeight.bold))),
                            TextButton(onPressed: _clearSearch, child: const Text('Clear', style: TextStyle(fontSize: 12, color: Color(0xFF388E3C)))),
                          ],
                        ),
                      ),
                    const SizedBox(height: 8),

                    // --- RECOMMENDED (HORIZONTAL LIST) ---
                    if (!showAllProducts && searchQuery.isEmpty) ...[
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: SizedBox(height: 160, child: Swiper(pages: bannerPages)),
                      ),
                      const SizedBox(height: 20),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Recommended', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                            TextButton.icon(
                              onPressed: () => setState(() { showAllProducts = true; filteredProductData = productData; }),
                              icon: const Text('See All', style: TextStyle(color: Color(0xFF388E3C), fontWeight: FontWeight.bold)),
                              label: const Icon(Icons.arrow_forward_ios, size: 14, color: Color(0xFF388E3C)),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 220,
                        child: isLoading 
                          ? const Center(child: CircularProgressIndicator(color: Color(0xFF388E3C)))
                          : ListView.builder(
                              scrollDirection: Axis.horizontal,
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                              itemCount: recommendedProducts.length,
                              itemBuilder: (context, index) {
                                // REFACTORED: Use Universal Card
                                return UniversalProductCard(
                                  productData: recommendedProducts[index],
                                  isGrid: false,
                                  isPreowned: false,
                                );
                              },
                            ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // --- FILTER BUTTONS ---
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: [
                          FilterChipButton(label: 'All', isSelected: selectedFilter == 'All', onTap: () => setState(() { selectedFilter = 'All'; _applyFilters(); })),
                          FilterChipButton(label: 'Price', isSelected: selectedFilter == 'Price', onTap: () => setState(() { selectedFilter = 'Price'; _applyFilters(); })),
                          FilterChipButton(label: 'Rating', isSelected: selectedFilter == 'Rating', onTap: () => setState(() { selectedFilter = 'Rating'; _applyFilters(); })),
                          if (selectedFilter != 'All')
                            Padding(padding: const EdgeInsets.only(left: 8), child: CircleAvatar(radius: 18, backgroundColor: const Color(0xFF388E3C), child: IconButton(onPressed: () => setState(() { isAscending = !isAscending; _applyFilters(); }), icon: Icon(isAscending ? Icons.arrow_upward : Icons.arrow_downward, color: Colors.white, size: 18)))),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // --- VERTICAL GRID ---
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        showAllProducts || searchQuery.isNotEmpty ? 'All Products (${filteredProductData.length})' : 'More Products',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(height: 12),

                    isLoading
                      ? const Center(child: CircularProgressIndicator(color: Color(0xFF388E3C)))
                      : GridView.builder(
                          physics: const NeverScrollableScrollPhysics(),
                          shrinkWrap: true,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2, childAspectRatio: 0.75, crossAxisSpacing: 8, mainAxisSpacing: 8,
                          ),
                          itemCount: filteredProductData.length,
                          itemBuilder: (context, index) {
                            // REFACTORED: Use Universal Card
                            return UniversalProductCard(
                              productData: filteredProductData[index],
                              isGrid: true,
                              isPreowned: false,
                            );
                          },
                        ),
                    const SizedBox(height: 80),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: _buildSellFab(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomNavBar(currentIndex: _currentIndex, onTap: _handleNavigation),
    );
  }

  Widget _buildSellFab() {
    return Container(
      width: 60, height: 60,
      decoration: BoxDecoration(shape: BoxShape.circle, gradient: const LinearGradient(colors: [Color(0xFF66BB6A), Color(0xFF388E3C)], begin: Alignment.topCenter, end: Alignment.bottomCenter), boxShadow: [BoxShadow(color: const Color(0xFF388E3C).withOpacity(0.4), blurRadius: 12, offset: const Offset(0, 4))]),
      child: FloatingActionButton(onPressed: () => _handleNavigation(2), backgroundColor: Colors.transparent, elevation: 0, child: const Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.add, size: 28), Text('Sell', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold))])),
    );
  }
}