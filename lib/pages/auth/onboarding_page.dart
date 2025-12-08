import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_application_1/utils/swiper.dart';
import '../../utils/router.dart';
import '../../widget/onboarding_content.dart'; 
import '../../widget/custom_button.dart'; 

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
      initialRoute: "/onboarding",
      onGenerateRoute: onGenerateRoute,
      home: OnboardingPage(),
    );
  }
}

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  // We can define the list directly here now
  final List<Widget> pages = const [
    OnboardingContent(
      lottiePath: 'assets/lottie/online shopping delivery.json',
      title: "Speed & Reliability Guaranteed",
      description: "Over 25 million customers enjoying same-day delivery from 500,000+ trusted merchants with 99.5% on-time",
    ),
    OnboardingContent(
      lottiePath: 'assets/lottie/ecommerce online banner.json',
      title: "Buy, Sell & Discover More",
      description: "Millions of new and secondhand items from 300,000+ trusted sellers - turn your unused items into cash today",
    ),
    OnboardingContent(
      lottiePath: 'assets/lottie/Eco Friendly Animetion.json',
      title: "Green Shopping Experience",
      description: "Supporting circular economy principles to reduce waste and promote sustainability through responsible shopping choices",
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        height: double.infinity,
        width: double.infinity,
        color: const Color(0xFFE4FEDB),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 80),
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                TextButton(
                  onPressed: () {},
                  child: const Text(
                    "Skip",
                    style: TextStyle(
                      fontFamily: 'Roboto',
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ),
              ],
            ),
            Expanded(child: Swiper(pages: pages)),
            const SizedBox(height: 40),
            
            // REPLACED: ElevatedButton with CustomButton
            CustomButton(
              text: "Next",
              onPressed: () {
                Navigator.pushReplacementNamed(context, "/login");
              },
              backgroundColor: const Color(0xFF87C159), // Your specific green
              textColor: Colors.black,
              fontFamily: 'Roboto',
              fontSize: 20,
              // Adjust padding by using minimumSize logic or keep it default
              // Your original had symmetric(horizontal: 100), let's approx that:
              minimumSize: const Size(250, 50), 
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}