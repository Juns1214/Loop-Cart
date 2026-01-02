import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';

// Utils
import '../../utils/date_time_picker.dart';
import '../../utils/address_form.dart';
import '../../utils/repair_option.dart';
import '../../utils/router.dart';
import '../checkout/payment.dart';

import '../../widget/custom_button.dart';
import '../../widget/custom_text_field.dart';
import '../../widget/image_picker_widget.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      initialRoute: "/repair-service",
      onGenerateRoute: onGenerateRoute,
    );
  }
}

class RepairServicePage extends StatefulWidget {
  const RepairServicePage({super.key});
  @override
  State<RepairServicePage> createState() => _RepairServicePageState();
}

class _RepairServicePageState extends State<RepairServicePage> {
  final _formKey = GlobalKey<FormState>();
  final _addressFormKey = GlobalKey<AddressFormState>();

  // Controllers
  final _itemNameController = TextEditingController();
  final _descriptionController = TextEditingController();

  // Address Controllers
  final _line1Controller = TextEditingController();
  final _line2Controller = TextEditingController();
  final _cityController = TextEditingController();
  final _postalController = TextEditingController();
  String? selectedState; // Changed to String?

  final User? user = FirebaseAuth.instance.currentUser;

  File? _image;
  DateTime selectedDate = DateTime.now();
  TimeOfDay selectedTime = const TimeOfDay(hour: 14, minute: 0);
  Map<String, String>? selectedRepair;
  double? calculatedDeliveryFee;
  bool _isLoadingAddress = true;

  // Data - Simplified fee structure
  static const Map<String, double> STATE_FEES = {
    'Kuala Lumpur': 10.0,
    'Selangor': 15.0,
    'Putrajaya': 12.0,
    'Negeri Sembilan': 25.0,
    'Melaka': 30.0,
    'Johor': 35.0,
    'Pahang': 40.0,
    'Terengganu': 45.0,
    'Kelantan': 50.0,
    'Perak': 35.0,
    'Penang': 40.0,
    'Kedah': 45.0,
    'Perlis': 50.0,
    'Sabah': 60.0,
    'Sarawak': 60.0,
    'Labuan': 60.0,
  };

  @override
  void initState() {
    super.initState();
    _loadUserAddress();
  }

  Future<void> _loadUserAddress() async {
    if (user == null) {
      setState(() => _isLoadingAddress = false);
      return;
    }
    try {
      DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection('user_profile')
          .doc(user!.uid)
          .get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        final addr = data['address'] as Map<String, dynamic>?;
        if (addr != null) {
          setState(() {
            _line1Controller.text = addr['line1'] ?? '';
            _line2Controller.text = addr['line2'] ?? '';
            _cityController.text = addr['city'] ?? '';
            _postalController.text = addr['postal'] ?? '';
            selectedState = addr['state']; // Changed
            _calculateDeliveryFee();
          });
        }
      }
    } catch (_) {}
    setState(() => _isLoadingAddress = false);
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

  // --- Logic ---
  Future<void> pickImage() async {
    try {
      final file = await ImagePicker().pickImage(source: ImageSource.gallery);
      if (file != null) setState(() => _image = File(file.path));
    } catch (_) {}
  }

  void _calculateDeliveryFee() {
    if (selectedState == null || selectedState!.isEmpty) {
      setState(() => calculatedDeliveryFee = null);
      return;
    }

    // Direct lookup from STATE_FEES map
    setState(() {
      calculatedDeliveryFee =
          STATE_FEES[selectedState] ?? 15.0; // Default to 15.0 if not found
    });
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate() ||
        !_addressFormKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please complete all fields')),
      );
      return;
    }
    if (_image == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please upload an image')));
      return;
    }
    if (selectedRepair == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a repair option')),
      );
      return;
    }

    try {
      final bytes = await _image!.readAsBytes();
      final base64Img = base64Encode(bytes);
      final isCustom = selectedRepair!['Repair'] == 'Custom Repair';

      final data = {
        "user_id": user?.uid,
        "name": _itemNameController.text,
        "description": _descriptionController.text,
        "image": base64Img,
        "scheduled_date": DateFormat('yyyy-MM-dd').format(selectedDate),
        "scheduled_time": selectedTime.format(context),
        "repair_option": selectedRepair,
        "address": _addressFormKey.currentState!.getAddressData(),
        "created_at": FieldValue.serverTimestamp(),
        "status": isCustom ? "Pending Review" : "Pending Payment",
        "deliveryFee": calculatedDeliveryFee ?? 15.0,
      };

      DocumentReference ref = await FirebaseFirestore.instance
          .collection("repair_record")
          .add(data);

      if (mounted) {
        if (isCustom) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Request submitted!'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context);
        } else {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => Payment(
                orderData: {
                  'repair_option': selectedRepair!,
                  'repairRecordId': ref.id,
                  'deliveryFee': calculatedDeliveryFee,
                },
              ),
            ),
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
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
        title: const Text(
          'Repair Service',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: _isLoadingAddress
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionHeader(
                      title: "Item Information",
                      subtitle: "Schedule a repair to extend your item's life.",
                    ),

                    CustomTextField(
                      controller: _itemNameController,
                      label: "Product Name",
                      hintText: "E.g. Broken Table",
                      validator: (v) => v!.isEmpty ? "Required" : null,
                    ),
                    const SizedBox(height: 24),

                    const Text(
                      "Product Image",
                      style: TextStyle(
                        fontFamily: 'Manrope',
                        fontSize: 15,
                        color: Color(0xFF1B5E20),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ImagePickerWidget(
                      imageFile: _image,
                      onImageSelected: (file) => setState(() => _image = file),
                    ),
                    const SizedBox(height: 24),

                    CustomTextField(
                      controller: _descriptionController,
                      label: "Description (Optional)",
                      hintText: "What needs fixing?",
                      maxLines: 3,
                    ),
                    const SizedBox(height: 32),

                    _buildSectionHeader(title: "Schedule & Location"),
                    SyncfusionDateTimePicker(
                      onDateTimeSelected: (d, t) => setState(() {
                        selectedDate = d;
                        selectedTime = t;
                      }),
                    ),
                    const SizedBox(height: 24),

                    AddressForm(
                      key: _addressFormKey,
                      line1Controller: _line1Controller,
                      line2Controller: _line2Controller,
                      cityController: _cityController,
                      postalController: _postalController,
                      selectedState: selectedState, // Changed parameter
                      onStateChanged: (value) {
                        setState(() => selectedState = value);
                        _calculateDeliveryFee(); // Recalculate when state changes
                      },
                    ),

                    if (calculatedDeliveryFee != null)
                      Container(
                        margin: const EdgeInsets.symmetric(vertical: 16),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.green.shade200),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              "Delivery Fee",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                              ),
                            ),
                            Text(
                              "RM ${calculatedDeliveryFee!.toStringAsFixed(2)}",
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                                color: Colors.green,
                              ),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 32),

                    _buildSectionHeader(title: "Repair Options"),
                    RepairOptionSelector(
                      initialSelection: selectedRepair,
                      onSelectionChanged: (r) =>
                          setState(() => selectedRepair = r),
                    ),
                    const SizedBox(height: 32),

                    Row(
                      children: [
                        Expanded(
                          child: CustomButton(
                            text: "Cancel",
                            backgroundColor: Colors.white,
                            textColor: const Color(0xFF2E5BFF),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: CustomButton(
                            text: "Confirm",
                            backgroundColor: const Color(0xFF2E5BFF),
                            onPressed: _handleSubmit,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
    );
  }


Widget _buildSectionHeader({
  required String title,
  String? subtitle,
}) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Color(0xFF1A1A1A),
          fontFamily: 'Manrope',
        ),
      ),
      if (subtitle != null) ...[
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: Colors.black,
            fontFamily: 'Manrope',
            height: 1.4,
          ),
        ),
      ],
      const SizedBox(height: 16),
    ],
  );
}
}
