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
  static const Color _primaryGreen = Color(0xFF2E7D32);

  final List<String> _categories = [
    'Cloth / Apparel',
    'Electronic & Gadgets',
    'Furniture / Home',
    'Fitness / Sports',
    'Kitchen Appliances / Tools',
    'Custom Repair'
  ];

  final Map<String, List<Map<String, String>>> _repairPrices = {
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

  Map<String, String>? _selectedRepair;
  int? _expandedCategoryIndex;

  @override
  void initState() {
    super.initState();
    _selectedRepair = widget.initialSelection;
  }

  int _calculateGreenCoin(String repairPrice) {
    try {
      final numbers = RegExp(r'\d+').allMatches(repairPrice).map((m) => int.parse(m.group(0)!)).toList();
      return numbers.isEmpty ? 0 : numbers.reduce((a, b) => a > b ? a : b);
    } catch (e) {
      return 0;
    }
  }

  bool get _isCustomRepair => _selectedRepair?['Repair'] == 'Custom Repair';

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: BoxDecoration(border: Border.all(color: const Color(0xFFE0E0E0), width: 1.5), borderRadius: BorderRadius.circular(12), color: Colors.white),
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _categories.length,
            separatorBuilder: (_, __) => const Divider(height: 1, color: Color(0xFFE0E0E0)),
            itemBuilder: (context, index) {
              final category = _categories[index];
              if (category == 'Custom Repair') return _buildCustomRepairTile();
              return _buildCategoryTile(index, category);
            },
          ),
        ),
        if (_selectedRepair != null && !_isCustomRepair) _buildGreenCoinInfo(),
        if (_isCustomRepair) _buildCustomRepairInfo(),
      ],
    );
  }

  Widget _buildCategoryTile(int index, String category) {
    final isExpanded = _expandedCategoryIndex == index;
    return Column(
      children: [
        ListTile(
          tileColor: isExpanded ? _primaryGreen.withOpacity(0.05) : Colors.white,
          title: Text(category, style: TextStyle(fontFamily: 'Roboto', fontSize: 15, fontWeight: FontWeight.w700, color: isExpanded ? _primaryGreen : const Color(0xFF212121))),
          trailing: Icon(isExpanded ? Icons.expand_less : Icons.expand_more, color: isExpanded ? _primaryGreen : const Color(0xFF424242)),
          onTap: () => setState(() => _expandedCategoryIndex = isExpanded ? null : index),
        ),
        if (isExpanded)
          ..._repairPrices[category]!.map((repair) {
            final isSelected = repair == _selectedRepair;
            return InkWell(
              onTap: () {
                setState(() => _selectedRepair = repair);
                widget.onSelectionChanged(repair);
              },
              child: Container(
                color: isSelected ? _primaryGreen.withOpacity(0.1) : Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(repair['Repair']!, style: TextStyle(fontFamily: 'Roboto', fontSize: 14, color: isSelected ? _primaryGreen : const Color(0xFF212121), fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500)),
                    Text(repair['Price']!, style: TextStyle(fontFamily: 'Roboto', fontSize: 14, color: isSelected ? _primaryGreen : const Color(0xFF424242), fontWeight: FontWeight.w700)),
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
      tileColor: isSelected ? _primaryGreen.withOpacity(0.1) : Colors.white,
      leading: Icon(Icons.build_outlined, color: isSelected ? _primaryGreen : const Color(0xFF424242)),
      title: Text('Custom Repair', style: TextStyle(fontFamily: 'Roboto', fontSize: 15, fontWeight: isSelected ? FontWeight.w800 : FontWeight.w700, color: isSelected ? _primaryGreen : const Color(0xFF212121))),
      onTap: _showCustomRepairDialog,
    );
  }

  void _showCustomRepairDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Custom Repair Request', style: TextStyle(fontFamily: 'Roboto', fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF212121))),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Describe your repair needs', style: TextStyle(fontFamily: 'Roboto', fontSize: 15, fontWeight: FontWeight.w500, color: Color(0xFF424242))),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              maxLines: 4,
              maxLength: 200,
              style: const TextStyle(fontFamily: 'Roboto', fontSize: 15, fontWeight: FontWeight.w500, color: Color(0xFF212121)),
              decoration: InputDecoration(
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _primaryGreen, width: 2)),
                hintText: 'Enter repair details...',
                hintStyle: const TextStyle(fontFamily: 'Roboto', fontSize: 14, fontWeight: FontWeight.w500, color: Color(0xFF9E9E9E)),
                contentPadding: const EdgeInsets.all(16),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel', style: TextStyle(fontFamily: 'Roboto', fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFF424242)))),
          ElevatedButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                setState(() {
                  _selectedRepair = {'Repair': 'Custom Repair', 'Price': 'To be determined', 'Description': controller.text};
                  _expandedCategoryIndex = _categories.indexOf('Custom Repair');
                });
                widget.onSelectionChanged(_selectedRepair);
                Navigator.pop(ctx);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: _primaryGreen, padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
            child: const Text('Select', style: TextStyle(fontFamily: 'Roboto', fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildGreenCoinInfo() {
    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: const Color(0xFFE8F5E9), borderRadius: BorderRadius.circular(12), border: Border.all(color: _primaryGreen.withOpacity(0.3))),
      child: Row(
        children: [
          const Icon(Icons.eco, color: _primaryGreen, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Earn Green Coins', style: TextStyle(fontFamily: 'Roboto', fontSize: 16, fontWeight: FontWeight.w800, color: _primaryGreen)),
                Text('You will earn ${_calculateGreenCoin(_selectedRepair!['Price']!)} Green Coins (RM1 = 1 coin)', style: const TextStyle(fontFamily: 'Roboto', fontSize: 14, fontWeight: FontWeight.w600, color: _primaryGreen)),
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
      decoration: BoxDecoration(color: _primaryGreen.withOpacity(0.1), borderRadius: BorderRadius.circular(12), border: Border.all(color: _primaryGreen.withOpacity(0.3))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: const [Icon(Icons.build_circle, color: _primaryGreen), SizedBox(width: 8), Text('Custom Request Selected', style: TextStyle(fontFamily: 'Roboto', fontSize: 15, fontWeight: FontWeight.w800, color: _primaryGreen))]),
          const SizedBox(height: 8),
          Text(_selectedRepair!['Description'] ?? '', style: const TextStyle(fontFamily: 'Roboto', fontSize: 14, fontWeight: FontWeight.w500, color: Color(0xFF212121))),
        ],
      ),
    );
  }
}