import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../widget/custom_text_field.dart';

class AddressForm extends StatefulWidget {
  final TextEditingController? line1Controller;
  final TextEditingController? line2Controller;
  final TextEditingController? cityController;
  final TextEditingController? postalController;
  final TextEditingController? stateController;
  final GlobalKey<FormState>? formKey;
  final ValueChanged<String>? onStateChanged;

  const AddressForm({
    super.key,
    this.line1Controller,
    this.line2Controller,
    this.cityController,
    this.postalController,
    this.stateController,
    this.formKey,
    this.onStateChanged,
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
    if (_isInternalController) {
      line1Controller.dispose();
      line2Controller.dispose();
      cityController.dispose();
      postalController.dispose();
      stateController.dispose();
    }
    super.dispose();
  }

  // Helper to check if user has started typing in any field
  bool get _hasAnyData =>
      line1Controller.text.isNotEmpty ||
      cityController.text.isNotEmpty ||
      postalController.text.isNotEmpty ||
      stateController.text.isNotEmpty;

  bool validate() {
    if (!_hasAnyData) return true; // Optional if all empty
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
          CustomTextField(
            controller: line1Controller,
            label: 'Address Line 1',
            hintText: 'Enter address line 1',
            validator: (value) {
              if (_hasAnyData && (value == null || value.trim().isEmpty)) {
                return 'Please enter Address Line 1';
              }
              return null;
            },
          ),
          const SizedBox(height: 18),
          
          CustomTextField(
            controller: line2Controller,
            label: 'Address Line 2 (Optional)',
            hintText: 'Enter address line 2',
          ),
          const SizedBox(height: 18),
          
          CustomTextField(
            controller: cityController,
            label: 'City',
            hintText: 'Enter city',
            validator: (value) {
              if (_hasAnyData && (value == null || value.trim().isEmpty)) {
                return 'Please enter your city';
              }
              return null;
            },
          ),
          const SizedBox(height: 18),
          
          CustomTextField(
            controller: postalController,
            label: 'Postal Code',
            hintText: 'Enter postal code',
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(5),
            ],
            validator: (value) {
              if (_hasAnyData && (value == null || value.trim().isEmpty)) {
                return 'Please enter postal code';
              }
              if (_hasAnyData && value!.trim().length < 5) {
                return 'Postal code must be 5 digits';
              }
              return null;
            },
          ),
          const SizedBox(height: 18),
          
          CustomTextField(
            controller: stateController,
            label: 'State',
            hintText: 'Enter state',
            onChanged: widget.onStateChanged,
            validator: (value) {
              if (_hasAnyData && (value == null || value.trim().isEmpty)) {
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