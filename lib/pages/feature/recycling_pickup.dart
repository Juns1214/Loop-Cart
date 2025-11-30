import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import '../../utils/date_time_picker.dart';
import '../../utils/address_form.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../utils/router.dart';

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
      initialRoute: "/recycling-pickup",
      onGenerateRoute: onGenerateRoute,
    );
  }
}

// Recycling category model
class RecyclingCategory {
  final String name;
  final IconData icon;
  final Color color;

  const RecyclingCategory({
    required this.name,
    required this.icon,
    required this.color,
  });
}

class RecyclingPickUpPage extends StatefulWidget {
  const RecyclingPickUpPage({super.key});

  @override
  State<RecyclingPickUpPage> createState() => _RecyclingPickUpPageState();
}

class _RecyclingPickUpPageState extends State<RecyclingPickUpPage> {
  final _formKey = GlobalKey<FormState>();
  final _itemNameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _addressFormKey = GlobalKey<AddressFormState>();
  final User? user = FirebaseAuth.instance.currentUser;

  File? _image;
  DateTime selectedDate = DateTime.now();
  TimeOfDay selectedTime = const TimeOfDay(hour: 14, minute: 0);
  String? _selectedCategory;

  // Define recycling categories
  static const List<RecyclingCategory> categories = [
    RecyclingCategory(
      name: 'Plastic',
      icon: Icons.water_drop_outlined,
      color: Color(0xFF4CAF50),
    ),
    RecyclingCategory(
      name: 'Paper',
      icon: Icons.description_outlined,
      color: Color(0xFF8D6E63),
    ),
    RecyclingCategory(
      name: 'Glass',
      icon: Icons.wine_bar_outlined,
      color: Color(0xFF00BCD4),
    ),
    RecyclingCategory(
      name: 'Metal',
      icon: Icons.recycling,
      color: Color(0xFF9E9E9E),
    ),
    RecyclingCategory(
      name: 'Electronics',
      icon: Icons.devices_outlined,
      color: Color(0xFFFF9800),
    ),
    RecyclingCategory(
      name: 'Cardboard',
      icon: Icons.inventory_2_outlined,
      color: Color(0xFF795548),
    ),
  ];

  @override
  void dispose() {
    _itemNameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    
    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
    }
  }

  Future<String> convertImageToBase64(File imageFile) async {
    List<int> imageBytes = await imageFile.readAsBytes();
    return base64Encode(imageBytes);
  }

  Future<void> uploadTaskToDb() async {
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

    if (_image == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please upload a product image')),
      );
      return;
    }

    if (_selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a recycling category')),
      );
      return;
    }

    try {
      final imageBase64 = await convertImageToBase64(_image!);

      await FirebaseFirestore.instance.collection("recycling_record").add({
        "user_id": user?.uid,
        "name": _itemNameController.text,
        "description": _descriptionController.text,
        "category": _selectedCategory,
        "image": imageBase64,
        "scheduled_date": DateFormat('yyyy-MM-dd').format(selectedDate),
        "scheduled_time": selectedTime.format(context),
        "address": _addressFormKey.currentState!.getAddressData(),
        "created_at": FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Recycling pickup scheduled successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
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
          'Recycling Pickup Service',
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
                  "Arrange a pickup for recyclable items and help protect the environment.",
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

                // Product Image
                const Text(
                  "Product Image",
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
                                "📸 Tap to upload image",
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontWeight: FontWeight.w500,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          )
                        : Stack(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.file(
                                  _image!,
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                  height: 200,
                                ),
                              ),
                              Positioned(
                                top: 8,
                                right: 8,
                                child: CircleAvatar(
                                  backgroundColor: Colors.white,
                                  child: IconButton(
                                    icon: const Icon(Icons.edit, size: 20),
                                    onPressed: pickImage,
                                    color: Color(0xFF2E5BFF),
                                  ),
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
                const SizedBox(height: 16),

                // Recycling Category
                const Text(
                  "Recycling Category",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: categories.map((category) {
                    final isSelected = _selectedCategory == category.name;
                    return ChoiceChip(
                      label: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            category.icon,
                            size: 18,
                            color: isSelected ? Colors.white : category.color,
                          ),
                          const SizedBox(width: 6),
                          Text(category.name),
                        ],
                      ),
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(() {
                          _selectedCategory = selected ? category.name : null;
                        });
                      },
                      selectedColor: category.color,
                      backgroundColor: category.color.withOpacity(0.1),
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : Colors.black87,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    );
                  }).toList(),
                ),
                if (_selectedCategory == null)
                  const Padding(
                    padding: EdgeInsets.only(top: 8),
                    child: Text(
                      'Please select a category',
                      style: TextStyle(color: Colors.red, fontSize: 12),
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
                  onChanged: (value) => setState(() {}),
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    hintText: "Enter item name",
                    hintStyle: const TextStyle(
                      fontSize: 15,
                      color: Colors.grey,
                      fontWeight: FontWeight.normal,
                    ),
                    suffixIcon: _itemNameController.text.isNotEmpty
                        ? const Icon(Icons.check_circle, color: Colors.green)
                        : null,
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return "Please enter item name";
                    }
                    return null;
                  },
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
                  maxLength: 200,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    hintText: "Describe the recyclable item",
                    hintStyle: const TextStyle(
                      color: Colors.grey,
                      fontSize: 14,
                    ),
                    counterText: "${_descriptionController.text.length}/200",
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
                        onPressed: uploadTaskToDb,
                        icon: const Icon(Icons.check_circle_outline),
                        label: const Text("Confirm Pickup"),
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