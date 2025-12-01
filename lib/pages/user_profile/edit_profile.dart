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

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
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
          
          // Remove +60 prefix if it exists in the database
          String phone = data['phoneNumber'] ?? '';
          if (phone.startsWith('+60')) {
            phone = phone.substring(3).trim();
          } else if (phone.startsWith('60')) {
            phone = phone.substring(2).trim();
          }
          _phoneController.text = phone;
          
          _dobController.text = data['dateOfBirth'] ?? '';
          
          // Load address data as map
          if (data['address'] != null && data['address'] is Map) {
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
      Fluttertoast.showToast(
        msg: "Error loading profile: ${e.toString()}",
        backgroundColor: Colors.red,
      );
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

    // Validate address form only if user has filled any address field
    bool hasAddressData = _line1Controller.text.isNotEmpty ||
        _cityController.text.isNotEmpty ||
        _postalController.text.isNotEmpty ||
        _stateController.text.isNotEmpty;

    if (hasAddressData && !_addressFormKey.currentState!.validate()) {
      Fluttertoast.showToast(msg: "Please complete the address information");
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
        imageBase64 = _existingImageBase64 ?? '';
      }

      // Prepare phone number with +60 prefix
      String phoneWithPrefix = _phoneController.text.trim().isNotEmpty 
          ? '+60${_phoneController.text.trim()}'
          : '';

      // Get address data
      Map<String, dynamic>? addressData;
      if (hasAddressData) {
        addressData = _addressFormKey.currentState!.getAddressData();
      }

      // Build update data - only include fields that are not empty
      Map<String, dynamic> updateData = {
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (_nameController.text.trim().isNotEmpty) {
        updateData['name'] = _nameController.text.trim();
      }
      if (_emailController.text.trim().isNotEmpty) {
        updateData['email'] = _emailController.text.trim();
      }
      if (phoneWithPrefix.isNotEmpty) {
        updateData['phoneNumber'] = phoneWithPrefix;
      }
      if (_dobController.text.trim().isNotEmpty) {
        updateData['dateOfBirth'] = _dobController.text.trim();
      }
      if (addressData != null) {
        updateData['address'] = addressData;
      }
      if (imageBase64 != null && imageBase64.isNotEmpty) {
        updateData['profileImageURL'] = imageBase64;
      }

      await FirebaseFirestore.instance
          .collection('user_profile')
          .doc(user!.uid)
          .set(updateData, SetOptions(merge: true));

      Fluttertoast.showToast(
        msg: "✓ Profile updated successfully!",
        backgroundColor: Color(0xFF388E3C),
        textColor: Colors.white,
        fontSize: 16,
      );
      Navigator.pop(context, true);
    } catch (e) {
      Fluttertoast.showToast(
        msg: "Error updating profile: ${e.toString()}",
        backgroundColor: Colors.red,
      );
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }

  InputDecoration _inputDecoration(String label, {bool readOnly = false, Widget? suffixIcon, String? prefixText}) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(
        fontFamily: 'Manrope',
        color: Colors.grey[600],
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
      filled: true,
      fillColor: readOnly ? Colors.grey[100] : Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.grey[300]!, width: 1.5),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.grey[300]!, width: 1.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Color(0xFF388E3C), width: 2.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.red[400]!, width: 1.5),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.red[400]!, width: 2.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      suffixIcon: suffixIcon,
      prefixText: prefixText,
      prefixStyle: TextStyle(
        fontFamily: 'Manrope',
        color: Colors.black87,
        fontSize: 16,
        fontWeight: FontWeight.w600,
      ),
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
          icon: Icon(Icons.arrow_back_ios_new, color: Colors.black87, size: 22),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Edit Profile',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.black87,
            fontFamily: 'Manrope',
            fontSize: 20,
          ),
        ),
        centerTitle: true,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                color: Color(0xFF388E3C),
                strokeWidth: 3,
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Profile Image Section with Enhanced Design
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Color(0xFF388E3C).withOpacity(0.3),
                            blurRadius: 20,
                            offset: Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Stack(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Color(0xFF388E3C).withOpacity(0.3),
                                width: 4,
                              ),
                            ),
                            child: CircleAvatar(
                              radius: 70,
                              backgroundColor: Colors.grey[200],
                              backgroundImage: _image != null
                                  ? FileImage(_image!)
                                  : (_existingImageBase64 != null && _existingImageBase64!.isNotEmpty
                                      ? MemoryImage(base64Decode(_existingImageBase64!))
                                      : AssetImage('assets/images/icon/LogoIcon.png')) as ImageProvider,
                            ),
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: InkWell(
                              onTap: _pickImageFromGallery,
                              child: Container(
                                padding: EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [Color(0xFF4CAF50), Color(0xFF388E3C)],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white, width: 4),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Color(0xFF388E3C).withOpacity(0.4),
                                      blurRadius: 8,
                                      offset: Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Icon(
                                  Icons.camera_alt_rounded,
                                  color: Colors.white,
                                  size: 22,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: 12),

                    Text(
                      'Tap to change profile picture',
                      style: TextStyle(
                        fontFamily: 'Manrope',
                        fontSize: 13,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),

                    SizedBox(height: 32),

                    // Form Fields with Enhanced Container
                    Container(
                      padding: EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.08),
                            blurRadius: 20,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Color(0xFF388E3C).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(
                                  Icons.person_rounded,
                                  color: Color(0xFF388E3C),
                                  size: 20,
                                ),
                              ),
                              SizedBox(width: 12),
                              Text(
                                'Personal Information',
                                style: TextStyle(
                                  fontFamily: 'Manrope',
                                  fontSize: 19,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 24),

                          // Name Field
                          TextFormField(
                            controller: _nameController,
                            decoration: _inputDecoration('Full Name'),
                            style: TextStyle(
                              fontFamily: 'Manrope',
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          SizedBox(height: 18),

                          // Email Field (Read-only)
                          TextFormField(
                            controller: _emailController,
                            decoration: _inputDecoration('Email', readOnly: true),
                            style: TextStyle(
                              fontFamily: 'Manrope',
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey[600],
                            ),
                            readOnly: true,
                            enabled: false,
                          ),
                          SizedBox(height: 18),

                          // Phone Field with +60 prefix
                          TextFormField(
                            controller: _phoneController,
                            decoration: _inputDecoration(
                              'Phone Number',
                              prefixText: '+60 ',
                            ),
                            style: TextStyle(
                              fontFamily: 'Manrope',
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                            keyboardType: TextInputType.phone,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                              LengthLimitingTextInputFormatter(11),
                            ],
                          ),
                          SizedBox(height: 18),

                          // Date of Birth Field
                          TextFormField(
                            controller: _dobController,
                            decoration: _inputDecoration(
                              'Date of Birth',
                              suffixIcon: Icon(
                                Icons.calendar_today_rounded,
                                color: Color(0xFF388E3C),
                                size: 22,
                              ),
                            ),
                            style: TextStyle(
                              fontFamily: 'Manrope',
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                            readOnly: true,
                            onTap: _selectDateOfBirth,
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: 20),

                    // Address Section
                    Container(
                      padding: EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.08),
                            blurRadius: 20,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.blue.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(
                                  Icons.location_on_rounded,
                                  color: Colors.blue[700],
                                  size: 20,
                                ),
                              ),
                              SizedBox(width: 12),
                              Text(
                                'Address Information',
                                style: TextStyle(
                                  fontFamily: 'Manrope',
                                  fontSize: 19,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 24),
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

                    SizedBox(height: 32),

                    // Save Button with Gradient
                    SizedBox(
                      width: double.infinity,
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          gradient: LinearGradient(
                            colors: [Color(0xFF4CAF50), Color(0xFF388E3C)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Color(0xFF388E3C).withOpacity(0.4),
                              blurRadius: 12,
                              offset: Offset(0, 6),
                            ),
                          ],
                        ),
                        child: ElevatedButton.icon(
                          onPressed: _isSaving ? null : _uploadProfileChanges,
                          icon: _isSaving
                              ? SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2.5,
                                  ),
                                )
                              : Icon(Icons.check_circle_rounded, size: 24),
                          label: Text(
                            _isSaving ? 'Saving Changes...' : 'Save Changes',
                            style: TextStyle(
                              fontFamily: 'Manrope',
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            foregroundColor: Colors.white,
                            shadowColor: Colors.transparent,
                            padding: const EdgeInsets.symmetric(vertical: 18),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                        ),
                      ),
                    ),

                    SizedBox(height: 24),
                  ],
                ),
              ),
            ),
    );
  }
}