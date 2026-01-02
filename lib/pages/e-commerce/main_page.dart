import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_application_1/utils/swiper.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_application_1/utils/bottom_nav_bar.dart';
import '../../utils/router.dart';
import '../preference/preference_service.dart';
import '../../utils/shopping_cart_icon.dart';
import '../../widget/app_drawer.dart';
import '../../widget/filter_button.dart';
import '../../widget/search_filter_bar.dart';
import '../../widget/product_card.dart';

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
  static const Color _primaryColor = Color(0xFF388E3C);
  static const double _headerIconSize = 28.0;

  int _currentIndex = 0;
  List<Widget> _bannerPages = [];
  List<Map<String, dynamic>> _allProducts = [];
  List<Map<String, dynamic>> _recommendedProducts = [];
  List<Map<String, dynamic>> _displayedProducts = [];

  bool _isLoading = true;
  bool _showAllProducts = false;
  String _searchQuery = '';
  String _selectedFilter = 'All';
  bool _isAscending = true;

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
    
    _bannerPages = bannerImages.map((img) => Center(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.asset(img, width: double.infinity, height: 160, fit: BoxFit.cover),
      ),
    )).toList();
  }

  Future<void> _loadProducts() async {
    setState(() {
      _isLoading = true;
      _showAllProducts = false;
      _searchQuery = '';
      _searchController.clear();
    });

    try {
      final products = await _preferenceService.getFilteredProducts();
      final shuffled = List<Map<String, dynamic>>.from(products)..shuffle();
      final recCount = shuffled.length > 10 ? 10 : shuffled.length;

      setState(() {
        _allProducts = products;
        _recommendedProducts = shuffled.take(recCount).toList();
        _displayedProducts = shuffled.skip(recCount).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  void _applyFilters() {
    var results = _allProducts;

    if (_searchQuery.isNotEmpty) {
      results = results.where((p) {
        final name = (p['name'] ?? '').toLowerCase();
        final category = (p['category'] ?? '').toLowerCase();
        final query = _searchQuery.toLowerCase();
        return name.contains(query) || category.contains(query);
      }).toList();
    }

    if (_selectedFilter != 'All') {
      results.sort((a, b) {
        final compare = _selectedFilter == 'Price'
            ? (a['price'] ?? 0).compareTo(b['price'] ?? 0)
            : (a['rating'] ?? 0).compareTo(b['rating'] ?? 0);
        return _isAscending ? compare : -compare;
      });
    }

    setState(() {
      _displayedProducts = results;
      _showAllProducts = true;
    });
  }

  void _runSearch(String query) {
    setState(() {
      _searchQuery = query;
      if (query.isEmpty) {
        _showAllProducts = false;
        _displayedProducts = _allProducts.skip(_recommendedProducts.length).toList();
      } else {
        _applyFilters();
      }
    });
  }

  void _clearSearch() {
    setState(() {
      _searchQuery = '';
      _showAllProducts = false;
      _selectedFilter = 'All';
      _searchController.clear();
      _displayedProducts = _allProducts.skip(_recommendedProducts.length).toList();
    });
  }

  void _handleNavigation(int index) {
    setState(() => _currentIndex = index);
    final routes = {
      0: '/repair-service',
      1: '/recycling-pickup',
      2: '/sell-second-hand-product',
      3: '/sustainability-dashboard',
      4: '/chatbot',
      5: '/user-profile',
    };
    if (routes.containsKey(index)) {
      Navigator.pushNamed(context, routes[index]!);
    }
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
              color: _primaryColor,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(),
                    _buildSearchBar(),
                    if (_searchQuery.isNotEmpty || _showAllProducts) _buildInfoBanner(),
                    const SizedBox(height: 8),
                    if (!_showAllProducts && _searchQuery.isEmpty) ...[
                      _buildBannerSection(),
                      _buildRecommendedSection(),
                    ],
                    _buildFilterButtons(),
                    const SizedBox(height: 16),
                    _buildProductGrid(),
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

  Widget _buildHeader() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: SafeArea(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Builder(
              builder: (c) => IconButton(
                icon: const Icon(Icons.menu, size: _headerIconSize),
                onPressed: () => Scaffold.of(c).openDrawer(),
              ),
            ),
            Row(
              children: [
                IconButton(
                  onPressed: () => Navigator.pushNamed(context, '/waste-sorting-assistant'),
                  icon: const Icon(Icons.notifications_outlined, size: _headerIconSize),
                ),
                const ShoppingCart(),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: SearchBarWithFilter(
        controller: _searchController,
        onChanged: _runSearch,
        onClear: _clearSearch,
        onFilterTap: () async {
          final result = await Navigator.pushNamed(context, '/category-filter');
          if (result is Map<String, dynamic> && result['filteredProducts'] != null) {
            setState(() {
              _showAllProducts = true;
              _displayedProducts = List<Map<String, dynamic>>.from(result['filteredProducts']);
            });
          }
        },
      ),
    );
  }

  Widget _buildInfoBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: _primaryColor.withOpacity(0.1),
      child: Row(
        children: [
          const Icon(Icons.info_outline, size: 18, color: _primaryColor),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _searchQuery.isNotEmpty ? 'Results for "$_searchQuery"' : 'Showing all products',
              style: const TextStyle(
                fontFamily: 'Roboto',
                fontSize: 15,
                color: _primaryColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          TextButton(
            onPressed: _clearSearch,
            style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6)),
            child: const Text(
              'Clear',
              style: TextStyle(
                fontFamily: 'Roboto',
                fontSize: 14,
                color: _primaryColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBannerSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: SizedBox(height: 160, child: Swiper(pages: _bannerPages)),
    );
  }

  Widget _buildRecommendedSection() {
    return Column(
      children: [
        const SizedBox(height: 20),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Recommended',
                style: TextStyle(
                  fontFamily: 'Roboto',
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton.icon(
                onPressed: () => setState(() {
                  _showAllProducts = true;
                  _displayedProducts = _allProducts;
                }),
                style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 8)),
                icon: const Text(
                  'See All',
                  style: TextStyle(
                    fontFamily: 'Roboto',
                    color: _primaryColor,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                label: const Icon(Icons.arrow_forward_ios, size: 14, color: _primaryColor),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 220,
          child: _isLoading
              ? const Center(child: CircularProgressIndicator(color: _primaryColor))
              : ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  itemCount: _recommendedProducts.length,
                  itemBuilder: (context, index) => ProductCard(
                    productData: _recommendedProducts[index],
                    isGrid: false,
                    isPreowned: false,
                  ),
                ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildFilterButtons() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          FilterButton(
            label: 'All',
            isSelected: _selectedFilter == 'All',
            onTap: () => setState(() {
              _selectedFilter = 'All';
              _applyFilters();
            }),
          ),
          FilterButton(
            label: 'Price',
            isSelected: _selectedFilter == 'Price',
            onTap: () => setState(() {
              _selectedFilter = 'Price';
              _applyFilters();
            }),
          ),
          FilterButton(
            label: 'Rating',
            isSelected: _selectedFilter == 'Rating',
            onTap: () => setState(() {
              _selectedFilter = 'Rating';
              _applyFilters();
            }),
          ),
          if (_selectedFilter != 'All')
            Padding(
              padding: const EdgeInsets.only(left: 8),
              child: CircleAvatar(
                radius: 18,
                backgroundColor: _primaryColor,
                child: IconButton(
                  onPressed: () => setState(() {
                    _isAscending = !_isAscending;
                    _applyFilters();
                  }),
                  icon: Icon(
                    _isAscending ? Icons.arrow_upward : Icons.arrow_downward,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildProductGrid() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            _showAllProducts || _searchQuery.isNotEmpty
                ? 'All Products (${_displayedProducts.length})'
                : 'More Products',
            style: const TextStyle(
              fontFamily: 'Roboto',
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 12),
        _isLoading
            ? const Center(child: CircularProgressIndicator(color: _primaryColor))
            : GridView.builder(
                physics: const NeverScrollableScrollPhysics(),
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.75,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                ),
                itemCount: _displayedProducts.length,
                itemBuilder: (context, index) => ProductCard(
                  productData: _displayedProducts[index],
                  isGrid: true,
                  isPreowned: false,
                ),
              ),
      ],
    );
  }

  Widget _buildSellFab() {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: _primaryColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: FloatingActionButton(
        onPressed: () => _handleNavigation(2),
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add, size: 28, color: Colors.white),
            Text(
              'Sell',
              style: TextStyle(
                fontFamily: 'Roboto',
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}