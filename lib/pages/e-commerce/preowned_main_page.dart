import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_application_1/utils/bottom_nav_bar.dart';
import 'package:flutter_application_1/utils/shopping_cart.dart';
import '../../widget/filter_button.dart';
import '../../widget/search_filter_bar.dart';
import '../../widget/product_card.dart';

class PreownedMainPage extends StatefulWidget {
  const PreownedMainPage({super.key});

  @override
  State<PreownedMainPage> createState() => _PreownedMainPageState();
}

class _PreownedMainPageState extends State<PreownedMainPage> {
  static const Color _primaryColor = Color(0xFF388E3C);

  final List<String> _categories = [
    'All',
    'Electronics',
    'Home Appliances',
    'Furniture',
    'Vehicles',
    'Baby and Kids',
    'Musical Instruments',
    'Books & Stationery',
  ];

  int _currentIndex = 0;
  List<Map<String, dynamic>> _allProducts = [];
  List<Map<String, dynamic>> _filteredProducts = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String _selectedCategory = 'All';
  String _selectedFilter = 'All';
  bool _isAscending = true;

  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadProducts() async {
    setState(() => _isLoading = true);
    try {
      final snapshot = await FirebaseFirestore.instance.collection('preowned_products').get();
      final products = snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          ...data,
          'id': data['id'] ?? doc.id,
          'name': data['name'] ?? 'Unknown',
          'price': _parsePrice(data['price']),
          'description': data['description'] ?? '',
          'category': data['category'] ?? '',
          'seller': data['seller'] ?? '',
          'imageUrl1': data['imageUrl1'] ?? '',
        };
      }).toList();

      setState(() {
        _allProducts = products;
        _filteredProducts = products;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  double _parsePrice(dynamic price) {
    if (price is int) return price.toDouble();
    if (price is double) return price;
    if (price is String) return double.tryParse(price) ?? 0.0;
    return 0.0;
  }

  void _applyFilters() {
    var results = List<Map<String, dynamic>>.from(_allProducts);

    // Filter by search query
    if (_searchQuery.isNotEmpty) {
      results = results.where((product) {
        final name = (product['name'] ?? '').toLowerCase();
        final category = (product['category'] ?? '').toLowerCase();
        final query = _searchQuery.toLowerCase();
        return name.contains(query) || category.contains(query);
      }).toList();
    }

    // Filter by category
    if (_selectedCategory != 'All') {
      results = results.where((product) {
        final category = (product['category'] ?? '').toLowerCase();
        return category == _selectedCategory.toLowerCase();
      }).toList();
    }

    // Sort by selected filter
    if (_selectedFilter != 'All') {
      results.sort((a, b) {
        final compare = _selectedFilter == 'Price'
            ? (a['price'] ?? 0).compareTo(b['price'] ?? 0)
            : (a['name'] ?? '').compareTo(b['name'] ?? '');
        return _isAscending ? compare : -compare;
      });
    }

    setState(() => _filteredProducts = results);
  }

  void _clearSearch() {
    setState(() {
      _searchQuery = '';
      _selectedCategory = 'All';
      _selectedFilter = 'All';
      _searchController.clear();
      _filteredProducts = _allProducts;
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
      backgroundColor: Colors.grey.shade50,
      body: Column(
        children: [
          _buildHeader(),
          if (_searchQuery.isNotEmpty || _selectedCategory != 'All') _buildInfoBanner(),
          _buildFilterButtons(),
          Expanded(child: _buildProductGrid()),
        ],
      ),
      floatingActionButton: _buildSellFab(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomNavBar(currentIndex: _currentIndex, onTap: _handleNavigation),
    );
  }

  Widget _buildHeader() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, size: 26),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const Expanded(
                    child: Text(
                      'Marketplace',
                      style: TextStyle(
                        fontFamily: 'Roboto',
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const ShoppingCart(),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: SearchBarWithFilter(
                controller: _searchController,
                hintText: 'Search marketplace...',
                onChanged: (value) {
                  setState(() => _searchQuery = value);
                  _applyFilters();
                },
                onClear: _clearSearch,
              ),
            ),
            _buildCategoryChips(),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryChips() {
    return SizedBox(
      height: 50,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          final category = _categories[index];
          final isSelected = _selectedCategory == category;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: ChoiceChip(
              label: Text(
                category,
                style: TextStyle(
                  fontFamily: 'Roboto',
                  fontSize: 16,
                  color: isSelected ? Colors.white : Colors.black,
                  fontWeight: FontWeight.bold,
                ),
              ),
              selected: isSelected,
              onSelected: (_) => setState(() {
                _selectedCategory = category;
                _applyFilters();
              }),
              backgroundColor: Colors.white,
              selectedColor: _primaryColor,
              side: BorderSide(
                color: isSelected ? _primaryColor : Colors.grey.shade300,
              ),
            ),
          );
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
          const Icon(Icons.filter_list, size: 18, color: _primaryColor),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _selectedCategory != 'All'
                  ? 'Category: $_selectedCategory'
                  : 'Search results',
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
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            ),
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

  Widget _buildFilterButtons() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      color: Colors.white,
      child: SingleChildScrollView(
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
              label: 'Name',
              isSelected: _selectedFilter == 'Name',
              onTap: () => setState(() {
                _selectedFilter = 'Name';
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
      ),
    );
  }

  Widget _buildProductGrid() {
    return RefreshIndicator(
      onRefresh: _loadProducts,
      color: _primaryColor,
      child: _isLoading
          ? const Center(child: CircularProgressIndicator(color: _primaryColor))
          : _filteredProducts.isEmpty
              ? Center(
                  child: Text(
                    'No items found',
                    style: TextStyle(
                      fontFamily: 'Roboto',
                      fontSize: 18,
                      color: Colors.grey.shade600,
                    ),
                  ),
                )
              : GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.75,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemCount: _filteredProducts.length,
                  itemBuilder: (context, index) => ProductCard(
                    productData: _filteredProducts[index],
                    isGrid: true,
                    isPreowned: true,
                  ),
                ),
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
            blurRadius: 12,
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