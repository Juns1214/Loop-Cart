import 'package:flutter/material.dart';

class RepairOptionSelector extends StatefulWidget {
  final Map<String, String>? initialSelection;
  final Function(Map<String, String>?) onSelectionChanged;

  const RepairOptionSelector({
    super.key,
    this.initialSelection,
    required this.onSelectionChanged,
  });

  @override
  State<RepairOptionSelector> createState() => _RepairOptionSelectorState();
}

class _RepairOptionSelectorState extends State<RepairOptionSelector> {
  final List<String> categories = [
    'Cloth / Apparel',
    'Electronic & Gadgets',
    'Furniture / Home',
    'Fitness / Sports',
    'Kitchen Appliances / Tools'
  ];

  Map<String, String>? selectedRepair;
  int? expandedCategoryIndex;

  final Map<String, List<Map<String, String>>> repairPrices = {
    'Cloth / Apparel': [
      {'Repair': 'Stitching', 'Price': 'RM15'},
      {'Repair': 'Button Replacement', 'Price': 'RM8'},
      {'Repair': 'Zipper Replacement', 'Price': 'RM20'},
      {'Repair': 'Hemming', 'Price': 'RM10'},
    ],
    'Electronic & Gadgets': [
      {'Repair': 'Screen Replacement', 'Price': 'RM200'},
      {'Repair': 'Battery Replacement', 'Price': 'RM150'},
      {'Repair': 'Charging Port Fix', 'Price': 'RM50'},
      {'Repair': 'Software Update', 'Price': 'RM30'},
    ],
    'Furniture / Home': [
      {'Repair': 'Leg Fix', 'Price': 'RM80'},
      {'Repair': 'Polish & Clean', 'Price': 'RM50'},
      {'Repair': 'Drawer Repair', 'Price': 'RM100'},
      {'Repair': 'Cushion Replace', 'Price': 'RM60'},
    ],
    'Fitness / Sports': [
      {'Repair': 'Equipment Maintenance', 'Price': 'RM90'},
      {'Repair': 'Part Replacement', 'Price': 'RM85'},
      {'Repair': 'Cleaning / Lubrication', 'Price': 'RM30'},
      {'Repair': 'Minor Fixes', 'Price': 'RM45'},
    ],
    'Kitchen Appliances / Tools': [
      {'Repair': 'Appliance Servicing', 'Price': 'RM115'},
      {'Repair': 'Part Replacement', 'Price': 'RM95'},
      {'Repair': 'Cleaning / Maintenance', 'Price': 'RM35'},
      {'Repair': 'Minor Fixes', 'Price': 'RM65'},
    ],
  };

  @override
  void initState() {
    super.initState();
    selectedRepair = widget.initialSelection;
  }

  int calculateGreenCoin(String repairPrice) {
    final matches = RegExp(r'\d+').allMatches(repairPrice);
    final numbers = matches.map((m) => int.parse(m.group(0)!)).toList();
    return numbers.isNotEmpty ? numbers.reduce((a, b) => a > b ? a : b) : 0;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Category List
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8),
          ),
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: categories.length,
            separatorBuilder: (_, __) => Divider(height: 1, color: Colors.grey.shade300),
            itemBuilder: (context, index) {
              final category = categories[index];
              final isExpanded = expandedCategoryIndex == index;

              return Column(
                children: [
                  ListTile(
                    tileColor: isExpanded ? Colors.grey[50] : Colors.white,
                    title: Text(
                      category,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    trailing: Icon(
                      isExpanded ? Icons.expand_less : Icons.expand_more,
                      color: Colors.grey[700],
                    ),
                    onTap: () {
                      setState(() {
                        expandedCategoryIndex = isExpanded ? null : index;
                      });
                    },
                  ),
                  if (isExpanded)
                    ...repairPrices[category]!.map((repair) {
                      final isSelected = repair == selectedRepair;
                      return InkWell(
                        onTap: () {
                          setState(() {
                            selectedRepair = repair;
                            widget.onSelectionChanged(repair);
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected ? Colors.blue[50] : Colors.white,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                repair['Repair']!,
                                style: TextStyle(
                                  color: isSelected
                                      ? const Color(0xFF2E5BFF)
                                      : Colors.grey[800],
                                  fontWeight: isSelected
                                      ? FontWeight.w600
                                      : FontWeight.normal,
                                ),
                              ),
                              Text(
                                repair['Price']!,
                                style: TextStyle(
                                  color: isSelected
                                      ? const Color(0xFF2E5BFF)
                                      : Colors.grey[600],
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                ],
              );
            },
          ),
        ),
        
        // Green Coin Reward Display
        if (selectedRepair != null) ...[
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF0FDF4),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFBBF7D0)),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: const BoxDecoration(
                    color: Color(0xFF22C55E),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.eco,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Earn Green Coin",
                        style: TextStyle(
                          color: Color(0xFF166534),
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "You will earn ${calculateGreenCoin(selectedRepair!['Price']!)} Green Coins for this repair service.",
                        style: const TextStyle(
                          color: Color(0xFF166534),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}