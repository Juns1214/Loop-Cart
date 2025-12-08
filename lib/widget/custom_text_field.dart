import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CustomTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hintText;
  final bool obscureText;
  final TextInputType? keyboardType;
  final String? prefixText;
  final String? Function(String?)? validator;
  final List<TextInputFormatter>? inputFormatters; // Added this
  final ValueChanged<String>? onChanged;           // Added this

  const CustomTextField({
    super.key,
    required this.controller,
    required this.label,
    required this.hintText,
    this.obscureText = false,
    this.keyboardType,
    this.prefixText,
    this.validator,
    this.inputFormatters,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Manrope',
            fontSize: 15,
            color: Color(0xFF1B5E20),
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          obscureText: obscureText,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters, // Use the parameter
          onChanged: onChanged,             // Use the parameter
          decoration: InputDecoration(
            border: const OutlineInputBorder(),
            labelText: hintText,
            prefixText: prefixText,
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
          ),
          validator: validator,
        ),
      ],
    );
  }
}