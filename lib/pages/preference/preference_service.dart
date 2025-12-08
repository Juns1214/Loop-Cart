import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PreferenceService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;


  Future<bool> saveUserPreferences({
    required List<String> dietaryPreferences,
    required List<String> lifestyleInterests,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      await _firestore.collection('user_preferences').doc(user.uid).set({
        'user_id': user.uid, 
        'dietary_preferences': dietaryPreferences,
        'lifestyle_interests': lifestyleInterests,
        'updated_at': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      return true;
    } catch (e) {
      print('Error saving preferences: $e');
      return false;
    }
  }

  Future<Map<String, dynamic>?> getUserPreferences() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return null;

      final doc = await _firestore.collection('user_preferences').doc(user.uid).get();
      return doc.exists ? doc.data() : null;
    } catch (e) {
      print('Error fetching preferences: $e');
      return null;
    }
  }


  Future<List<Map<String, dynamic>>> getFilteredProducts() async {
    try {
      final prefs = await getUserPreferences();
      final productsSnapshot = await _firestore.collection('products').get();
      
      // Normalize product data immediately
      var allProducts = productsSnapshot.docs.map((doc) => _normalizeProductData(doc)).toList();

      // If no preferences, just return shuffled list
      if (prefs == null || _arePreferencesEmpty(prefs)) {
        allProducts.shuffle();
        return allProducts;
      }

      final dietary = List<String>.from(prefs['dietary_preferences'] ?? []);
      
      // Filter logic
      var filteredProducts = allProducts.where((product) {
        return _isProductAllowed(product, dietary);
      }).toList();

      filteredProducts.shuffle();
      return filteredProducts;
    } catch (e) {
      print('Error filtering products: $e');
      return [];
    }
  }

  // --- Helper Methods (Private) ---

  // Standardize product data structure
  Map<String, dynamic> _normalizeProductData(QueryDocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return {
      'id': doc.id,
      'name': data['name'] ?? data['productName'] ?? 'Unknown',
      'category': (data['category'] ?? '').toString().toLowerCase(),
      'tags': data['tags'] ?? [],
      'searchText': _generateSearchText(data),
      ...data,
    };
  }

  // Combine text fields for easier searching/filtering
  String _generateSearchText(Map<String, dynamic> data) {
    final name = (data['name'] ?? data['productName'] ?? '').toString();
    final cat = (data['category'] ?? '').toString();
    final tags = (data['tags'] ?? []).join(' ');
    final desc = (data['description'] ?? '').toString();
    return '$name $cat $tags $desc'.toLowerCase();
  }

  bool _arePreferencesEmpty(Map<String, dynamic> prefs) {
    return (prefs['dietary_preferences']?.isEmpty ?? true) &&
           (prefs['lifestyle_interests']?.isEmpty ?? true);
  }

  // The core logic for checking if a product matches dietary needs
  bool _isProductAllowed(Map<String, dynamic> product, List<String> dietaryPrefs) {
    final text = product['searchText'] as String;

    for (final pref in dietaryPrefs) {
      final p = pref.toLowerCase();
      
      // Exclusion Rules
      if (p == 'halal' && (text.contains('non-halal') || text.contains('pork') || text.contains('alcohol'))) return false;
      if (p == 'non-halal' && text.contains('halal') && !text.contains('non-halal')) return false; // Strictly non-halal eater? Rare, but keeping logic.
      if (p == 'vegan' && _containsAnimalProduct(text)) return false;
      if (p == 'vegetarian' && _containsMeat(text)) return false;
      if (p == 'gluten-free' && text.contains('gluten')) return false;
      if (p == 'nut-free' && (text.contains('nut') || text.contains('peanut') || text.contains('almond'))) return false;
    }
    return true;
  }

  bool _containsAnimalProduct(String text) => 
      _containsMeat(text) || text.contains('dairy') || text.contains('egg') || text.contains('cheese');

  bool _containsMeat(String text) => 
      text.contains('meat') || text.contains('chicken') || text.contains('beef') || text.contains('lamb') || text.contains('fish');
}