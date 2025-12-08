import 'package:flutter/material.dart';

class LogoWidget extends StatelessWidget {
  final double size;

  const LogoWidget({
    super.key,
    this.size = 150,
  });

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/images/icon/LogoIcon.png',
      height: size,
      width: size,
      fit: BoxFit.contain,
    );
  }
}