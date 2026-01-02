import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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
  static const Color _primaryColor = Color(0xFF388E3C);
  static const Color _iconColor = Color(0xFF1B5E20);
  
  final Map<String, IconData> _categoryIcons = {
    'Clothing': Icons.checkroom,
    'Dairy-Free': Icons.no_food,
    'Eco-Friendly': Icons.nature,
    'Fitness': Icons.fitness_center,
    'Gluten-Free': Icons.local_dining,
    'Gluten': Icons.bakery_dining,
    'Halal Products': Icons.mosque,
    'Non-Halal Products': Icons.no_meals,
    'Nut': Icons.set_meal,
    'Electronic & Gadget': Icons.computer,
    'Vegan Products': Icons.eco,
  };

  final List<String> _allCategories = [
    'Clothing', 'Dairy-Free', 'Eco-Friendly', 'Fitness',
    'Gluten-Free', 'Gluten', 'Halal Products', 'Non-Halal Products',
    'Nut', 'Electronic & Gadget', 'Vegan Products',
  ];

  final Set<String> _selectedCategories = {};
  List<Product> _allProducts = [];
  List<Product> _filteredProducts = [];
  bool _isLoading = true;
  bool _showPreview = false;

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    try {
      final snapshot = await FirebaseFirestore.instance.collection('products').get();
      setState(() {
        _allProducts = snapshot.docs.map((doc) => Product.fromFirestore(doc)).toList();
        _filteredProducts = List.from(_allProducts);
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _filterProducts() {
    setState(() {
      if (_selectedCategories.isEmpty) {
        _filteredProducts = List.from(_allProducts);
      } else {
        _filteredProducts = _allProducts.where((product) {
          final searchText = '${product.category} ${product.name} ${product.description}'.toLowerCase();
          final productTags = product.tags.map((e) => e.toLowerCase()).toList();

          return _selectedCategories.any((category) {
            final filter = category.toLowerCase();
            return searchText.contains(filter) || productTags.any((tag) => tag.contains(filter));
          });
        }).toList();
      }
      _showPreview = true;
    });
  }

  void _toggleCategory(String category) {
    setState(() {
      _selectedCategories.contains(category)
          ? _selectedCategories.remove(category)
          : _selectedCategories.add(category);
      _showPreview = false;
    });
  }

  void _clearAll() {
    setState(() {
      _selectedCategories.clear();
      _filteredProducts = List.from(_allProducts);
      _showPreview = false;
    });
  }

  void _applyFilters() {
    Navigator.pop(context, {
      'selectedCategories': _selectedCategories.toList(),
      'filteredProducts': _filteredProducts.map((p) => p.toMap()).toList(),
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Filter by Category',
          style: TextStyle(
            fontFamily: 'Manrope',
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          TextButton(
            onPressed: _clearAll,
            child: const Text(
              'Clear All',
              style: TextStyle(
                fontFamily: 'Manrope',
                color: _primaryColor,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          if (_selectedCategories.isNotEmpty) _buildSelectionBanner(),
          Expanded(child: _buildCategoryList()),
          if (_showPreview) _buildPreviewBanner(),
          _buildActionButtons(),
        ],
      ),
    );
  }

  Widget _buildSelectionBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      color: _primaryColor.withOpacity(0.1),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '${_selectedCategories.length} ${_selectedCategories.length == 1 ? 'category' : 'categories'} selected',
            style: const TextStyle(
              fontFamily: 'Manrope',
              color: _primaryColor,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
          TextButton(
            onPressed: () => setState(() => _selectedCategories.addAll(_allCategories)),
            style: TextButton.styleFrom(padding: const EdgeInsets.all(8)),
            child: const Text(
              'Select All',
              style: TextStyle(
                fontFamily: 'Manrope',
                color: _primaryColor,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryList() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: _primaryColor),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      itemCount: _allCategories.length,
      itemBuilder: (context, index) {
        final category = _allCategories[index];
        final isSelected = _selectedCategories.contains(category);
        final icon = _categoryIcons[category] ?? Icons.category;

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? _primaryColor : Colors.grey.shade300,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: CheckboxListTile(
            secondary: Icon(
              icon,
              color: isSelected ? _primaryColor : _iconColor,
              size: 24,
            ),
            title: Text(
              category,
              style: TextStyle(
                fontFamily: 'Manrope',
                fontSize: 16,
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

  Widget _buildPreviewBanner() {
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
              fontFamily: 'Manrope',
              fontSize: 17,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            '${_filteredProducts.length} ${_filteredProducts.length == 1 ? 'product' : 'products'}',
            style: TextStyle(
              fontFamily: 'Manrope',
              fontSize: 15,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: _isLoading ? null : _filterProducts,
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: _primaryColor, width: 2),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text(
                'Preview',
                style: TextStyle(
                  fontFamily: 'Manrope',
                  color: _primaryColor,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _applyFilters,
              style: ElevatedButton.styleFrom(
                backgroundColor: _primaryColor,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text(
                'Apply Filters',
                style: TextStyle(
                  fontFamily: 'Manrope',
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}