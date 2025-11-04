import 'package:flutter/material.dart';

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

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(
        color: Colors.grey[600],
        fontSize: 14,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.grey[300]!),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.grey[300]!),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Color(0xFF2E5BFF), width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.red[300]!),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }

  bool validate() {
    return _formKey.currentState?.validate() ?? false;
  }

  Map<String, String> getAddressData() {
    return {
      'line1': line1Controller.text,
      'line2': line2Controller.text,
      'city': cityController.text,
      'postal': postalController.text,
      'state': stateController.text,
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
            decoration: _inputDecoration('Address Line 1 *'),
            validator: (value) =>
                value == null || value.isEmpty ? 'Please enter Address Line 1' : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: line2Controller,
            decoration: _inputDecoration('Address Line 2 (Optional)'),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: cityController,
            decoration: _inputDecoration('City *'),
            validator: (value) =>
                value == null || value.isEmpty ? 'Please enter your city' : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: postalController,
            decoration: _inputDecoration('Postal Code *'),
            keyboardType: TextInputType.number,
            validator: (value) =>
                value == null || value.isEmpty ? 'Please enter postal code' : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: stateController,
            decoration: _inputDecoration('State *'),
            validator: (value) =>
                value == null || value.isEmpty ? 'Please enter your state' : null,
          ),
        ],
      ),
    );
  }
}