import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_application_1/utils/swiper.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: const OnboardingPage(),
    );
  }
}

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  List<String> pages = [];

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    pages = const [
      "assets/lottie/online shopping delivery.json",
      "assets/lottie/ecommerce online banner.json",
      "assets/lottie/Eco Friendly Animetion.json",
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(body: Swiper(pages: pages));
  }
}
