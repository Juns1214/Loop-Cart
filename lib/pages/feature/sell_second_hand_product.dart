import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:convert';
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

  // Pick image from gallery
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
    String base64Image = base64Encode(imageBytes);
    return base64Image;
  }

  // Upload form data to Firestore (Publish or Draft)
  Future<void> uploadTaskToDb({required bool isDraft}) async {
    if (!_formKey.currentState!.validate()) return;

    try {
      String? imageBase64;
      if (_image != null) {
        imageBase64 = await convertImageToBase64(_image!);
      }

      await FirebaseFirestore.instance.collection("sell_items").add({
        "user_id": user?.uid,
        "name": nameController.text,
        "description": descriptionController.text,
        "image": imageBase64,
        "price": priceController.text,
        "isDraft": isDraft,
        "posted_at": FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isDraft ? 'Saved as draft' : 'Item published successfully!',
          ),
        ),
      );

      if (!isDraft) _handleCancel(); // Clear form after publishing
    } catch (e) {
      print(e);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  // Load the most recent draft from Firestore
  Future<void> loadDraft() async {
    try {
      QuerySnapshot draftSnapshot = await FirebaseFirestore.instance
          .collection('repair_record')
          .where('isDraft', isEqualTo: true)
          .orderBy('posted_at', descending: true)
          .limit(1)
          .get();

      if (draftSnapshot.docs.isNotEmpty) {
        var data = draftSnapshot.docs.first.data() as Map<String, dynamic>;
        setState(() {
          nameController.text = data['name'] ?? '';
          descriptionController.text = data['description'] ?? '';
          priceController.text = data['price'] ?? '';

          // Decode image if Base64 exists
          if (data['image'] != null && data['image'] != '') {
            final decodedBytes = base64Decode(data['image']);
            // Save temporary file to display in Image.file widget
            final tempDir = Directory.systemTemp;
            final tempFile = File('${tempDir.path}/tempImage.jpg');
            tempFile.writeAsBytesSync(decodedBytes);
            _image = tempFile;
          }
        });
      }
    } catch (e) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading draft: $e')));
      });
    }
  }

  // Button Handlers
  void _handlePublish() {
    if (_image == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please upload a product image')),
      );
      return;
    }
    uploadTaskToDb(isDraft: false);
  }

  void _handleDraft() => uploadTaskToDb(isDraft: true);

  void _handleCancel() {
    nameController.clear();
    descriptionController.clear();
    priceController.clear();
    setState(() {
      _image = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Sell Your Item',
          style: TextStyle(fontWeight: FontWeight.bold),
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
                  "Post your second-hand item to marketplace",
                  style: TextStyle(
                    fontSize: 20,
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
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
                    fontWeight: FontWeight.w900,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: nameController,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    hintText: "Enter product name",
                    hintStyle: const TextStyle(
                      fontSize: 15,
                      color: Colors.black,
                      fontWeight: FontWeight.w600,
                    ),
                    errorStyle: const TextStyle(color: Colors.red),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return "Please enter text only";
                    }
                    if (!RegExp(r'^[a-zA-Z\s]+$').hasMatch(value)) {
                      return "Please enter text only";
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
                                "Browser or Desktop",
                                style: TextStyle(
                                  color: Colors.black,
                                  fontWeight: FontWeight.w900,
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
                  controller: descriptionController,
                  maxLines: 4,
                  maxLength: 100,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    hintText:
                        "A detailed description of the product helps customers to learn more about the product.",
                    hintStyle: const TextStyle(
                      color: Colors.black,
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                    ),
                    counterText: "${descriptionController.text.length}/100",
                  ),
                  onChanged: (value) => setState(() {}),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return "Please enter item description";
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Product Price
                const Text(
                  "Product Price",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: priceController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    prefixText: "RM ",
                    prefixStyle: const TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.w500,
                    ),
                    hintText: "0.00",
                    hintStyle: const TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return "Please enter item price";
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),

                // Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _handleCancel,
                        icon: const Icon(Icons.delete_outline, size: 20),
                        label: const Text(
                          "Cancel",
                          style: TextStyle(fontWeight: FontWeight.w900),
                        ),
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
                      child: OutlinedButton.icon(
                        onPressed: _handleDraft,
                        icon: const Icon(Icons.drafts_outlined, size: 20),
                        label: const Text(
                          "Draft",
                          style: TextStyle(fontWeight: FontWeight.w900),
                        ),
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
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _handlePublish,
                    icon: const Icon(Icons.publish, size: 20),
                    label: const Text(
                      "Publish",
                      style: TextStyle(fontWeight: FontWeight.w900),
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
          ),
        ),
      ),
    );
  }
}
