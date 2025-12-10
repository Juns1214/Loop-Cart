import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_application_1/utils/bottom_nav_bar.dart';
import 'package:flutter_application_1/utils/cart_icon_with_badge.dart';
import '../../widget/filter_chip_button.dart';
import '../../widget/search_input.dart';
import '../../widget/universal_product_card.dart';

class PreownedMainPage extends StatefulWidget {
  const PreownedMainPage({super.key});

  @override
  State<PreownedMainPage> createState() => _PreownedMainPageState();
}

class _PreownedMainPageState extends State<PreownedMainPage> {
  int _currentIndex = 0;
  final List<String> categories = [
    'All',
    'Electronics',
    'Home Appliances',
    'Furniture',
    'Vehicles',
    'Baby and Kids',
    'Musical Instruments',
    'Books & Stationery',
  ];

  List<Map<String, dynamic>> allProducts = [];
  List<Map<String, dynamic>> filteredProducts = [];
  bool isLoading = true;
  String searchQuery = '';
  String selectedCategory = 'All';
  String selectedFilter = 'All';
  bool isAscending = true;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    setState(() => isLoading = true);
    try {
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('preowned_products')
          .get();
      List<Map<String, dynamic>> products = snapshot.docs.map((doc) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

        // Parsing helper
        double price = 0.0;
        var p = data['price'];
        if (p is int)
          price = p.toDouble();
        else if (p is double)
          price = p;
        else if (p is String)
          price = double.tryParse(p) ?? 0.0;

        return {
          ...data, // <--- MOVE THIS TO THE TOP
          'id': data['id'] ?? doc.id,
          'name': data['name'] ?? 'Unknown',
          'price':
              price, // Now this converted double will overwrite the raw data
          'description': data['description'] ?? '',
          'category': data['category'] ?? '',
          'seller': data['seller'] ?? '',
          'imageUrl1': data['imageUrl1'] ?? '',
        };
      }).toList();

      setState(() {
        allProducts = products;
        filteredProducts = products;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  void _applyFilters() {
    List<Map<String, dynamic>> results = allProducts;
    if (selectedFilter != 'All') {
      results.sort((a, b) {
        int cmp = 0;
        if (selectedFilter == 'Price') {
          // Safely handle both int and double
          num priceA = a['price'] ?? 0;
          num priceB = b['price'] ?? 0;
          cmp = priceA.compareTo(priceB);
        } else if (selectedFilter == 'Name') {
          cmp = (a['name'] ?? '').compareTo(b['name'] ?? '');
        }
        return isAscending ? cmp : -cmp;
      });
    }
    setState(() => filteredProducts = results);
  }

  void _clearSearch() {
    setState(() {
      searchQuery = '';
      selectedCategory = 'All';
      selectedFilter = 'All';
      _searchController.clear();
      filteredProducts = allProducts;
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
    if (routes.containsKey(index)) Navigator.pushNamed(context, routes[index]!);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: Column(
        children: [
          Container(
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
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back, size: 24),
                          onPressed: () => Navigator.pop(context),
                        ),
                        const Expanded(
                          child: Text(
                            'Marketplace',
                            style: TextStyle(
                              fontFamily: 'Manrope',
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const CartIconWithBadge(),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: SearchInput(
                      controller: _searchController,
                      hintText: 'Search marketplace...',
                      onChanged: (val) {
                        searchQuery = val;
                        _applyFilters();
                      },
                      onClear: _clearSearch,
                    ),
                  ),
                  SizedBox(
                    height: 50,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      itemCount: categories.length,
                      itemBuilder: (context, index) {
                        final cat = categories[index];
                        final isSelected = selectedCategory == cat;
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: ChoiceChip(
                            label: Text(cat),
                            selected: isSelected,
                            onSelected: (_) => setState(() {
                              selectedCategory = cat;
                              _applyFilters();
                            }),
                            backgroundColor: Colors.white,
                            selectedColor: const Color(0xFF388E3C),
                            labelStyle: TextStyle(
                              color: isSelected ? Colors.white : Colors.black87,
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                            side: BorderSide(
                              color: isSelected
                                  ? const Color(0xFF388E3C)
                                  : Colors.grey.shade300,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),

          if (searchQuery.isNotEmpty || selectedCategory != 'All')
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              color: const Color(0xFF388E3C).withOpacity(0.1),
              child: Row(
                children: [
                  const Icon(
                    Icons.filter_list,
                    size: 16,
                    color: Color(0xFF388E3C),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      selectedCategory != 'All'
                          ? 'Category: $selectedCategory'
                          : 'Search results',
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF388E3C),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: _clearSearch,
                    child: const Text(
                      'Clear',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF388E3C),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            color: Colors.white,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  FilterChipButton(
                    label: 'All',
                    isSelected: selectedFilter == 'All',
                    onTap: () => setState(() {
                      selectedFilter = 'All';
                      _applyFilters();
                    }),
                  ),
                  FilterChipButton(
                    label: 'Price',
                    isSelected: selectedFilter == 'Price',
                    onTap: () => setState(() {
                      selectedFilter = 'Price';
                      _applyFilters();
                    }),
                  ),
                  FilterChipButton(
                    label: 'Name',
                    isSelected: selectedFilter == 'Name',
                    onTap: () => setState(() {
                      selectedFilter = 'Name';
                      _applyFilters();
                    }),
                  ),
                  if (selectedFilter != 'All')
                    Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: CircleAvatar(
                        radius: 18,
                        backgroundColor: const Color(0xFF388E3C),
                        child: IconButton(
                          onPressed: () => setState(() {
                            isAscending = !isAscending;
                            _applyFilters();
                          }),
                          icon: Icon(
                            isAscending
                                ? Icons.arrow_upward
                                : Icons.arrow_downward,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),

          Expanded(
            child: RefreshIndicator(
              onRefresh: _loadProducts,
              color: const Color(0xFF388E3C),
              child: isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF388E3C),
                      ),
                    )
                  : filteredProducts.isEmpty
                  ? Center(
                      child: Text(
                        'No items found',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    )
                  : GridView.builder(
                      padding: const EdgeInsets.all(16),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            childAspectRatio: 0.75,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                          ),
                      itemCount: filteredProducts.length,
                      itemBuilder: (context, index) {
                        // REFACTORED: Use Universal Card
                        return UniversalProductCard(
                          productData: filteredProducts[index],
                          isGrid: true, // Marketplace is always grid
                          isPreowned:
                              true, // Triggers Preowned logic (Location, Route)
                        );
                      },
                    ),
            ),
          ),
        ],
      ),
      floatingActionButton: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const LinearGradient(
            colors: [Color(0xFF66BB6A), Color(0xFF388E3C)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF388E3C).withOpacity(0.4),
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
              Icon(Icons.add, size: 28),
              Text(
                'Sell',
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomNavBar(
        currentIndex: _currentIndex,
        onTap: _handleNavigation,
      ),
    );
  }
}
