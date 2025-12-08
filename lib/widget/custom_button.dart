import 'package:flutter/material.dart';

class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  
  // Customization options (all have defaults, so you don't HAVE to pass them)
  final Color backgroundColor;
  final Color textColor;
  final double fontSize;
  final Size? minimumSize; // Pass Size(double.infinity, 50) for full width
  final String fontFamily;
  final double borderRadius;
  final bool isLoading; // Pass true to show a spinner instead of text

  const CustomButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.backgroundColor = const Color(0xFF388E3C), // Default App Green
    this.textColor = Colors.white,
    this.fontSize = 18,
    this.minimumSize, // Let Flutter decide size, or override it
    this.fontFamily = 'Manrope',
    this.borderRadius = 12.0,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: isLoading ? null : onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: backgroundColor,
        minimumSize: minimumSize ?? const Size(120, 54), // Default size if none provided
        elevation: 2,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadius),
        ),
      ),
      child: isLoading
          ? SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                color: textColor,
                strokeWidth: 2.5,
              ),
            )
          : Text(
              text,
              style: TextStyle(
                fontFamily: fontFamily,
                fontSize: fontSize,
                color: textColor,
                fontWeight: FontWeight.bold, // Bold for better readability
                letterSpacing: 0.5,
              ),
            ),
    );
  }
}