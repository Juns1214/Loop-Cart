import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'preference_model.dart';
import 'preference_tile.dart';
import '../../utils/router.dart';


void main() {
  WidgetsFlutterBinding.ensureInitialized();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
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

            _buildPreferenceSection('Dietary Preferences', dietaryPreferences),
            const SizedBox(height: 24),
            _buildPreferenceSection('Lifestyle/ Interests', lifestyleChoices),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.pushNamedAndRemoveUntil(context, "/mainpage", (route) => false);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF388E3C),
                minimumSize: const Size.fromHeight(48),
              ),
              child: const Text(
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
                onPressed: () {
                  Navigator.pushNamedAndRemoveUntil(context, "/mainpage", (route) => false);
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
