import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PreferenceService {
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  Future<Map<String, dynamic>?> getUserPreferences() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return null;

      final doc = await _firestore
          .collection('user_preferences')
          .doc(user.uid)
          .get();
      return doc.exists ? doc.data() : null;
    } catch (e) {
      return null;
    }
  }

  Future<List<Map<String, dynamic>>> getFilteredProducts() async {
    try {
      final prefs = await getUserPreferences();
      final productsSnapshot = await _firestore.collection('products').get();

      var allProducts = productsSnapshot.docs.map((doc) {
        final data = doc.data();
        final name = (data['name'] ?? data['productName'] ?? '').toString();
        final cat = (data['category'] ?? '').toString();
        final tags = (data['tags'] ?? []).join(' ');
        final desc = (data['description'] ?? '').toString();
        final searchText = '$name $cat $tags $desc'.toLowerCase();

        return {
          'id': doc.id,
          'name': name.isNotEmpty ? name : 'Unknown',
          'category': cat.toLowerCase(),
          'tags': data['tags'] ?? [],
          'searchText': searchText,
          ...data,
        };
      }).toList();

      if (prefs == null || (prefs['dietary_preferences']?.isEmpty ?? true)) {
        allProducts.shuffle();
        return allProducts;
      }

      final dietary = List<String>.from(prefs['dietary_preferences'] ?? []);

      var filteredProducts = allProducts.where((product) {
        final text = product['searchText'] as String;

        for (final pref in dietary) {
          final p = pref.toLowerCase();

          if (p == 'halal' &&
              (text.contains('non-halal') ||
                  text.contains('pork') ||
                  text.contains('alcohol')))
            return false;
          if (p == 'vegan' && _containsAnimalProduct(text)) return false;
          if (p == 'vegetarian' && _containsMeat(text)) return false;
          if (p == 'gluten-free' && text.contains('gluten')) return false;
          if (p == 'nut-free' &&
              (text.contains('nut') ||
                  text.contains('peanut') ||
                  text.contains('almond')))
            return false;
        }
        return true;
      }).toList();

      filteredProducts.shuffle();
      return filteredProducts;
    } catch (e) {
      return [];
    }
  }

  bool _containsAnimalProduct(String text) =>
      _containsMeat(text) ||
      text.contains('dairy') ||
      text.contains('egg') ||
      text.contains('cheese');

  bool _containsMeat(String text) =>
      text.contains('meat') ||
      text.contains('chicken') ||
      text.contains('beef') ||
      text.contains('lamb') ||
      text.contains('fish');
}
