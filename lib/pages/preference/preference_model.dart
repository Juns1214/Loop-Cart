import 'package:flutter/material.dart';

class Preference {
  final String name;
  final IconData icon;
  bool isSelected;

  Preference(this.name, {required this.icon, this.isSelected = false});

  void toggleSelection() => isSelected = !isSelected;

  // Static data prevents cluttering the UI files
  static List<Preference> get defaultDietaryOptions => [
    Preference('Halal', icon: Icons.mosque),
    Preference('Vegan', icon: Icons.eco),
    Preference('Gluten-Free', icon: Icons.local_dining),
    Preference('Dairy-Free', icon: Icons.no_food),
    Preference('Nut-Free', icon: Icons.no_food),
  ];

  static List<Preference> get defaultLifestyleOptions => [
    Preference('Eco-Friendly', icon: Icons.nature),
    Preference('Fitness Enthusiast', icon: Icons.fitness_center),
    Preference('Tech Savvy', icon: Icons.computer),
    Preference('Traveler', icon: Icons.flight),
    Preference('Book Lover', icon: Icons.book),
  ];
}