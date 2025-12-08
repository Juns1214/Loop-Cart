import 'package:flutter/material.dart';

class SocialSignInButton extends StatelessWidget {
  final String iconPath;
  final VoidCallback onTap;
  final double size;

  const SocialSignInButton({
    super.key,
    required this.iconPath,
    required this.onTap,
    this.size = 40,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      customBorder: const CircleBorder(),
      child: Container(
        height: size,
        width: size,
        decoration: BoxDecoration(
          color: Colors.grey[200],
          shape: BoxShape.circle,
        ),
        child: Center(
          child: Image.asset(
            iconPath,
            height: size * 0.75,
            width: size * 0.75,
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }
}