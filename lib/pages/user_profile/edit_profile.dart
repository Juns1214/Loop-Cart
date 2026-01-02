import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'dart:io';

import '../../utils/address_form.dart';
import '../../utils/router.dart';
import '../../widget/custom_text_field.dart';
import '../../widget/custom_button.dart';


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
      initialRoute: "/edit-profile",
      onGenerateRoute: onGenerateRoute,
    );
  }
}

class EditProfile extends StatefulWidget {
  const EditProfile({super.key});

  @override
  State<EditProfile> createState() => _EditProfileState();
}

class _EditProfileState extends State<EditProfile> {
  // Controllers
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _dobController = TextEditingController();

  // Address Controllers (Using AddressForm widget logic)
  final TextEditingController _line1Controller = TextEditingController();
  final TextEditingController _line2Controller = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _postalController = TextEditingController();
  String? selectedState;

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final GlobalKey<AddressFormState> _addressFormKey =
      GlobalKey<AddressFormState>();

  File? _image;
  String? _existingImageBase64;
  bool _isLoading = true;
  bool _isSaving = false;

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
    _line1Controller.dispose();
    _line2Controller.dispose();
    _cityController.dispose();
    _postalController.dispose();
    super.dispose();
  }

  Future<void> _loadUserProfile() async {
    if (user == null) return;
    try {
      final doc = await FirebaseFirestore.instance
          .collection('user_profile')
          .doc(user!.uid)
          .get();
      if (doc.exists) {
        final data = doc.data()!;
        setState(() {
          _nameController.text = data['name'] ?? '';
          _emailController.text = data['email'] ?? user!.email ?? '';

          String phone = data['phoneNumber'] ?? '';
          if (phone.startsWith('+60')) {
            phone = phone.substring(3).trim();
          } else if (phone.startsWith('60'))
            phone = phone.substring(2).trim();
          _phoneController.text = phone;

          _dobController.text = data['dateOfBirth'] ?? '';

          if (data['address'] != null && data['address'] is Map) {
            final address = data['address'] as Map<String, dynamic>;
            _line1Controller.text = address['line1'] ?? '';
            _line2Controller.text = address['line2'] ?? '';
            _cityController.text = address['city'] ?? '';
            _postalController.text = address['postal'] ?? '';
            selectedState = address['state'] ?? '';
          }
          _existingImageBase64 = data['profileImageURL'];
          _isLoading = false;
        });
      } else {
        setState(() {
          _emailController.text = user!.email ?? '';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() => _isLoading = false);
      Fluttertoast.showToast(
        msg: "Error loading profile: $e",
        backgroundColor: Colors.red,
      );
    }
  }

  Future<void> _pickImageFromGallery() async {
    try {
      final XFile? pickedFile = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      if (pickedFile != null) {
        setState(() => _image = File(pickedFile.path));
      }
    } catch (e) {
      Fluttertoast.showToast(msg: "Error picking image: $e");
    }
  }

  Future<void> _selectDateOfBirth() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _dobController.text.isNotEmpty
          ? DateFormat('dd/MM/yyyy').parse(_dobController.text)
          : DateTime(2000),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(primary: Color(0xFF388E3C)),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() {
        _dobController.text = DateFormat('dd/MM/yyyy').format(picked);
      });
    }
  }

  Future<void> _uploadProfileChanges() async {
    if (!_formKey.currentState!.validate()) {
      Fluttertoast.showToast(msg: "Please fill in all required fields");
      return;
    }

    // Check if address form has data and validate it
    bool hasAddressData =
        _line1Controller.text.isNotEmpty || _cityController.text.isNotEmpty;
    if (hasAddressData && _addressFormKey.currentState?.validate() == false) {
      Fluttertoast.showToast(msg: "Please complete the address information");
      return;
    }

    setState(() => _isSaving = true);

    try {
      String? imageBase64 = _existingImageBase64 ?? '';
      if (_image != null) {
        List<int> imageBytes = await _image!.readAsBytes();
        imageBase64 = base64Encode(imageBytes);
      }

      String phoneWithPrefix = _phoneController.text.trim().isNotEmpty
          ? '+60${_phoneController.text.trim()}'
          : '';

      Map<String, dynamic>? addressData;
      if (hasAddressData) {
        addressData = _addressFormKey.currentState!.getAddressData();
      }

      // Only adding non-empty fields
      Map<String, dynamic> updateData = {
        'updatedAt': FieldValue.serverTimestamp(),
        if (_nameController.text.isNotEmpty)
          'name': _nameController.text.trim(),
        if (_emailController.text.isNotEmpty)
          'email': _emailController.text.trim(),
        if (phoneWithPrefix.isNotEmpty) 'phoneNumber': phoneWithPrefix,
        if (_dobController.text.isNotEmpty)
          'dateOfBirth': _dobController.text.trim(),
        if (addressData != null) 'address': addressData,
        if (imageBase64.isNotEmpty) 'profileImageURL': imageBase64,
      };

      await FirebaseFirestore.instance
          .collection('user_profile')
          .doc(user!.uid)
          .set(updateData, SetOptions(merge: true));

      Fluttertoast.showToast(
        msg: "✓ Profile updated successfully!",
        backgroundColor: const Color(0xFF388E3C),
        textColor: Colors.white,
      );
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      Fluttertoast.showToast(
        msg: "Error updating: $e",
        backgroundColor: Colors.red,
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50], 
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: Colors.black87,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Edit Profile',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            color: Colors.black87,
            fontFamily: 'Manrope',
            fontSize: 20,
          ),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF388E3C)),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    _buildAvatarSection(),
                    const SizedBox(height: 32),

                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSectionHeader(
                            title: 'Personal Information',
                            subtitle: 'Update your personal details',
                          ),
                          CustomTextField(
                            controller: _nameController,
                            label: 'Full Name',
                            hintText: 'Enter your name',
                            validator: (val) =>
                                val!.isEmpty ? 'Name required' : null,
                          ),
                          const SizedBox(height: 20),
                          CustomTextField(
                            controller: _emailController,
                            label: 'Email',
                            hintText: 'Email address',
                            readOnly: true, 
                          ),
                          const SizedBox(height: 20),
                          CustomTextField(
                            controller: _phoneController,
                            label: 'Phone Number',
                            hintText: '123456789',
                            prefixText: '+60 ',
                            keyboardType: TextInputType.phone,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                              LengthLimitingTextInputFormatter(11),
                            ],
                          ),
                          const SizedBox(height: 20),
                          CustomTextField(
                            controller: _dobController,
                            label: 'Date of Birth',
                            hintText: 'DD/MM/YYYY',
                            readOnly: true,
                            onTap: _selectDateOfBirth,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSectionHeader(
                            title: 'Address',
                            subtitle: 'Where should we deliver your orders?',
                          ),
                          AddressForm(
                            key: _addressFormKey,
                            line1Controller: _line1Controller,
                            line2Controller: _line2Controller,
                            cityController: _cityController,
                            postalController: _postalController,
                            selectedState:
                                selectedState, 
                            onStateChanged: (value) {
                              setState(() => selectedState = value);
                            },
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 32),

                    CustomButton(
                      text: "Save Changes",
                      onPressed: _uploadProfileChanges,
                      isLoading: _isSaving,
                      minimumSize: const Size(
                        double.infinity,
                        56,
                      ), // Full width
                    ),
                    const SizedBox(height: 24),
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

  Widget _buildAvatarSection() {
    return Center(
      child: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: const Color(0xFF388E3C).withOpacity(0.2),
                width: 4,
              ),
            ),
            child: CircleAvatar(
              radius: 65,
              backgroundColor: Colors.grey[200],
              backgroundImage: _image != null
                  ? FileImage(_image!)
                  : (_existingImageBase64 != null &&
                                _existingImageBase64!.isNotEmpty
                            ? MemoryImage(base64Decode(_existingImageBase64!))
                            : const AssetImage(
                                'assets/images/icon/LogoIcon.png',
                              ))
                        as ImageProvider,
            ),
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: GestureDetector(
              onTap: _pickImageFromGallery,
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF388E3C),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 3),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF388E3C).withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.camera_alt_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
