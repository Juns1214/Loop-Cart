import 'package:flutter/material.dart';

class SearchBarWithFilter extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback? onClear;
  final VoidCallback? onFilterTap;
  final String hintText;

  const SearchBarWithFilter({
    super.key,
    required this.controller,
    required this.onChanged,
    this.onClear,
    this.onFilterTap,
    this.hintText = 'Search...',
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: _buildSearchBar()),
        
        if (onFilterTap != null) ...[
          const SizedBox(width: 8),
          _buildFilterButton(),
        ],
      ],
    );
  }

  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(8),
      ),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        style: const TextStyle(
          color: Colors.black87,
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: TextStyle(
            color: Colors.grey.shade900,
            fontSize: 15,
            fontWeight: FontWeight.bold,
          ),
          prefixIcon: Icon(Icons.search, color: Colors.grey.shade700),
          suffixIcon: controller.text.isNotEmpty
              ? IconButton(
                  icon: Icon(Icons.clear, color: Colors.grey.shade700),
                  onPressed: onClear,
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
        ),
      ),
    );
  }

  Widget _buildFilterButton() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(8),
      ),
      child: IconButton(
        onPressed: onFilterTap,
        icon: Icon(Icons.tune, color: Colors.grey.shade800),
        tooltip: 'Filter',
      ),
    );
  }
}