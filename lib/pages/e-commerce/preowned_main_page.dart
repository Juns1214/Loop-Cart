import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'preowned_product.dart';
import 'package:flutter_application_1/utils/bottom_nav_bar.dart';
import 'package:flutter_application_1/utils/cart_icon_with_badge.dart';

class PreownedMainPage extends StatefulWidget {
  const PreownedMainPage({super.key});

  @override
  State<PreownedMainPage> createState() => _PreownedMainPageState();
}

class _PreownedMainPageState extends State<PreownedMainPage> {
  int _currentIndex = 0;

  // Categories from JSON
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

  // Firebase data
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

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Load products from Firestore
  Future<void> _loadProducts() async {
    setState(() {
      isLoading = true;
    });

    try {
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('preowned_products')
          .get();

      List<Map<String, dynamic>> products = snapshot.docs.map((doc) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

        // Convert price to double safely
        double price = 0.0;
        if (data['price'] != null) {
          if (data['price'] is int) {
            price = (data['price'] as int).toDouble();
          } else if (data['price'] is double) {
            price = data['price'] as double;
          } else if (data['price'] is String) {
            price = double.tryParse(data['price']) ?? 0.0;
          }
        }

        return {
          'id': data['id'] ?? doc.id,
          'name': data['name'] ?? 'Unknown',
          'price': price,
          'description': data['description'] ?? '',
          'category': data['category'] ?? '',
          'seller': data['seller'] ?? '',
          'imageUrl1': data['imageUrl1'] ?? '',
          'imageUrl2': data['imageUrl2'] ?? '',
          'imageUrl3': data['imageUrl3'] ?? '',
          ...data,
        };
      }).toList();

      setState(() {
        allProducts = products;
        filteredProducts = products;
        isLoading = false;
      });

      print('Loaded ${products.length} pre-owned products');
    } catch (e) {
      print('Error loading pre-owned products: $e');
      setState(() {
        isLoading = false;
      });

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

  // Filter and search products
  void _applyFilters() {
    List<Map<String, dynamic>> results = allProducts;

    // Apply category filter
    if (selectedCategory != 'All') {
      results = results.where((product) {
        return product['category'] == selectedCategory;
      }).toList();
    }

    // Apply search filter
    if (searchQuery.isNotEmpty) {
      results = results.where((product) {
        String name = (product['name'] ?? '').toLowerCase();
        String category = (product['category'] ?? '').toLowerCase();
        String seller = (product['seller'] ?? '').toLowerCase();
        return name.contains(searchQuery.toLowerCase()) ||
            category.contains(searchQuery.toLowerCase()) ||
            seller.contains(searchQuery.toLowerCase());
      }).toList();
    }

    // Apply sorting
    if (selectedFilter == 'Price') {
      results.sort((a, b) {
        // Safely convert to double
        double priceA = 0.0;
        if (a['price'] is int) {
          priceA = (a['price'] as int).toDouble();
        } else if (a['price'] is double) {
          priceA = a['price'] as double;
        }

        double priceB = 0.0;
        if (b['price'] is int) {
          priceB = (b['price'] as int).toDouble();
        } else if (b['price'] is double) {
          priceB = b['price'] as double;
        }

        int comparison = priceA.compareTo(priceB);
        return isAscending ? comparison : -comparison;
      });
    } else if (selectedFilter == 'Name') {
      results.sort((a, b) {
        int comparison = (a['name'] ?? '').compareTo(b['name'] ?? '');
        return isAscending ? comparison : -comparison;
      });
    }

    setState(() {
      filteredProducts = results;
    });
  }

  void _onCategorySelected(String category) {
    setState(() {
      selectedCategory = category;
      _applyFilters();
    });
  }

  void _runFilter(String enteredKeyword) {
    setState(() {
      searchQuery = enteredKeyword;
      _applyFilters();
    });
  }

  void _clearSearch() {
    setState(() {
      searchQuery = '';
      selectedCategory = 'All';
      selectedFilter = 'All';
      isAscending = true;
      _searchController.clear();
      filteredProducts = allProducts;
    });
  }

  void _toggleSortOrder() {
    setState(() {
      isAscending = !isAscending;
      _applyFilters();
    });
  }

  void _handleNavigation(int index) {
    setState(() {
      _currentIndex = index;
    });

    switch (index) {
      case 0:
        Navigator.pushNamed(context, '/repair-service');
        break;
      case 1:
        Navigator.pushNamed(context, '/recycling-pickup');
        break;
      case 2:
        Navigator.pushNamed(context, '/sell-second-hand-product');
        break;
      case 3:
        Navigator.pushNamed(context, '/sustainability-dashboard');
        break;
      case 4:
        Navigator.pushNamed(context, '/chatbot');
        break;
      case 5:
        Navigator.pushNamed(context, '/user-profile');
        break;
    }
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
      backgroundColor: Colors.grey.shade50,
      body: Column(
        children: [
          // Modern Header
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: SafeArea(
              child: Column(
                children: [
                  // Top bar
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        IconButton(
                          icon: Icon(Icons.arrow_back, size: 24),
                          onPressed: () => Navigator.pop(context),
                        ),
                        Expanded(
                          child: Text(
                            'Marketplace',
                            style: TextStyle(
                              fontFamily: 'Manrope',
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        CartIconWithBadge(),
                      ],
                    ),
                  ),

                  // Search bar
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(25),
                      ),
                      child: TextField(
                        controller: _searchController,
                        onChanged: (value) => _runFilter(value),
                        decoration: InputDecoration(
                          hintText: 'Search marketplace...',
                          hintStyle: TextStyle(
                            color: Colors.grey.shade500,
                            fontSize: 15,
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
                            horizontal: 20,
                            vertical: 14,
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Categories horizontal scroll
                  Container(
                    height: 50,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: EdgeInsets.symmetric(horizontal: 12),
                      itemCount: categories.length,
                      itemBuilder: (context, index) {
                        final category = categories[index];
                        final isSelected = selectedCategory == category;
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: ChoiceChip(
                            label: Text(category),
                            selected: isSelected,
                            onSelected: (selected) {
                              _onCategorySelected(category);
                            },
                            backgroundColor: Colors.white,
                            selectedColor: Color(0xFF388E3C),
                            labelStyle: TextStyle(
                              color: isSelected ? Colors.white : Colors.black87,
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                              fontSize: 13,
                            ),
                            side: BorderSide(
                              color: isSelected
                                  ? Color(0xFF388E3C)
                                  : Colors.grey.shade300,
                            ),
                            padding: EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
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

          // Active filters indicator
          if (searchQuery.isNotEmpty || selectedCategory != 'All')
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              color: Color(0xFF388E3C).withOpacity(0.1),
              child: Row(
                children: [
                  Icon(Icons.filter_list, size: 16, color: Color(0xFF388E3C)),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      selectedCategory != 'All'
                          ? 'Category: $selectedCategory (${filteredProducts.length})'
                          : 'Showing ${filteredProducts.length} results',
                      style: TextStyle(
                        fontFamily: 'Manrope',
                        fontSize: 13,
                        color: Color(0xFF388E3C),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  if (searchQuery.isNotEmpty || selectedCategory != 'All')
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

          // Sort filters
          Container(
            padding: EdgeInsets.symmetric(vertical: 12),
            color: Colors.white,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  filterButton('All', isSelected: selectedFilter == 'All'),
                  filterButton('Price', isSelected: selectedFilter == 'Price'),
                  filterButton('Name', isSelected: selectedFilter == 'Name'),
                  if (selectedFilter != 'All')
                    Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Color(0xFF388E3C),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: IconButton(
                          onPressed: _toggleSortOrder,
                          icon: Icon(
                            isAscending
                                ? Icons.arrow_upward
                                : Icons.arrow_downward,
                            color: Colors.white,
                            size: 18,
                          ),
                          padding: EdgeInsets.all(8),
                          constraints: BoxConstraints(),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),

          // Products grid
          Expanded(
            child: RefreshIndicator(
              onRefresh: _loadProducts,
              color: Color(0xFF388E3C),
              child: isLoading
                  ? Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF388E3C),
                      ),
                    )
                  : filteredProducts.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.shopping_bag_outlined,
                            size: 80,
                            color: Colors.grey.shade400,
                          ),
                          SizedBox(height: 16),
                          Text(
                            searchQuery.isEmpty
                                ? 'No items available'
                                : 'No items found',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Try adjusting your search or filters',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade500,
                            ),
                          ),
                          if (searchQuery.isNotEmpty ||
                              selectedCategory != 'All')
                            Padding(
                              padding: const EdgeInsets.only(top: 16),
                              child: ElevatedButton(
                                onPressed: _clearSearch,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Color(0xFF388E3C),
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 24,
                                    vertical: 12,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                ),
                                child: Text('Clear Filters'),
                              ),
                            ),
                        ],
                      ),
                    )
                  : GridView.builder(
                      padding: EdgeInsets.all(16),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 0.75,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                      ),
                      itemCount: filteredProducts.length,
                      itemBuilder: (context, index) {
                        final product = filteredProducts[index];
                        // Ensure price is double
                        double price = 0.0;
                        if (product['price'] is double) {
                          price = product['price'];
                        } else if (product['price'] is int) {
                          price = (product['price'] as int).toDouble();
                        }

                        return PreownedProductCard(
                          imageUrl: product['imageUrl1'] ?? '',
                          productName: product['name'] ?? 'Unknown',
                          productPrice: price,
                          location: product['seller'] ?? '',
                          category: product['category'] ?? '',
                          productData: product,
                        );
                      },
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
