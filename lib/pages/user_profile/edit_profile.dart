import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'dart:io';
import '../../utils/address_form.dart';
import '../../widget/custom_text_field.dart';
import '../../widget/custom_button.dart';

class EditProfile extends StatefulWidget {
  const EditProfile({super.key});

  @override
  State<EditProfile> createState() => _EditProfileState();
}

class _EditProfileState extends State<EditProfile> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _dobController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final _addressFormKey = GlobalKey<AddressFormState>();

  File? _imageFile;
  String? _existingImageBase64;
  bool _isLoading = true, _isSaving = false;
  final User? user = FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _dobController.dispose();
    super.dispose();
  }

  Future<void> _loadUserProfile() async {
    if (user == null) return;
    try {
      final doc = await FirebaseFirestore.instance.collection('user_profile').doc(user!.uid).get();
      if (doc.exists) {
        final data = doc.data()!;
        setState(() {
          _nameController.text = data['name'] ?? '';
          _emailController.text = data['email'] ?? user!.email ?? '';
          _phoneController.text = data['phoneNumber']?.toString().replaceFirst('+60', '') ?? '';
          _dobController.text = data['dateOfBirth'] ?? '';
          _existingImageBase64 = data['profileImageURL'];
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      debugPrint('Error loading profile: $e');
    }
  }

  Future<void> _pickImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.gallery, maxWidth: 512, maxHeight: 512, imageQuality: 75);
      
      if (image != null) setState(() => _imageFile = File(image.path));
    } catch (e) {
      debugPrint('Error picking image: $e');
      Fluttertoast.showToast(msg: "Error selecting image", backgroundColor: const Color(0xFFD32F2F), textColor: Colors.white);
    }
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().subtract(const Duration(days: 365 * 18)),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) => Theme(data: Theme.of(context).copyWith(colorScheme: const ColorScheme.light(primary: Color(0xFF2E7D32))), child: child!),
    );
    if (picked != null) setState(() => _dobController.text = DateFormat('yyyy-MM-dd').format(picked));
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    try {
      final hasAddressData = _addressFormKey.currentState?.validate() == true;
      final phoneWithPrefix = _phoneController.text.trim().isNotEmpty ? '+60${_phoneController.text.trim()}' : '';

      Map<String, dynamic>? addressData;
      if (hasAddressData) addressData = _addressFormKey.currentState!.getAddressData();

      String? imageBase64;
      if (_imageFile != null) {
        final bytes = await _imageFile!.readAsBytes();
        imageBase64 = base64Encode(bytes);
      }

      Map<String, dynamic> updateData = {
        'updatedAt': Timestamp.now(),
        if (_nameController.text.isNotEmpty) 'name': _nameController.text.trim(),
        if (_emailController.text.isNotEmpty) 'email': _emailController.text.trim(),
        if (phoneWithPrefix.isNotEmpty) 'phoneNumber': phoneWithPrefix,
        if (_dobController.text.isNotEmpty) 'dateOfBirth': _dobController.text.trim(),
        if (addressData != null) 'address': addressData,
        if (imageBase64 != null) 'profileImageURL': imageBase64,
      };

      await FirebaseFirestore.instance.collection('user_profile').doc(user!.uid).set(updateData, SetOptions(merge: true));

      Fluttertoast.showToast(msg: "✓ Profile updated successfully!", backgroundColor: const Color(0xFF2E7D32), textColor: Colors.white);
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      Fluttertoast.showToast(msg: "Error updating: $e", backgroundColor: const Color(0xFFD32F2F), textColor: Colors.white);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F8F4),
      appBar: AppBar(
        elevation: 0, backgroundColor: Colors.white,
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF212121), size: 22), onPressed: () => Navigator.pop(context)),
        title: const Text('Edit Profile', style: TextStyle(fontFamily: 'Roboto', fontWeight: FontWeight.w800, color: Color(0xFF212121), fontSize: 22)),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF2E7D32), strokeWidth: 3))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    _buildAvatarSection(),
                    const SizedBox(height: 32),
                    _FormSection(
                      title: 'Personal Information',
                      subtitle: 'Update your personal details',
                      children: [
                        CustomTextField(
                          controller: _nameController,
                          label: 'Full Name',
                          hintText: 'Enter your full name',
                          validator: (value) => value?.isEmpty == true ? 'Name is required' : null,
                        ),
                        const SizedBox(height: 16),
                        CustomTextField(
                          controller: _emailController,
                          label: 'Email Address',
                          hintText: 'Enter your email',
                          keyboardType: TextInputType.emailAddress,
                          validator: (value) {
                            if (value?.isEmpty == true) return 'Email is required';
                            if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value!)) return 'Invalid email';
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        CustomTextField(
                          controller: _phoneController,
                          label: 'Phone Number',
                          hintText: 'Enter phone number',
                          keyboardType: TextInputType.phone,
                          prefixText: '+60 ',
                          validator: (value) {
                            if (value?.isEmpty == true) return null;
                            if (!RegExp(r'^\d{9,10}$').hasMatch(value!)) return 'Invalid phone number';
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        CustomTextField(
                          controller: _dobController,
                          label: 'Date of Birth',
                          hintText: 'Select your date of birth',
                          readOnly: true,
                          onTap: _selectDate,
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    _FormSection(
                      title: 'Address',
                      subtitle: 'Update your shipping address',
                      children: [AddressForm(key: _addressFormKey)],
                    ),
                    const SizedBox(height: 32),
                    CustomButton(
                      text: 'Save Changes',
                      onPressed: _handleSave,
                      isLoading: _isSaving,
                      backgroundColor: const Color(0xFF2E7D32),
                      minimumSize: const Size(double.infinity, 56),
                      borderRadius: 16,
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildAvatarSection() {
    final name = _nameController.text;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 100, height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: _imageFile == null && _existingImageBase64 == null ? const LinearGradient(colors: [Color(0xFF2E7D32), Color(0xFF66BB6A)]) : null,
                  boxShadow: [BoxShadow(color: const Color(0xFF2E7D32).withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 8))],
                ),
                child: ClipOval(
                  child: _imageFile != null
                      ? Image.file(_imageFile!, fit: BoxFit.cover)
                      : _existingImageBase64 != null
                          ? Image.memory(base64Decode(_existingImageBase64!), fit: BoxFit.cover, errorBuilder: (_, __, ___) => _buildDefaultAvatar(name))
                          : _buildDefaultAvatar(name),
                ),
              ),
              Positioned(
                bottom: 0, right: 0,
                child: GestureDetector(
                  onTap: _pickImage,
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2E7D32),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 3),
                      boxShadow: [BoxShadow(color: const Color(0xFF2E7D32).withOpacity(0.4), blurRadius: 8, offset: const Offset(0, 2))],
                    ),
                    child: const Icon(Icons.camera_alt, color: Colors.white, size: 18),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(name.isEmpty ? 'Your Name' : name, style: const TextStyle(fontFamily: 'Roboto', fontSize: 20, fontWeight: FontWeight.w800, color: Color(0xFF212121))),
          const SizedBox(height: 4),
          Text('Tap camera icon to change photo', style: const TextStyle(fontFamily: 'Roboto', fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF424242))),
        ],
      ),
    );
  }

  Widget _buildDefaultAvatar(String name) {
    return Container(
      decoration: const BoxDecoration(gradient: LinearGradient(colors: [Color(0xFF2E7D32), Color(0xFF66BB6A)])),
      child: Center(child: Text(name.isNotEmpty ? name[0].toUpperCase() : 'U', style: const TextStyle(fontFamily: 'Roboto', fontSize: 40, fontWeight: FontWeight.w800, color: Colors.white))),
    );
  }
}

class _FormSection extends StatelessWidget {
  final String title, subtitle;
  final List<Widget> children;

  const _FormSection({required this.title, required this.subtitle, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: const Color(0xFFE8F5E9), borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.edit_note, color: Color(0xFF2E7D32), size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontFamily: 'Roboto', fontSize: 19, fontWeight: FontWeight.w800, color: Color(0xFF1B5E20))),
                    const SizedBox(height: 2),
                    Text(subtitle, style: const TextStyle(fontFamily: 'Roboto', fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF424242))),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          ...children,
        ],
      ),
    );
  }
}