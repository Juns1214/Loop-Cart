import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lottie/lottie.dart';

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
      home: const GetStartedPage(),
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
              'assets/images/LogoIcon.png',
              width: 150,
              height: 200,
            ),

            const SizedBox(height: 20),

            Text( 
              "Shop Smart,\nLoop Forever.",
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

            ElevatedButton(
              onPressed: () {
                
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF7CB342),
                minimumSize: Size(200, 50),
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              child: const Text(
                "Get Started",
                style: TextStyle(
                  fontFamily: 'AbhayaLibre',
                  fontSize: 30, 
                  color: Color(0xFF1B5E20), 
                  fontWeight: FontWeight.w500),
              ),
            )

          ],
        ),
      ),
    );
  }
}