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
import 'package:fluttertoast/fluttertoast.dart';

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
      home: const RecyclingPickUpPage(),
    );
  }
}

// Recycling category model with green coin rewards
class RecyclingCategory {
  final String name;
  final IconData icon;
  final Color color;
  final List<String> keywords;
  final int greenCoins;

  const RecyclingCategory({
    required this.name,
    required this.icon,
    required this.color,
    required this.keywords,
    required this.greenCoins,
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

  bool _isPickerActive = false;
  File? _image;
  DateTime selectedDate = DateTime.now();
  TimeOfDay selectedTime = const TimeOfDay(hour: 14, minute: 0);
  String? _selectedCategory;

  // Define recycling categories with green coin rewards
  static const List<RecyclingCategory> categories = [
    RecyclingCategory(
      name: 'Plastic',
      icon: Icons.water_drop_outlined,
      color: Color(0xFF4CAF50),
      keywords: [
        'plastic',
        'bottle',
        'container',
        'packaging',
        'bag',
        'cup',
        'straw',
        'wrapper',
      ],
      greenCoins: 15,
    ),
    RecyclingCategory(
      name: 'Paper',
      icon: Icons.description_outlined,
      color: Color(0xFF8D6E63),
      keywords: [
        'paper',
        'cardboard',
        'box',
        'newspaper',
        'magazine',
        'book',
        'document',
        'envelope',
      ],
      greenCoins: 10,
    ),
    RecyclingCategory(
      name: 'Glass',
      icon: Icons.wine_bar_outlined,
      color: Color(0xFF00BCD4),
      keywords: ['glass', 'jar', 'wine', 'beer', 'mirror', 'window'],
      greenCoins: 20,
    ),
    RecyclingCategory(
      name: 'Metal',
      icon: Icons.recycling,
      color: Color(0xFF9E9E9E),
      keywords: ['metal', 'can', 'aluminum', 'tin', 'steel', 'copper', 'wire'],
      greenCoins: 25,
    ),
    RecyclingCategory(
      name: 'Electronics',
      icon: Icons.devices_outlined,
      color: Color(0xFFFF9800),
      keywords: [
        'phone',
        'computer',
        'laptop',
        'tablet',
        'electronic',
        'battery',
        'charger',
        'cable',
        'monitor',
        'keyboard',
      ],
      greenCoins: 30,
    ),
    RecyclingCategory(
      name: 'Cardboard',
      icon: Icons.inventory_2_outlined,
      color: Color(0xFF795548),
      keywords: ['cardboard', 'box', 'carton', 'packaging'],
      greenCoins: 10,
    ),
  ];

  @override
  void dispose() {
    _itemNameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  int _getGreenCoinsForCategory(String? category) {
    if (category == null) return 0;
    try {
      return categories.firstWhere((c) => c.name == category).greenCoins;
    } catch (e) {
      return 0;
    }
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

  String _generateTransactionId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = (timestamp % 10000).toString().padLeft(4, '0');
    return 'TXN$timestamp$random';
  }

  Future<void> _recordGreenCoinTransaction({
    required String transactionId,
    required int amount,
    required String activity,
    required String description,
    Map<String, dynamic>? activityDetails,
  }) async {
    if (user == null) return;

    try {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('user_profile')
          .doc(user!.uid)
          .get();

      int currentBalance = 0;
      if (userDoc.exists) {
        Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
        currentBalance = userData['greenCoins'] ?? 0;
      }

      int newBalance = currentBalance + amount;

      await FirebaseFirestore.instance
          .collection('green_coin_transactions')
          .doc(transactionId)
          .set({
            'transactionId': transactionId,
            'userId': user!.uid,
            'amount': amount,
            'balanceAfter': newBalance,
            'activity': activity,
            'activityDetails': activityDetails ?? {},
            'description': description,
            'createdAt': FieldValue.serverTimestamp(),
            'status': 'completed',
          });

      print(
        'Green coin transaction recorded: $amount coins, activity: $activity',
      );
    } catch (e) {
      print('Error recording green coin transaction: $e');
    }
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
      final transactionId = _generateTransactionId();
      final greenCoinsEarned = _getGreenCoinsForCategory(_selectedCategory);

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
        "greenCoinsEarned": greenCoinsEarned,
        "transactionId": transactionId,
      });

      // Update user's green coins
      await FirebaseFirestore.instance
          .collection('user_profile')
          .doc(user!.uid)
          .update({'greenCoins': FieldValue.increment(greenCoinsEarned)});

      // Record green coin transaction
      await _recordGreenCoinTransaction(
        transactionId: transactionId,
        amount: greenCoinsEarned,
        activity: 'recycling_pickup',
        description:
            'Earned $greenCoinsEarned Green Coins from $_selectedCategory recycling',
        activityDetails: {
          'category': _selectedCategory,
          'itemName': _itemNameController.text,
        },
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Recycling pickup scheduled! You earned $greenCoinsEarned Green Coins.',
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
                                "📸 Tap to upload & auto-detect",
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
                        fontWeight: isSelected
                            ? FontWeight.bold
                            : FontWeight.normal,
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

                // Green Coin Reward Display
                if (_selectedCategory != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0FDF4),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFBBF7D0)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: const BoxDecoration(
                            color: Color(0xFF22C55E),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.eco,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "Earn Green Coins",
                                style: TextStyle(
                                  color: Color(0xFF166534),
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                "You will earn ${_getGreenCoinsForCategory(_selectedCategory)} Green Coins for recycling this category.",
                                style: const TextStyle(
                                  color: Color(0xFF166534),
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
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
                    hintText: "Auto-filled or enter manually",
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
                    hintText:
                        "Auto-filled with detection results or enter manually",
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
