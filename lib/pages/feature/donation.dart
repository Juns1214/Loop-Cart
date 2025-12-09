import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../utils/donation_data.dart';
//import '../../utils/router.dart';
import '../../widget/custom_button.dart';
import '../../widget/custom_text_field.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) => const MaterialApp(debugShowCheckedModeBanner: false, home: DonationPage());
}

class DonationPage extends StatefulWidget {
  const DonationPage({super.key});
  @override
  State<DonationPage> createState() => _DonationPageState();
}

class _DonationPageState extends State<DonationPage> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();

  int? selectedCategoryIndex;
  int? selectedPresetAmount;
  final List<int> presets = [10, 25, 50, 100, 150, 200];

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

  @override
  Widget build(BuildContext context) {
    final double amountVal = double.tryParse(_amountController.text) ?? 0;
    final int greenCoins = amountVal.floor();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        leading: BackButton(color: Colors.black),
        title: const Text('Donation', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
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
                    style: TextStyle(fontSize: 22, fontFamily: 'Manrope'),
                    children: [
                      TextSpan(text: "Help us ", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                      TextSpan(text: "save ", style: TextStyle(color: Color(0xFF2E5BFF), fontWeight: FontWeight.bold)),
                      TextSpan(text: "the world", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 30),

              const Text("Select Cause", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1B5E20))),
              const SizedBox(height: 12),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: donationOptions.length,
                itemBuilder: (context, index) {
                  final opt = donationOptions[index];
                  final isSel = selectedCategoryIndex == index;
                  return GestureDetector(
                    onTap: () => setState(() => selectedCategoryIndex = index),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: opt['color'],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: isSel ? const Color(0xFF2E5BFF) : Colors.transparent, width: 2),
                      ),
                      child: Row(
                        children: [
                          ClipOval(child: Image.asset(opt['imageURL'], width: 50, height: 50, fit: BoxFit.cover)),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(opt['title'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87)),
                                Text(opt['description'], maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: Colors.grey[700], fontSize: 12)),
                              ],
                            ),
                          ),
                          if (isSel) const Icon(Icons.check_circle, color: Color(0xFF2E5BFF)),
                        ],
                      ),
                    ),
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
                  if ((double.tryParse(v) ?? 0) < 1) return "Min RM 1";
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
                children: presets.map((amt) {
                  final isSel = selectedPresetAmount == amt;
                  return ElevatedButton(
                    onPressed: () => _onPresetTap(amt),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isSel ? const Color(0xFF2E5BFF) : Colors.white,
                      foregroundColor: isSel ? Colors.white : const Color(0xFF2E5BFF),
                      elevation: 0,
                      side: const BorderSide(color: Color(0xFF2E5BFF)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: Text("RM $amt", style: const TextStyle(fontWeight: FontWeight.bold)),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),

              if (amountVal > 0)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0FDF4),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.green.shade200),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Rewards", style: TextStyle(color: Color(0xFF1B5E20), fontWeight: FontWeight.bold)),
                          Text("RM1 = 1 Green Coin", style: TextStyle(fontSize: 12, color: Colors.black54)),
                        ],
                      ),
                      Text("+$greenCoins Coins", style: const TextStyle(color: Color(0xFF1B5E20), fontSize: 20, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              const SizedBox(height: 32),

              CustomButton(
                text: "Proceed to Payment",
                backgroundColor: const Color(0xFF2E5BFF),
                minimumSize: const Size(double.infinity, 54),
                onPressed: () {
                  if (_formKey.currentState!.validate() && selectedCategoryIndex != null) {
                    Navigator.pushNamed(context, '/payment', arguments: {
                      'amount': double.parse(_amountController.text),
                      'category': donationOptions[selectedCategoryIndex!]['title'],
                    });
                  } else if (selectedCategoryIndex == null) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please select a cause")));
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}