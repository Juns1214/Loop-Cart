import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../../widget/custom_button.dart';
import '../../widget/custom_text_field.dart';

class SellItemPage extends StatefulWidget {
  const SellItemPage({super.key});

  @override
  State<SellItemPage> createState() => _SellItemPageState();
}

class _SellItemPageState extends State<SellItemPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();

  final User? user = FirebaseAuth.instance.currentUser;
  static const Color _primaryGreen = Color(0xFF2E7D32);

  File? _imageFile;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadDraft();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    super.dispose();
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

  Future<void> _uploadItem({required bool isDraft}) async {
    if (!_formKey.currentState!.validate()) return;
    if (!isDraft && _imageFile == null) {
      _showSnackBar('Please upload a product image');
      return;
    }

    setState(() => _isLoading = true);

    try {
      String? imageBase64;
      if (_imageFile != null) {
        final imageBytes = await _imageFile!.readAsBytes();
        imageBase64 = base64Encode(imageBytes);
      }

      await FirebaseFirestore.instance.collection("sell_items").add({
        "user_id": user?.uid,
        "name": _nameController.text.trim(),
        "description": _descriptionController.text.trim(),
        "image": imageBase64,
        "price": double.tryParse(_priceController.text.trim()) ?? 0.0,
        "status": isDraft ? "Draft" : "Active",
        "posted_at": FieldValue.serverTimestamp(),
      });

      if (mounted) {
        _showSnackBar(isDraft ? 'Draft saved' : 'Item published successfully!', isSuccess: true);
        if (!isDraft) _handleClear();
      }
    } catch (e) {
      _showSnackBar('Error uploading item');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadDraft() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('sell_items')
          .where('status', isEqualTo: 'Draft')
          .where('user_id', isEqualTo: user?.uid)
          .orderBy('posted_at', descending: true)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty && mounted) {
        final data = snapshot.docs.first.data();
        setState(() {
          _nameController.text = data['name'] ?? '';
          _descriptionController.text = data['description'] ?? '';
          _priceController.text = (data['price'] ?? 0.0).toString();
          if (data['image'] != null && data['image'] != '') {
            final decodedBytes = base64Decode(data['image']);
            final tempDir = Directory.systemTemp;
            final tempFile = File('${tempDir.path}/temp_${DateTime.now().millisecondsSinceEpoch}.jpg');
            tempFile.writeAsBytesSync(decodedBytes);
            _imageFile = tempFile;
          }
        });
      }
    } catch (_) {}
  }

  void _handleClear() {
    _nameController.clear();
    _descriptionController.clear();
    _priceController.clear();
    setState(() => _imageFile = null);
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
        title: const Text('Sell Your Item', style: TextStyle(fontFamily: 'Roboto', fontSize: 20, fontWeight: FontWeight.w800, color: Color(0xFF212121))),
        centerTitle: true,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionHeader('Item Information', 'Post your second-hand item to the marketplace'),
              CustomTextField(
                controller: _nameController,
                label: "Product Name",
                hintText: "E.g. Vintage Camera",
                validator: (value) {
                  if (value == null || value.isEmpty) return "Required";
                  if (!RegExp(r'^[a-zA-Z\s0-9]+$').hasMatch(value)) return "No special characters";
                  return null;
                },
              ),
              const SizedBox(height: 24),
              _buildLabel('Product Image'),
              const SizedBox(height: 8),
              _buildImagePicker(),
              const SizedBox(height: 24),
              CustomTextField(
                controller: _descriptionController,
                label: "Description",
                hintText: "Describe the condition, age, and features...",
                maxLines: 4,
                validator: (v) => (v == null || v.isEmpty) ? "Required" : null,
              ),
              const SizedBox(height: 24),
              CustomTextField(
                controller: _priceController,
                label: "Price",
                hintText: "0.00",
                prefixText: "RM ",
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}'))],
                validator: (v) => (v == null || v.isEmpty) ? "Required" : null,
              ),
              const SizedBox(height: 32),
              Row(
                children: [
                  Expanded(child: CustomButton(text: "Clear", backgroundColor: Colors.white, textColor: _primaryGreen, onPressed: _handleClear)),
                  const SizedBox(width: 12),
                  Expanded(child: CustomButton(text: "Save Draft", backgroundColor: Colors.white, textColor: _primaryGreen, onPressed: () => _uploadItem(isDraft: true))),
                ],
              ),
              const SizedBox(height: 12),
              CustomButton(text: "Publish Item", backgroundColor: _primaryGreen, minimumSize: const Size(double.infinity, 54), isLoading: _isLoading, onPressed: () => _uploadItem(isDraft: false)),
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
}