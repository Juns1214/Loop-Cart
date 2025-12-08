import 'package:flutter/material.dart';

class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final Color? backgroundColor;
  final Color? textColor;
  final double? fontSize;
  final Size? minimumSize;
  final String? fontFamily; // Added this

  const CustomButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.backgroundColor = const Color(0xFF388E3C),
    this.textColor = Colors.white,
    this.fontSize = 20,
    this.minimumSize = const Size(250, 50),
    this.fontFamily = 'Manrope', // Default value
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: backgroundColor,
        minimumSize: minimumSize,
        padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30),
        ),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontFamily: fontFamily, // Use the parameter
          fontSize: fontSize,
          color: textColor,
          fontWeight: FontWeight.bold, // Added bold to match your UI
        ),
      ),
    );
  }
}