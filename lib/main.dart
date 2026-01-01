import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lottie/lottie.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_application_1/utils/firebase_options.dart';
import 'utils/router.dart';
import 'widget/custom_button.dart';

void main() async {
  //Ensures Flutter is ready before running code
  WidgetsFlutterBinding.ensureInitialized();
  //Initializes Firebase services uses the Firebase config for your platform
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  //Hides the system UI (status bar & navigation bar) for full-screen mode
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      initialRoute: "/start",
      onGenerateRoute: onGenerateRoute,
      home: GetStartedPage(),
    );
  }
}

class GetStartedPage extends StatelessWidget {
  const GetStartedPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE4FEDB),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/images/icon/LogoIcon.png',
              height: 150,
              width: 150,
              fit: BoxFit.contain,
            ),

            const SizedBox(height: 20),

            const Text(
              "Shop Smart,\nLoop Forever.",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'AbhayaLibre',
                fontSize: 45,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1B5E20),
              ),
            ),

            const SizedBox(height: 10),

            Lottie.asset(
              'assets/lottie/Shopping Green.json',
              width: 300,
              height: 400,
              fit: BoxFit.fill,
              repeat: true,
              animate: true,
            ),

            const SizedBox(height: 20),

            CustomButton(
              text: "Get Started",
              onPressed: () {
                Navigator.pushReplacementNamed(context, "/onboarding");
              },
              backgroundColor: const Color(0xFF7CB342),
              textColor: const Color(0xFF1B5E20),
              fontFamily: 'AbhayaLibre',
              fontSize: 30,
              minimumSize: const Size(200, 50),
            ),
          ],
        ),
      ),
    );
  }
}