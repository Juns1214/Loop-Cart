import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import '../../utils/router.dart';
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
      initialRoute: "/sell-second-hand-product",
      onGenerateRoute: onGenerateRoute,
    );
  }
}

class SellItemPage extends StatefulWidget {
  const SellItemPage({super.key});

  @override
  State<SellItemPage> createState() => _SellItemPageState();
}

class _SellItemPageState extends State<SellItemPage> {
  final _formKey = GlobalKey<FormState>();
  File? _image;

  final TextEditingController nameController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController priceController = TextEditingController();
  final User? user = FirebaseAuth.instance.currentUser;

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    loadDraft();
  }

  @override
  void dispose() {
    nameController.dispose();
    descriptionController.dispose();
    priceController.dispose();
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

  Future<void> uploadTaskToDb({required bool isDraft}) async {
    if (!_formKey.currentState!.validate()) return;
    if (!isDraft && _image == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please upload a product image')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      String? imageBase64;
      if (_image != null) {
        List<int> imageBytes = await _image!.readAsBytes();
        imageBase64 = base64Encode(imageBytes);
      }

      await FirebaseFirestore.instance.collection("sell_items").add({
        "user_id": user?.uid,
        "name": nameController.text.trim(),
        "description": descriptionController.text.trim(),
        "image": imageBase64,
        "price": priceController.text.trim(),
        "isDraft": isDraft,
        "posted_at": FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isDraft ? 'Draft saved' : 'Item published successfully!'),
            backgroundColor: isDraft ? Colors.grey[700] : Colors.green,
          ),
        );
        if (!isDraft) _handleCancel();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> loadDraft() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('sell_items')
          .where('isDraft', isEqualTo: true)
          .where('user_id', isEqualTo: user?.uid)
          .orderBy('posted_at', descending: true)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        var data = snapshot.docs.first.data();
        setState(() {
          nameController.text = data['name'] ?? '';
          descriptionController.text = data['description'] ?? '';
          priceController.text = data['price'] ?? '';
          if (data['image'] != null && data['image'] != '') {
            final decodedBytes = base64Decode(data['image']);
            final tempDir = Directory.systemTemp;
            final tempFile = File('${tempDir.path}/temp_${DateTime.now().millisecondsSinceEpoch}.jpg');
            tempFile.writeAsBytesSync(decodedBytes);
            _image = tempFile;
          }
        });
      }
    } catch (e) {
      debugPrint("Error loading draft: $e");
    }
  }

  void _handleCancel() {
    nameController.clear();
    descriptionController.clear();
    priceController.clear();
    setState(() => _image = null);
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
        title: const Text('Sell Your Item', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
        centerTitle: true,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionHeader(
                title: "Item Information",
                subtitle: "Post your second-hand item to the marketplace.",
              ),

              CustomTextField(
                controller: nameController,
                label: "Product Name",
                hintText: "E.g. Vintage Camera",
                validator: (value) {
                  if (value == null || value.isEmpty) return "Please enter a name";
                  if (!RegExp(r'^[a-zA-Z\s0-9]+$').hasMatch(value)) return "No special characters allowed";
                  return null;
                },
              ),
              const SizedBox(height: 24),

              const Text("Product Image", style: TextStyle(fontFamily: 'Manrope', fontSize: 15, color: Color(0xFF1B5E20), fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              ImagePickerWidget(
                imageFile: _image,
                onTap: pickImage,
                label: "Upload Photo",
              ),
              const SizedBox(height: 24),

              CustomTextField(
                controller: descriptionController,
                label: "Description",
                hintText: "Describe the condition, age, and features...",
                maxLines: 4,
                validator: (v) => (v == null || v.isEmpty) ? "Description required" : null,
              ),
              const SizedBox(height: 24),

              CustomTextField(
                controller: priceController,
                label: "Price",
                hintText: "0.00",
                prefixText: "RM ",
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                validator: (v) => (v == null || v.isEmpty) ? "Price required" : null,
              ),
              const SizedBox(height: 32),

              Row(
                children: [
                  Expanded(
                    child: CustomButton(
                      text: "Cancel",
                      backgroundColor: Colors.white,
                      textColor: const Color(0xFF2E5BFF),
                      onPressed: _handleCancel,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: CustomButton(
                      text: "Draft",
                      backgroundColor: Colors.white,
                      textColor: const Color(0xFF2E5BFF),
                      onPressed: () => uploadTaskToDb(isDraft: true),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              CustomButton(
                text: "Publish Item",
                backgroundColor: const Color(0xFF2E5BFF),
                minimumSize: const Size(double.infinity, 54),
                isLoading: _isLoading,
                onPressed: () => uploadTaskToDb(isDraft: false),
              ),
            ],
          ),
        ),
      ),
    );
  }

/// Section header - replaces SectionHeader widget
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