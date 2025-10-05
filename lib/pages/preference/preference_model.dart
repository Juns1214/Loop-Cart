import 'package:flutter/material.dart';

class Preference {
  final String name;
  final IconData icon;
  bool isSelected;

  Preference(this.name, {required this.icon, this.isSelected = false});

  void toggleSelection() => isSelected = !isSelected;
}
