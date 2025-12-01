import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AddressForm extends StatefulWidget {
  final TextEditingController? line1Controller;
  final TextEditingController? line2Controller;
  final TextEditingController? cityController;
  final TextEditingController? postalController;
  final TextEditingController? stateController;
  final GlobalKey<FormState>? formKey;

  const AddressForm({
    super.key,
    this.line1Controller,
    this.line2Controller,
    this.cityController,
    this.postalController,
    this.stateController,
    this.formKey,
  });

  @override
  State<AddressForm> createState() => AddressFormState();
}

class AddressFormState extends State<AddressForm> {
  late final TextEditingController line1Controller;
  late final TextEditingController line2Controller;
  late final TextEditingController cityController;
  late final TextEditingController postalController;
  late final TextEditingController stateController;
  late final GlobalKey<FormState> _formKey;
  
  bool _isInternalController = false;

  @override
  void initState() {
    super.initState();
    _isInternalController = widget.line1Controller == null;
    
    line1Controller = widget.line1Controller ?? TextEditingController();
    line2Controller = widget.line2Controller ?? TextEditingController();
    cityController = widget.cityController ?? TextEditingController();
    postalController = widget.postalController ?? TextEditingController();
    stateController = widget.stateController ?? TextEditingController();
    _formKey = widget.formKey ?? GlobalKey<FormState>();
  }

  @override
  void dispose() {
    // Only dispose controllers if they were created internally
    if (_isInternalController) {
      line1Controller.dispose();
      line2Controller.dispose();
      cityController.dispose();
      postalController.dispose();
      stateController.dispose();
    }
    super.dispose();
  }

  InputDecoration _inputDecoration(String label, {bool isOptional = false}) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(
        fontFamily: 'Manrope',
        color: Colors.grey[600],
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
      filled: true,
      fillColor: Colors.white,
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
    );
  }

  bool validate() {
    // Check if at least one field is filled
    bool hasAnyData = line1Controller.text.isNotEmpty ||
        cityController.text.isNotEmpty ||
        postalController.text.isNotEmpty ||
        stateController.text.isNotEmpty;

    if (!hasAnyData) {
      return true; // Address is optional, so return true if all fields are empty
    }

    // If any field is filled, validate the form
    return _formKey.currentState?.validate() ?? false;
  }

  Map<String, String> getAddressData() {
    return {
      'line1': line1Controller.text.trim(),
      'line2': line2Controller.text.trim(),
      'city': cityController.text.trim(),
      'postal': postalController.text.trim(),
      'state': stateController.text.trim(),
    };
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextFormField(
            controller: line1Controller,
            decoration: _inputDecoration('Address Line 1'),
            style: TextStyle(
              fontFamily: 'Manrope',
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
            validator: (value) {
              // Only validate if any address field has data
              bool hasAnyData = line1Controller.text.isNotEmpty ||
                  cityController.text.isNotEmpty ||
                  postalController.text.isNotEmpty ||
                  stateController.text.isNotEmpty;

              if (hasAnyData && (value == null || value.trim().isEmpty)) {
                return 'Please enter Address Line 1';
              }
              return null;
            },
          ),
          const SizedBox(height: 18),
          
          TextFormField(
            controller: line2Controller,
            decoration: _inputDecoration('Address Line 2 (Optional)', isOptional: true),
            style: TextStyle(
              fontFamily: 'Manrope',
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 18),
          
          TextFormField(
            controller: cityController,
            decoration: _inputDecoration('City'),
            style: TextStyle(
              fontFamily: 'Manrope',
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
            validator: (value) {
              bool hasAnyData = line1Controller.text.isNotEmpty ||
                  cityController.text.isNotEmpty ||
                  postalController.text.isNotEmpty ||
                  stateController.text.isNotEmpty;

              if (hasAnyData && (value == null || value.trim().isEmpty)) {
                return 'Please enter your city';
              }
              return null;
            },
          ),
          const SizedBox(height: 18),
          
          TextFormField(
            controller: postalController,
            decoration: _inputDecoration('Postal Code'),
            style: TextStyle(
              fontFamily: 'Manrope',
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(5),
            ],
            validator: (value) {
              bool hasAnyData = line1Controller.text.isNotEmpty ||
                  cityController.text.isNotEmpty ||
                  postalController.text.isNotEmpty ||
                  stateController.text.isNotEmpty;

              if (hasAnyData && (value == null || value.trim().isEmpty)) {
                return 'Please enter postal code';
              }
              if (hasAnyData && value!.trim().length < 5) {
                return 'Postal code must be 5 digits';
              }
              return null;
            },
          ),
          const SizedBox(height: 18),
          
          TextFormField(
            controller: stateController,
            decoration: _inputDecoration('State'),
            style: TextStyle(
              fontFamily: 'Manrope',
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
            validator: (value) {
              bool hasAnyData = line1Controller.text.isNotEmpty ||
                  cityController.text.isNotEmpty ||
                  postalController.text.isNotEmpty ||
                  stateController.text.isNotEmpty;

              if (hasAnyData && (value == null || value.trim().isEmpty)) {
                return 'Please enter your state';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }
}