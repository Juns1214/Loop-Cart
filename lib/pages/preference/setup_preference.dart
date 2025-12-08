import 'package:flutter/material.dart';
import 'preference_tile.dart';
import 'preference_model.dart';
import 'preference_service.dart'; // Import your service
import '../../widget/custom_button.dart'; // Import your custom button

// Removed 'main' and 'MyApp' - this file should just be the Page widget.

class SetupPreferencePage extends StatefulWidget {
  const SetupPreferencePage({super.key});

  @override
  State<SetupPreferencePage> createState() => _SetupPreferencePageState();
}

class _SetupPreferencePageState extends State<SetupPreferencePage> {
  final PreferenceService _preferenceService = PreferenceService();
  bool _isLoading = false;

  // Load data from Model
  late final List<Preference> dietaryPreferences = Preference.defaultDietaryOptions;
  late final List<Preference> lifestyleChoices = Preference.defaultLifestyleOptions;

  Future<void> _handleSave() async {
    setState(() => _isLoading = true);

    // Extract selected names
    final selectedDietary = dietaryPreferences
        .where((p) => p.isSelected).map((p) => p.name).toList();
    
    final selectedLifestyle = lifestyleChoices
        .where((p) => p.isSelected).map((p) => p.name).toList();

    // Use the Service - Don't write Firestore logic in UI!
    final success = await _preferenceService.saveUserPreferences(
      dietaryPreferences: selectedDietary,
      lifestyleInterests: selectedLifestyle,
    );

    if (mounted) {
      setState(() => _isLoading = false);
      
      if (success) {
        Navigator.pushNamedAndRemoveUntil(context, "/mainpage", (route) => false);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error saving preferences'), backgroundColor: Colors.red),
        );
      }
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
                const SizedBox(height: 40), // Safe area spacing
                Center(
                  child: Image.asset(
                    'assets/images/icon/LogoIcon.png',
                    height: 80,
                    width: 80,
                    fit: BoxFit.contain,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Set Up Your Preferences',
                  style: TextStyle(
                    fontFamily: 'Manrope',
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Help us personalize your shopping experience by selecting your dietary and lifestyle/ interests preferences.',
                  style: TextStyle(
                    fontFamily: 'Manrope',
                    fontSize: 15,
                    color: Color(0xFF1B5E20),
                  ),
                ),
                const SizedBox(height: 20),
                
                _buildSection('Dietary Preferences', dietaryPreferences),
                const SizedBox(height: 24),
                _buildSection('Lifestyle/ Interests', lifestyleChoices),
                
                const SizedBox(height: 30),
                
                // Refactored: Using CustomButton to reduce code and maintain consistency
                Center(
                  child: CustomButton(
                    text: 'Continue',
                    onPressed: _handleSave,
                    minimumSize: const Size.fromHeight(48),
                    // If you want to show loading indicator inside button, CustomButton needs an update, 
                    // otherwise, the Stack overlay handles the UI blocking.
                  ),
                ),
                
                const SizedBox(height: 10),
                Center(
                  child: TextButton(
                    onPressed: _isLoading ? null : () => 
                      Navigator.pushNamedAndRemoveUntil(context, "/mainpage", (r) => false),
                    child: const Text(
                      'Skip',
                      style: TextStyle(fontFamily: 'Manrope', fontSize: 15, color: Color(0xFF1B5E20)),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
          
          if (_isLoading)
            Container(
              color: Colors.black12, // Lighter overlay
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }

  Widget _buildSection(String title, List<Preference> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontFamily: 'Manrope',
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 10),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 2.6,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: items.length,
          itemBuilder: (context, index) {
            final item = items[index];
            // Note: In a stateless widget list, we need to rebuild the state on tap.
            return PreferenceTile(
              preference: item,
              onTap: () => setState(() => item.toggleSelection()),
            );
          },
        ),
      ],
    );
  }
}