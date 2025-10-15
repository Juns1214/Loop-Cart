import 'package:flutter/material.dart';

class SortFilterButtons extends StatefulWidget {
  final Function(String sortType, bool ascending) onSortChanged;

  const SortFilterButtons({required this.onSortChanged, super.key});

  @override
  _SortFilterButtonsState createState() => _SortFilterButtonsState();
}

class _SortFilterButtonsState extends State<SortFilterButtons> {
  int selectedIndex = 0;
  bool ascending = true;

  final List<String> buttonLabels = ["All", "Price", "Rating", "Best Value"];

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: List.generate(buttonLabels.length, (index) {
        bool isSelected = selectedIndex == index;

        return Expanded(
          child: ElevatedButton(
            onPressed: () {
              setState(() {
                if (selectedIndex == index && index != 0) {
                  ascending = !ascending;
                } else {
                  selectedIndex = index;
                  ascending = true;
                }

                widget.onSortChanged(buttonLabels[index], ascending);
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: isSelected ? Color(0xFF008000) : Colors.white,
              foregroundColor: isSelected ? Colors.white : Colors.black,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              side: BorderSide(color: Colors.grey.shade300),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(buttonLabels[index]),
                if (isSelected && index != 0)
                  Icon(
                    ascending ? Icons.arrow_upward : Icons.arrow_downward,
                    size: 16,
                    color: isSelected ? Colors.white : Colors.black,
                  ),
              ],
            ),
          ),
        );
      }),
    );
  }
}
