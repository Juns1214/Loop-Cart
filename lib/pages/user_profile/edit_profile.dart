import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'dart:io';
import '../../utils/address_form.dart';
import '../../utils/router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);
  runApp(MyApp());
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
  
  // Address form controllers
  final TextEditingController _line1Controller = TextEditingController();
  final TextEditingController _line2Controller = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _postalController = TextEditingController();
  final TextEditingController _stateController = TextEditingController();
  
  // Form keys
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final GlobalKey<AddressFormState> _addressFormKey = GlobalKey<AddressFormState>();
  
  // Image
  File? _image;
  String? _existingImageBase64;
  
  // Loading state
  bool _isLoading = true;
  bool _isSaving = false;
  
  // User
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
    _stateController.dispose();
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
          _phoneController.text = data['phoneNumber'] ?? '';
          _dobController.text = data['dateOfBirth'] ?? '';
          
          // Load address data
          if (data['address'] != null) {
            final address = data['address'] as Map<String, dynamic>;
            _line1Controller.text = address['line1'] ?? '';
            _line2Controller.text = address['line2'] ?? '';
            _cityController.text = address['city'] ?? '';
            _postalController.text = address['postal'] ?? '';
            _stateController.text = address['state'] ?? '';
          }
          
          // Load existing image
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
      setState(() {
        _isLoading = false;
      });
      Fluttertoast.showToast(msg: "Error loading profile: ${e.toString()}");
    }
  }

  Future<void> _pickImageFromGallery() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        setState(() {
          _image = File(pickedFile.path);
        });
      }
    } catch (e) {
      Fluttertoast.showToast(msg: "Error picking image: ${e.toString()}");
    }
  }

  Future<String> _convertImageToBase64(File imageFile) async {
    List<int> imageBytes = await imageFile.readAsBytes();
    return base64Encode(imageBytes);
  }

  Future<void> _selectDateOfBirth() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _dobController.text.isNotEmpty
          ? DateFormat('dd/MM/yyyy').parse(_dobController.text)
          : DateTime(2000),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Color(0xFF388E3C),
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
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

    if (!_addressFormKey.currentState!.validate()) {
      Fluttertoast.showToast(msg: "Please complete the address");
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      String? imageBase64;
      
      // Convert new image to base64 if selected
      if (_image != null) {
        imageBase64 = await _convertImageToBase64(_image!);
      } else {
        imageBase64 = _existingImageBase64;
      }

      final addressData = _addressFormKey.currentState!.getAddressData();

      await FirebaseFirestore.instance
          .collection('user_profile')
          .doc(user!.uid)
          .set({
        'name': _nameController.text.trim(),
        'email': _emailController.text.trim(),
        'phoneNumber': _phoneController.text.trim(),
        'dateOfBirth': _dobController.text.trim(),
        'address': addressData,
        'profileImageURL': imageBase64,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      Fluttertoast.showToast(
        msg: "Profile updated successfully",
        backgroundColor: Colors.green,
      );
      Navigator.pop(context, true); // Return true to indicate success
    } catch (e) {
      Fluttertoast.showToast(msg: "Error updating profile: ${e.toString()}");
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }

  InputDecoration _inputDecoration(String label, {bool readOnly = false}) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(
        fontFamily: 'Manrope',
        color: Colors.grey[600],
        fontSize: 14,
      ),
      filled: readOnly,
      fillColor: readOnly ? Colors.grey[100] : Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey[300]!),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey[300]!),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Color(0xFF388E3C), width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.red[300]!),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Edit Profile',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.black87,
            fontFamily: 'Manrope',
          ),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(color: Color(0xFF388E3C)),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Profile Image Section
                    Stack(
                      children: [
                        CircleAvatar(
                          radius: 70,
                          backgroundColor: Colors.grey[200],
                          backgroundImage: _image != null
                              ? FileImage(_image!)
                              : (_existingImageBase64 != null && _existingImageBase64!.isNotEmpty
                                  ? MemoryImage(base64Decode(_existingImageBase64!))
                                  : AssetImage('assets/images/icon/LogoIcon.png')) as ImageProvider,
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: InkWell(
                            onTap: _pickImageFromGallery,
                            child: Container(
                              padding: EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Color(0xFF388E3C),
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 3),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.2),
                                    blurRadius: 5,
                                    offset: Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Icon(
                                Icons.camera_alt,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: 8),

                    Text(
                      'Tap to change profile picture',
                      style: TextStyle(
                        fontFamily: 'Manrope',
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),

                    SizedBox(height: 30),

                    // Form Fields
                    Container(
                      padding: EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Personal Information',
                            style: TextStyle(
                              fontFamily: 'Manrope',
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          SizedBox(height: 20),

                          // Name Field
                          TextFormField(
                            controller: _nameController,
                            decoration: _inputDecoration('Full Name *'),
                            style: TextStyle(fontFamily: 'Manrope'),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Please enter your name';
                              }
                              return null;
                            },
                          ),
                          SizedBox(height: 16),

                          // Email Field (Read-only)
                          TextFormField(
                            controller: _emailController,
                            decoration: _inputDecoration('Email', readOnly: true),
                            style: TextStyle(fontFamily: 'Manrope'),
                            readOnly: true,
                            enabled: false,
                          ),
                          SizedBox(height: 16),

                          // Phone Field
                          TextFormField(
                            controller: _phoneController,
                            decoration: _inputDecoration('Phone Number *').copyWith(
                              prefixText: '+60 ',
                              prefixStyle: TextStyle(
                                fontFamily: 'Manrope',
                                color: Colors.black87,
                              ),
                            ),
                            style: TextStyle(fontFamily: 'Manrope'),
                            keyboardType: TextInputType.phone,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Please enter your phone number';
                              }
                              if (value.trim().length < 9) {
                                return 'Enter a valid phone number';
                              }
                              return null;
                            },
                          ),
                          SizedBox(height: 16),

                          // Date of Birth Field
                          TextFormField(
                            controller: _dobController,
                            decoration: _inputDecoration('Date of Birth *').copyWith(
                              suffixIcon: Icon(Icons.calendar_today, color: Color(0xFF388E3C)),
                            ),
                            style: TextStyle(fontFamily: 'Manrope'),
                            readOnly: true,
                            onTap: _selectDateOfBirth,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Please select your date of birth';
                              }
                              return null;
                            },
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: 20),

                    // Address Section
                    Container(
                      padding: EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Address Information',
                            style: TextStyle(
                              fontFamily: 'Manrope',
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          SizedBox(height: 20),
                          AddressForm(
                            key: _addressFormKey,
                            line1Controller: _line1Controller,
                            line2Controller: _line2Controller,
                            cityController: _cityController,
                            postalController: _postalController,
                            stateController: _stateController,
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: 30),

                    // Save Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _isSaving ? null : _uploadProfileChanges,
                        icon: _isSaving
                            ? SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.check_circle_outline),
                        label: Text(
                          _isSaving ? 'Saving...' : 'Save Changes',
                          style: TextStyle(
                            fontFamily: 'Manrope',
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF388E3C),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 2,
                        ),
                      ),
                    ),

                    SizedBox(height: 20),
                  ],
                ),
              ),
            ),
    );
  }
}