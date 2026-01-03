import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../../utils/date_time_picker.dart';
import '../../utils/address_form.dart';
import '../../utils/repair_option.dart';
import '../checkout/payment.dart';
import '../../widget/custom_button.dart';
import '../../widget/custom_text_field.dart';

class RepairServicePage extends StatefulWidget {
  const RepairServicePage({super.key});
  @override
  State<RepairServicePage> createState() => _RepairServicePageState();
}

class _RepairServicePageState extends State<RepairServicePage> {
  final _formKey = GlobalKey<FormState>();
  final _addressFormKey = GlobalKey<AddressFormState>();
  final _itemNameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _line1Controller = TextEditingController();
  final _line2Controller = TextEditingController();
  final _cityController = TextEditingController();
  final _postalController = TextEditingController();

  final User? user = FirebaseAuth.instance.currentUser;
  static const Color _primaryGreen = Color(0xFF2E7D32);

  static const Map<String, double> _stateFees = {
    'Kuala Lumpur': 10.0, 'Selangor': 15.0, 'Putrajaya': 12.0, 'Negeri Sembilan': 25.0, 'Melaka': 30.0, 'Johor': 35.0,
    'Pahang': 40.0, 'Terengganu': 45.0, 'Kelantan': 50.0, 'Perak': 35.0, 'Penang': 40.0, 'Kedah': 45.0,
    'Perlis': 50.0, 'Sabah': 60.0, 'Sarawak': 60.0, 'Labuan': 60.0,
  };

  File? _imageFile;
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = const TimeOfDay(hour: 14, minute: 0);
  Map<String, String>? _selectedRepair;
  String? _selectedState;
  double? _calculatedDeliveryFee;
  bool _isLoadingAddress = true;

  @override
  void initState() {
    super.initState();
    _loadUserAddress();
  }

  @override
  void dispose() {
    _itemNameController.dispose();
    _descriptionController.dispose();
    _line1Controller.dispose();
    _line2Controller.dispose();
    _cityController.dispose();
    _postalController.dispose();
    super.dispose();
  }

  Future<void> _loadUserAddress() async {
    if (user == null) {
      setState(() => _isLoadingAddress = false);
      return;
    }
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
            _calculateDeliveryFee();
          });
        }
      }
    } catch (_) {}
    setState(() => _isLoadingAddress = false);
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

  void _calculateDeliveryFee() {
    if (_selectedState == null || _selectedState!.isEmpty) {
      setState(() => _calculatedDeliveryFee = null);
      return;
    }
    setState(() => _calculatedDeliveryFee = _stateFees[_selectedState] ?? 15.0);
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate() || !_addressFormKey.currentState!.validate()) {
      _showSnackBar('Please complete all fields');
      return;
    }
    if (_imageFile == null) {
      _showSnackBar('Please upload an image');
      return;
    }
    if (_selectedRepair == null) {
      _showSnackBar('Please select a repair option');
      return;
    }

    try {
      final bytes = await _imageFile!.readAsBytes();
      final base64Img = base64Encode(bytes);
      final isCustom = _selectedRepair!['Repair'] == 'Custom Repair';

      final data = {
        "user_id": user?.uid,
        "repair_type": _itemNameController.text,
        "description": _descriptionController.text,
        "image": base64Img,
        "scheduled_date": DateFormat('yyyy-MM-dd').format(_selectedDate),
        "scheduled_time": _selectedTime.format(context),
        "repair_option": _selectedRepair,
        "address": _addressFormKey.currentState!.getAddressData(),
        "created_at": FieldValue.serverTimestamp(),
        "status": isCustom ? "Pending Review" : "Pending Payment",
        "deliveryFee": _calculatedDeliveryFee ?? 15.0,
      };

      DocumentReference ref = await FirebaseFirestore.instance.collection("repair_record").add(data);

      if (mounted) {
        if (isCustom) {
          _showSnackBar('Request submitted!', isSuccess: true);
          Navigator.pop(context);
        } else {
          Navigator.push(context, MaterialPageRoute(builder: (_) => Payment(orderData: {'repair_option': _selectedRepair!, 'repairRecordId': ref.id, 'deliveryFee': _calculatedDeliveryFee})));
        }
      }
    } catch (e) {
      _showSnackBar('Error submitting request');
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
        title: const Text('Repair Service', style: TextStyle(fontFamily: 'Roboto', fontSize: 20, fontWeight: FontWeight.w800, color: Color(0xFF212121))),
        centerTitle: true,
      ),
      body: _isLoadingAddress
          ? const Center(child: CircularProgressIndicator(color: _primaryGreen))
          : Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionHeader('Item Information', 'Schedule a repair to extend your item\'s life'),
                    CustomTextField(controller: _itemNameController, label: "Product Name", hintText: "E.g. Broken Table", validator: (v) => v!.isEmpty ? "Required" : null),
                    const SizedBox(height: 24),
                    _buildLabel('Product Image'),
                    const SizedBox(height: 8),
                    _buildImagePicker(),
                    const SizedBox(height: 24),
                    CustomTextField(controller: _descriptionController, label: "Description (Optional)", hintText: "What needs fixing?", maxLines: 3),
                    const SizedBox(height: 32),
                    _buildSectionHeader('Schedule & Location'),
                    DateTimePicker(onDateTimeSelected: (d, t) => setState(() {_selectedDate = d; _selectedTime = t;}), initialDate: _selectedDate, initialTime: _selectedTime),
                    const SizedBox(height: 24),
                    AddressForm(key: _addressFormKey, line1Controller: _line1Controller, line2Controller: _line2Controller, cityController: _cityController, postalController: _postalController, selectedState: _selectedState, onStateChanged: (value) {setState(() => _selectedState = value); _calculateDeliveryFee();}),
                    if (_calculatedDeliveryFee != null) ...[const SizedBox(height: 16), _buildDeliveryFeeBanner()],
                    const SizedBox(height: 32),
                    _buildSectionHeader('Repair Options'),
                    RepairOptionSelector(initialSelection: _selectedRepair, onSelectionChanged: (r) => setState(() => _selectedRepair = r)),
                    const SizedBox(height: 32),
                    Row(children: [
                      Expanded(child: CustomButton(text: "Cancel", backgroundColor: Colors.white, textColor: _primaryGreen, onPressed: () => Navigator.pop(context))),
                      const SizedBox(width: 12),
                      Expanded(child: CustomButton(text: "Confirm", backgroundColor: _primaryGreen, onPressed: _handleSubmit)),
                    ]),
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

  Widget _buildDeliveryFeeBanner() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: const Color(0xFFE8F5E9), borderRadius: BorderRadius.circular(12), border: Border.all(color: _primaryGreen.withOpacity(0.3))),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text('Delivery Fee', style: TextStyle(fontFamily: 'Roboto', fontSize: 16, fontWeight: FontWeight.w700, color: _primaryGreen)),
          Text('RM ${_calculatedDeliveryFee!.toStringAsFixed(2)}', style: const TextStyle(fontFamily: 'Roboto', fontSize: 18, fontWeight: FontWeight.w800, color: _primaryGreen)),
        ],
      ),
    );
  }
}