import 'package:flutter/material.dart';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../../utils/date_time_picker.dart';
import '../../utils/address_form.dart';
import '../../widget/custom_button.dart';
import '../../widget/custom_text_field.dart';

class RecyclingPickUpPage extends StatefulWidget {
  const RecyclingPickUpPage({super.key});
  @override
  State<RecyclingPickUpPage> createState() => _RecyclingPickUpPageState();
}

class _RecyclingPickUpPageState extends State<RecyclingPickUpPage> {
  final _formKey = GlobalKey<FormState>();
  final _addressFormKey = GlobalKey<AddressFormState>();
  final _descController = TextEditingController();
  final _line1Controller = TextEditingController();
  final _line2Controller = TextEditingController();
  final _cityController = TextEditingController();
  final _postalController = TextEditingController();

  final User? user = FirebaseAuth.instance.currentUser;
  static const Color _primaryGreen = Color(0xFF2E7D32);

  File? _imageFile;
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = const TimeOfDay(hour: 14, minute: 0);
  String? _selectedCategory;
  String? _selectedState;
  bool _isLoading = false;

  static const List<_Category> _categories = [
    _Category(name: 'Plastic', icon: Icons.water_drop_outlined, color: Color(0xFF4CAF50), coins: 15),
    _Category(name: 'Paper', icon: Icons.description_outlined, color: Color(0xFF8D6E63), coins: 10),
    _Category(name: 'Glass', icon: Icons.wine_bar_outlined, color: Color(0xFF00BCD4), coins: 20),
    _Category(name: 'Metal', icon: Icons.recycling, color: Color(0xFF9E9E9E), coins: 25),
    _Category(name: 'Electronics', icon: Icons.devices_outlined, color: Color(0xFFFF9800), coins: 30),
    _Category(name: 'Cardboard', icon: Icons.inventory_2_outlined, color: Color(0xFF795548), coins: 10),
  ];

  @override
  void initState() {
    super.initState();
    _loadUserAddress();
  }

  @override
  void dispose() {
    _descController.dispose();
    _line1Controller.dispose();
    _line2Controller.dispose();
    _cityController.dispose();
    _postalController.dispose();
    super.dispose();
  }

  Future<void> _loadUserAddress() async {
    if (user == null) return;
    try {
      final doc = await FirebaseFirestore.instance.collection('user_profile').doc(user!.uid).get();
      if (doc.exists && mounted) {
        final addr = doc.data()?['address'] as Map<String, dynamic>?;
        if (addr != null) {
          setState(() {
            _line1Controller.text = addr['line1'] ?? '';
            _line2Controller.text = addr['line2'] ?? '';
            _cityController.text = addr['city'] ?? '';
            _postalController.text = addr['postal'] ?? '';
            _selectedState = addr['state'];
          });
        }
      }
    } catch (_) {}
  }

  Future<void> _pickImage() async {
    try {
      final picker = ImagePicker();
      final image = await picker.pickImage(source: ImageSource.gallery, maxWidth: 512, maxHeight: 512, imageQuality: 75);
      if (image != null && mounted) setState(() => _imageFile = File(image.path));
    } catch (e) {
      Fluttertoast.showToast(msg: "Error selecting image", backgroundColor: const Color(0xFFD32F2F), textColor: Colors.white);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || !_addressFormKey.currentState!.validate()) return;
    if (_imageFile == null) {
      _showSnackBar('Please upload an image');
      return;
    }
    if (_selectedCategory == null) {
      _showSnackBar('Please select a category');
      return;
    }

    setState(() => _isLoading = true);
    try {
      final bytes = await _imageFile!.readAsBytes();
      final base64Img = base64Encode(bytes);
      final coins = _categories.firstWhere((c) => c.name == _selectedCategory).coins;
      final txnId = 'TXN${DateTime.now().millisecondsSinceEpoch}';

      await FirebaseFirestore.instance.collection("recycling_record").add({
        "user_id": user?.uid,
        "description": _descController.text,
        "item_category": _selectedCategory,
        "image": base64Img,
        "scheduled_date": DateFormat('yyyy-MM-dd').format(_selectedDate),
        "scheduled_time": _selectedTime.format(context),
        "address": _addressFormKey.currentState!.getAddressData(),
        "created_at": FieldValue.serverTimestamp(),
        "status": "Pending",
        "greenCoinsEarned": coins,
        "transactionId": txnId,
      });

      await FirebaseFirestore.instance.collection('user_profile').doc(user!.uid).update({'greenCoins': FieldValue.increment(coins)});

      await FirebaseFirestore.instance.collection('green_coin_transactions').doc(txnId).set({
        'transactionId': txnId,
        'userId': user!.uid,
        'amount': coins,
        'activity': 'recycling_pickup',
        'description': 'Recycling Pickup: $_selectedCategory',
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        _showSnackBar('Pickup Scheduled! +$coins Coins', isSuccess: true);
        Navigator.pop(context);
      }
    } catch (e) {
      _showSnackBar('Error scheduling pickup');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnackBar(String message, {bool isSuccess = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message, style: const TextStyle(fontFamily: 'Roboto', fontWeight: FontWeight.w600)), backgroundColor: isSuccess ? _primaryGreen : const Color(0xFFD32F2F)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: const BackButton(color: Color(0xFF212121)),
        title: const Text('Recycling Pickup', style: TextStyle(fontFamily: 'Roboto', fontSize: 20, fontWeight: FontWeight.w800, color: Color(0xFF212121))),
        centerTitle: true,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionHeader('Pickup Details', 'Recycle items to earn Green Coins'),
              _buildLabel('Photo Evidence'),
              const SizedBox(height: 8),
              _buildImagePicker(),
              const SizedBox(height: 24),
              _buildLabel('Category'),
              const SizedBox(height: 12),
              _buildCategoryChips(),
              if (_selectedCategory != null) ...[const SizedBox(height: 16), _buildCoinsBanner()],
              const SizedBox(height: 24),
              CustomTextField(controller: _descController, label: "Description (Optional)", hintText: "Extra details...", maxLines: 2),
              const SizedBox(height: 32),
              _buildSectionHeader('Schedule & Location'),
              DateTimePicker(onDateTimeSelected: (d, t) => setState(() {_selectedDate = d; _selectedTime = t;}), initialDate: _selectedDate, initialTime: _selectedTime),
              const SizedBox(height: 24),
              AddressForm(key: _addressFormKey, line1Controller: _line1Controller, line2Controller: _line2Controller, cityController: _cityController, postalController: _postalController, selectedState: _selectedState, onStateChanged: (value) => setState(() => _selectedState = value)),
              const SizedBox(height: 32),
              CustomButton(text: "Confirm Pickup", onPressed: _submit, isLoading: _isLoading, backgroundColor: _primaryGreen, minimumSize: const Size(double.infinity, 54)),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, [String? subtitle]) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontFamily: 'Roboto', fontSize: 20, fontWeight: FontWeight.w800, color: Color(0xFF212121))),
        if (subtitle != null) ...[const SizedBox(height: 4), Text(subtitle, style: const TextStyle(fontFamily: 'Roboto', fontSize: 15, fontWeight: FontWeight.w500, color: Color(0xFF424242)))],
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildLabel(String text) {
    return Text(text, style: const TextStyle(fontFamily: 'Roboto', fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF212121)));
  }

  Widget _buildImagePicker() {
    return GestureDetector(
      onTap: _pickImage,
      child: Container(
        width: double.infinity,
        height: 200,
        decoration: BoxDecoration(color: Colors.white, border: Border.all(color: _primaryGreen, width: 2), borderRadius: BorderRadius.circular(12)),
        child: _imageFile == null
            ? Column(mainAxisAlignment: MainAxisAlignment.center, children: [Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: _primaryGreen.withOpacity(0.1), shape: BoxShape.circle), child: const Icon(Icons.add_photo_alternate_outlined, size: 50, color: _primaryGreen)), const SizedBox(height: 12), const Text('Tap to upload image', style: TextStyle(fontFamily: 'Roboto', fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF212121)))])
            : ClipRRect(borderRadius: BorderRadius.circular(12), child: Stack(fit: StackFit.expand, children: [Image.file(_imageFile!, fit: BoxFit.cover), Positioned(bottom: 8, right: 8, child: Container(padding: const EdgeInsets.all(8), decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle), child: const Icon(Icons.edit, size: 20, color: _primaryGreen)))])),
      ),
    );
  }

  Widget _buildCategoryChips() {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: _categories.map((c) {
        final isSelected = _selectedCategory == c.name;
        return ChoiceChip(
          label: Text(c.name, style: TextStyle(fontFamily: 'Roboto', fontSize: 14, fontWeight: FontWeight.w700, color: isSelected ? Colors.white : const Color(0xFF212121))),
          avatar: Icon(c.icon, size: 18, color: isSelected ? Colors.white : c.color),
          selected: isSelected,
          onSelected: (s) => setState(() => _selectedCategory = s ? c.name : null),
          selectedColor: c.color,
          backgroundColor: const Color(0xFFF5F5F5),
          side: BorderSide(color: isSelected ? c.color : const Color(0xFFE0E0E0)),
        );
      }).toList(),
    );
  }

  Widget _buildCoinsBanner() {
    final coins = _categories.firstWhere((c) => c.name == _selectedCategory).coins;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: const Color(0xFFE8F5E9), borderRadius: BorderRadius.circular(12), border: Border.all(color: _primaryGreen.withOpacity(0.3))),
      child: Row(children: [const Icon(Icons.eco, color: _primaryGreen, size: 24), const SizedBox(width: 12), Expanded(child: Text('Earn $coins Green Coins for this item!', style: const TextStyle(fontFamily: 'Roboto', fontSize: 15, fontWeight: FontWeight.w700, color: _primaryGreen)))]),
    );
  }
}

class _Category {
  final String name;
  final IconData icon;
  final Color color;
  final int coins;
  const _Category({required this.name, required this.icon, required this.color, required this.coins});
}