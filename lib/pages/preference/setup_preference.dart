import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../widget/custom_button.dart';

class SetupPreferencePage extends StatefulWidget {
  const SetupPreferencePage({super.key});

  @override
  State<SetupPreferencePage> createState() => _SetupPreferencePageState();
}

class _SetupPreferencePageState extends State<SetupPreferencePage> {
  bool _isLoading = false;

  final List<_Preference> dietaryPreferences = [
    _Preference('Halal', icon: Icons.mosque),
    _Preference('Vegan', icon: Icons.eco),
    _Preference('Gluten-Free', icon: Icons.local_dining),
    _Preference('Dairy-Free', icon: Icons.no_food),
    _Preference('Nut-Free', icon: Icons.no_food),
  ];

  final List<_Preference> lifestyleChoices = [
    _Preference('Eco-Friendly', icon: Icons.nature),
    _Preference('Fitness Enthusiast', icon: Icons.fitness_center),
    _Preference('Tech Savvy', icon: Icons.computer),
    _Preference('Traveler', icon: Icons.flight),
    _Preference('Book Lover', icon: Icons.book),
  ];

  Future<void> _handleSave() async {
    setState(() => _isLoading = true);

    final selectedDietary = dietaryPreferences.where((p) => p.isSelected).map((p) => p.name).toList();
    final selectedLifestyle = lifestyleChoices.where((p) => p.isSelected).map((p) => p.name).toList();

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance.collection('user_preferences').doc(user.uid).set({
          'user_id': user.uid,
          'dietary_preferences': selectedDietary,
          'lifestyle_interests': selectedLifestyle,
          'updated_at': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

        if (mounted) {
          Navigator.pushNamedAndRemoveUntil(context, "/mainpage", (route) => false);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error saving preferences', style: TextStyle(fontFamily: 'Roboto', fontWeight: FontWeight.w600)), backgroundColor: Color(0xFFD32F2F)),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 40),
                Center(
                  child: Image.asset('assets/images/icon/LogoIcon.png', height: 80, width: 80, fit: BoxFit.contain),
                ),
                const SizedBox(height: 16),
                const Text('Set Up Your Preferences', style: TextStyle(fontFamily: 'Roboto', fontSize: 24, fontWeight: FontWeight.w800, color: Color(0xFF212121))),
                const SizedBox(height: 12),
                const Text('Help us personalize your shopping experience by selecting your dietary and lifestyle preferences.', style: TextStyle(fontFamily: 'Roboto', fontSize: 16, fontWeight: FontWeight.w500, color: Color(0xFF424242))),
                const SizedBox(height: 24),
                _buildSection('Dietary Preferences', dietaryPreferences),
                const SizedBox(height: 24),
                _buildSection('Lifestyle / Interests', lifestyleChoices),
                const SizedBox(height: 32),
                CustomButton(text: 'Continue', onPressed: _handleSave, minimumSize: const Size.fromHeight(48)),
                const SizedBox(height: 12),
                Center(
                  child: TextButton(
                    onPressed: _isLoading ? null : () => Navigator.pushNamedAndRemoveUntil(context, "/mainpage", (r) => false),
                    child: const Text('Skip', style: TextStyle(fontFamily: 'Roboto', fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF2E7D32))),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
          if (_isLoading) Container(color: Colors.black26, child: const Center(child: CircularProgressIndicator(color: Color(0xFF2E7D32)))),
        ],
      ),
    );
  }

  Widget _buildSection(String title, List<_Preference> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontFamily: 'Roboto', fontSize: 20, fontWeight: FontWeight.w800, color: Color(0xFF212121))),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, childAspectRatio: 2.6, crossAxisSpacing: 12, mainAxisSpacing: 12),
          itemCount: items.length,
          itemBuilder: (context, index) {
            final item = items[index];
            return _PreferenceTile(preference: item, onTap: () => setState(() => item.isSelected = !item.isSelected));
          },
        ),
      ],
    );
  }
}

// Private preference model - only used in this file
class _Preference {
  final String name;
  final IconData icon;
  bool isSelected = false;
  _Preference(this.name, {required this.icon});
}

// Private preference tile widget - only used in this file
class _PreferenceTile extends StatelessWidget {
  final _Preference preference;
  final VoidCallback onTap;

  const _PreferenceTile({required this.preference, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isSelected = preference.isSelected;
    const themeColor = Color(0xFF2E7D32);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: isSelected ? themeColor : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isSelected ? themeColor : const Color(0xFFE0E0E0), width: 1.5),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(2, 2))],
        ),
        child: Stack(
          children: [
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(preference.icon, color: isSelected ? Colors.white : const Color(0xFF212121), size: 24),
                  const SizedBox(height: 4),
                  Text(preference.name, style: TextStyle(fontFamily: 'Roboto', color: isSelected ? Colors.white : const Color(0xFF212121), fontSize: 14, fontWeight: FontWeight.w700)),
                ],
              ),
            ),
            if (isSelected) const Positioned(top: 8, right: 8, child: Icon(Icons.check_circle, color: Colors.white, size: 18)),
          ],
        ),
      ),
    );
  }
}