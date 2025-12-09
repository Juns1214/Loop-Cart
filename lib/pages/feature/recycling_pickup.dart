import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import '../../utils/date_time_picker.dart';
import '../../utils/address_form.dart';
import '../../widget/custom_button.dart';
import '../../widget/custom_text_field.dart';
import '../../widget/image_picker_widget.dart';
import '../../widget/section_header.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) => const MaterialApp(debugShowCheckedModeBanner: false, home: RecyclingPickUpPage());
}

class RecyclingCategory {
  final String name;
  final IconData icon;
  final Color color;
  final int greenCoins;
  const RecyclingCategory({required this.name, required this.icon, required this.color, required this.greenCoins});
}

class RecyclingPickUpPage extends StatefulWidget {
  const RecyclingPickUpPage({super.key});
  @override
  State<RecyclingPickUpPage> createState() => _RecyclingPickUpPageState();
}

class _RecyclingPickUpPageState extends State<RecyclingPickUpPage> {
  final _formKey = GlobalKey<FormState>();
  final _addressFormKey = GlobalKey<AddressFormState>();
  final _descController = TextEditingController();
  
  final User? user = FirebaseAuth.instance.currentUser;
  
  // Address
  final _line1 = TextEditingController();
  final _line2 = TextEditingController();
  final _city = TextEditingController();
  final _postal = TextEditingController();
  final _state = TextEditingController();

  File? _image;
  DateTime selectedDate = DateTime.now();
  TimeOfDay selectedTime = const TimeOfDay(hour: 14, minute: 0);
  String? _selectedCategory;
  bool _isLoading = false;

  static const List<RecyclingCategory> categories = [
    RecyclingCategory(name: 'Plastic', icon: Icons.water_drop_outlined, color: Color(0xFF4CAF50), greenCoins: 15),
    RecyclingCategory(name: 'Paper', icon: Icons.description_outlined, color: Color(0xFF8D6E63), greenCoins: 10),
    RecyclingCategory(name: 'Glass', icon: Icons.wine_bar_outlined, color: Color(0xFF00BCD4), greenCoins: 20),
    RecyclingCategory(name: 'Metal', icon: Icons.recycling, color: Color(0xFF9E9E9E), greenCoins: 25),
    RecyclingCategory(name: 'Electronics', icon: Icons.devices_outlined, color: Color(0xFFFF9800), greenCoins: 30),
    RecyclingCategory(name: 'Cardboard', icon: Icons.inventory_2_outlined, color: Color(0xFF795548), greenCoins: 10),
  ];

  @override
  void initState() {
    super.initState();
    _loadUserAddress();
  }

  Future<void> _loadUserAddress() async {
    if (user == null) return;
    try {
      final doc = await FirebaseFirestore.instance.collection('user_profile').doc(user!.uid).get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        final addr = data['address'] as Map<String, dynamic>?;
        if (addr != null) {
          setState(() {
            _line1.text = addr['line1'] ?? '';
            _line2.text = addr['line2'] ?? '';
            _city.text = addr['city'] ?? '';
            _postal.text = addr['postal'] ?? '';
            _state.text = addr['state'] ?? '';
          });
        }
      }
    } catch (_) {}
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || !_addressFormKey.currentState!.validate()) return;
    if (_image == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please upload an image')));
      return;
    }
    if (_selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a category')));
      return;
    }

    setState(() => _isLoading = true);
    try {
      final bytes = await _image!.readAsBytes();
      final base64Img = base64Encode(bytes);
      final coins = categories.firstWhere((c) => c.name == _selectedCategory).greenCoins;
      final txnId = 'TXN${DateTime.now().millisecondsSinceEpoch}';

      // Record Pickup
      await FirebaseFirestore.instance.collection("recycling_record").add({
        "user_id": user?.uid,
        "description": _descController.text,
        "category": _selectedCategory,
        "image": base64Img,
        "scheduled_date": DateFormat('yyyy-MM-dd').format(selectedDate),
        "scheduled_time": selectedTime.format(context),
        "address": _addressFormKey.currentState!.getAddressData(),
        "created_at": FieldValue.serverTimestamp(),
        "greenCoinsEarned": coins,
        "transactionId": txnId,
      });

      // Update User Coins
      await FirebaseFirestore.instance.collection('user_profile').doc(user!.uid)
          .update({'greenCoins': FieldValue.increment(coins)});

      // Record Transaction
      await FirebaseFirestore.instance.collection('green_coin_transactions').doc(txnId).set({
        'transactionId': txnId,
        'userId': user!.uid,
        'amount': coins,
        'activity': 'recycling_pickup',
        'description': 'Recycling Pickup: $_selectedCategory',
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Pickup Scheduled! +$coins Coins'), backgroundColor: Colors.green));
        Navigator.pop(context);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: BackButton(color: Colors.black),
        title: const Text('Recycling Pickup', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SectionHeader(title: "Pickup Details", subtitle: "Recycle items to earn Green Coins."),
              
              const Text("Photo Evidence", style: TextStyle(fontFamily: 'Manrope', fontSize: 15, color: Color(0xFF1B5E20), fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              ImagePickerWidget(
                imageFile: _image,
                onTap: () async {
                  final f = await ImagePicker().pickImage(source: ImageSource.gallery);
                  if (f != null) setState(() => _image = File(f.path));
                },
                label: "Upload Item Photo",
              ),
              const SizedBox(height: 24),

              const Text("Category", style: TextStyle(fontFamily: 'Manrope', fontSize: 15, color: Color(0xFF1B5E20), fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: categories.map((c) {
                  final isSelected = _selectedCategory == c.name;
                  return ChoiceChip(
                    label: Text(c.name),
                    avatar: Icon(c.icon, size: 18, color: isSelected ? Colors.white : c.color),
                    selected: isSelected,
                    onSelected: (s) => setState(() => _selectedCategory = s ? c.name : null),
                    selectedColor: c.color,
                    labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.black87, fontWeight: FontWeight.w600),
                    backgroundColor: Colors.grey[100],
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),

              if (_selectedCategory != null)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: const Color(0xFFF0FDF4), borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.green.shade200)),
                  child: Row(
                    children: [
                      const Icon(Icons.eco, color: Colors.green),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          "Earn ${categories.firstWhere((c) => c.name == _selectedCategory).greenCoins} Green Coins for this item!",
                          style: const TextStyle(color: Color(0xFF1B5E20), fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),
              if (_selectedCategory != null) const SizedBox(height: 24),

              CustomTextField(
                controller: _descController,
                label: "Description (Optional)",
                hintText: "Extra details...",
                maxLines: 2,
              ),
              const SizedBox(height: 32),

              const SectionHeader(title: "Schedule & Location"),
              SyncfusionDateTimePicker(
                onDateTimeSelected: (d, t) => setState(() { selectedDate = d; selectedTime = t; }),
              ),
              const SizedBox(height: 24),
              
              AddressForm(
                key: _addressFormKey,
                line1Controller: _line1,
                line2Controller: _line2,
                cityController: _city,
                postalController: _postal,
                stateController: _state,
              ),
              const SizedBox(height: 32),

              CustomButton(
                text: "Confirm Pickup",
                onPressed: _submit,
                isLoading: _isLoading,
                backgroundColor: const Color(0xFF2E5BFF),
                minimumSize: const Size(double.infinity, 54),
              ),
            ],
          ),
        ),
      ),
    );
  }
}