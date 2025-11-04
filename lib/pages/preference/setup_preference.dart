import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'preference_tile.dart';
import '../../utils/router.dart';
import 'preference_model.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      initialRoute: "/setup-preference",
      onGenerateRoute: onGenerateRoute,
      home: const SetupPreferencePage(),
    );
  }
}

class SetupPreferencePage extends StatefulWidget {
  const SetupPreferencePage({super.key});

  @override
  State<SetupPreferencePage> createState() => _SetupPreferencePageState();
}

class _SetupPreferencePageState extends State<SetupPreferencePage> {
  bool _isLoading = false;

  List<Preference> dietaryPreferences = [
    Preference('Halal', icon: Icons.mosque),
    Preference('Vegan', icon: Icons.eco),
    Preference('Gluten-Free', icon: Icons.local_dining),
    Preference('Dairy-Free', icon: Icons.no_food),
    Preference('Nut-Free', icon: Icons.no_food),
  ];

  List<Preference> lifestyleChoices = [
    Preference('Eco-Friendly', icon: Icons.nature),
    Preference('Fitness Enthusiast', icon: Icons.fitness_center),
    Preference('Tech Savvy', icon: Icons.computer),
    Preference('Traveler', icon: Icons.flight),
    Preference('Book Lover', icon: Icons.book),
  ];

  Future<void> _savePreferences() async {
    setState(() => _isLoading = true);

    try {
      // Get current user ID
      final userId = FirebaseAuth.instance.currentUser?.uid;

      if (userId == null) {
        throw Exception('User not logged in');
      }

      // Get selected preferences
      final selectedDietary = dietaryPreferences
          .where((pref) => pref.isSelected)
          .map((pref) => pref.name)
          .toList();

      final selectedLifestyle = lifestyleChoices
          .where((pref) => pref.isSelected)
          .map((pref) => pref.name)
          .toList();

      // Save to Firestore
      await FirebaseFirestore.instance
          .collection('user_preferences')
          .doc(userId)
          .set({
            'user_id': userId,
            'dietary_preferences': selectedDietary,
            'lifestyle_interests': selectedLifestyle,
            'updated_at': FieldValue.serverTimestamp(),
          });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Preferences saved successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pushNamedAndRemoveUntil(
          context,
          "/mainpage",
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving preferences: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
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
                Center(
                  child: Image.asset(
                    'assets/images/icon/LogoIcon.png',
                    height: 80,
                    width: 80,
                    fit: BoxFit.fill,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Set Up Your Preferences',
                  style: TextStyle(
                    fontFamily: 'Manrope',
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Help us personalize your shopping experience by selecting your dietary and lifestyle/ interests preferences.',
                  style: TextStyle(
                    fontFamily: 'Manrope',
                    fontSize: 15,
                    color: Color(0xFF1B5E20),
                  ),
                ),
                const SizedBox(height: 20),
                _buildPreferenceSection(
                  'Dietary Preferences',
                  dietaryPreferences,
                ),
                const SizedBox(height: 24),
                _buildPreferenceSection(
                  'Lifestyle/ Interests',
                  lifestyleChoices,
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _isLoading ? null : _savePreferences,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF388E3C),
                    minimumSize: const Size.fromHeight(48),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'Continue',
                          style: TextStyle(
                            fontFamily: 'Manrope',
                            fontSize: 15,
                            color: Colors.white,
                          ),
                        ),
                ),
                Center(
                  child: TextButton(
                    onPressed: _isLoading
                        ? null
                        : () {
                            Navigator.pushNamedAndRemoveUntil(
                              context,
                              "/mainpage",
                              (route) => false,
                            );
                          },
                    child: const Text(
                      'Skip',
                      style: TextStyle(
                        fontFamily: 'Manrope',
                        fontSize: 15,
                        color: Color(0xFF1B5E20),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.3),
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }

  Widget _buildPreferenceSection(String title, List<Preference> preferences) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
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
          itemCount: preferences.length,
          itemBuilder: (context, index) {
            final preference = preferences[index];
            return PreferenceTile(
              preference: preference,
              onTap: () => setState(() => preference.toggleSelection()),
            );
          },
        ),
      ],
    );
  }
}
