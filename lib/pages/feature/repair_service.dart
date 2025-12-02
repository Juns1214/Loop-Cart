import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import '../../utils/date_time_picker.dart';
import '../../utils/address_form.dart';
import '../../utils/repair_option.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../utils/router.dart';
import '../checkout/payment.dart';

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
  final _itemNameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _addressFormKey = GlobalKey<AddressFormState>();
  final User? user = FirebaseAuth.instance.currentUser;

  bool _isPickerActive = false;
  File? _image;
  DateTime selectedDate = DateTime.now();
  TimeOfDay selectedTime = const TimeOfDay(hour: 14, minute: 0);
  Map<String, String>? selectedRepair;

  @override
  void dispose() {
    _itemNameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> pickImage() async {
    if (_isPickerActive) return;

    setState(() {
      _isPickerActive = true;
    });

    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: ImageSource.gallery);

      if (pickedFile != null) {
        setState(() {
          _image = File(pickedFile.path);
        });
      }
    } catch (e) {
      Fluttertoast.showToast(
        msg: "Error loading image: $e",
        toastLength: Toast.LENGTH_SHORT,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isPickerActive = false;
        });
      }
    }
  }

  Future<String> convertImageToBase64(File imageFile) async {
    List<int> imageBytes = await imageFile.readAsBytes();
    return base64Encode(imageBytes);
  }

  bool _isCustomRepair() {
    return selectedRepair != null &&
        selectedRepair!['Repair'] == 'Custom Repair';
  }

  Future<void> _saveCustomRepairRequest() async {
    // Validate forms
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all required fields')),
      );
      return;
    }

    if (!_addressFormKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please complete the address')),
      );
      return;
    }

    if (selectedRepair == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a repair option')),
      );
      return;
    }

    if (_image == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please upload a product image')),
      );
      return;
    }

    try {
      final imageBase64 = await convertImageToBase64(_image!);

      await FirebaseFirestore.instance.collection("repair_record").add({
        "user_id": user?.uid,
        "name": _itemNameController.text,
        "description": _descriptionController.text,
        "image": imageBase64,
        "scheduled_date": DateFormat('yyyy-MM-dd').format(selectedDate),
        "scheduled_time": selectedTime.format(context),
        "repair_option": selectedRepair,
        "address": _addressFormKey.currentState!.getAddressData(),
        "created_at": FieldValue.serverTimestamp(),
        "status": "Pending Review",
        "paymentStatus": "Pending",
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Custom repair request submitted! We\'ll contact you soon.',
            ),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
      }
    }
  }

  Future<void> _proceedToPayment() async {
    // Validate forms
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all required fields')),
      );
      return;
    }

    if (!_addressFormKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please complete the address')),
      );
      return;
    }

    if (selectedRepair == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a repair option')),
      );
      return;
    }

    if (_image == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please upload a product image')),
      );
      return;
    }

    try {
      // Save repair request first (without payment status)
      final imageBase64 = await convertImageToBase64(_image!);

      await FirebaseFirestore.instance.collection("repair_record").add({
        "user_id": user?.uid,
        "name": _itemNameController.text,
        "description": _descriptionController.text,
        "image": imageBase64,
        "scheduled_date": DateFormat('yyyy-MM-dd').format(selectedDate),
        "scheduled_time": selectedTime.format(context),
        "repair_option": selectedRepair,
        "address": _addressFormKey.currentState!.getAddressData(),
        "created_at": FieldValue.serverTimestamp(),
        "status": "Pending Payment",
      });

      // Navigate to payment
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                Payment(orderData: {'repair_option': selectedRepair!}),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
      }
    }
  }

  void _handleConfirmation() {
    if (_isCustomRepair()) {
      _saveCustomRepairRequest();
    } else {
      _proceedToPayment();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Repair Service',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
        ),
        centerTitle: true,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Schedule a repair and extend the life of your item.",
                  style: TextStyle(
                    fontSize: 20,
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),

                // SECTION: Item Information
                const Text(
                  "Item Information",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2E5BFF),
                  ),
                ),
                const SizedBox(height: 16),

                // Product Name
                const Text(
                  "Product Name",
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.black,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _itemNameController,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    hintText: "Enter product name",
                    hintStyle: const TextStyle(
                      fontSize: 15,
                      color: Colors.grey,
                      fontWeight: FontWeight.normal,
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return "Please enter item name";
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Product Image
                const Text(
                  "Product Images",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: pickImage,
                  child: Container(
                    width: double.infinity,
                    height: 200,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade400),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: _image == null
                        ? Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.add_photo_alternate_outlined,
                                size: 60,
                                color: Colors.grey.shade400,
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                "Browse from Gallery",
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          )
                        : ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.file(_image!, fit: BoxFit.cover),
                          ),
                  ),
                ),
                const SizedBox(height: 16),

                // Product Description
                const Text(
                  "Product Description",
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.black,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _descriptionController,
                  maxLines: 4,
                  maxLength: 100,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    hintText:
                        "A detailed description of the product helps understand what needs repair.",
                    hintStyle: const TextStyle(
                      color: Colors.grey,
                      fontSize: 14,
                    ),
                    counterText: "${_descriptionController.text.length}/100",
                  ),
                  onChanged: (value) => setState(() {}),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return "Please enter item description";
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),

                // Date & Time Picker
                const Text(
                  "Schedule Details",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2E5BFF),
                  ),
                ),
                const SizedBox(height: 8),
                SyncfusionDateTimePicker(
                  onDateTimeSelected: (date, time) {
                    setState(() {
                      selectedDate = date;
                      selectedTime = time;
                    });
                  },
                ),
                const SizedBox(height: 24),

                // Address Form
                const Text(
                  "Service Address",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2E5BFF),
                  ),
                ),
                const SizedBox(height: 8),
                AddressForm(key: _addressFormKey),
                const SizedBox(height: 24),

                // Repair Option Selector
                const Text(
                  "Repair Options",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2E5BFF),
                  ),
                ),
                const SizedBox(height: 8),
                RepairOptionSelector(
                  initialSelection: selectedRepair,
                  onSelectionChanged: (repair) {
                    setState(() {
                      selectedRepair = repair;
                    });
                  },
                ),
                const SizedBox(height: 20),

                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close),
                        label: const Text("Cancel"),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF2E5BFF),
                          side: const BorderSide(color: Color(0xFF2E5BFF)),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _handleConfirmation,
                        icon: Icon(
                          _isCustomRepair()
                              ? Icons.send_outlined
                              : Icons.payment_outlined,
                        ),
                        label: Text(
                          _isCustomRepair()
                              ? "Submit Request"
                              : "Proceed to Payment",
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2E5BFF),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
