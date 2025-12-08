import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class OnboardingContent extends StatelessWidget {
  final String lottiePath;
  final String title;
  final String description;

  const OnboardingContent({
    super.key,
    required this.lottiePath,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Lottie.asset(
            lottiePath,
            width: 350,
            height: 450,
            fit: BoxFit.fill,
            repeat: true,
            animate: true,
          ),
          const SizedBox(height: 20),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'Roboto',
              fontSize: 25,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            description,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'Roboto',
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF424242),
            ),
          ),
        ],
      ),
    );
  }
}