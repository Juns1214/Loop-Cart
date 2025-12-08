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

  // Address controllers
  final _line1Controller = TextEditingController();
  final _line2Controller = TextEditingController();
  final _cityController = TextEditingController();
  final _postalController = TextEditingController();
  final _stateController = TextEditingController();

  bool _isPickerActive = false;
  bool _isLoadingAddress = true;
  bool _isDeliveryFeesExpanded = false; // NEW: For expandable section
  File? _image;
  DateTime selectedDate = DateTime.now();
  TimeOfDay selectedTime = const TimeOfDay(hour: 14, minute: 0);
  Map<String, String>? selectedRepair;
  
  double? calculatedDeliveryFee;

  // STATE-BASED DELIVERY FEES (Malaysian Ringgit)
  static const Map<String, double> STATE_DELIVERY_FEES = {
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
  };

  // NEW: Get list of valid states
  static List<String> get validStates => STATE_DELIVERY_FEES.keys.toList();

  @override
  void initState() {
    super.initState();
    _loadUserAddress();
  }

  Future<void> _loadUserAddress() async {
    if (user == null) {
      setState(() {
        _isLoadingAddress = false;
      });
      return;
    }

    try {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('user_profile')
          .doc(user!.uid)
          .get();

      if (userDoc.exists && mounted) {
        Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
        
        if (userData.containsKey('address') && userData['address'] != null) {
          Map<String, dynamic> address = userData['address'] as Map<String, dynamic>;
          
          setState(() {
            _line1Controller.text = address['line1'] ?? '';
            _line2Controller.text = address['line2'] ?? '';
            _cityController.text = address['city'] ?? '';
            _postalController.text = address['postal'] ?? '';
            _stateController.text = address['state'] ?? '';
            // Auto-calculate fee when state is loaded
            _calculateDeliveryFee();
          });
        }
      }
    } catch (e) {
      print('Error loading address: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingAddress = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _itemNameController.dispose();
    _descriptionController.dispose();
    _line1Controller.dispose();
    _line2Controller.dispose();
    _cityController.dispose();
    _postalController.dispose();
    _stateController.dispose();
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

  // NEW: Validate if state is in the valid list
  bool _isValidState(String state) {
    return validStates.any(
      (validState) => validState.toLowerCase() == state.trim().toLowerCase(),
    );
  }

  /// Simple state-based delivery fee calculation with validation
  void _calculateDeliveryFee() {
    String state = _stateController.text.trim();
    
    if (state.isEmpty) {
      setState(() {
        calculatedDeliveryFee = null;
      });
      return;
    }

    // Validate state
    if (!_isValidState(state)) {
      setState(() {
        calculatedDeliveryFee = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('⚠️ "$state" is not a valid Malaysian state. Please select from the list.'),
          backgroundColor: Colors.orange,
          duration: const Duration(seconds: 3),
          action: SnackBarAction(
            label: 'View States',
            textColor: Colors.white,
            onPressed: () {
              setState(() {
                _isDeliveryFeesExpanded = true;
              });
            },
          ),
        ),
      );
      return;
    }

    // Find matching state (case-insensitive)
    double? fee;
    STATE_DELIVERY_FEES.forEach((stateName, price) {
      if (stateName.toLowerCase() == state.toLowerCase()) {
        fee = price;
      }
    });

    setState(() {
      calculatedDeliveryFee = fee;
    });

    if (fee != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✓ Delivery fee for $state: RM ${fee!.toStringAsFixed(2)}'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );
    }
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

    // NEW: Validate state before proceeding
    if (!_isValidState(_stateController.text)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid Malaysian state'),
          backgroundColor: Colors.orange,
        ),
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
        "deliveryFee": calculatedDeliveryFee ?? 15.0,
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

    // NEW: Validate state before proceeding
    if (!_isValidState(_stateController.text)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid Malaysian state'),
          backgroundColor: Colors.orange,
        ),
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

    if (calculatedDeliveryFee == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a valid state to calculate delivery fee'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      final imageBase64 = await convertImageToBase64(_image!);

      // Create the repair document
      DocumentReference repairRef = await FirebaseFirestore.instance
          .collection("repair_record")
          .add({
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
            "deliveryFee": calculatedDeliveryFee,
          });

      String repairRecordId = repairRef.id;

      // Navigate to payment with delivery fee included
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => Payment(
              orderData: {
                'repair_option': selectedRepair!,
                'repairRecordId': repairRecordId,
                'deliveryFee': calculatedDeliveryFee,
              },
            ),
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
      body: _isLoadingAddress
          ? const Center(child: CircularProgressIndicator())
          : Form(
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

                      // Product Description (Optional)
                      const Text(
                        "Product Description (Optional)",
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
                              "A detailed description of the product helps understand what needs repair (optional).",
                          hintStyle: const TextStyle(
                            color: Colors.grey,
                            fontSize: 14,
                          ),
                          counterText: "${_descriptionController.text.length}/100",
                        ),
                        onChanged: (value) => setState(() {}),
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
                      AddressForm(
                        key: _addressFormKey,
                        line1Controller: _line1Controller,
                        line2Controller: _line2Controller,
                        cityController: _cityController,
                        postalController: _postalController,
                        stateController: _stateController,
                        onStateChanged: (state) {
                          // Auto-calculate when state changes
                          _calculateDeliveryFee();
                        },
                      ),

                      // Delivery Fee Display
                      if (calculatedDeliveryFee != null)
                        Container(
                          margin: const EdgeInsets.only(top: 16),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.green.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.green.shade200),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.local_shipping_outlined,
                                    color: Colors.green.shade700,
                                    size: 24,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    "Delivery Fee",
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green.shade900,
                                    ),
                                  ),
                                ],
                              ),
                              Text(
                                "RM ${calculatedDeliveryFee!.toStringAsFixed(2)}",
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green.shade700,
                                ),
                              ),
                            ],
                          ),
                        ),

                      // NEW: Expandable Pricing Info Card
                      Container(
                        margin: const EdgeInsets.only(top: 16),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.blue.shade200),
                        ),
                        child: Column(
                          children: [
                            // Header with expand button
                            InkWell(
                              onTap: () {
                                setState(() {
                                  _isDeliveryFeesExpanded = !_isDeliveryFeesExpanded;
                                });
                              },
                              borderRadius: BorderRadius.circular(8),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.info_outline,
                                          color: Colors.blue.shade700,
                                          size: 20,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          "Delivery Fees by State",
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.blue.shade900,
                                          ),
                                        ),
                                      ],
                                    ),
                                    Row(
                                      children: [
                                        Text(
                                          _isDeliveryFeesExpanded ? "Hide" : "View All",
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.blue.shade700,
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        Icon(
                                          _isDeliveryFeesExpanded
                                              ? Icons.expand_less
                                              : Icons.expand_more,
                                          color: Colors.blue.shade700,
                                          size: 24,
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            
                            // Expandable content
                            if (_isDeliveryFeesExpanded)
                              Container(
                                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                                child: Column(
                                  children: [
                                    const Divider(height: 1),
                                    const SizedBox(height: 12),
                                    ...STATE_DELIVERY_FEES.entries.map((entry) {
                                      bool isSelected = _stateController.text.trim().toLowerCase() == 
                                                        entry.key.toLowerCase();
                                      return Container(
                                        margin: const EdgeInsets.only(bottom: 6),
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                        decoration: BoxDecoration(
                                          color: isSelected 
                                              ? Colors.green.shade100 
                                              : Colors.white,
                                          borderRadius: BorderRadius.circular(6),
                                          border: Border.all(
                                            color: isSelected 
                                                ? Colors.green.shade300 
                                                : Colors.grey.shade200,
                                            width: isSelected ? 2 : 1,
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Row(
                                              children: [
                                                if (isSelected)
                                                  Icon(
                                                    Icons.check_circle,
                                                    size: 16,
                                                    color: Colors.green.shade700,
                                                  ),
                                                if (isSelected) const SizedBox(width: 8),
                                                Text(
                                                  entry.key,
                                                  style: TextStyle(
                                                    fontSize: 13,
                                                    color: Colors.black87,
                                                    fontWeight: isSelected 
                                                        ? FontWeight.bold 
                                                        : FontWeight.normal,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            Text(
                                              "RM ${entry.value.toStringAsFixed(0)}",
                                              style: TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.bold,
                                                color: isSelected 
                                                    ? Colors.green.shade900 
                                                    : Colors.black87,
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    }).toList(),
                                    const SizedBox(height: 8),
                                    Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: Colors.amber.shade50,
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(color: Colors.amber.shade200),
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.warning_amber_rounded,
                                            size: 16,
                                            color: Colors.amber.shade800,
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              "Please enter the state name exactly as shown above",
                                              style: TextStyle(
                                                fontSize: 11,
                                                color: Colors.amber.shade900,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
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