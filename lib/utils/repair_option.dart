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
    'Cloth / Apparel', 'Electronic & Gadgets', 'Furniture / Home', 
    'Fitness / Sports', 'Kitchen Appliances / Tools', 'Custom Repair'
  ];

  Map<String, String>? selectedRepair;
  int? expandedCategoryIndex;
  
  // Static data map
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
    try {
      final numbers = RegExp(r'\d+').allMatches(repairPrice)
          .map((m) => int.parse(m.group(0)!)).toList();
      return numbers.isEmpty ? 0 : numbers.reduce((a, b) => a > b ? a : b);
    } catch (e) {
      return 0;
    }
  }

  bool get _isCustomRepair => selectedRepair?['Repair'] == 'Custom Repair';

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(12),
            color: Colors.white,
          ),
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: categories.length,
            separatorBuilder: (_, __) => Divider(height: 1, color: Colors.grey.shade200),
            itemBuilder: (context, index) {
              final category = categories[index];
              if (category == 'Custom Repair') return _buildCustomRepairTile();
              return _buildCategoryTile(index, category);
            },
          ),
        ),
        if (selectedRepair != null && !_isCustomRepair) _buildGreenCoinInfo(),
        if (_isCustomRepair) _buildCustomRepairInfo(),
      ],
    );
  }

  Widget _buildCategoryTile(int index, String category) {
    final isExpanded = expandedCategoryIndex == index;
    return Column(
      children: [
        ListTile(
          tileColor: isExpanded ? Colors.grey[50] : Colors.white,
          title: Text(category, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.black87)),
          trailing: Icon(isExpanded ? Icons.expand_less : Icons.expand_more, color: Colors.grey[700]),
          onTap: () => setState(() => expandedCategoryIndex = isExpanded ? null : index),
        ),
        if (isExpanded)
          ...repairPrices[category]!.map((repair) {
            final isSelected = repair == selectedRepair;
            return InkWell(
              onTap: () {
                setState(() => selectedRepair = repair);
                widget.onSelectionChanged(repair);
              },
              child: Container(
                color: isSelected ? const Color(0xFFE3F2FD) : Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(repair['Repair']!, style: TextStyle(color: isSelected ? const Color(0xFF2E5BFF) : Colors.black87, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
                    Text(repair['Price']!, style: TextStyle(color: isSelected ? const Color(0xFF2E5BFF) : Colors.black87, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            );
          }),
      ],
    );
  }

  Widget _buildCustomRepairTile() {
    final isSelected = _isCustomRepair;
    return ListTile(
      tileColor: isSelected ? const Color(0xFFE3F2FD) : Colors.white,
      leading: Icon(Icons.build_outlined, color: isSelected ? const Color(0xFF2E5BFF) : Colors.grey[700]),
      title: Text('Custom Repair', style: TextStyle(fontSize: 15, fontWeight: isSelected ? FontWeight.bold : FontWeight.w600, color: isSelected ? const Color(0xFF2E5BFF) : Colors.black87)),
      trailing: isSelected ? const Icon(Icons.check_circle, color: Color(0xFF2E5BFF)) : null,
      onTap: _showCustomRepairDialog,
    );
  }

  void _showCustomRepairDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Custom Repair Request', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Describe your repair needs:', style: TextStyle(fontWeight: FontWeight.w500)),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              maxLines: 4,
              maxLength: 200,
              decoration: InputDecoration(
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                hintText: 'Enter repair details...',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                setState(() {
                  selectedRepair = {
                    'Repair': 'Custom Repair',
                    'Price': 'To be determined',
                    'Description': controller.text,
                  };
                  expandedCategoryIndex = categories.indexOf('Custom Repair');
                });
                widget.onSelectionChanged(selectedRepair);
                Navigator.pop(ctx);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2E5BFF)),
            child: const Text('Select', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildGreenCoinInfo() {
    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFBBF7D0)),
      ),
      child: Row(
        children: [
          const Icon(Icons.eco, color: Color(0xFF22C55E), size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Earn Green Coins", style: TextStyle(color: Color(0xFF166534), fontSize: 16, fontWeight: FontWeight.bold)),
                Text("You will earn ${calculateGreenCoin(selectedRepair!['Price']!)} Green Coins (RM1 = 1 coin).", style: const TextStyle(color: Color(0xFF166534), fontSize: 14)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomRepairInfo() {
    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFE3F2FD),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF90CAF9)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(children: [
            Icon(Icons.build_circle, color: Color(0xFF2E5BFF)),
            SizedBox(width: 8),
            Text('Custom Request Selected', style: TextStyle(color: Color(0xFF2E5BFF), fontWeight: FontWeight.bold)),
          ]),
          const SizedBox(height: 8),
          Text(selectedRepair!['Description'] ?? '', style: const TextStyle(color: Colors.black87)),
        ],
      ),
    );
  }
}