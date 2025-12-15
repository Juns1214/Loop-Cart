import 'package:flutter/material.dart';

class MalaysiaStates {
  static const List<String> all = [
    'Johor',
    'Kedah',
    'Kelantan',
    'Melaka',
    'Negeri Sembilan',
    'Pahang',
    'Perak',
    'Perlis',
    'Penang',
    'Sabah',
    'Sarawak',
    'Selangor',
    'Terengganu',
    'Kuala Lumpur',
    'Labuan',
    'Putrajaya',
  ];
}

class MalaysiaStateDropdown extends StatelessWidget {
  final String? value;
  final ValueChanged<String?> onChanged;
  final String label;
  final String? Function(String?)? validator;

  const MalaysiaStateDropdown({
    super.key,
    required this.value,
    required this.onChanged,
    this.label = 'State',
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      value: value,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      items: MalaysiaStates.all.map((state) {
        return DropdownMenuItem(
          value: state,
          child: Text(state),
        );
      }).toList(),
      onChanged: onChanged,
      validator: validator ??
          (value) =>
              value == null ? 'Please select a state' : null,
    );
  }
}
