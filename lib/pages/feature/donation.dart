import 'package:flutter/material.dart';
import '../../widget/custom_button.dart';
import '../../widget/custom_text_field.dart';

class DonationPage extends StatefulWidget {
  const DonationPage({super.key});

  @override
  State<DonationPage> createState() => _DonationPageState();
}

class _DonationPageState extends State<DonationPage> {
  static final List<Map<String, dynamic>> _donationOptions = [
    {
      'title': 'Low-Income Families',
      'description': 'Support families in need with daily necessities.',
      'imageURL': 'assets/images/donation category/Low Income Families.jpg',
      'color': const Color(0xFFFFE0B2),
    },
    {
      'title': 'Orphanage',
      'description': 'Provide children with education and care.',
      'imageURL': 'assets/images/donation category/Orphanage.jpg',
      'color': const Color(0xFFF8BBD0),
    },
    {
      'title': 'Old Folks Home',
      'description': 'Help elderly people live comfortably.',
      'imageURL': 'assets/images/donation category/Old Folk Home.jpg',
      'color': const Color(0xFFBBDEFB),
    },
    {
      'title': 'Cancer Support',
      'description': 'Support cancer patients with treatment and care.',
      'imageURL': 'assets/images/donation category/NCSM-Logo.png',
      'color': const Color(0xFFFFCDD2),
    },
    {
      'title': 'Wildlife Protection',
      'description': 'Protect endangered animals and their habitat.',
      'imageURL': 'assets/images/donation category/WWF.png',
      'color': const Color(0xFFC8E6C9),
    },
    {
      'title': 'Environment & Pollution',
      'description': 'Support projects that protect the environment.',
      'imageURL': 'assets/images/donation category/CETDEM.png',
      'color': const Color(0xFFB2DFDB),
    },
  ];

  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();

  int? selectedCategoryIndex;
  int? selectedPresetAmount;
  final List<int> _presets = [10, 25, 50, 100, 150, 200];

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  void _onPresetTap(int amount) {
    setState(() {
      selectedPresetAmount = amount;
      _amountController.text = amount.toString();
    });
  }

  void _handleProceed() {
    if (_formKey.currentState!.validate() && selectedCategoryIndex != null) {
      Navigator.pushNamed(context, '/payment', arguments: {
        'amount': double.parse(_amountController.text),
        'category': _donationOptions[selectedCategoryIndex!]['title'],
      });
    } else if (selectedCategoryIndex == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a cause', style: TextStyle(fontFamily: 'Roboto', fontWeight: FontWeight.w600)),
          backgroundColor: Color(0xFFD32F2F),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final double amountVal = double.tryParse(_amountController.text) ?? 0;
    final int greenCoins = amountVal.floor();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF212121), size: 22),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Donation', style: TextStyle(fontFamily: 'Roboto', fontWeight: FontWeight.w800, fontSize: 22, color: Color(0xFF212121))),
        centerTitle: true,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: RichText(
                  textAlign: TextAlign.center,
                  text: const TextSpan(
                    style: TextStyle(fontSize: 26, fontFamily: 'Roboto'),
                    children: [
                      TextSpan(text: "Help us ", style: TextStyle(color: Color(0xFF212121), fontWeight: FontWeight.w800)),
                      TextSpan(text: "make a difference", style: TextStyle(color: Color(0xFF2E7D32), fontWeight: FontWeight.w800)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 30),
              const Text("Select Cause", style: TextStyle(fontFamily: 'Roboto', fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF1B5E20))),
              const SizedBox(height: 12),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _donationOptions.length,
                itemBuilder: (context, index) {
                  final opt = _donationOptions[index];
                  final isSel = selectedCategoryIndex == index;
                  return _DonationCategoryCard(
                    title: opt['title'],
                    description: opt['description'],
                    imageURL: opt['imageURL'],
                    color: opt['color'],
                    isSelected: isSel,
                    onTap: () => setState(() => selectedCategoryIndex = index),
                  );
                },
              ),
              const SizedBox(height: 24),
              CustomTextField(
                controller: _amountController,
                label: "Donation Amount",
                hintText: "Enter amount",
                prefixText: "RM ",
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                onChanged: (val) => setState(() => selectedPresetAmount = null),
                validator: (v) {
                  if (v == null || v.isEmpty) return "Enter amount";
                  if ((double.tryParse(v) ?? 0) < 1) return "Minimum RM 1";
                  return null;
                },
              ),
              const SizedBox(height: 16),
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 3,
                childAspectRatio: 2.2,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                children: _presets.map((amt) {
                  final isSel = selectedPresetAmount == amt;
                  return _PresetAmountButton(amount: amt, isSelected: isSel, onTap: () => _onPresetTap(amt));
                }).toList(),
              ),
              const SizedBox(height: 24),
              if (amountVal > 0) _RewardsSummary(greenCoins: greenCoins),
              const SizedBox(height: 32),
              CustomButton(
                text: "Proceed to Payment",
                backgroundColor: const Color(0xFF2E7D32),
                minimumSize: const Size(double.infinity, 56),
                borderRadius: 16,
                onPressed: _handleProceed,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DonationCategoryCard extends StatelessWidget {
  final String title, description, imageURL;
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  const _DonationCategoryCard({
    required this.title,
    required this.description,
    required this.imageURL,
    required this.color,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: isSelected ? const Color(0xFF2E7D32) : Colors.transparent, width: 3),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(isSelected ? 0.1 : 0.04), blurRadius: 8, offset: const Offset(0, 2)),
          ],
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.asset(imageURL, width: 56, height: 56, fit: BoxFit.cover),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontFamily: 'Roboto', fontWeight: FontWeight.w800, fontSize: 16, color: Color(0xFF212121))),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontFamily: 'Roboto', color: Color(0xFF424242), fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(color: Color(0xFF2E7D32), shape: BoxShape.circle),
                child: const Icon(Icons.check, color: Colors.white, size: 18),
              ),
          ],
        ),
      ),
    );
  }
}

class _PresetAmountButton extends StatelessWidget {
  final int amount;
  final bool isSelected;
  final VoidCallback onTap;

  const _PresetAmountButton({required this.amount, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: isSelected ? const Color(0xFF2E7D32) : Colors.white,
        foregroundColor: isSelected ? Colors.white : const Color(0xFF2E7D32),
        elevation: 0,
        side: BorderSide(color: const Color(0xFF2E7D32), width: isSelected ? 2 : 1.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      child: Text("RM $amount", style: TextStyle(fontFamily: 'Roboto', fontWeight: isSelected ? FontWeight.w800 : FontWeight.w700, fontSize: 15)),
    );
  }
}

class _RewardsSummary extends StatelessWidget {
  final int greenCoins;

  const _RewardsSummary({required this.greenCoins});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFFE8F5E9), Color(0xFFC8E6C9)]),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF66BB6A), width: 2),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
            child: const Icon(Icons.eco, color: Color(0xFF2E7D32), size: 24),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Rewards", style: TextStyle(fontFamily: 'Roboto', color: Color(0xFF1B5E20), fontWeight: FontWeight.w800, fontSize: 16)),
                SizedBox(height: 2),
                Text("RM1 = 1 Green Coin", style: TextStyle(fontFamily: 'Roboto', fontSize: 13, color: Color(0xFF424242), fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          Text("+$greenCoins", style: const TextStyle(fontFamily: 'Roboto', color: Color(0xFF1B5E20), fontSize: 28, fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}