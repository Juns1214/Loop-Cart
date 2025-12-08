import 'package:flutter/material.dart';
import 'preference_model.dart';

class PreferenceTile extends StatelessWidget {
  final Preference preference;
  final VoidCallback onTap;

  const PreferenceTile({
    super.key,
    required this.preference,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = preference.isSelected;
    // Using the Green theme from your CustomButton (0xFF388E3C)
    final themeColor = const Color(0xFF388E3C);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: isSelected ? themeColor : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            // Use theme color for border when selected, grey when not
            color: isSelected ? themeColor : Colors.grey[300]!,
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(2, 2),
            ),
          ],
        ),
        child: Stack(
          children: [
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    preference.icon,
                    color: isSelected ? Colors.white : Colors.black54,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    preference.name,
                    style: TextStyle(
                      fontFamily: 'Manrope', // Added to match your app font
                      color: isSelected ? Colors.white : Colors.black,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Positioned(
                top: 8,
                right: 8,
                child: Icon(Icons.check_circle, color: Colors.white, size: 18),
              ),
          ],
        ),
      ),
    );
  }
}