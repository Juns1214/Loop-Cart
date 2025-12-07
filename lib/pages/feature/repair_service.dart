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
import '../../utils/delivery_fee_service.dart';

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
  bool _isCalculatingFee = false;
  File? _image;
  DateTime selectedDate = DateTime.now();
  TimeOfDay selectedTime = const TimeOfDay(hour: 14, minute: 0);
  Map<String, String>? selectedRepair;
  
  // Delivery fee related
  Map<String, dynamic>? deliveryFeeResult;
  double? calculatedDeliveryFee;
  double? calculatedDistance;

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

  /// Calculate delivery fee based on current address
  Future<void> _calculateDeliveryFee() async {
    if (!_addressFormKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please complete the address first'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isCalculatingFee = true;
      deliveryFeeResult = null;
      calculatedDeliveryFee = null;
      calculatedDistance = null;
    });

    try {
      Map<String, dynamic> addressData = 
          _addressFormKey.currentState!.getAddressData();
      
      Map<String, dynamic> result = 
          await DeliveryFeeService.calculateDeliveryFee(addressData);

      if (mounted) {
        setState(() {
          deliveryFeeResult = result;
          if (result['success']) {
            calculatedDeliveryFee = result['deliveryFee'].toDouble();
            calculatedDistance = result['distance'].toDouble();
          }
          _isCalculatingFee = false;
        });

        if (result['success']) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '✓ Delivery fee calculated: RM ${result['deliveryFee'].toStringAsFixed(2)}',
              ),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['error']),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 5),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isCalculatingFee = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error calculating delivery fee: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
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
        "deliveryFee": calculatedDeliveryFee,
        "distance": calculatedDistance,
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

    // Validate delivery fee is calculated
    if (calculatedDeliveryFee == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please calculate delivery fee first'),
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
            "distance": calculatedDistance,
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
                'distance': calculatedDistance,
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
                      ),
                      const SizedBox(height: 16),

                      // Calculate Delivery Fee Button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _isCalculatingFee ? null : _calculateDeliveryFee,
                          icon: _isCalculatingFee
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white,
                                    ),
                                  ),
                                )
                              : const Icon(Icons.calculate_outlined),
                          label: Text(
                            _isCalculatingFee
                                ? "Calculating..."
                                : "Calculate Delivery Fee",
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

                      // Delivery Fee Display
                      if (deliveryFeeResult != null && deliveryFeeResult!['success'])
                        Container(
                          margin: const EdgeInsets.only(top: 16),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.green.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.green.shade200),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.check_circle,
                                    color: Colors.green.shade700,
                                    size: 24,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    "Delivery Fee Calculated",
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green.shade900,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    "Distance:",
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  Text(
                                    "${calculatedDistance!.toStringAsFixed(1)} km",
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.black87,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    "Category:",
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  Text(
                                    deliveryFeeResult!['tierLabel'],
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.black87,
                                    ),
                                  ),
                                ],
                              ),
                              const Divider(height: 24),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    "Delivery Fee:",
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black,
                                    ),
                                  ),
                                  Text(
                                    "RM ${calculatedDeliveryFee!.toStringAsFixed(2)}",
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green.shade700,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                      // Pricing Info Card
                      Container(
                        margin: const EdgeInsets.only(top: 16),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.blue.shade200),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
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
                                  "Delivery Fee Rates",
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue.shade900,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            ...DeliveryFeeService.getPricingTiersInfo()
                                .map((tier) {
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 6),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      tier['label'],
                                      style: const TextStyle(
                                        fontSize: 13,
                                        color: Colors.black87,
                                      ),
                                    ),
                                    Text(
                                      "RM ${tier['fee'].toStringAsFixed(0)}",
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.black87,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                            const SizedBox(height: 8),
                            Text(
                              "Maximum service radius: 50 km from KL",
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade700,
                                fontStyle: FontStyle.italic,
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