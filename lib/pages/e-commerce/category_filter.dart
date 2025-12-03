import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CategoryFilterPage extends StatefulWidget {
  const CategoryFilterPage({super.key});

  @override
  State<CategoryFilterPage> createState() => _CategoryFilterPageState();
}

class _CategoryFilterPageState extends State<CategoryFilterPage> {
  // All available categories
  final List<String> allCategories = [
    'Clothing',
    'Dairy-Free',
    'Eco-Friendly',
    'Fitness',
    'Gluten-Free',
    'Gluten',
    'Halal Products',
    'Non-Halal Products',
    'Nut',
    'Electronic & Gadget',
    'Vegan Products',
  ];

  // Selected categories
  Set<String> selectedCategories = {};
  
  // Filtered products
  List<Map<String, dynamic>> filteredProducts = [];
  bool isLoading = false;
  bool hasSearched = false;

  @override
  void initState() {
    super.initState();
    // Load all products initially
    _loadAllProducts();
  }

  Future<void> _loadAllProducts() async {
    setState(() {
      isLoading = true;
      hasSearched = false;
    });

    try {
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('products')
          .get();

      List<Map<String, dynamic>> products = snapshot.docs.map((doc) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        return {
          'id': doc.id,
          'name': data['name'] ?? data['productName'] ?? 'Unknown',
          'price': (data['price'] ?? data['productPrice'] ?? 0).toDouble(),
          'rating': (data['rating'] ?? data['bestValue'] ?? 0).toDouble(),
          'category': data['category'] ?? '',
          'description': data['description'] ?? '',
          'imageUrl': data['imageUrl'] ?? data['image_url'] ?? '',
          'tags': data['tags'] ?? [],
          ...data,
        };
      }).toList();

      setState(() {
        filteredProducts = products;
        isLoading = false;
      });
    } catch (e) {
      print('Error loading products: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _filterProducts() async {
    if (selectedCategories.isEmpty) {
      await _loadAllProducts();
      return;
    }

    setState(() {
      isLoading = true;
      hasSearched = true;
    });

    try {
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('products')
          .get();

      List<Map<String, dynamic>> products = snapshot.docs.map((doc) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        return {
          'id': doc.id,
          'name': data['name'] ?? data['productName'] ?? 'Unknown',
          'price': (data['price'] ?? data['productPrice'] ?? 0).toDouble(),
          'rating': (data['rating'] ?? data['bestValue'] ?? 0).toDouble(),
          'category': data['category'] ?? '',
          'description': data['description'] ?? '',
          'imageUrl': data['imageUrl'] ?? data['image_url'] ?? '',
          'tags': data['tags'] ?? [],
          ...data,
        };
      }).toList();

      // Filter products by selected categories
      List<Map<String, dynamic>> filtered = products.where((product) {
        String category = (product['category'] ?? '').toString().toLowerCase();
        String name = (product['name'] ?? '').toString().toLowerCase();
        String description = (product['description'] ?? '').toString().toLowerCase();
        List<dynamic> tags = product['tags'] ?? [];
        
        // Combine all text for searching
        String allText = '$category $name $description ${tags.join(' ')}'.toLowerCase();

        // Check if product matches any selected category
        for (String selectedCat in selectedCategories) {
          String catLower = selectedCat.toLowerCase();
          if (allText.contains(catLower) || 
              category.contains(catLower) ||
              tags.any((tag) => tag.toString().toLowerCase().contains(catLower))) {
            return true;
          }
        }
        return false;
      }).toList();

      setState(() {
        filteredProducts = filtered;
        isLoading = false;
      });

      print('Filtered ${filtered.length} products from ${products.length} total');
    } catch (e) {
      print('Error filtering products: $e');
      setState(() {
        isLoading = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error filtering products: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _toggleCategory(String category) {
    setState(() {
      if (selectedCategories.contains(category)) {
        selectedCategories.remove(category);
      } else {
        selectedCategories.add(category);
      }
    });
  }

  void _clearAll() {
    setState(() {
      selectedCategories.clear();
      hasSearched = false;
    });
    _loadAllProducts();
  }

  void _selectAll() {
    setState(() {
      selectedCategories = Set.from(allCategories);
    });
  }

  // Preview function - just shows the count
  Future<void> _previewResults() async {
    await _filterProducts();
  }

  // Apply filters and return to previous screen
  Future<void> _applyAndReturn() async {
    // First filter the products if not already done
    if (!hasSearched || isLoading) {
      await _filterProducts();
    }
    
    // Then return with the results
    if (mounted) {
      Navigator.pop(context, {
        'selectedCategories': selectedCategories.toList(),
        'filteredProducts': filteredProducts,
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Filter by Category',
          style: TextStyle(
            fontFamily: 'Manrope',
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          TextButton(
            onPressed: _clearAll,
            child: Text(
              'Clear All',
              style: TextStyle(
                fontFamily: 'Manrope',
                color: Color(0xFF388E3C),
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Selected count banner
          if (selectedCategories.isNotEmpty)
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              color: Color(0xFF388E3C).withOpacity(0.1),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${selectedCategories.length} ${selectedCategories.length == 1 ? 'category' : 'categories'} selected',
                    style: TextStyle(
                      fontFamily: 'Manrope',
                      color: Color(0xFF388E3C),
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  TextButton(
                    onPressed: _selectAll,
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      minimumSize: Size(0, 0),
                    ),
                    child: Text(
                      'Select All',
                      style: TextStyle(
                        fontFamily: 'Manrope',
                        color: Color(0xFF388E3C),
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // Category list
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.symmetric(vertical: 8),
              itemCount: allCategories.length,
              itemBuilder: (context, index) {
                final category = allCategories[index];
                final isSelected = selectedCategories.contains(category);

                return Container(
                  margin: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected 
                          ? Color(0xFF388E3C) 
                          : Colors.grey.shade300,
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: CheckboxListTile(
                    title: Text(
                      category,
                      style: TextStyle(
                        fontFamily: 'Manrope',
                        fontSize: 15,
                        fontWeight: isSelected 
                            ? FontWeight.w600 
                            : FontWeight.normal,
                      ),
                    ),
                    value: isSelected,
                    activeColor: Color(0xFF388E3C),
                    onChanged: (bool? value) {
                      _toggleCategory(category);
                    },
                    controlAffinity: ListTileControlAffinity.trailing,
                  ),
                );
              },
            ),
          ),

          // Results preview (only shows after preview button is clicked)
          if (hasSearched)
            Container(
              padding: EdgeInsets.all(16),
              color: Colors.white,
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Preview Results',
                        style: TextStyle(
                          fontFamily: 'Manrope',
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${filteredProducts.length} ${filteredProducts.length == 1 ? 'product' : 'products'}',
                        style: TextStyle(
                          fontFamily: 'Manrope',
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

          // Bottom action buttons
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: Offset(0, -5),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: (isLoading || selectedCategories.isEmpty) 
                        ? null 
                        : _previewResults,
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(
                        color: selectedCategories.isEmpty 
                            ? Colors.grey.shade300 
                            : Color(0xFF388E3C),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: isLoading
                        ? SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Color(0xFF388E3C),
                            ),
                          )
                        : Text(
                            'Preview',
                            style: TextStyle(
                              fontFamily: 'Manrope',
                              color: selectedCategories.isEmpty 
                                  ? Colors.grey.shade400 
                                  : Color(0xFF388E3C),
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: (isLoading || selectedCategories.isEmpty) 
                        ? null 
                        : _applyAndReturn,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: selectedCategories.isEmpty 
                          ? Colors.grey.shade300 
                          : Color(0xFF388E3C),
                      disabledBackgroundColor: Colors.grey.shade300,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: Text(
                      'Apply Filters',
                      style: TextStyle(
                        fontFamily: 'Manrope',
                        color: selectedCategories.isEmpty 
                            ? Colors.grey.shade500 
                            : Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}