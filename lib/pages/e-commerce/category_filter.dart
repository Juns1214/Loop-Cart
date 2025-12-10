import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// 1. Model Class for Type Safety
class Product {
  final String id;
  final String name;
  final double price;
  final double rating;
  final String category;
  final String description;
  final String imageUrl;
  final List<String> tags;

  Product({
    required this.id,
    required this.name,
    required this.price,
    required this.rating,
    required this.category,
    required this.description,
    required this.imageUrl,
    required this.tags,
  });

  factory Product.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Product(
      id: doc.id,
      name: data['name'] ?? data['productName'] ?? 'Unknown',
      price: (data['price'] ?? data['productPrice'] ?? 0).toDouble(),
      rating: (data['rating'] ?? data['bestValue'] ?? 0).toDouble(),
      category: data['category'] ?? '',
      description: data['description'] ?? '',
      imageUrl: data['imageUrl'] ?? data['image_url'] ?? '',
      tags: List<String>.from(data['tags'] ?? []),
    );
  }

  // Helper for converting back to Map if needed for navigation
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'price': price,
      'rating': rating,
      'category': category,
      'description': description,
      'imageUrl': imageUrl,
      'tags': tags,
    };
  }
}

class CategoryFilterPage extends StatefulWidget {
  const CategoryFilterPage({super.key});

  @override
  State<CategoryFilterPage> createState() => _CategoryFilterPageState();
}

class _CategoryFilterPageState extends State<CategoryFilterPage> {
  // Constants
  static const Color _primaryColor = Color(0xFF388E3C);
  
  final List<String> _allCategories = [
    'Clothing', 'Dairy-Free', 'Eco-Friendly', 'Fitness',
    'Gluten-Free', 'Gluten', 'Halal Products', 'Non-Halal Products',
    'Nut', 'Electronic & Gadget', 'Vegan Products',
  ];

  // State
  final Set<String> _selectedCategories = {};
  List<Product> _allProductsCache = []; // Store all data here to avoid refetching
  List<Product> _filteredResults = [];
  bool _isLoading = true;
  bool _hasPreviewed = false;

  @override
  void initState() {
    super.initState();
    _fetchInitialData();
  }

  // 2. Fetch data ONLY ONCE
  Future<void> _fetchInitialData() async {
    try {
      QuerySnapshot snapshot = await FirebaseFirestore.instance.collection('products').get();
      
      setState(() {
        _allProductsCache = snapshot.docs.map((doc) => Product.fromFirestore(doc)).toList();
        _filteredResults = List.from(_allProductsCache); // Default to showing all
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading products: $e');
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading data: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  // 3. Filter locally in memory (Instant)
  void _runLocalFilter() {
    if (_selectedCategories.isEmpty) {
      setState(() {
        _filteredResults = List.from(_allProductsCache);
        _hasPreviewed = true;
      });
      return;
    }

    setState(() => _isLoading = true);

    // Simulate a brief delay for UI feedback (optional, remove if not needed)
    Future.delayed(const Duration(milliseconds: 300), () {
      final filtered = _allProductsCache.where((product) {
        // Prepare search strings
        final category = product.category.toLowerCase();
        final name = product.name.toLowerCase();
        final desc = product.description.toLowerCase();
        final tags = product.tags.map((e) => e.toLowerCase()).toList();

        // Check against selection
        for (String selectedCat in _selectedCategories) {
          String filterTerm = selectedCat.toLowerCase();
          
          bool matchesTag = tags.any((t) => t.contains(filterTerm));
          bool matchesText = '$category $name $desc'.contains(filterTerm);

          if (matchesText || matchesTag) return true;
        }
        return false;
      }).toList();

      if (mounted) {
        setState(() {
          _filteredResults = filtered;
          _isLoading = false;
          _hasPreviewed = true;
        });
      }
    });
  }

  void _toggleCategory(String category) {
    setState(() {
      if (_selectedCategories.contains(category)) {
        _selectedCategories.remove(category);
      } else {
        _selectedCategories.add(category);
      }
      _hasPreviewed = false; // Reset preview state when selection changes
    });
  }

  void _applyAndReturn() {
    // Ensure we send back Map<String, dynamic> to match original expectation
    final resultList = _filteredResults.map((p) => p.toMap()).toList();
    
    Navigator.pop(context, {
      'selectedCategories': _selectedCategories.toList(),
      'filteredProducts': resultList,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          _buildSelectionBanner(),
          Expanded(child: _buildCategoryList()),
          if (_hasPreviewed) _buildResultsPreviewBanner(),
          _buildBottomActionArea(),
        ],
      ),
    );
  }

  // --- UI WIDGETS EXTRACTED ---

  AppBar _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.black),
        onPressed: () => Navigator.pop(context),
      ),
      title: const Text(
        'Filter by Category',
        style: TextStyle(
          fontFamily: 'Manrope', color: Colors.black, 
          fontSize: 18, fontWeight: FontWeight.bold
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            setState(() {
              _selectedCategories.clear();
              _filteredResults = List.from(_allProductsCache);
              _hasPreviewed = false;
            });
          },
          child: const Text(
            'Clear All',
            style: TextStyle(
              fontFamily: 'Manrope', color: _primaryColor, fontSize: 14
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSelectionBanner() {
    if (_selectedCategories.isEmpty) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: _primaryColor.withOpacity(0.1),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '${_selectedCategories.length} ${_selectedCategories.length == 1 ? 'category' : 'categories'} selected',
            style: const TextStyle(
              fontFamily: 'Manrope', color: _primaryColor, 
              fontSize: 14, fontWeight: FontWeight.w600
            ),
          ),
          TextButton(
            onPressed: () => setState(() => _selectedCategories.addAll(_allCategories)),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: const Text(
              'Select All',
              style: TextStyle(fontFamily: 'Manrope', color: _primaryColor, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryList() {
    if (_isLoading && _allProductsCache.isEmpty) {
      return const Center(child: CircularProgressIndicator(color: _primaryColor));
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: _allCategories.length,
      itemBuilder: (context, index) {
        final category = _allCategories[index];
        final isSelected = _selectedCategories.contains(category);

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? _primaryColor : Colors.grey.shade300,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: CheckboxListTile(
            title: Text(
              category,
              style: TextStyle(
                fontFamily: 'Manrope', fontSize: 15,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
            value: isSelected,
            activeColor: _primaryColor,
            onChanged: (_) => _toggleCategory(category),
            controlAffinity: ListTileControlAffinity.trailing,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      },
    );
  }

  Widget _buildResultsPreviewBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Results',
            style: TextStyle(
              fontFamily: 'Manrope', fontSize: 16, fontWeight: FontWeight.bold
            ),
          ),
          Text(
            '${_filteredResults.length} ${_filteredResults.length == 1 ? 'product' : 'products'}',
            style: TextStyle(
              fontFamily: 'Manrope', fontSize: 14, color: Colors.grey.shade600
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomActionArea() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10, offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: (_isLoading && _allProductsCache.isEmpty) ? null : _runLocalFilter,
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: _primaryColor),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: _isLoading && _filteredResults.isEmpty
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: _primaryColor))
                  : const Text(
                      'Preview',
                      style: TextStyle(
                        fontFamily: 'Manrope', color: _primaryColor, 
                        fontSize: 16, fontWeight: FontWeight.w600
                      ),
                    ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: (_isLoading && _allProductsCache.isEmpty) ? null : _applyAndReturn,
              style: ElevatedButton.styleFrom(
                backgroundColor: _primaryColor,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: const Text(
                'Apply Filters',
                style: TextStyle(
                  fontFamily: 'Manrope', color: Colors.white, 
                  fontSize: 16, fontWeight: FontWeight.w600
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}