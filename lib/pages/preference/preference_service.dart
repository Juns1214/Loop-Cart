import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PreferenceService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get current user's preferences
  Future<Map<String, dynamic>?> getUserPreferences() async {
    try {
      User? user = _auth.currentUser;
      if (user == null) {
        print('No authenticated user found');
        return null;
      }

      DocumentSnapshot doc = await _firestore
          .collection('user_preferences')
          .doc(user.uid)
          .get();

      if (doc.exists) {
        print('User preferences found for ${user.uid}');
        return doc.data() as Map<String, dynamic>;
      } else {
        print('No preferences set for user ${user.uid}');
        return null;
      }
    } catch (e) {
      print('Error getting user preferences: $e');
      return null;
    }
  }

  // Save user preferences
  Future<bool> saveUserPreferences({
    required List<String> dietaryPreferences,
    required List<String> lifestyleInterests,
  }) async {
    try {
      User? user = _auth.currentUser;
      if (user == null) {
        print('No authenticated user found');
        return false;
      }

      await _firestore
          .collection('user_preferences')
          .doc(user.uid)
          .set({
        'dietary_preferences': dietaryPreferences,
        'lifestyle_interests': lifestyleInterests,
        'updated_at': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      print('Preferences saved successfully for ${user.uid}');
      return true;
    } catch (e) {
      print('Error saving user preferences: $e');
      return false;
    }
  }

  // Get products filtered by preferences (or shuffled if no preferences)
  Future<List<Map<String, dynamic>>> getFilteredProducts() async {
    try {
      // Get user preferences
      Map<String, dynamic>? prefs = await getUserPreferences();

      // Fetch all products from Firestore
      QuerySnapshot productsSnapshot = await _firestore
          .collection('products')
          .get();

      List<Map<String, dynamic>> allProducts = productsSnapshot.docs
          .map((doc) {
            Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
            return {
              'id': doc.id,
              'name': data['name'] ?? data['productName'] ?? 'Unknown Product',
              'price': (data['price'] ?? data['productPrice'] ?? 0).toDouble(),
              'rating': (data['rating'] ?? data['bestValue'] ?? 0).toDouble(),
              'category': data['category'] ?? '',
              'description': data['description'] ?? '',
              'imageUrl': data['imageUrl'] ?? data['image_url'] ?? '',
              'tags': data['tags'] ?? [],
              ...data, // Include all other fields
            };
          })
          .toList();

      print('Fetched ${allProducts.length} products from Firestore');

      // No preferences -> return all products shuffled
      if (prefs == null ||
          ((prefs['dietary_preferences']?.isEmpty ?? true) &&
              (prefs['lifestyle_interests']?.isEmpty ?? true))) {
        print('No preferences found, returning shuffled products');
        allProducts.shuffle();
        return allProducts;
      }

      List<String> dietaryPrefs =
          List<String>.from(prefs['dietary_preferences'] ?? []);
      List<String> lifestylePrefs =
          List<String>.from(prefs['lifestyle_interests'] ?? []);

      print('Filtering with dietary: $dietaryPrefs, lifestyle: $lifestylePrefs');

      // Filter products based on preferences
      List<Map<String, dynamic>> filteredProducts = allProducts.where((product) {
        String category = (product['category'] ?? '').toString().toLowerCase();
        String name = (product['name'] ?? '').toString().toLowerCase();
        List<dynamic> tags = product['tags'] ?? [];
        String allText = '$category $name ${tags.join(' ')}'.toLowerCase();

        // Exclusion rules for dietary preferences
        for (String pref in dietaryPrefs) {
          String prefLower = pref.toLowerCase();
          
          if (prefLower == 'halal' && (
              allText.contains('non-halal') || 
              allText.contains('pork') || 
              allText.contains('alcohol'))) {
            print('Excluding ${product['name']} - not halal');
            return false;
          }
          
          if (prefLower == 'non-halal' && 
              allText.contains('halal') && 
              !allText.contains('non-halal')) {
            print('Excluding ${product['name']} - halal only');
            return false;
          }
          
          if (prefLower == 'vegan' && (
              allText.contains('meat') || 
              allText.contains('chicken') || 
              allText.contains('beef') || 
              allText.contains('lamb') ||
              allText.contains('fish') ||
              allText.contains('dairy') ||
              allText.contains('egg'))) {
            print('Excluding ${product['name']} - not vegan');
            return false;
          }
          
          if (prefLower == 'vegetarian' && (
              allText.contains('meat') || 
              allText.contains('chicken') || 
              allText.contains('beef') || 
              allText.contains('lamb') ||
              allText.contains('fish'))) {
            print('Excluding ${product['name']} - not vegetarian');
            return false;
          }
          
          if (prefLower == 'gluten-free' && allText.contains('gluten')) {
            print('Excluding ${product['name']} - contains gluten');
            return false;
          }
          
          if (prefLower == 'nut-free' && (
              allText.contains('nut') || 
              allText.contains('peanut') || 
              allText.contains('almond'))) {
            print('Excluding ${product['name']} - contains nuts');
            return false;
          }
        }

        // Inclusion boost for lifestyle interests (optional - for future ranking)
        // For now, we just exclude restricted items and include everything else
        return true;
      }).toList();

      print('Filtered to ${filteredProducts.length} products');

      // Randomize order to keep it fresh
      filteredProducts.shuffle();
      
      return filteredProducts;
    } catch (e) {
      print('Error getting filtered products: $e');
      print('Stack trace: ${StackTrace.current}');
      return [];
    }
  }

  // Search products with preference-aware filtering
  Future<List<Map<String, dynamic>>> searchProducts(String query) async {
    List<Map<String, dynamic>> products = await getFilteredProducts();
    if (query.isEmpty) return products;

    String lowerQuery = query.toLowerCase();
    
    List<Map<String, dynamic>> results = products.where((product) {
      String name = (product['name'] ?? '').toLowerCase();
      String category = (product['category'] ?? '').toLowerCase();
      String description = (product['description'] ?? '').toLowerCase();
      List<dynamic> tags = product['tags'] ?? [];

      return name.contains(lowerQuery) ||
          category.contains(lowerQuery) ||
          description.contains(lowerQuery) ||
          tags.any((tag) => tag.toString().toLowerCase().contains(lowerQuery));
    }).toList();

    print('Search for "$query" returned ${results.length} results');
    return results;
  }

  // Get products by category with preference filtering
  Future<List<Map<String, dynamic>>> getProductsByCategory(String category) async {
    List<Map<String, dynamic>> products = await getFilteredProducts();
    
    if (category.isEmpty || category.toLowerCase() == 'all') {
      return products;
    }

    return products.where((product) {
      String productCategory = (product['category'] ?? '').toLowerCase();
      return productCategory.contains(category.toLowerCase());
    }).toList();
  }

  // Get user preferences summary
  Future<String> getUserPreferencesSummary() async {
    Map<String, dynamic>? prefs = await getUserPreferences();
    if (prefs == null) return 'No preferences set';

    List<String> dietary = List<String>.from(prefs['dietary_preferences'] ?? []);
    List<String> lifestyle = List<String>.from(prefs['lifestyle_interests'] ?? []);
    List<String> allPrefs = [...dietary, ...lifestyle];

    return allPrefs.isEmpty ? 'No preferences set' : allPrefs.join(', ');
  }

  // Check if user has set preferences
  Future<bool> hasPreferences() async {
    Map<String, dynamic>? prefs = await getUserPreferences();
    if (prefs == null) return false;

    List<String> dietary = List<String>.from(prefs['dietary_preferences'] ?? []);
    List<String> lifestyle = List<String>.from(prefs['lifestyle_interests'] ?? []);

    return dietary.isNotEmpty || lifestyle.isNotEmpty;
  }

  // Clear user preferences
  Future<bool> clearUserPreferences() async {
    try {
      User? user = _auth.currentUser;
      if (user == null) return false;

      await _firestore
          .collection('user_preferences')
          .doc(user.uid)
          .delete();

      print('Preferences cleared for ${user.uid}');
      return true;
    } catch (e) {
      print('Error clearing user preferences: $e');
      return false;
    }
  }
}